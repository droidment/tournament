-- Migration to add tiered tournament format support
-- Run this script in your Supabase SQL Editor

-- First, we need to drop the existing CHECK constraint on format column and add a new one
-- Check if the constraint exists and drop it
DO $$ 
BEGIN
  -- Drop existing format check constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name LIKE '%format%' 
    AND constraint_schema = 'public'
  ) THEN
    -- Find and drop the constraint
    EXECUTE (
      SELECT 'ALTER TABLE public.tournaments DROP CONSTRAINT ' || constraint_name
      FROM information_schema.check_constraints 
      WHERE constraint_name LIKE '%format%' 
      AND constraint_schema = 'public'
      LIMIT 1
    );
  END IF;
END $$;

-- Add new CHECK constraint that includes 'tiered'
ALTER TABLE public.tournaments 
ADD CONSTRAINT tournaments_format_check 
CHECK (format IN ('round_robin', 'swiss_ladder', 'single_elimination', 'double_elimination', 'custom_bracket', 'custom', 'swiss', 'tiered'));

-- Add a comment to document the supported formats
COMMENT ON COLUMN public.tournaments.format IS 'Supported formats: round_robin, single_elimination, double_elimination, swiss, custom, tiered';

-- Create tournament_groups table for tiered tournament group management
CREATE TABLE IF NOT EXISTS public.tournament_groups (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  group_name VARCHAR(50) NOT NULL, -- 'A', 'B', 'C', etc.
  group_number INTEGER NOT NULL,
  teams_data JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of team assignments
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique group names and numbers per tournament
  UNIQUE(tournament_id, group_name),
  UNIQUE(tournament_id, group_number)
);

-- Create tournament_tiers table for tiered tournament tier assignments
CREATE TABLE IF NOT EXISTS public.tournament_tiers (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
  tier VARCHAR(20) NOT NULL CHECK (tier IN ('pro', 'intermediate', 'novice')),
  group_position INTEGER NOT NULL, -- Position within the group (1st, 2nd, 3rd, etc.)
  group_points INTEGER NOT NULL DEFAULT 0, -- Points earned in group stage
  point_differential INTEGER NOT NULL DEFAULT 0, -- Point differential from group stage
  tier_seed INTEGER NOT NULL, -- Seed within the tier for playoffs
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique team assignments per tournament
  UNIQUE(tournament_id, team_id),
  -- Ensure unique tier seeds per tier per tournament
  UNIQUE(tournament_id, tier, tier_seed)
);

-- Enable Row Level Security for new tables
ALTER TABLE public.tournament_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_tiers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tournament_groups table
CREATE POLICY "Anyone can view tournament groups" ON public.tournament_groups
  FOR SELECT USING (true);

CREATE POLICY "Tournament organizers can manage groups" ON public.tournament_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- RLS Policies for tournament_tiers table  
CREATE POLICY "Anyone can view tournament tiers" ON public.tournament_tiers
  FOR SELECT USING (true);

CREATE POLICY "Tournament organizers can manage tiers" ON public.tournament_tiers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournament_groups_tournament_id ON public.tournament_groups(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_groups_group_number ON public.tournament_groups(group_number);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tournament_id ON public.tournament_tiers(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_team_id ON public.tournament_tiers(team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tier ON public.tournament_tiers(tier);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tier_seed ON public.tournament_tiers(tier, tier_seed);

-- Create updated_at triggers for new tables
CREATE OR REPLACE FUNCTION update_tournament_groups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tournament_groups_updated_at
    BEFORE UPDATE
    ON public.tournament_groups
    FOR EACH ROW
EXECUTE FUNCTION update_tournament_groups_updated_at();

CREATE OR REPLACE FUNCTION update_tournament_tiers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tournament_tiers_updated_at
    BEFORE UPDATE
    ON public.tournament_tiers
    FOR EACH ROW
EXECUTE FUNCTION update_tournament_tiers_updated_at();

-- Success message
SELECT 'Tiered tournament format support added successfully!' as status; 