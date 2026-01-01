import type { Day, Entry } from "$lib/tracker/types";

export function groupEntries(entries: Entry[]): Day[] {
    const dayMap = new Map<string, Entry[]>();

    for (const entry of entries) {
        const dateKey = entry.createdAt.toISOString().split('T')[0];

        if (!dayMap.has(dateKey)) {
            dayMap.set(dateKey, []);
        }
        dayMap.get(dateKey)!.push(entry);
    }

    const days: Day[] = Array.from(dayMap.entries()).map(([date, dayEntries]) => ({
        date,
        entries: dayEntries.sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime()),
        total: dayEntries.reduce((sum, entry) => sum + entry.value, 0),
    }));

    return days.sort((a, b) => b.date.localeCompare(a.date));
}