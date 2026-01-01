export function formatTimeUntil(target: Date, now: Date): string {
    const diffMs = target.getTime() - now.getTime();
    if (diffMs <= 0) return 'Now';

    const hours = Math.floor(diffMs / (60 * 60 * 1000));
    const minutes = Math.round((diffMs % (60 * 60 * 1000)) / (60 * 1000));

    if (hours > 0) {
        return `in ${hours}h ${minutes}m`;
    }

    return `in ${minutes}m`;
}