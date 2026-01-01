<script lang="ts">
    import type {MealRecommendation} from "$lib/tracker/types";

    export let recommendation: MealRecommendation;

    function getProgressColor(recommendation: MealRecommendation): string {
        return recommendation.percentUsed > 100 ? "#ef4444" : "#22c55e";
    }

    function getCompensationColor(amount: number): string {
        if (amount < -50) return "#ef4444"; // Red for significant reduction
        if (amount < 0) return "#f97316"; // Orange for moderate reduction
        if (amount > 50) return "#22c55e"; // Green for increase
        if (amount > 0) return "#84cc16"; // Light green for small increase

        return "#6b7280"; // Gray for no change
    }

    function getCompensationIcon(amount: number): string {
        if (amount < 0) return "📉";
        if (amount > 0) return "📈";

        return "➡️";
    }
</script>

<div style="width: 100%;" class="card highlight">
    <div class="card-header">
        <h2>📊 Rolling 24h Budget</h2>
        <span
                class="badge"
                style="background-color: {recommendation.percentUsed > 100
                    ? '#fef2f2'
                    : '#f0fdf4'}; color: {getProgressColor(recommendation)}"
        >
                {recommendation.percentUsed > 100 ? "Exceeded" : "On Track"}
            </span>
    </div>
    <div class="card-body">
        <div class="stats-row">
            <!-- Circular Progress -->
            <div class="circular-progress">
                <svg viewBox="0 0 100 100">
                    <circle
                            cx="50"
                            cy="50"
                            r="40"
                            fill="none"
                            stroke="#e5e7eb"
                            stroke-width="8"
                    />
                    <circle
                            cx="50"
                            cy="50"
                            r="40"
                            fill="none"
                            stroke={getProgressColor(recommendation)}
                            stroke-width="8"
                            stroke-dasharray={`${Math.min(100, recommendation.percentUsed) * 2.51} 251`}
                            stroke-linecap="round"
                            transform="rotate(-90 50 50)"
                    />
                </svg>
                <div class="progress-text">
                        <span
                                class="percent"
                                style="color: {getProgressColor(recommendation)}"
                        >
                            {Math.round(recommendation.percentUsed)}%
                        </span>
                    <span class="label">used</span>
                </div>
            </div>

            <!-- Stats Details -->
            <div class="stats-details">
                <div class="stat-row">
                    <span>Last 24h</span>
                    <strong style="color: {getProgressColor(recommendation)}"
                    >{Math.round(recommendation.consumed24h)} kcal</strong
                    >
                </div>
                <div class="stat-row">
                    <span>Target</span>
                    <strong>
                        {recommendation.target24h} kcal
                        {#if recommendation.compensation.isActive}
                                <span class="target-adjustment" style="color: {getCompensationColor(recommendation.compensation.amount)}">
                                    ({recommendation.compensation.amount > 0 ? '+' : ''}{recommendation.compensation.amount})
                                </span>
                        {/if}
                    </strong>
                </div>
                <div class="stat-row">
                    <span>Available</span>
                    <strong
                            style="color: {recommendation.remaining24h > 0
                                ? '#22c55e'
                                : '#ef4444'}"
                    >
                        {Math.round(recommendation.remaining24h)} kcal
                    </strong>
                </div>
            </div>
        </div>

        <!-- Progress Bar -->
        <div class="progress-bar-container">
            <div
                    class="progress-bar"
                    style="width: {Math.min(100, recommendation.percentUsed)}%; background-color: {getProgressColor(recommendation)}"
            ></div>
        </div>
        <div class="progress-labels">
            <span>0%</span>
            <span>50%</span>
            <span>100%</span>
        </div>

        <!-- Compensation Info -->
        {#if recommendation.compensation.isActive}
            <div class="compensation-box" style="border-color: {getCompensationColor(recommendation.compensation.amount)}40; background-color: {getCompensationColor(recommendation.compensation.amount)}10">
                <span class="compensation-icon">{getCompensationIcon(recommendation.compensation.amount)}</span>
                <div class="compensation-content">
                    <span class="compensation-label">Adaptive Target</span>
                    <span class="compensation-reason">{recommendation.compensation.reason}</span>
                    {#if recommendation.baseTarget24h !== recommendation.target24h}
                            <span class="compensation-detail">
                                Base: {recommendation.baseTarget24h} kcal → Adjusted: {recommendation.target24h} kcal
                            </span>
                    {/if}
                </div>
            </div>
        {/if}
    </div>
</div>

<style>
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

    /* Stats Row */
    .stats-row {
        display: flex;
        align-items: center;
        gap: 24px;
        margin-bottom: 16px;
    }

    .circular-progress {
        position: relative;
        width: 100px;
        height: 100px;
        flex-shrink: 0;
    }

    .circular-progress svg {
        width: 100%;
        height: 100%;
    }

    .progress-text {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        text-align: center;
    }

    .progress-text .percent {
        display: block;
        font-size: 1.5rem;
        font-weight: bold;
    }

    .progress-text .label {
        font-size: 0.75rem;
        color: #6b7280;
    }

    .stats-details {
        flex: 1;
    }

    .stat-row {
        display: flex;
        justify-content: space-between;
        margin-bottom: 8px;
    }

    .stat-row span {
        color: #6b7280;
    }

    .target-adjustment {
        font-size: 0.75rem;
        font-weight: 500;
        margin-left: 4px;
    }

    /* Progress Bar */
    .progress-bar-container {
        height: 8px;
        background: #e5e7eb;
        border-radius: 4px;
        overflow: hidden;
    }

    .progress-bar {
        height: 100%;
        border-radius: 4px;
        transition: width 0.3s ease;
    }

    .progress-labels {
        display: flex;
        justify-content: space-between;
        font-size: 0.625rem;
        color: #9ca3af;
        margin-top: 4px;
    }

    /* Compensation Box */
    .compensation-box {
        display: flex;
        align-items: flex-start;
        gap: 12px;
        margin-top: 16px;
        padding: 12px;
        border-radius: 10px;
        border: 1px solid;
    }

    .compensation-icon {
        font-size: 1.25rem;
        flex-shrink: 0;
    }

    .compensation-content {
        display: flex;
        flex-direction: column;
        gap: 2px;
    }

    .compensation-label {
        font-size: 0.75rem;
        font-weight: 600;
        color: #374151;
    }

    .compensation-reason {
        font-size: 0.875rem;
        color: #4b5563;
    }

    .compensation-detail {
        font-size: 0.75rem;
        color: #6b7280;
        margin-top: 2px;
    }
</style>