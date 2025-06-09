-- Add the missing team_ids column to tournament_groups table
-- This will fix the "team_ids column not found" error

-- Add the team_ids column that the app expects
ALTER TABLE tournament_groups 
ADD COLUMN team_ids TEXT[] NOT NULL DEFAULT '{}';

-- Optional: Migrate data from teams_data to team_ids if needed
-- (Uncomment the lines below if you have existing data to migrate)

/*
UPDATE tournament_groups 
SET team_ids = ARRAY(
    SELECT jsonb_array_elements_text(teams_data)
)
WHERE teams_data != '[]'::jsonb;
*/

-- Verify the column was added
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tournament_groups'
  AND column_name IN ('team_ids', 'teams_data')
ORDER BY column_name;

-- Success message
SELECT 'team_ids column added successfully! Your group generation should now work.' as status; 