import { supabase } from "../config/supabaseClient";
import { City } from "../models/city";

export const getAllCities = async (): Promise<City[]> => {
  const { data, error } = await supabase.from("cities").select("*");

  if (error) {
    console.error("Error fetching cities:", error);
    throw error;
  }

  return data as City[];
};

export const searchCities = async (query: string): Promise<City[]> => {
  const { data, error } = await supabase
    .from("cities")
    .select("*")
    .ilike("name_en", `%${query}%`);

  if (error) {
    console.error("Error searching cities:", error);
    throw error;
  }

  return data as City[];
};
