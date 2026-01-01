import type {BudgetForecast, Entry, ExpiringEntry, MealRecommendation, RollingTrackerConfig} from "$lib/tracker/types";
import {DEFAULT_CONFIG} from "$lib/tracker/config";

export function consumedInLast24h(entries: Entry[], asOf: Date): number {
    const windowStart = new Date(asOf.getTime() - 24 * 60 * 60 * 1000);

    return entries
        .filter(e => e.createdAt > windowStart && e.createdAt <= asOf)
        .reduce((sum, e) => sum + e.value, 0);
}

/**
 * Get remaining budget in the rolling 24h window
 */
export function remainingBudget(entries: Entry[], asOf: Date, target24h: number): number {
    const consumed = consumedInLast24h(entries, asOf);

    return Math.max(0, Math.min(target24h, target24h - consumed));
}

/**
 * Get entries within the last 24 hours, sorted newest first
 */
export function entriesInLast24h(entries: Entry[], asOf: Date): Entry[] {
    const windowStart = new Date(asOf.getTime() - 24 * 60 * 60 * 1000);

    return entries
        .filter(e => e.createdAt > windowStart && e.createdAt <= asOf)
        .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
}

export function lastMealTime(entries: Entry[], asOf: Date): Date | null {
    const recent = entries.filter(e => e.createdAt <= asOf);
    if (recent.length === 0) {
        return null;
    }

    return recent.reduce((latest, e) =>
            e.createdAt > latest ? e.createdAt : latest,
        recent[0].createdAt
    );
}

/**
 * Get hours since last meal
 */
export function hoursSinceLastMeal(entries: Entry[], asOf: Date): number | null {
    const last = lastMealTime(entries, asOf);
    if (!last) {
        return null;
    }

    return (asOf.getTime() - last.getTime()) / (60 * 60 * 1000);
}

/**
 * Calculate time-weighted consumption deviation for compensation.
 *
 * This function analyzes consumption over the compensation window (e.g., 48 hours)
 * and calculates a weighted deviation from target, where more recent periods
 * have higher weight (controlled by decayFactor).
 *
 * @returns Object containing:
 *   - weightedDeviation: Net calories over/under target (positive = over-consumed)
 *   - totalWeight: Sum of all weights (for normalization)
 *   - periodBreakdown: Per-period analysis for debugging
 */
export function calculateWeightedDeviation(
    entries: Entry[],
    asOf: Date,
    config: RollingTrackerConfig
): {
    weightedDeviation: number;
    totalWeight: number;
    periodBreakdown: Array<{
        periodStart: Date;
        periodEnd: Date;
        hoursAgo: number;
        consumed: number;
        expected: number;
        deviation: number;
        weight: number;
        weightedDeviation: number;
    }>;
} {
    const {windowHours, decayFactor} = config.compensation;
    const targetPerHour = config.targetDailyCalories / 24;

    // Analyze in 6-hour periods for granularity while keeping computation reasonable
    const periodHours = 6;
    const numPeriods = Math.ceil(windowHours / periodHours);

    const periodBreakdown: Array<{
        periodStart: Date;
        periodEnd: Date;
        hoursAgo: number;
        consumed: number;
        expected: number;
        deviation: number;
        weight: number;
        weightedDeviation: number;
    }> = [];

    let totalWeightedDeviation = 0;
    let totalWeight = 0;

    for (let i = 0; i < numPeriods; i++) {
        const periodEndHoursAgo = i * periodHours;
        const periodStartHoursAgo = Math.min((i + 1) * periodHours, windowHours);

        // Skip if we're beyond the window
        if (periodEndHoursAgo >= windowHours) continue;

        const periodEnd = new Date(asOf.getTime() - periodEndHoursAgo * 60 * 60 * 1000);
        const periodStart = new Date(asOf.getTime() - periodStartHoursAgo * 60 * 60 * 1000);
        const actualPeriodHours = periodStartHoursAgo - periodEndHoursAgo;

        // Calculate consumption in this period
        const periodConsumed = entries
            .filter(e => e.createdAt > periodStart && e.createdAt <= periodEnd)
            .reduce((sum, e) => sum + e.value, 0);

        // Expected consumption for this period
        const expectedConsumption = targetPerHour * actualPeriodHours;

        // Deviation (positive = over-consumed)
        const deviation = periodConsumed - expectedConsumption;

        // Weight based on how recent the period is
        // decay^0 = 1 for most recent, decay^1 for next, etc.
        const weight = Math.pow(decayFactor, i);

        const weightedDev = deviation * weight;
        totalWeightedDeviation += weightedDev;
        totalWeight += weight;

        periodBreakdown.push({
            periodStart,
            periodEnd,
            hoursAgo: periodEndHoursAgo,
            consumed: periodConsumed,
            expected: expectedConsumption,
            deviation,
            weight,
            weightedDeviation: weightedDev,
        });
    }

    return {
        weightedDeviation: totalWeightedDeviation,
        totalWeight,
        periodBreakdown,
    };
}

