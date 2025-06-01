-- Tournament Categories Migration
-- Run this script in your Supabase SQL Editor

-- Create tournament_categories table
CREATE TABLE IF NOT EXISTS public.tournament_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  max_teams INTEGER,
  min_teams INTEGER DEFAULT 2,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique category names within a tournament
  UNIQUE(tournament_id, name)
);

-- Add category_id to teams table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'teams' AND column_name = 'category_id') THEN
    ALTER TABLE public.teams ADD COLUMN category_id UUID REFERENCES public.tournament_categories(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Enable Row Level Security
ALTER TABLE public.tournament_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tournament_categories table
CREATE POLICY "Anyone can view tournament categories" ON public.tournament_categories
  FOR SELECT USING (true);

CREATE POLICY "Tournament organizers can create categories" ON public.tournament_categories
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

CREATE POLICY "Tournament organizers can update their categories" ON public.tournament_categories
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

CREATE POLICY "Tournament organizers can delete their categories" ON public.tournament_categories
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- Create updated_at trigger for tournament_categories
CREATE OR REPLACE FUNCTION update_tournament_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tournament_categories_updated_at
    BEFORE UPDATE
    ON public.tournament_categories
    FOR EACH ROW
EXECUTE FUNCTION update_tournament_categories_updated_at();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tournament_categories_tournament_id ON public.tournament_categories(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_categories_display_order ON public.tournament_categories(tournament_id, display_order);
CREATE INDEX IF NOT EXISTS idx_teams_category_id ON public.teams(category_id);

-- Insert some default categories for existing tournaments (optional)
-- Uncomment the lines below if you want default categories for existing tournaments

/*
INSERT INTO public.tournament_categories (tournament_id, name, description, display_order)
SELECT 
  id as tournament_id,
  'Open' as name,
  'Open category for all teams' as description,
  1 as display_order
FROM public.tournaments
WHERE NOT EXISTS (
  SELECT 1 FROM public.tournament_categories 
  WHERE tournament_id = tournaments.id
);
*/

-- Success message
SELECT 'Tournament categories migration completed successfully!' as status; 