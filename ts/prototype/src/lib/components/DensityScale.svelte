<script lang="ts">
    import type { Entry } from "$lib/tracker/types";

    export let entries: Entry[] = [];

    // Date range - either use start/end dates or calculate from now
    export let startDate: Date | null = null;
    export let endDate: Date | null = null;

    // Fallback: hours back from now (only used if startDate/endDate not provided)
    export let hoursToShow: number = 24;
    export let now: Date = new Date();

    // Settings
    export let intervalMinutes: number = 60;
    export let maxCaloriesPerInterval: number = 500;
    export let showSettings: boolean = false;
    export let showLegend: boolean = false;

    // Interval options for the settings dropdown
    const intervalOptions = [
        { value: 15, label: '15 min' },
        { value: 30, label: '30 min' },
        { value: 60, label: '1 hour' },
        { value: 120, label: '2 hours' },
    ];

    // Compute effective date range
    $: effectiveStart = startDate ?? new Date(now.getTime() - hoursToShow * 60 * 60 * 1000);
    $: effectiveEnd = endDate ?? now;

    // Calculate time slots
    $: slots = calculateSlots(entries, effectiveStart, effectiveEnd, intervalMinutes);

    interface TimeSlot {
        startTime: Date;
        endTime: Date;
        calories: number;
        intensity: number;
        isCurrent: boolean;
    }

    function calculateSlots(
        entries: Entry[],
        start: Date,
        end: Date,
        interval: number
    ): TimeSlot[] {
        const slots: TimeSlot[] = [];
        const intervalMs = interval * 60 * 1000;

        // Align to interval boundary
        const alignedStart = new Date(
            Math.floor(start.getTime() / intervalMs) * intervalMs
        );
        const alignedEnd = new Date(
            Math.ceil(end.getTime() / intervalMs) * intervalMs
        );

        const totalSlots = Math.ceil((alignedEnd.getTime() - alignedStart.getTime()) / intervalMs);

        for (let i = 0; i < totalSlots; i++) {
            const slotStart = new Date(alignedStart.getTime() + i * intervalMs);
            const slotEnd = new Date(slotStart.getTime() + intervalMs);

            // Sum calories in this slot
            const slotCalories = entries
                .filter(e => e.createdAt >= slotStart && e.createdAt < slotEnd)
                .reduce((sum, e) => sum + e.value, 0);

            // Calculate intensity (0-4 like GitHub)
            const intensity = getIntensity(slotCalories, maxCaloriesPerInterval);

            // Check if this slot contains current time
            const currentTime = new Date();
            const isCurrent = currentTime >= slotStart && currentTime < slotEnd;

            slots.push({
                startTime: slotStart,
                endTime: slotEnd,
                calories: slotCalories,
                intensity,
                isCurrent,
            });
        }

        return slots;
    }

    function getIntensity(calories: number, max: number): number {
        if (calories === 0) return 0;
        const ratio = calories / max;
        if (ratio <= 0.25) return 1;
        if (ratio <= 0.5) return 2;
        if (ratio <= 0.75) return 3;
        return 4;
    }

    function getIntensityColor(intensity: number): string {
        const colors = [
            '#ebedf0',
            '#9be9a8',
            '#40c463',
            '#30a14e',
            '#216e39',
        ];
        return colors[intensity] || colors[0];
    }

    function formatSlotTime(date: Date): string {
        return date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        });
    }

    function formatSlotDate(date: Date): string {
        return date.toLocaleDateString('en-US', {
            weekday: 'short',
            month: 'short',
            day: 'numeric'
        });
    }

    // Tooltip state
    let hoveredSlot: TimeSlot | null = null;
    let tooltipX = 0;
    let tooltipY = 0;

    function handleMouseEnter(event: MouseEvent, slot: TimeSlot) {
        hoveredSlot = slot;
        const rect = (event.target as HTMLElement).getBoundingClientRect();
        tooltipX = rect.left + rect.width / 2;
        tooltipY = rect.top - 8;
    }

    function handleMouseLeave() {
        hoveredSlot = null;
    }

    // Settings panel toggle
    let settingsOpen = false;
</script>

