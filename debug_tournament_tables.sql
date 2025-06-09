-- Debug script to check tournament tables status
-- Run this in your Supabase SQL Editor

-- 1. Check if tournament_groups table exists
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'tournament_groups';

-- 2. Check tournament_groups table columns (if it exists)
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tournament_groups'
ORDER BY ordinal_position;

-- 3. Check if tournament_tiers table exists  
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'tournament_tiers';

-- 4. Check tournament_tiers table columns (if it exists)
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'tournament_tiers'
ORDER BY ordinal_position;

-- 5. Check all tables that contain 'tournament' in the name
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name LIKE '%tournament%'
ORDER BY table_name;

-- 6. Check constraints on tournament_groups table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.table_name = 'tournament_groups' 
    AND tc.table_schema = 'public'; 