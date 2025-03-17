export interface City {
    id: number;
    district_id: number;
    name_en: string;
    name_si: string;
    name_ta: string;
    sub_name_en?: string;
    sub_name_si?: string;
    sub_name_ta?: string;
    postcode?: string;
    latitude: number;
    longitude: number;
  }
  