/**
 * Calculate the compensated daily target based on recent consumption patterns.
 *
 * If the user has over-consumed, the target is reduced to help them get back on track.
 * If under-consumed, the target can be slightly increased.
 *
 * @returns Object containing:
 *   - adjustedTarget: The new effective daily calorie target
 *   - compensationAmount: How many calories the target was adjusted by (negative = reduced)
 *   - compensationReason: Human-readable explanation
 *   - rawDeviation: The unweighted total deviation
 */
export function getCompensatedTarget(
    entries: Entry[],
    asOf: Date,
    config: RollingTrackerConfig
): {
    adjustedTarget: number;
    compensationAmount: number;
    compensationReason: string;
    rawDeviation: number;
    isCompensating: boolean;
} {
    const {strength, windowHours} = config.compensation;
    const baseTarget = config.targetDailyCalories;

    // Calculate weighted deviation
    const {weightedDeviation, totalWeight, periodBreakdown} = calculateWeightedDeviation(
        entries,
        asOf,
        config
    );

    // Normalize by total weight to get average weighted deviation per period
    const normalizedDeviation = totalWeight > 0 ? weightedDeviation / totalWeight : 0;

    // Calculate raw (unweighted) total deviation for reference
    const rawDeviation = periodBreakdown.reduce((sum, p) => sum + p.deviation, 0);

    // Apply strength factor to determine compensation amount
    // We spread the compensation over the window period, so divide by windowHours/24
    // This means if you over-consumed 500 cal over 48h, you don't try to compensate all at once
    const windowDays = windowHours / 24;
    const compensationAmount = -(normalizedDeviation * strength);

    // Limit compensation to prevent extreme adjustments
    // Max reduction: 30% of base target
    // Max increase: 15% of base target (less aggressive for under-eating)
    const maxReduction = baseTarget * 0.3;
    const maxIncrease = baseTarget * 0.15;

    const clampedCompensation = Math.max(-maxReduction, Math.min(maxIncrease, compensationAmount));

    const adjustedTarget = Math.round(baseTarget + clampedCompensation);

    // Ensure target stays within reasonable bounds
    const minTarget = Math.round(baseTarget * 0.6); // Never go below 60% of base
    const maxTarget = Math.round(baseTarget * 1.2); // Never exceed 120% of base
    const finalTarget = Math.max(minTarget, Math.min(maxTarget, adjustedTarget));

    // Generate reason
    let compensationReason: string;
    const isCompensating = Math.abs(clampedCompensation) > 10;

    if (!isCompensating) {
        compensationReason = "On track with your targets.";
    } else if (clampedCompensation < 0) {
        const overBy = Math.round(-clampedCompensation);
        compensationReason = `Compensating for recent over-consumption. Target reduced by ${overBy} kcal.`;
    } else {
        const underBy = Math.round(clampedCompensation);
        compensationReason = `Room to catch up from under-consumption. Target increased by ${underBy} kcal.`;
    }

    return {
        adjustedTarget: finalTarget,
        compensationAmount: Math.round(clampedCompensation),
        compensationReason,
        rawDeviation: Math.round(rawDeviation),
        isCompensating,
    };
}

/**
 * Calculate recommended meal size
 */
function calculateMealSize(
    remainingBudget: number,
    consumedKCal: number,
    target24hKCal: number,
    config: RollingTrackerConfig
): {
    minKCal: number;
    maxKCal: number;
    reasoning: string
} {
    if (remainingBudget <= 50) {
        return {
            minKCal: 0,
            maxKCal: 0,
            reasoning: "You've reached your 24h target. Calories will free up as time passes."
        };
    }

    if (remainingBudget < config.minMealSize) {
        return {
            minKCal: 0,
            maxKCal: remainingBudget,
            reasoning: `Limited budget remaining (${Math.round(remainingBudget)} kcal). Small snack only if needed.`
        };
    }

    const avgMealSize = (config.minMealSize + config.maxMealSize) / 2;
    const estimatedMealsRemaining = Math.max(1, Math.min(4, remainingBudget / avgMealSize));
    const idealSize = remainingBudget / estimatedMealsRemaining;

    const minKCal = Math.max(config.minMealSize, Math.min(remainingBudget, idealSize * 0.7));
    const maxKCal = Math.max(minKCal, Math.min(config.maxMealSize, Math.min(remainingBudget, idealSize * 1.3)));

    const percentUsed = Math.round((consumedKCal / target24hKCal) * 100);
    const reasoning = `${percentUsed}% of 24h budget used. ${Math.round(remainingBudget)} kcal available for ~${Math.round(estimatedMealsRemaining)} more meal(s).`;

    return {
        minKCal: minKCal,
        maxKCal: maxKCal,
        reasoning: reasoning
    };
}