<div class="density-wrapper">
    {#if showSettings}
        <div class="settings-row">
            <button
                    class="settings-toggle"
                    class:active={settingsOpen}
                    on:click={() => settingsOpen = !settingsOpen}
                    aria-label="Toggle settings"
            >
                ⚙️
            </button>
        </div>

        {#if settingsOpen}
            <div class="settings-panel">
                <div class="setting-row">
                    <label for="interval-select">Interval</label>
                    <select
                            id="interval-select"
                            bind:value={intervalMinutes}
                            class="setting-select"
                    >
                        {#each intervalOptions as option}
                            <option value={option.value}>{option.label}</option>
                        {/each}
                    </select>
                </div>
                {#if !startDate && !endDate}
                    <div class="setting-row">
                        <label for="hours-input">Hours</label>
                        <input
                                id="hours-input"
                                type="number"
                                bind:value={hoursToShow}
                                min="1"
                                max="720"
                                class="setting-input"
                        />
                    </div>
                {/if}
            </div>
        {/if}
    {/if}

    <div class="density-row">
        <div class="density-cells">
            {#each slots as slot}
                <div
                        class="density-cell"
                        class:is-current={slot.isCurrent}
                        style="background-color: {getIntensityColor(slot.intensity)}"
                        on:mouseenter={(e) => handleMouseEnter(e, slot)}
                        on:mouseleave={handleMouseLeave}
                        role="gridcell"
                        tabindex="0"
                ></div>
            {/each}
        </div>
        {#if showLegend}
            <div class="legend">
                {#each [0, 1, 2, 3, 4] as level}
                    <div
                            class="legend-cell"
                            style="background-color: {getIntensityColor(level)}"
                    ></div>
                {/each}
            </div>
        {/if}
    </div>
</div>

{#if hoveredSlot}
    <div
            class="tooltip"
            style="left: {tooltipX}px; top: {tooltipY}px"
    >
        <div class="tooltip-calories">
            {Math.round(hoveredSlot.calories)} kcal
        </div>
        <div class="tooltip-time">
            {formatSlotTime(hoveredSlot.startTime)} - {formatSlotTime(hoveredSlot.endTime)}
        </div>
        <div class="tooltip-date">
            {formatSlotDate(hoveredSlot.startTime)}
        </div>
    </div>
{/if}

<style>
    * {
        box-sizing: border-box;
    }

    .density-wrapper {
        width: 100%;
        overflow-x: auto;
    }

    .settings-row {
        display: flex;
        justify-content: flex-end;
        margin-bottom: 8px;
    }

    .settings-toggle {
        background: none;
        border: none;
        font-size: 1rem;
        cursor: pointer;
        padding: 4px 8px;
        border-radius: 8px;
        transition: background-color 0.2s;
    }

    .settings-toggle:hover {
        background-color: #f3f4f6;
    }

    .settings-toggle.active {
        background-color: #e5e7eb;
    }

    .settings-panel {
        background: #f9fafb;
        border-radius: 12px;
        padding: 12px 16px;
        margin-bottom: 12px;
        display: flex;
        gap: 16px;
        flex-wrap: wrap;
    }

    .setting-row {
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .setting-row label {
        font-size: 0.875rem;
        color: #4b5563;
    }

    .setting-select,
    .setting-input {
        padding: 6px 10px;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        font-size: 0.875rem;
        background: white;
    }

    .setting-input {
        width: 70px;
    }

    .density-row {
        display: flex;
        align-items: center;
        gap: 8px;
        overflow-x: auto;
    }

    .density-cells {
        display: flex;
        gap: 2px;
        flex-shrink: 0;
        flex-wrap: nowrap;
    }

    .density-cell {
        width: 10px;
        height: 10px;
        min-width: 10px;
        flex-shrink: 0;
        border-radius: 2px;
        cursor: pointer;
        transition: transform 0.1s;
    }

    .density-cell:hover {
        transform: scale(1.3);
        z-index: 1;
    }

    .density-cell.is-current {
        outline: 2px solid #3b82f6;
        outline-offset: 1px;
    }

    .legend {
        display: flex;
        gap: 2px;
        flex-shrink: 0;
    }

    .legend-cell {
        width: 10px;
        height: 10px;
        border-radius: 2px;
    }

    .tooltip {
        position: fixed;
        transform: translate(-50%, -100%);
        background: #1f2937;
        color: white;
        padding: 8px 12px;
        border-radius: 8px;
        font-size: 0.75rem;
        pointer-events: none;
        z-index: 1000;
        white-space: nowrap;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    }

    .tooltip::after {
        content: '';
        position: absolute;
        top: 100%;
        left: 50%;
        transform: translateX(-50%);
        border: 6px solid transparent;
        border-top-color: #1f2937;
    }

    .tooltip-calories {
        font-weight: 600;
        font-size: 0.875rem;
    }

    .tooltip-time {
        color: #9ca3af;
        margin-top: 2px;
    }

    .tooltip-date {
        color: #9ca3af;
        font-size: 0.7rem;
    }
</style>