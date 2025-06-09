-- Cleanup script for tiered tournament tables
-- Run this if you need to start completely fresh
-- This will remove all existing tiered tournament tables and triggers

-- Drop existing triggers first
DROP TRIGGER IF EXISTS update_tournament_groups_updated_at ON tournament_groups;
DROP TRIGGER IF EXISTS update_tournament_tiers_updated_at ON tournament_tiers;

-- Drop existing tables (this will also drop all data!)
DROP TABLE IF EXISTS tournament_tiers CASCADE;
DROP TABLE IF EXISTS tournament_groups CASCADE;

-- Drop trigger functions
DROP FUNCTION IF EXISTS update_tournament_groups_updated_at();
DROP FUNCTION IF EXISTS update_tournament_tiers_updated_at();

-- Success message
SELECT 'Cleanup completed! You can now run the create_tiered_tournament_tables_simple.sql migration.' as status; 