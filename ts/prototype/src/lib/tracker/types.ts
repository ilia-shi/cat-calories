export type CompensationInfo = {
    /** Whether compensation is currently active (non-negligible adjustment) */
    isActive: boolean;
    /** Amount the target was adjusted by (negative = reduced, positive = increased) */
    amount: number;
    /** Human-readable explanation of the compensation */
    reason: string;
    /** Raw total deviation over the compensation window (unweighted) */
    rawDeviation: number;
}

export type MealRecommendation = {
    consumed24h: number;
    remaining24h: number;
    /** The effective (possibly compensated) 24h target */
    target24h: number;
    /** The original base target before compensation */
    baseTarget24h: number;
    recommendedMin: number;
    recommendedMax: number;
    waitUntil: Date | null;
    reasoning: string;
    hoursSinceLastMeal: number | null;
    lastMealTime: Date | null;
    percentUsed: number;
    /** Compensation information (if user has been over/under consuming) */
    compensation: CompensationInfo;
}

export type Day = {
    total: number;
    date: string;
    entries: Entry[];
}

export type Entry = {
    createdAt: Date;
    value: number;
}


export type BudgetForecast = {
    time: Date;
    availableBudget: number;
}

export type ExpiringEntry = {
    entry: Entry;
    expiresAt: Date;
}

export type RollingTrackerConfig = {
    targetDailyCalories: number;
    minMealSize: number;
    maxMealSize: number;
    minHoursBetweenMeals: number;
    compensation: {
        /**
         * How aggressively to compensate (0-1).
         * 0 = no compensation, 1 = full compensation
         */
        strength: number;
        /**
         * Decay factor for time-weighting (0-1).
         * Lower values = faster decay (more emphasis on recent periods)
         * 0.85 means each older period has 85% the weight of the previous
         */
        decayFactor: number;
        /**
         * How far back to look for compensation calculation (in hours).
         * Default 48 = look at last 2 days
         */
        windowHours: number;
    };
}