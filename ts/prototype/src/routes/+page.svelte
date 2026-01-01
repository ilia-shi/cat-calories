<script lang="ts">
    import { type Entry, testEntries } from "./entries";
    import {
        getRecommendation,
        getForecast,
        getUpcomingExpirations,
        entriesInLast24h,
        getAverageDaily,
    } from "$lib/tracker/tracker";
    import type {MealRecommendation, RollingTrackerConfig, BudgetForecast} from "$lib/tracker/types";
    import Recommendation from "$lib/components/Recommendation.svelte";
    import Forecast from "$lib/components/Forecast.svelte";
    import Days from "$lib/components/Days.svelte";
    import DensityScale from "$lib/components/DensityScale.svelte";
    import {formatTime} from "$lib/format-time";
    import {formatDuration} from "$lib/format-duration";
    import {formatDate} from "$lib/format-date";
    import {DEFAULT_CONFIG} from "$lib/tracker/config";
    import {EntryRepository} from "$lib/tracker/entiry-repository";

    // Configuration
    const config: RollingTrackerConfig = DEFAULT_CONFIG;

    let entries: Entry[] = [...testEntries];

    const repo = new EntryRepository(entries);

    let newCalories: number | null = null;

    const baseDate = new Date("2025-01-10 00:00:00");
    let hoursOffset = 0;

    // Reactive calculations
    $: now = new Date(baseDate.getTime() + hoursOffset * 60 * 60 * 1000);
    $: recommendation = getRecommendation(entries, now, config);
    $: forecast = getForecast(entries, now, config, 12);
    $: expirations = getUpcomingExpirations(entries, now, 6);
    $: recentEntries = entriesInLast24h(entries, now);
    $: avgDaily = getAverageDaily(entries, now, 7);

    // Calculate eating window range from forecast
    type EatingWindow = {
        canEatNow: boolean;
        currentBudget: number;
        windows: Array<{
            hoursFromNow: number;
            availableKcal: number;
            time: Date;
        }>;
        summary: string;
    };

    function getEatingWindows(
        forecast: BudgetForecast[],
        recommendation: MealRecommendation,
        config: RollingTrackerConfig,
        currentTime: Date
    ): EatingWindow {
        const windows: EatingWindow['windows'] = [];
        const minMeal = config.minMealSize;

        // Check current situation
        const currentBudget = recommendation.remaining24h;
        const canEatNow = currentBudget >= minMeal &&
            (!recommendation.waitUntil || recommendation.waitUntil <= currentTime);

        // Analyze forecast to find key budget thresholds
        for (const point of forecast) {
            const hoursFromNow = (point.time.getTime() - currentTime.getTime()) / (1000 * 60 * 60);

            if (hoursFromNow > 0 && point.availableBudget >= minMeal) {
                windows.push({
                    hoursFromNow: Math.round(hoursFromNow * 10) / 10,
                    availableKcal: Math.round(point.availableBudget),
                    time: point.time,
                });
            }
        }

        // Generate summary
        let summary = '';

        if (currentBudget <= 0) {
            const firstWindow = windows.find(w => w.availableKcal >= minMeal);
            if (firstWindow) {
                summary = `${firstWindow.availableKcal} kcal available in ${formatHours(firstWindow.hoursFromNow)}`;
            } else {
                summary = "Budget depleted - wait for meals to expire";
            }
        } else if (canEatNow) {
            const laterWindow = windows.find(w => w.availableKcal > currentBudget + 100);
            if (laterWindow) {
                summary = `${Math.round(currentBudget)} kcal now → ${laterWindow.availableKcal} kcal in ${formatHours(laterWindow.hoursFromNow)}`;
            } else {
                summary = `${Math.round(currentBudget)} kcal available now`;
            }
        } else if (recommendation.waitUntil) {
            const waitHours = (recommendation.waitUntil.getTime() - currentTime.getTime()) / (1000 * 60 * 60);
            const budgetAtWait = windows.find(w => w.hoursFromNow >= waitHours);
            const laterWindow = windows.find(w => w.hoursFromNow > waitHours + 2 && w.availableKcal > currentBudget + 100);

            if (laterWindow && budgetAtWait) {
                summary = `${Math.round(currentBudget)} kcal in ${formatHours(waitHours)} → ${laterWindow.availableKcal} kcal in ${formatHours(laterWindow.hoursFromNow)}`;
            } else {
                summary = `${Math.round(currentBudget)} kcal in ${formatHours(waitHours)}`;
            }
        } else {
            // Edge case
            summary = `${Math.round(currentBudget)} kcal available`;
        }

        return {
            canEatNow,
            currentBudget,
            windows,
            summary,
        };
    }

    function formatHours(hours: number): string {
        if (hours < 1) {
            return `${Math.round(hours * 60)}m`;
        } else if (hours === Math.floor(hours)) {
            return `${hours}h`;
        } else {
            const h = Math.floor(hours);
            const m = Math.round((hours - h) * 60);
            return m > 0 ? `${h}h ${m}m` : `${h}h`;
        }
    }

    $: eatingWindow = getEatingWindows(forecast, recommendation, config, now);

    // Add a new entry
    function addEntry() {
        if (newCalories && newCalories > 0) {
            const entry: Entry = {
                createdAt: now,
                value: newCalories,
            };
            entries = [...entries, entry];
            newCalories = null;
        }
    }

    // Remove an entry
    function removeEntry(entryToRemove: Entry) {
        entries = entries.filter(
            (e) =>
                e.createdAt.getTime() !== entryToRemove.createdAt.getTime() ||
                e.value !== entryToRemove.value
        );
    }

    // Handle Enter key in input
    function handleKeydown(event: KeyboardEvent) {
        if (event.key === "Enter") {
            addEntry();
        }
    }

    function getTimingStatus(recommendation: MealRecommendation): {
        color: string;
        text: string;
        icon: string;
    } {
        if (recommendation.remaining24h <= 0) {
            return { color: "#ef4444", text: "Budget Used", icon: "⏳" };
        }
        if (!recommendation.waitUntil || recommendation.waitUntil <= now) {
            return { color: "#22c55e", text: "Ready to Eat!", icon: "🍽️" };
        }

        return { color: "#f97316", text: "Wait", icon: "⏰" };
    }

    function getMealAgeColor(hoursAgo: number): string {
        if (hoursAgo < 4) {
            return "#3b82f6";
        }

        if (hoursAgo < 12) {
            return "#f97316";
        }

        return "#22c55e";
    }

    $: timingStatus = getTimingStatus(recommendation);
