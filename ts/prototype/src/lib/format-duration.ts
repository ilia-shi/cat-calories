/**
 * Format duration
 */
export function formatDuration(hours: number): string {
    const h = Math.floor(hours);
    const m = Math.round((hours - h) * 60);

    if (h > 0) {
        return `${h}h ${m}m`;
    }
    return `${m}m`;
}
