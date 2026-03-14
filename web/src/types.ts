export interface CalorieRecord {
  id: number;
  value: number;
  description: string | null;
  created_at: string;
  eaten_at: string | null;
  weight_grams: number | null;
  protein_grams: number | null;
  fat_grams: number | null;
  carb_grams: number | null;
}

export interface Profile {
  name: string;
  calories_limit_goal: number;
}

export interface ApiResponse {
  profile: Profile;
  records: CalorieRecord[];
}
