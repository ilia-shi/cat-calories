<script lang="ts">
    import type {BudgetForecast, ExpiringEntry} from "$lib/tracker/types";
    import {formatTimeUntil} from "$lib/tracker/format-time-until";

    export let forecast: BudgetForecast[];

    export let expirations: ExpiringEntry[];

    export let now: Date;
</script>
<!-- Budget Forecast -->
<div class="card">
    <div class="card-header">
        <h2>📈 Budget Forecast</h2>
        <span class="badge" style="background-color: #dbeafe; color: #3b82f6">
                Rolling 24h
            </span>
    </div>
    <div class="card-body">
        <p class="subtitle">
            Budget frees up as meals age past 24 hours
        </p>

        <!-- Forecast Chart -->
        <div class="forecast-chart">
            {#each forecast as point, i}
                {@const maxBudget = Math.max(...forecast.map((f) => f.availableBudget))}
                {@const minBudget = Math.min(...forecast.map((f) => f.availableBudget))}
                {@const range = maxBudget - minBudget || 1}
                {@const height = ((point.availableBudget - minBudget) / range) * 0.7 + 0.3}
                {@const isNow = i === 0}
                {@const isGrowing = point.availableBudget > forecast[0].availableBudget}
                <div class="forecast-bar-wrapper">
                        <span
                                class="forecast-value"
                                style="color: {isNow ? '#22c55e' : '#6b7280'}"
                        >
                            {Math.round(point.availableBudget)}
                        </span>
                    <div
                            class="forecast-bar"
                            style="height: {height * 100}%; background-color: {isNow
                                ? '#22c55e'
                                : isGrowing
                                  ? '#86efac'
                                  : '#93c5fd'}; {isNow
                                ? 'border: 2px solid #22c55e;'
                                : ''}"
                    ></div>
                    <span
                            class="forecast-label"
                            style="color: {isNow ? '#22c55e' : '#6b7280'}"
                    >
                            {isNow ? "Now" : `+${i * 2}h`}
                        </span>
                </div>
            {/each}
        </div>

        <!-- Upcoming Expirations -->
        {#if expirations.length > 0}
            <div class="expirations-section">
                <h3>🗓️ Upcoming Budget Release</h3>
                {#each expirations.slice(0, 4) as exp}
                    <div class="expiration-row">
                        <div class="expiration-left">
                            <span class="expiration-dot"></span>
                            <span class="expiration-value"
                            >+{exp.entry.value} kcal</span
                            >
                        </div>
                        <span class="expiration-time">
                                {formatTimeUntil(exp.expiresAt, now)}
                            </span>
                    </div>
                {/each}
                {#if expirations.length > 4}
                    <p class="more-text">+{expirations.length - 4} more...</p>
                {/if}
            </div>
        {:else}
            <div class="info-box gray">
                <span>ℹ️</span>
                <span
                >No meals expiring in the next 6 hours. Your budget will
                        stay consistent.</span
                >
            </div>
        {/if}
    </div>
</div>

<style>
    * {
        box-sizing: border-box;
    }

    .card {
        background: white;
        border-radius: 16px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        margin-bottom: 12px;
        overflow: hidden;
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

    .subtitle {
        font-size: 0.875rem;
        color: #6b7280;
        margin-bottom: 16px;
    }

    /* Forecast Chart */
    .forecast-chart {
        display: flex;
        gap: 4px;
        height: 120px;
        margin-bottom: 20px;
    }

    .forecast-bar-wrapper {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .forecast-value {
        font-size: 0.625rem;
        font-weight: 600;
        margin-bottom: 4px;
    }

    .forecast-bar {
        flex: 1;
        width: 100%;
        border-radius: 4px;
        min-height: 20px;
    }

    .forecast-label {
        font-size: 0.625rem;
        margin-top: 4px;
    }

    /* Expirations */
    .expirations-section {
        background: #f0fdf4;
        padding: 16px;
        border-radius: 12px;
    }

    .expirations-section h3 {
        font-size: 0.875rem;
        font-weight: 600;
        color: #166534;
        margin-bottom: 12px;
    }

    .expiration-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;
    }

    .expiration-left {
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .expiration-dot {
        width: 8px;
        height: 8px;
        background: #22c55e;
        border-radius: 50%;
    }

    .expiration-value {
        font-weight: 600;
        color: #166534;
    }

    .expiration-time {
        font-size: 0.75rem;
        color: #6b7280;
    }
</style>