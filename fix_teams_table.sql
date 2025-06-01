-- Fix teams table - add missing columns
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create teams table with all required columns if it doesn't exist
CREATE TABLE IF NOT EXISTS public.teams (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  logo_url TEXT,
  manager_id UUID REFERENCES public.users(id),
  category_id UUID,
  contact_email TEXT,
  contact_phone TEXT,
  seed INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tournament_id, name)
);

-- Add missing columns if they don't exist
DO $$ 
BEGIN
  -- Add tournament_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'tournament_id') THEN
    ALTER TABLE public.teams ADD COLUMN tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE;
    RAISE NOTICE 'Added tournament_id column to teams table';
  ELSE
    RAISE NOTICE 'tournament_id column already exists in teams table';
  END IF;
  
  -- Add category_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'category_id') THEN
    ALTER TABLE public.teams ADD COLUMN category_id UUID;
    RAISE NOTICE 'Added category_id column to teams table';
  ELSE
    RAISE NOTICE 'category_id column already exists in teams table';
  END IF;
  
  -- Add contact_email column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'contact_email') THEN
    ALTER TABLE public.teams ADD COLUMN contact_email TEXT;
    RAISE NOTICE 'Added contact_email column to teams table';
  ELSE
    RAISE NOTICE 'contact_email column already exists in teams table';
  END IF;
  
  -- Add contact_phone column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'contact_phone') THEN
    ALTER TABLE public.teams ADD COLUMN contact_phone TEXT;
    RAISE NOTICE 'Added contact_phone column to teams table';
  ELSE
    RAISE NOTICE 'contact_phone column already exists in teams table';
  END IF;
  
  -- Add seed column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'seed') THEN
    ALTER TABLE public.teams ADD COLUMN seed INTEGER;
    RAISE NOTICE 'Added seed column to teams table';
  ELSE
    RAISE NOTICE 'seed column already exists in teams table';
  END IF;
  
  -- Add is_active column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'is_active') THEN
    ALTER TABLE public.teams ADD COLUMN is_active BOOLEAN DEFAULT true;
    RAISE NOTICE 'Added is_active column to teams table';
  ELSE
    RAISE NOTICE 'is_active column already exists in teams table';
  END IF;
  
  -- Add logo_url column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'logo_url') THEN
    ALTER TABLE public.teams ADD COLUMN logo_url TEXT;
    RAISE NOTICE 'Added logo_url column to teams table';
  ELSE
    RAISE NOTICE 'logo_url column already exists in teams table';
  END IF;
END $$;

-- Enable Row Level Security on teams table
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Drop existing policies and recreate them to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view teams" ON public.teams;
DROP POLICY IF EXISTS "Team managers can create teams" ON public.teams;
DROP POLICY IF EXISTS "Team managers can update their teams" ON public.teams;
DROP POLICY IF EXISTS "Team managers can delete their teams" ON public.teams;
DROP POLICY IF EXISTS "Tournament organizers can manage teams" ON public.teams;

-- Create comprehensive RLS policies for teams table
CREATE POLICY "Anyone can view teams" ON public.teams
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create teams" ON public.teams
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Team managers and tournament organizers can update teams" ON public.teams
  FOR UPDATE USING (
    auth.uid() = manager_id OR
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND created_by = auth.uid()
    )
  );

CREATE POLICY "Team managers and tournament organizers can delete teams" ON public.teams
  FOR DELETE USING (
    auth.uid() = manager_id OR
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND created_by = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_teams_tournament_id ON public.teams(tournament_id);
CREATE INDEX IF NOT EXISTS idx_teams_manager_id ON public.teams(manager_id);
CREATE INDEX IF NOT EXISTS idx_teams_category_id ON public.teams(category_id);
CREATE INDEX IF NOT EXISTS idx_teams_is_active ON public.teams(is_active);

-- Add foreign key constraint for category_id if tournament_categories table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tournament_categories') THEN
    -- Check if foreign key constraint already exists
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints 
      WHERE table_schema = 'public' 
      AND table_name = 'teams' 
      AND constraint_name = 'teams_category_id_fkey'
    ) THEN
      ALTER TABLE public.teams 
      ADD CONSTRAINT teams_category_id_fkey 
      FOREIGN KEY (category_id) REFERENCES public.tournament_categories(id) ON DELETE SET NULL;
      RAISE NOTICE 'Added foreign key constraint for category_id';
    ELSE
      RAISE NOTICE 'Foreign key constraint for category_id already exists';
    END IF;
  ELSE
    RAISE NOTICE 'tournament_categories table does not exist yet - skipping foreign key constraint';
  END IF;
END $$;

-- Success message
SELECT 'Teams table structure fixed successfully!' as status; 