</script>

<div class="container">
    <!-- Time Control -->
    <div class="card">
        <div class="card-header">
            <h2>⏱️ Time Simulation</h2>
        </div>
        <div class="card-body">
            <p class="now-display">Now: <strong>{formatDate(now)}</strong></p>
            <input
                    type="range"
                    min="-96"
                    max="120"
                    bind:value={hoursOffset}
                    class="slider"
            />
            <label class="slider-label"
            >Offset: {hoursOffset >= 0 ? "+" : ""}{hoursOffset} hours</label
            >
        </div>
    </div>

    <DensityScale entries={entries} now={now} />

    <!-- Add Entry Card -->
    <div class="card">
        <div class="card-header">
            <h2>➕ Log Meal</h2>
        </div>
        <div class="card-body">
            <div class="add-entry-form">
                <input
                        type="number"
                        bind:value={newCalories}
                        on:keydown={handleKeydown}
                        placeholder="Calories (kcal)"
                        min="1"
                        max="5000"
                        class="calorie-input"
                />
                <button
                        on:click={addEntry}
                        disabled={!newCalories || newCalories <= 0}
                        class="add-button"
                >
                    Add Entry
                </button>
            </div>
            <p class="form-hint">
                Entry will be logged at current time: {formatTime(now)}
            </p>
        </div>
    </div>

    <div style="display: flex; gap: 1rem;">
        <Recommendation recommendation={recommendation} />
        <div class="card" style="width: 100%;">
            <div class="card-header">
                <h2>🍽️ Meal Recommendation</h2>
                <span
                        class="badge"
                        style="background-color: {timingStatus.color}20; color: {timingStatus.color}"
                >
                    {timingStatus.icon}
                    {timingStatus.text}
                </span>
            </div>
            <div class="card-body">
                <!-- Eating Window Range - NEW -->
                <div class="eating-window-section" style="border-color: {timingStatus.color}40">
                    <div class="window-header">
                        <div
                                class="timing-icon"
                                style="background-color: {timingStatus.color}20"
                        >
                            <span style="font-size: 1.5rem">{timingStatus.icon}</span>
                        </div>
                        <div class="window-summary">
                            <span class="timing-label">Eating Window</span>
                            <span class="window-value" style="color: {timingStatus.color}">
                                {eatingWindow.summary}
                            </span>
                        </div>
                    </div>

                    <!-- Window Timeline -->
                    {#if eatingWindow.windows.length > 0 && !eatingWindow.canEatNow}
                        <div class="window-timeline">
                            {#each eatingWindow.windows.slice(0, 4) as window}
                                <div class="window-point">
                                    <div class="window-kcal">{window.availableKcal}</div>
                                    <div class="window-bar" style="height: {Math.min(100, (window.availableKcal / config.targetDailyCalories) * 100)}%"></div>
                                    <div class="window-time">+{formatHours(window.hoursFromNow)}</div>
                                </div>
                            {/each}
                        </div>
                    {:else if eatingWindow.canEatNow && eatingWindow.windows.length > 0}
                        <div class="window-timeline can-eat">
                            <div class="window-point now">
                                <div class="window-kcal">{Math.round(eatingWindow.currentBudget)}</div>
                                <div class="window-bar now-bar" style="height: {Math.min(100, (eatingWindow.currentBudget / config.targetDailyCalories) * 100)}%"></div>
                                <div class="window-time">Now</div>
                            </div>
                            {#each eatingWindow.windows.slice(0, 3) as window}
                                <div class="window-point">
                                    <div class="window-kcal">{window.availableKcal}</div>
                                    <div class="window-bar" style="height: {Math.min(100, (window.availableKcal / config.targetDailyCalories) * 100)}%"></div>
                                    <div class="window-time">+{formatHours(window.hoursFromNow)}</div>
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>

                <!-- Recommended Portion -->
                {#if recommendation.remaining24h > 0 && recommendation.recommendedMax > 0}
                    <div class="portion-section">
                        <h3>Recommended Portion</h3>
                        <div class="portion-scale">
                            <div class="scale-marker left">
                                <span class="scale-value" style="color: #f97316"
                                >{Math.round(recommendation.recommendedMin)}</span
                                >
                                <span class="scale-label">kcal</span>
                            </div>
                            <div class="scale-marker center">
                                <span class="scale-value" style="color: #22c55e">
                                    {Math.round(
                                        (recommendation.recommendedMin +
                                            recommendation.recommendedMax) /
                                        2
                                    )}
                                </span>
                                <span class="scale-label">kcal</span>
                            </div>
                            <div class="scale-marker right">
                                <span class="scale-value" style="color: #ef4444"
                                >{Math.round(recommendation.recommendedMax)}</span
                                >
                                <span class="scale-label">kcal</span>
                            </div>
                        </div>
                        <div class="portion-bar"></div>
                        <div class="portion-labels">
                            <span>Min</span>
                            <span>Ideal</span>
                            <span>Max</span>
                        </div>
                    </div>
                {/if}

                <!-- Last Meal Info -->
                {#if recommendation.lastMealTime}
                    <div class="info-box blue">
                        <span>🕐</span>
                        <div>
                            <span class="info-label">Last meal</span>
                            <span class="info-value">
                                {formatTime(recommendation.lastMealTime)} ({recommendation.hoursSinceLastMeal?.toFixed(
                                1
                            )}h ago)
                            </span>
                        </div>
                    </div>
                {/if}

                <!-- Reasoning -->
                <div class="info-box amber">
                    <span>💡</span>
                    <span>{recommendation.reasoning}</span>
                </div>
            </div>
        </div>
    </div>

    <Forecast
            forecast={forecast}
            expirations={expirations}
            now={now}
    />


    <Days entries={entries} target24h={config.targetDailyCalories} now={now} />

    <!-- Recent Meals (24h) -->
    <div class="card">
        <div class="card-header">
            <h2>🍴 Recent Meals (24h)</h2>
            <span class="badge" style="background-color: #f3f4f6; color: #374151">
                {recentEntries.length} meals
            </span>
        </div>
        <div class="card-body">
            {#if recentEntries.length === 0}
                <div class="info-box gray">
                    <span>ℹ️</span>
                    <span>No meals logged in the last 24 hours.</span>
                </div>
            {:else}
                <div class="meals-list">
                    {#each recentEntries.slice(0, 8) as entry}
                        {@const hoursAgo =
                            (now.getTime() - entry.createdAt.getTime()) /
                            (60 * 60 * 1000)}
                        {@const expiresIn = 24 - hoursAgo}
                        <div class="meal-row">
                            <div class="meal-left">
                                <div
                                        class="meal-dot"
                                        style="background-color: {getMealAgeColor(hoursAgo)}"
                                ></div>
                                <span class="meal-value">{entry.value} kcal</span>
                            </div>
                            <div class="meal-right">
                                <span class="meal-time">{formatTime(entry.createdAt)}</span>
                                <span
                                        class="meal-expires"
                                        style="color: {expiresIn < 2 ? '#22c55e' : '#6b7280'}"
                                >
                                    {expiresIn < 2
                                        ? `Expires in ${formatDuration(expiresIn)}`
                                        : `${formatDuration(hoursAgo)} ago`}
                                </span>
                            </div>
                            <button
                                    class="delete-button"
                                    on:click={() => removeEntry(entry)}
                                    aria-label="Remove entry"
                            >
                                ×
                            </button>
                        </div>
                    {/each}
                    {#if recentEntries.length > 8}
                        <p class="more-text">+{recentEntries.length - 8} more...</p>
                    {/if}
                </div>
            {/if}

            <!-- Average Section -->
            <div class="average-section">
                <h3>📊 7-Day Average</h3>
                <div class="average-row">
                    <div>
                        <span class="average-label">Daily average</span>
                        <span class="average-value">{Math.round(avgDaily)} kcal</span>
                    </div>
                    <div
                            class="average-indicator"
                            style="color: {avgDaily > config.targetDailyCalories
                            ? '#ef4444'
                            : avgDaily < config.targetDailyCalories * 0.9
                              ? '#f97316'
                              : '#22c55e'}"
                    >
                        {#if avgDaily > config.targetDailyCalories}
                            ↑ Over target
                        {:else if avgDaily < config.targetDailyCalories * 0.9}
                            ↓ Under target
                        {:else}
                            ✓ On track
                        {/if}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    * {
        box-sizing: border-box;
    }

    .container {
        max-width: 900px;
        margin: 0 auto;
        padding: 16px;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
        sans-serif;
    }

    .card {
        background: white;
        border-radius: 16px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        margin-bottom: 12px;
        overflow: hidden;
    }

    .card.highlight {
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }

    .card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px 20px 0;
    }

    .card-header h2 {
        margin: 0;
        font-size: 1.1rem;
        font-weight: 600;
        color: #1f2937;
    }

    .card-body {
        padding: 16px 20px 20px;
    }

    .badge {
        padding: 4px 10px;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    /* Time Simulation */
    .now-display {
        font-size: 1rem;
        margin-bottom: 12px;
    }

    .slider {
        width: 100%;
        height: 8px;
        border-radius: 4px;
        -webkit-appearance: none;
        appearance: none;
        background: #e5e7eb;
        outline: none;
    }

    .slider::-webkit-slider-thumb {
        -webkit-appearance: none;
        width: 20px;
        height: 20px;
        border-radius: 50%;
        background: #3b82f6;
        cursor: pointer;
    }

    .slider-label {
        display: block;
        text-align: center;
        margin-top: 8px;
        font-size: 0.875rem;
        color: #6b7280;
    }

    /* Add Entry Form */
    .add-entry-form {
        display: flex;
        gap: 12px;
    }

    .calorie-input {
        flex: 1;
        padding: 12px 16px;
        border: 2px solid #e5e7eb;
        border-radius: 10px;
        font-size: 1rem;
        transition: border-color 0.2s;
    }

    .calorie-input:focus {
        outline: none;
        border-color: #3b82f6;
    }

    .calorie-input::placeholder {
        color: #9ca3af;
    }

    .add-button {
        padding: 12px 24px;
        background: #22c55e;
        color: white;
        border: none;
        border-radius: 10px;
        font-size: 1rem;
        font-weight: 600;
        cursor: pointer;
        transition: background-color 0.2s, transform 0.1s;
    }

    .add-button:hover:not(:disabled) {
        background: #16a34a;
    }

    .add-button:active:not(:disabled) {
        transform: scale(0.98);
    }

    .add-button:disabled {
        background: #d1d5db;
        cursor: not-allowed;
    }

    .form-hint {
        margin-top: 8px;
        font-size: 0.75rem;
        color: #6b7280;
    }

    /* Delete Button */
    .delete-button {
        width: 28px;
        height: 28px;
        border: none;
        border-radius: 6px;
        background: #fee2e2;
        color: #ef4444;
        font-size: 0.75rem;
        font-weight: bold;
        cursor: pointer;
        transition: background-color 0.2s, transform 0.1s;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-left: 12px;
        flex-shrink: 0;
    }

    .delete-button:hover {
        background: #fecaca;
    }

    .delete-button:active {
        transform: scale(0.95);
    }

    /* Eating Window Section - NEW */
    .eating-window-section {
        padding: 16px;
        background: #f9fafb;
        border-radius: 12px;
        border: 1px solid;
        margin-bottom: 16px;
    }

    .window-header {
        display: flex;
        align-items: center;
        gap: 16px;
    }

    .window-summary {
        display: flex;
        flex-direction: column;
    }

    .window-value {
        font-size: 1.1rem;
        font-weight: bold;
    }

    .window-timeline {
        display: flex;
        justify-content: space-around;
        align-items: flex-end;
        height: 80px;
        margin-top: 16px;
        padding-top: 8px;
        border-top: 1px solid #e5e7eb;
    }

    .window-timeline.can-eat {
        margin-top: 12px;
    }

    .window-point {
        display: flex;
        flex-direction: column;
        align-items: center;
        flex: 1;
        max-width: 60px;
    }

    .window-point.now .window-bar {
        background: linear-gradient(to top, #22c55e, #86efac);
    }

    .window-kcal {
        font-size: 0.75rem;
        font-weight: 600;
        color: #374151;
        margin-bottom: 4px;
    }

    .window-bar {
        width: 24px;
        min-height: 8px;
        background: linear-gradient(to top, #3b82f6, #93c5fd);
        border-radius: 4px 4px 0 0;
        transition: height 0.3s ease;
    }

    .window-bar.now-bar {
        background: linear-gradient(to top, #22c55e, #86efac);
    }

    .window-time {
        font-size: 0.625rem;
        color: #6b7280;
        margin-top: 4px;
    }

    .window-point.now .window-time {
        color: #22c55e;
        font-weight: 600;
    }

    /* Timing Section */
    .timing-section {
        display: flex;
        align-items: center;
        gap: 16px;
        padding: 16px;
        background: #f9fafb;
        border-radius: 12px;
        border: 1px solid;
        margin-bottom: 16px;
    }

    .timing-icon {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .timing-info {
        display: flex;
        flex-direction: column;
    }

    .timing-label {
        font-size: 0.75rem;
        color: #6b7280;
    }

    .timing-value {
        font-size: 1.25rem;
        font-weight: bold;
    }

    .timing-subtitle {
        font-size: 0.75rem;
        color: #6b7280;
    }

    /* Portion Section */
    .portion-section {
        margin-bottom: 16px;
    }

    .portion-section h3 {
        font-size: 0.875rem;
        font-weight: 600;
        margin-bottom: 12px;
    }

    .portion-scale {
        display: flex;
        justify-content: space-between;
        margin-bottom: 8px;
    }

    .scale-marker {
        text-align: center;
        background: white;
        padding: 4px 8px;
        border-radius: 8px;
        box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
    }

    .scale-value {
        display: block;
        font-weight: bold;
        font-size: 0.875rem;
    }

    .scale-label {
        font-size: 0.625rem;
        color: #6b7280;
    }

    .portion-bar {
        height: 8px;
        border-radius: 4px;
        background: linear-gradient(
                to right,
                #d1d5db,
                #fdba74,
                #86efac,
                #fdba74,
                #d1d5db
        );
    }

    .portion-labels {
        display: flex;
        justify-content: space-between;
        font-size: 0.625rem;
        color: #6b7280;
        margin-top: 4px;
    }

    /* Info Box */
    .info-box {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        padding: 12px;
        border-radius: 10px;
        font-size: 0.875rem;
        margin-top: 12px;
    }

    .info-box.blue {
        background: #eff6ff;
        color: #1e40af;
    }

    .info-box.amber {
        background: #fffbeb;
        color: #92400e;
    }

    .info-box.gray {
        background: #f3f4f6;
        color: #4b5563;
    }

    .info-label {
        display: block;
        font-size: 0.75rem;
        opacity: 0.7;
    }

    .info-value {
        font-weight: 600;
    }

    /* Meals List */
    .meals-list {
        margin-bottom: 20px;
    }

    .meal-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 0;
        border-bottom: 1px solid #f3f4f6;
    }

    .meal-left {
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .meal-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
    }

    .meal-value {
        font-weight: 500;
    }

    .meal-right {
        text-align: right;
        flex: 1;
        margin-left: 16px;
    }

    .meal-time {
        display: block;
        font-size: 0.75rem;
        color: #6b7280;
    }

    .meal-expires {
        font-size: 0.625rem;
    }

    .more-text {
        font-size: 0.75rem;
        color: #6b7280;
        font-style: italic;
        margin-top: 8px;
    }

    /* Average Section */
    .average-section {
        background: #f9fafb;
        padding: 16px;
        border-radius: 12px;
    }

    .average-section h3 {
        font-size: 0.875rem;
        font-weight: 600;
        margin-bottom: 12px;
    }

    .average-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .average-label {
        display: block;
        font-size: 0.75rem;
        color: #6b7280;
    }

    .average-value {
        font-weight: bold;
        color: #374151;
    }
</style>