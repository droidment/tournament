-- Targeted fix for tournament_groups table
-- This will ensure the table has the correct schema

-- First, let's check what exists
DO $$
BEGIN
    -- Check if tournament_groups table exists and what columns it has
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tournament_groups' AND table_schema = 'public') THEN
        RAISE NOTICE 'tournament_groups table exists, checking columns...';
        
        -- Check if team_ids column exists
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tournament_groups' AND column_name = 'team_ids' AND table_schema = 'public') THEN
            RAISE NOTICE 'team_ids column missing, adding it...';
            ALTER TABLE tournament_groups ADD COLUMN team_ids TEXT[] NOT NULL DEFAULT '{}';
        ELSE
            RAISE NOTICE 'team_ids column already exists';
        END IF;
        
    ELSE
        RAISE NOTICE 'tournament_groups table does not exist, creating it...';
        
        -- Create the table
        CREATE TABLE tournament_groups (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
            group_name TEXT NOT NULL,
            group_number INTEGER NOT NULL,
            team_ids TEXT[] NOT NULL DEFAULT '{}',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            
            UNIQUE(tournament_id, group_number),
            UNIQUE(tournament_id, group_name)
        );
        
        -- Create indexes
        CREATE INDEX idx_tournament_groups_tournament_id ON tournament_groups(tournament_id);
        CREATE INDEX idx_tournament_groups_group_number ON tournament_groups(tournament_id, group_number);
        
        RAISE NOTICE 'tournament_groups table created successfully';
    END IF;
END $$;

-- Also ensure tournament_tiers table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tournament_tiers' AND table_schema = 'public') THEN
        RAISE NOTICE 'Creating tournament_tiers table...';
        
        CREATE TABLE tournament_tiers (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
            team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
            tier TEXT NOT NULL CHECK (tier IN ('pro', 'intermediate', 'novice')),
            group_position INTEGER NOT NULL,
            group_points INTEGER NOT NULL DEFAULT 0,
            point_differential INTEGER NOT NULL DEFAULT 0,
            tier_seed INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            
            UNIQUE(tournament_id, team_id),
            UNIQUE(tournament_id, tier, tier_seed)
        );
        
        -- Create indexes
        CREATE INDEX idx_tournament_tiers_tournament_id ON tournament_tiers(tournament_id);
        CREATE INDEX idx_tournament_tiers_team_id ON tournament_tiers(team_id);
        CREATE INDEX idx_tournament_tiers_tier ON tournament_tiers(tournament_id, tier);
        CREATE INDEX idx_tournament_tiers_tier_seed ON tournament_tiers(tournament_id, tier, tier_seed);
        
        RAISE NOTICE 'tournament_tiers table created successfully';
    ELSE
        RAISE NOTICE 'tournament_tiers table already exists';
    END IF;
END $$;

-- Final verification
SELECT 
    'tournament_groups' as table_name,
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tournament_groups'
ORDER BY ordinal_position;

-- Success message
SELECT 'Fix completed! Check the column list above to verify team_ids column exists.' as status; 