-- Recreate teams table from scratch
-- ⚠️ WARNING: This will delete all existing team data!
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop the existing teams table completely (this will delete all data)
DROP TABLE IF EXISTS public.teams CASCADE;

-- Create the teams table with correct structure
CREATE TABLE public.teams (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  logo_url TEXT,
  manager_id UUID REFERENCES public.users(id),
  created_by UUID REFERENCES public.users(id), -- Added for consistency with tournaments table
  updated_by UUID REFERENCES public.users(id), -- Track who last updated the team
  category_id UUID, -- Will add FK constraint later if tournament_categories exists
  contact_email TEXT,
  contact_phone TEXT,
  seed INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique team names within each tournament
  UNIQUE(tournament_id, name)
);

-- Enable Row Level Security
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for teams table
CREATE POLICY "Anyone can view teams" ON public.teams
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create teams" ON public.teams
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Team managers and tournament organizers can update teams" ON public.teams
  FOR UPDATE USING (
    auth.uid() = manager_id OR
    auth.uid() = created_by OR
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND created_by = auth.uid()
    )
  );

CREATE POLICY "Team managers and tournament organizers can delete teams" ON public.teams
  FOR DELETE USING (
    auth.uid() = manager_id OR
    auth.uid() = created_by OR
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND created_by = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX idx_teams_tournament_id ON public.teams(tournament_id);
CREATE INDEX idx_teams_manager_id ON public.teams(manager_id);
CREATE INDEX idx_teams_created_by ON public.teams(created_by);
CREATE INDEX idx_teams_updated_by ON public.teams(updated_by);
CREATE INDEX idx_teams_category_id ON public.teams(category_id);
CREATE INDEX idx_teams_is_active ON public.teams(is_active);
CREATE INDEX idx_teams_name ON public.teams(name);

-- Add foreign key constraint for category_id if tournament_categories table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tournament_categories') THEN
    ALTER TABLE public.teams 
    ADD CONSTRAINT teams_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES public.tournament_categories(id) ON DELETE SET NULL;
    RAISE NOTICE 'Added foreign key constraint for category_id to tournament_categories';
  ELSE
    RAISE NOTICE 'tournament_categories table does not exist - skipping foreign key constraint (will be added when categories table is created)';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'Foreign key constraint already exists';
END $$;

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_teams_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid(); -- Set the updated_by to current user
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updating updated_at column
CREATE TRIGGER update_teams_updated_at
    BEFORE UPDATE
    ON public.teams
    FOR EACH ROW
EXECUTE FUNCTION update_teams_updated_at();

-- Success message
SELECT 'Teams table recreated successfully with correct structure!' as status; 