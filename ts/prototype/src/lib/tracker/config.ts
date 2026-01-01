import type {RollingTrackerConfig} from "$lib/tracker/types";

export const DEFAULT_CONFIG: RollingTrackerConfig = {
    targetDailyCalories: 2000,
    minMealSize: 100,
    maxMealSize: 1000,
    minHoursBetweenMeals: 2.0,
    compensation: {
        strength: 0.2,
        decayFactor: 0.85,
        windowHours: 96,
    }
};

export function getConfig(): RollingTrackerConfig {
    return DEFAULT_CONFIG;
}