export function getRecommendation(
    entries: Entry[],
    now: Date,
    config: RollingTrackerConfig = DEFAULT_CONFIG
): MealRecommendation {
    // Ensure config has compensation settings
    const fullConfig: RollingTrackerConfig = {
        ...DEFAULT_CONFIG,
        ...config,
        compensation: {
            ...DEFAULT_CONFIG.compensation,
            ...config.compensation,
        }
    };

    // Get compensation-adjusted target
    const {
        adjustedTarget,
        compensationAmount,
        compensationReason,
        rawDeviation,
        isCompensating,
    } = getCompensatedTarget(entries, now, fullConfig);

    // Use adjusted target for calculations
    const consumed = consumedInLast24h(entries, now);
    const remaining = remainingBudget(entries, now, adjustedTarget);
    const hoursSinceLast = hoursSinceLastMeal(entries, now);
    const lastTime = lastMealTime(entries, now);

    // Should they wait before eating?
    let waitUntil: Date | null = null;
    if (hoursSinceLast !== null && hoursSinceLast < fullConfig.minHoursBetweenMeals && lastTime) {
        waitUntil = new Date(lastTime.getTime() + fullConfig.minHoursBetweenMeals * 60 * 60 * 1000);
    }

    // Calculate recommended meal size using adjusted target
    const {minKCal, maxKCal, reasoning} = calculateMealSize(
        remaining,
        consumed,
        adjustedTarget,
        fullConfig
    );

    const percentUsed = adjustedTarget > 0 ? (consumed / adjustedTarget) * 100 : 0;

    return {
        consumed24h: consumed,
        remaining24h: remaining,
        target24h: adjustedTarget,
        baseTarget24h: fullConfig.targetDailyCalories,
        recommendedMin: minKCal,
        recommendedMax: maxKCal,
        waitUntil,
        reasoning,
        hoursSinceLastMeal: hoursSinceLast,
        lastMealTime: lastTime,
        percentUsed,
        // Compensation info
        compensation: {
            isActive: isCompensating,
            amount: compensationAmount,
            reason: compensationReason,
            rawDeviation,
        },
    };
}

/**
 * Project when budget will free up (as old calories "expire" from the 24h window)
 */
export function getForecast(
    entries: Entry[],
    now: Date,
    config: RollingTrackerConfig = DEFAULT_CONFIG,
    hours: number = 12
): BudgetForecast[] {
    const forecasts: BudgetForecast[] = [];

    // Get current adjusted target
    const fullConfig: RollingTrackerConfig = {
        ...DEFAULT_CONFIG,
        ...config,
        compensation: {
            ...DEFAULT_CONFIG.compensation,
            ...config.compensation,
        }
    };

    const {adjustedTarget} = getCompensatedTarget(entries, now, fullConfig);

    for (let h = 0; h <= hours; h += 2) {
        const futureTime = new Date(now.getTime() + h * 60 * 60 * 1000);
        // Use adjusted target for forecast
        const futureRemaining = remainingBudget(entries, futureTime, adjustedTarget);
        forecasts.push({time: futureTime, availableBudget: futureRemaining});
    }

    return forecasts;
}

/**
 * Get entries that will "expire" (age past 24h) in the next N hours
 */
export function getUpcomingExpirations(
    entries: Entry[],
    now: Date,
    withinHours: number = 6
): ExpiringEntry[] {
    const windowStart = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const windowEnd = new Date(now.getTime() - (24 - withinHours) * 60 * 60 * 1000);

    return entries
        .filter(e => e.createdAt > windowStart && e.createdAt < windowEnd)
        .map(entry => ({
            entry,
            expiresAt: new Date(entry.createdAt.getTime() + 24 * 60 * 60 * 1000)
        }))
        .sort((a, b) => a.expiresAt.getTime() - b.expiresAt.getTime());
}

/**
 * Get long-term average daily consumption (for compensation)
 */
export function getAverageDaily(
    entries: Entry[],
    asOf: Date,
    days: number = 7
): number {
    const startDate = new Date(asOf.getTime() - days * 24 * 60 * 60 * 1000);

    const relevantEntries = entries.filter(e =>
        e.createdAt > startDate && e.createdAt < asOf
    );

    if (relevantEntries.length === 0) return 0;

    const total = relevantEntries.reduce((sum, e) => sum + e.value, 0);

    return total / days;
}

