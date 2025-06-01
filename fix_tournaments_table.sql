-- Fix tournaments table - add missing created_by column
-- Run this script in your Supabase SQL Editor

-- First, create the tournaments table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.tournaments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  format TEXT NOT NULL, -- 'round_robin', 'single_elimination', 'double_elimination', 'swiss', 'custom'
  status TEXT DEFAULT 'draft', -- 'draft', 'registration', 'active', 'completed', 'cancelled'
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  max_teams INTEGER,
  registration_deadline TIMESTAMP WITH TIME ZONE,
  rules TEXT,
  prize_description TEXT,
  created_by UUID REFERENCES public.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if they don't exist
DO $$ 
BEGIN
  -- Add created_by column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tournaments' AND column_name = 'created_by') THEN
    ALTER TABLE public.tournaments ADD COLUMN created_by UUID REFERENCES public.users(id) NOT NULL DEFAULT auth.uid();
  END IF;
  
  -- Add other potentially missing columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tournaments' AND column_name = 'max_teams') THEN
    ALTER TABLE public.tournaments ADD COLUMN max_teams INTEGER;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tournaments' AND column_name = 'registration_deadline') THEN
    ALTER TABLE public.tournaments ADD COLUMN registration_deadline TIMESTAMP WITH TIME ZONE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tournaments' AND column_name = 'rules') THEN
    ALTER TABLE public.tournaments ADD COLUMN rules TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tournaments' AND column_name = 'prize_description') THEN
    ALTER TABLE public.tournaments ADD COLUMN prize_description TEXT;
  END IF;
END $$;

-- Create tournament_participants table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.tournament_participants (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL, -- 'organizer', 'admin', 'team_manager', 'player'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tournament_id, user_id)
);

-- Enable Row Level Security on tournaments table
ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_participants ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies for tournaments table (if they don't exist)
DO $$
BEGIN
  -- Drop existing policies if they exist and recreate them
  DROP POLICY IF EXISTS "Anyone can view tournaments" ON public.tournaments;
  DROP POLICY IF EXISTS "Authenticated users can create tournaments" ON public.tournaments;
  DROP POLICY IF EXISTS "Tournament creators can update their tournaments" ON public.tournaments;
  DROP POLICY IF EXISTS "Tournament creators can delete their tournaments" ON public.tournaments;
  
  CREATE POLICY "Anyone can view tournaments" ON public.tournaments
    FOR SELECT USING (true);
  
  CREATE POLICY "Authenticated users can create tournaments" ON public.tournaments
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  
  CREATE POLICY "Tournament creators can update their tournaments" ON public.tournaments
    FOR UPDATE USING (auth.uid() = created_by);
  
  CREATE POLICY "Tournament creators can delete their tournaments" ON public.tournaments
    FOR DELETE USING (auth.uid() = created_by);
END $$;

-- Create RLS Policies for tournament_participants table (if they don't exist)
DO $$
BEGIN
  DROP POLICY IF EXISTS "Anyone can view tournament participants" ON public.tournament_participants;
  DROP POLICY IF EXISTS "Users can join tournaments" ON public.tournament_participants;
  DROP POLICY IF EXISTS "Users can leave tournaments they joined" ON public.tournament_participants;
  
  CREATE POLICY "Anyone can view tournament participants" ON public.tournament_participants
    FOR SELECT USING (true);
  
  CREATE POLICY "Users can join tournaments" ON public.tournament_participants
    FOR INSERT WITH CHECK (auth.uid() = user_id);
  
  CREATE POLICY "Users can leave tournaments they joined" ON public.tournament_participants
    FOR DELETE USING (auth.uid() = user_id);
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournaments_created_by ON public.tournaments(created_by);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON public.tournaments(status);
CREATE INDEX IF NOT EXISTS idx_tournaments_start_date ON public.tournaments(start_date);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_tournament_id ON public.tournament_participants(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_user_id ON public.tournament_participants(user_id);

-- Success message
SELECT 'Tournaments table fix completed successfully!' as status; 