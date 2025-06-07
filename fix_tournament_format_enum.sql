-- Fix tournament_format enum issue
-- Run this script in your Supabase SQL Editor

-- Step 1: Check what type the format column currently is
SELECT 
    column_name, 
    data_type, 
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tournaments' 
  AND column_name = 'format';

-- Step 2: If it's using a custom enum, we need to convert it to TEXT
-- First, let's alter the column to TEXT type
DO $$ 
BEGIN
    -- Try to alter the column to TEXT
    BEGIN
        ALTER TABLE public.tournaments ALTER COLUMN format TYPE TEXT;
        RAISE NOTICE 'Successfully converted format column to TEXT';
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'Column might already be TEXT or conversion failed: %', SQLERRM;
    END;
END $$;

-- Step 3: Drop any existing CHECK constraints on format
DO $$ 
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find and drop existing format constraints
    FOR constraint_name IN 
        SELECT conname
        FROM pg_constraint 
        WHERE conrelid = 'public.tournaments'::regclass 
          AND conname LIKE '%format%'
    LOOP
        EXECUTE 'ALTER TABLE public.tournaments DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Step 4: Add the correct CHECK constraint that includes all formats
ALTER TABLE public.tournaments 
ADD CONSTRAINT tournaments_format_check 
CHECK (format IN (
    'round_robin', 
    'swiss_ladder', 
    'single_elimination', 
    'double_elimination', 
    'custom_bracket', 
    'custom', 
    'swiss', 
    'tiered',
    'roundRobin',
    'singleElimination', 
    'doubleElimination'
));

-- Step 5: Try to drop the enum type if it exists
DO $$ 
BEGIN
    DROP TYPE IF EXISTS tournament_format CASCADE;
    RAISE NOTICE 'Dropped tournament_format enum type if it existed';
EXCEPTION 
    WHEN OTHERS THEN
        RAISE NOTICE 'No tournament_format enum type to drop or drop failed: %', SQLERRM;
END $$;

-- Step 6: Create tournament_groups table for tiered tournament group management
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

-- Step 7: Create tournament_tiers table for tiered tournament tier assignments
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

-- Step 8: Enable Row Level Security for new tables
ALTER TABLE public.tournament_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_tiers ENABLE ROW LEVEL SECURITY;

-- Step 9: RLS Policies for tournament_groups table
DROP POLICY IF EXISTS "Anyone can view tournament groups" ON public.tournament_groups;
CREATE POLICY "Anyone can view tournament groups" ON public.tournament_groups
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tournament organizers can manage groups" ON public.tournament_groups;
CREATE POLICY "Tournament organizers can manage groups" ON public.tournament_groups
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- Step 10: RLS Policies for tournament_tiers table  
DROP POLICY IF EXISTS "Anyone can view tournament tiers" ON public.tournament_tiers;
CREATE POLICY "Anyone can view tournament tiers" ON public.tournament_tiers
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Tournament organizers can manage tiers" ON public.tournament_tiers;
CREATE POLICY "Tournament organizers can manage tiers" ON public.tournament_tiers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- Step 11: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournament_groups_tournament_id ON public.tournament_groups(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_groups_group_number ON public.tournament_groups(group_number);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tournament_id ON public.tournament_tiers(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_team_id ON public.tournament_tiers(team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tier ON public.tournament_tiers(tier);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tier_seed ON public.tournament_tiers(tier, tier_seed);

-- Step 12: Create updated_at triggers for new tables
CREATE OR REPLACE FUNCTION update_tournament_groups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_tournament_groups_updated_at ON public.tournament_groups;
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

DROP TRIGGER IF EXISTS update_tournament_tiers_updated_at ON public.tournament_tiers;
CREATE TRIGGER update_tournament_tiers_updated_at
    BEFORE UPDATE
    ON public.tournament_tiers
    FOR EACH ROW
EXECUTE FUNCTION update_tournament_tiers_updated_at();

-- Step 13: Add comment to document the supported formats
COMMENT ON COLUMN public.tournaments.format IS 'Supported formats: round_robin, single_elimination, double_elimination, swiss, custom, tiered, roundRobin, singleElimination, doubleElimination';

-- Step 14: Final verification - show the current column info
SELECT 
    column_name, 
    data_type, 
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tournaments' 
  AND column_name = 'format';

-- Success message
SELECT 'Tournament format enum issue has been fixed successfully!' as status; 