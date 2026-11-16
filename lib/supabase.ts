import { createClient } from '@supabase/supabase-js'

// Før Supabase er koblet til (første gang appen legges ut) brukes en plassholder, så bygget
// går gjennom. Appen viser da feilmeldinger til nøklene er lagt inn i Vercel.
// Nøkkelen: den nye publishable-nøkkelen (sb_publishable_…) anbefales. Den gamle anon-nøkkelen virker også,
// men Supabase faser den ut ved slutten av 2026.
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
export const supabaseConfigured = !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!supabaseKey
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ikke-koblet-til.supabase.co'
const supabaseAnonKey = supabaseKey || 'ikke-koblet-til'

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
})

export type Item = {
  id: string
  room_id: string
  name: string
  quantity: number
  unit: string
  owner: 'person1' | 'person2' | 'person3'
  note?: string
  added_at: string
  updated_at: string
  status: 'active' | 'archived'
}

export type Room = {
  id: string
  slug: string
  person1_name: string
  person2_name: string
  person3_name: string
  created_at: string
}

export type HistoryEntry = {
  id: string
  room_id: string
  item_id?: string
  item_name: string
  action: string
  owner?: string
  quantity_before?: number
  quantity_after?: number
  timestamp: string
}
