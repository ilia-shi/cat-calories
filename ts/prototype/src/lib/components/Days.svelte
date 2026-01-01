<script lang="ts">
    import type { Entry, Day } from "$lib/tracker/types";
    import { groupEntries } from "$lib/tracker/days";
    import DensityScale from "$lib/components/DensityScale.svelte";

    export let entries: Entry[] = [];
    export let target24h: number = 2200;
    export let now: Date = new Date();

    $: todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

    $: days = groupEntries(entries);

    function getStatusColor(total: number): string {
        const percent = (total / target24h) * 100;
        if (percent < 80) return "#f97316"; // Orange - under
        if (percent <= 110) return "#22c55e"; // Green - on target

        return "#ef4444";
    }

    function getStatusText(total: number): string {
        const percent = (total / target24h) * 100;
        if (percent < 80) return "Under";
        if (percent <= 110) return "On Track";
        return "Over";
    }

    function isToday(dateStr: string): boolean {
        return dateStr === todayStr;
    }

    function formatDate(dateStr: string): string {
        if (isToday(dateStr)) {
            return "Today";
        }

        const date = new Date(dateStr + 'T00:00:00');

        return date.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric'
        });
    }

    function getDayStart(dateStr: string): Date {
        return new Date(dateStr + 'T00:00:00');
    }

    function getDayEnd(dateStr: string): Date {
        return new Date(dateStr + 'T23:59:59');
    }

    $: averageCalories = days.length > 0
        ? Math.round(days.reduce((sum, d) => sum + d.total, 0) / days.length)
        : 0;

    $: daysOnTarget = days.filter(d => {
        const percent = (d.total / target24h) * 100;
        return percent >= 80 && percent <= 110;
    }).length;
</script>

<div class="card">
    <div class="card-header">
        <h2>📅 Daily History</h2>
        <span class="badge" style="background-color: #f3f4f6; color: #374151">
            {days.length} day{days.length !== 1 ? 's' : ''}
        </span>
    </div>
    <div class="card-body">
        {#if days.length === 0}
            <div class="info-box gray">
                <span>ℹ️</span>
                <span>No entries logged yet.</span>
            </div>
        {:else}
            <!-- Summary Stats -->
            <div class="summary-row">
                <div class="summary-stat">
                    <span class="summary-value">{averageCalories}</span>
                    <span class="summary-label">kcal avg/day</span>
                </div>
                <div class="summary-stat">
                    <span class="summary-value" style="color: #22c55e">{daysOnTarget}</span>
                    <span class="summary-label">days on target</span>
                </div>
                <div class="summary-stat">
                    <span class="summary-value">{target24h}</span>
                    <span class="summary-label">kcal target</span>
                </div>
            </div>

            <!-- Days List -->
            <div class="days-list">
                {#each days as day}
                    {@const percent = Math.round((day.total / target24h) * 100)}
                    {@const statusColor = getStatusColor(day.total)}
                    {@const today = isToday(day.date)}
                    <div class="day-row" class:today-row={today}>
                        <div class="day-left">
                            <div class="day-date-wrapper">
                                <span class="day-date" class:today-date={today}>{formatDate(day.date)} ({day.entries.length})</span>
                            </div>
                        </div>
                        <div class="day-center">
                            <DensityScale
                                    entries={day.entries}
                                    startDate={getDayStart(day.date)}
                                    endDate={getDayEnd(day.date)}
                                    intervalMinutes={60}
                                    showLegend={false}
                            />
                        </div>
                        <div class="day-right">
                            <span class="day-total" style="color: {statusColor}">
                                {Math.round(day.total)} kcal {percent}%
                            </span>
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Weekly Average Bar -->
            <div class="average-section">
                <h3>📊 Period Average</h3>
                <div class="average-bar-container">
                    <div class="average-bar-bg">
                        <div
                                class="average-bar-fill"
                                style="width: {Math.min(100, (averageCalories / target24h) * 100)}%; background-color: {getStatusColor(averageCalories)}"
                        ></div>
                        <div class="target-line" style="left: 100%"></div>
                    </div>
                    <div class="average-labels">
                        <span>{averageCalories} kcal avg</span>
                        <span style="color: {getStatusColor(averageCalories)}">{getStatusText(averageCalories)}</span>
                    </div>
                </div>
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

    /* Info Box */
    .info-box {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        padding: 12px;
        border-radius: 10px;
        font-size: 0.875rem;
    }

    .info-box.gray {
        background: #f3f4f6;
        color: #4b5563;
    }

    /* Summary Row */
    .summary-row {
        display: flex;
        justify-content: space-around;
        padding: 16px;
        background: #f9fafb;
        border-radius: 12px;
        margin-bottom: 16px;
    }

    .summary-stat {
        text-align: center;
    }

    .summary-value {
        display: block;
        font-size: 1.25rem;
        font-weight: bold;
        color: #374151;
    }

    .summary-label {
        font-size: 0.75rem;
        color: #6b7280;
    }

    /* Days List */
    .days-list {
        margin-bottom: 16px;
    }

    .day-row {
        display: flex;
        align-items: center;
        padding: 12px 0;
        border-bottom: 1px solid #f3f4f6;
        gap: 12px;
    }

    .day-row:last-child {
        border-bottom: none;
    }

    /* Today highlight styles */
    .today-row {
        background: linear-gradient(90deg, #eff6ff 0%, #dbeafe 50%, #eff6ff 100%);
        margin: 0 -20px;
        padding: 16px 20px;
        border-radius: 12px;
        border-bottom: none;
        box-shadow: 0 2px 8px rgba(59, 130, 246, 0.15);
    }

    .today-badge {
        display: inline-block;
        background: #3b82f6;
        color: white;
        font-size: 0.625rem;
        font-weight: 700;
        padding: 2px 6px;
        border-radius: 4px;
        margin-right: 6px;
        letter-spacing: 0.5px;
    }

    .day-date-wrapper {
        display: flex;
        align-items: center;
    }

    .today-date {
        color: #1d4ed8 !important;
        font-weight: 600 !important;
    }

    .day-left {
        width: 110px;
        flex-shrink: 0;
    }

    .day-date {
        display: block;
        font-weight: 500;
        font-size: 0.875rem;
        color: #374151;
    }

    .day-entries {
        font-size: 0.75rem;
        color: #9ca3af;
    }

    .day-center {
        flex: 1;
        min-width: 0;
        overflow: hidden;
    }

    .day-right {
        width: 120px;
        text-align: right;
        flex-shrink: 0;
    }

    .day-total {
        display: block;
        font-weight: 600;
        font-size: 0.875rem;
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
        color: #374151;
    }

    .average-bar-container {
        position: relative;
    }

    .average-bar-bg {
        height: 12px;
        background: #e5e7eb;
        border-radius: 6px;
        overflow: hidden;
        position: relative;
    }

    .average-bar-fill {
        height: 100%;
        border-radius: 6px;
        transition: width 0.3s ease;
    }

    .target-line {
        position: absolute;
        top: -4px;
        width: 2px;
        height: 20px;
        background: #374151;
        transform: translateX(-50%);
    }

    .average-labels {
        display: flex;
        justify-content: space-between;
        font-size: 0.75rem;
        color: #6b7280;
        margin-top: 8px;
    }
</style>