import supabase from '../utils/supabaseClient';
import { Elephant } from '../models/elephant';

// Get elephants detected in the last 30 minutes and within 5km
export const getNearbyElephants = async (latitude: number, longitude: number): Promise<Elephant[]> => {
  const { data, error } = await supabase
    .from('alerts')
    .select('id, latitude, longitude, timestamp')
    .gte('timestamp', new Date(Date.now() - 30 * 60 * 1000).toISOString()) // Last 30 minutes
    .order('timestamp', { ascending: false });

  if (error) {
    console.error('Error fetching elephants:', error.message);
    throw new Error('Failed to fetch elephants');
  }

  // Filter elephants that are within 5km of the given coordinates
  return data.filter(elephant => {
    const distance = calculateDistance(latitude, longitude, elephant.latitude, elephant.longitude);
    return distance <= 5; // Only return elephants within 5km
  });
};

// Haversine formula to calculate distance between two points
export const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
  const R = 6371; // Radius of the Earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180); // Convert latitude difference to radians
  const dLon = (lon2 - lon1) * (Math.PI / 180); // Convert longitude difference to radians

  // Haversine formula
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in km
};

