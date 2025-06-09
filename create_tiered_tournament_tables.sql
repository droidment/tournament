-- Migration: Create tables for tiered tournament functionality
-- Run this in your Supabase SQL Editor

-- ====================================
-- CREATE TOURNAMENT_GROUPS TABLE
-- ====================================

CREATE TABLE IF NOT EXISTS tournament_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    group_name TEXT NOT NULL,
    group_number INTEGER NOT NULL,
    team_ids TEXT[] NOT NULL DEFAULT '{}', -- Array of team IDs as strings
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure group numbers are unique within a tournament
    UNIQUE(tournament_id, group_number),
    
    -- Ensure group names are unique within a tournament  
    UNIQUE(tournament_id, group_name)
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_tournament_groups_tournament_id ON tournament_groups(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_groups_group_number ON tournament_groups(tournament_id, group_number);

-- Add RLS policies
ALTER TABLE tournament_groups ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access groups for tournaments they can access
CREATE POLICY "Users can access tournament groups for their tournaments" ON tournament_groups
    FOR ALL USING (
        tournament_id IN (
            SELECT id FROM tournaments WHERE organizer_id = auth.uid()
        )
    );

-- ====================================
-- CREATE TOURNAMENT_TIERS TABLE
-- ====================================

CREATE TABLE IF NOT EXISTS tournament_tiers (
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
    
    -- Ensure a team can only be in one tier per tournament
    UNIQUE(tournament_id, team_id),
    
    -- Ensure tier seeds are unique within a tier and tournament
    UNIQUE(tournament_id, tier, tier_seed)
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tournament_id ON tournament_tiers(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_team_id ON tournament_tiers(team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tier ON tournament_tiers(tournament_id, tier);
CREATE INDEX IF NOT EXISTS idx_tournament_tiers_tier_seed ON tournament_tiers(tournament_id, tier, tier_seed);

-- Add RLS policies
ALTER TABLE tournament_tiers ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access tiers for tournaments they can access
CREATE POLICY "Users can access tournament tiers for their tournaments" ON tournament_tiers
    FOR ALL USING (
        tournament_id IN (
            SELECT id FROM tournaments WHERE organizer_id = auth.uid()
        )
    );

-- ====================================
-- CREATE UPDATE TRIGGERS
-- ====================================

-- Trigger function for tournament_groups
CREATE OR REPLACE FUNCTION update_tournament_groups_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tournament_groups_updated_at
    BEFORE UPDATE ON tournament_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_tournament_groups_updated_at();

-- Trigger function for tournament_tiers  
CREATE OR REPLACE FUNCTION update_tournament_tiers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tournament_tiers_updated_at
    BEFORE UPDATE ON tournament_tiers
    FOR EACH ROW
    EXECUTE FUNCTION update_tournament_tiers_updated_at();

-- ====================================
-- VERIFICATION QUERIES
-- ====================================

-- Verify tables were created successfully
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable 
FROM information_schema.columns 
WHERE table_name IN ('tournament_groups', 'tournament_tiers')
ORDER BY table_name, ordinal_position; 