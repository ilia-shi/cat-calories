/**
 * Type-compatibility check: hand-written types vs OpenAPI-generated types.
 *
 * This file does NOT run at runtime. It is validated at compile time via:
 *   npm run check:api-types
 *
 * If the hand-written types in `types.ts` diverge from the OpenAPI spec,
 * this file will produce TypeScript compilation errors.
 */

import type { components } from "../generated-api.js";
import type {
  CalorieRecord,
  Profile,
  ApiResponse,
  HomeDashboard,
  RecentMeal,
} from "../types.js";

// ---------- helpers ----------

/** Asserting A is assignable to B */
type AssertAssignable<_A extends B, B> = true;

// ---------- schema aliases ----------

type GenCalorieRecord = components["schemas"]["CalorieRecord"];
type GenProfile = components["schemas"]["Profile"];
type GenRecordsResponse = components["schemas"]["RecordsResponse"];
type GenHomeDashboard = components["schemas"]["HomeDashboardResponse"];
type GenRecentMeal = components["schemas"]["RecentMeal"];

// ---------- CalorieRecord ----------

export type CheckCR1 = AssertAssignable<CalorieRecord, GenCalorieRecord>;
export type CheckCR2 = AssertAssignable<GenCalorieRecord, CalorieRecord>;

// ---------- Profile ----------

export type CheckP1 = AssertAssignable<Profile, GenProfile>;
export type CheckP2 = AssertAssignable<GenProfile, Profile>;

// ---------- ApiResponse <-> RecordsResponse ----------

export type CheckAR1 = AssertAssignable<ApiResponse, GenRecordsResponse>;
export type CheckAR2 = AssertAssignable<GenRecordsResponse, ApiResponse>;

// ---------- RecentMeal ----------

export type CheckRM1 = AssertAssignable<RecentMeal, GenRecentMeal>;
export type CheckRM2 = AssertAssignable<GenRecentMeal, RecentMeal>;

// ---------- HomeDashboard <-> HomeDashboardResponse ----------

export type CheckHD1 = AssertAssignable<HomeDashboard, GenHomeDashboard>;
export type CheckHD2 = AssertAssignable<GenHomeDashboard, HomeDashboard>;
