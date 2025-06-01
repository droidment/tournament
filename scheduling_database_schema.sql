-- Tournament Scheduling System Database Schema
-- Run this script in your Supabase SQL Editor

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tournament_resources table (courts, fields, etc.)
CREATE TABLE IF NOT EXISTS public.tournament_resources (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'court', 'field', 'table', 'pitch', etc.
  description TEXT,
  capacity INTEGER, -- Max players/teams that can use this resource simultaneously
  location TEXT, -- Physical location description
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique resource names within a tournament
  UNIQUE(tournament_id, name)
);

-- Create resource_availability table (when resources are available)
CREATE TABLE IF NOT EXISTS public.resource_availability (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  resource_id UUID NOT NULL REFERENCES public.tournament_resources(id) ON DELETE CASCADE,
  day_of_week INTEGER, -- 0=Sunday, 1=Monday, etc. (NULL for specific dates)
  specific_date DATE, -- For specific date availability (NULL for recurring)
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Basic constraint to ensure start_time < end_time
  CHECK (start_time < end_time),
  
  -- Ensure either day_of_week OR specific_date is set, but not both
  CHECK (
    (day_of_week IS NOT NULL AND specific_date IS NULL) OR
    (day_of_week IS NULL AND specific_date IS NOT NULL)
  )
);

-- Create games table (scheduled matches)
CREATE TABLE IF NOT EXISTS public.games (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.tournament_categories(id) ON DELETE SET NULL,
  round INTEGER, -- Round number (1, 2, 3, etc.)
  round_name TEXT, -- 'Quarterfinals', 'Semifinals', 'Finals', etc.
  game_number INTEGER, -- Game number within the round
  
  -- Teams/participants
  team1_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  team2_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  
  -- Scheduling
  resource_id UUID REFERENCES public.tournament_resources(id) ON DELETE SET NULL,
  scheduled_date DATE,
  scheduled_time TIME,
  estimated_duration INTEGER DEFAULT 60, -- Duration in minutes
  
  -- Game status and results
  status TEXT DEFAULT 'scheduled' CHECK (
    status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'postponed', 'forfeit')
  ),
  winner_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  team1_score INTEGER,
  team2_score INTEGER,
  
  -- Additional info
  notes TEXT,
  is_published BOOLEAN DEFAULT false, -- Whether visible to participants
  referee_notes TEXT,
  stream_url TEXT, -- For live streaming
  
  -- Audit fields
  created_by UUID REFERENCES public.users(id),
  updated_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable Row Level Security
ALTER TABLE public.tournament_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tournament_resources
CREATE POLICY "Anyone can view tournament resources" ON public.tournament_resources
  FOR SELECT USING (true);

CREATE POLICY "Tournament organizers can manage resources" ON public.tournament_resources
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- RLS Policies for resource_availability
CREATE POLICY "Anyone can view resource availability" ON public.resource_availability
  FOR SELECT USING (true);

CREATE POLICY "Tournament organizers can manage availability" ON public.resource_availability
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournament_resources tr
      JOIN public.tournaments t ON tr.tournament_id = t.id
      WHERE tr.id = resource_id AND t.organizer_id = auth.uid()
    )
  );

-- RLS Policies for games
CREATE POLICY "Anyone can view published games" ON public.games
  FOR SELECT USING (is_published = true OR 
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

CREATE POLICY "Tournament organizers can manage games" ON public.games
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.tournaments 
      WHERE id = tournament_id AND organizer_id = auth.uid()
    )
  );

-- Create indexes for better performance
CREATE INDEX idx_tournament_resources_tournament_id ON public.tournament_resources(tournament_id);
CREATE INDEX idx_tournament_resources_type ON public.tournament_resources(type);
CREATE INDEX idx_tournament_resources_is_active ON public.tournament_resources(is_active);

CREATE INDEX idx_resource_availability_resource_id ON public.resource_availability(resource_id);
CREATE INDEX idx_resource_availability_day_of_week ON public.resource_availability(day_of_week);
CREATE INDEX idx_resource_availability_specific_date ON public.resource_availability(specific_date);

-- Create unique constraint to prevent duplicate availability slots
CREATE UNIQUE INDEX idx_resource_availability_unique_recurring 
ON public.resource_availability(resource_id, day_of_week, start_time, end_time) 
WHERE day_of_week IS NOT NULL;

CREATE UNIQUE INDEX idx_resource_availability_unique_specific 
ON public.resource_availability(resource_id, specific_date, start_time, end_time) 
WHERE specific_date IS NOT NULL;

CREATE INDEX idx_games_tournament_id ON public.games(tournament_id);
CREATE INDEX idx_games_category_id ON public.games(category_id);
CREATE INDEX idx_games_round ON public.games(round);
CREATE INDEX idx_games_status ON public.games(status);
CREATE INDEX idx_games_scheduled_date ON public.games(scheduled_date);
CREATE INDEX idx_games_team1_id ON public.games(team1_id);
CREATE INDEX idx_games_team2_id ON public.games(team2_id);
CREATE INDEX idx_games_resource_id ON public.games(resource_id);
CREATE INDEX idx_games_is_published ON public.games(is_published);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION update_tournament_resources_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tournament_resources_updated_at
    BEFORE UPDATE
    ON public.tournament_resources
    FOR EACH ROW
EXECUTE FUNCTION update_tournament_resources_updated_at();

CREATE OR REPLACE FUNCTION update_games_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_games_updated_at
    BEFORE UPDATE
    ON public.games
    FOR EACH ROW
EXECUTE FUNCTION update_games_updated_at();

-- Create a view for schedule display with team names and resource info
CREATE OR REPLACE VIEW public.schedule_view AS
SELECT 
  g.id,
  g.tournament_id,
  g.category_id,
  g.round,
  g.round_name,
  g.game_number,
  g.scheduled_date,
  g.scheduled_time,
  g.estimated_duration,
  g.status,
  g.team1_score,
  g.team2_score,
  g.notes,
  g.is_published,
  g.stream_url,
  
  -- Team 1 info
  t1.name as team1_name,
  t1.id as team1_id,
  
  -- Team 2 info
  t2.name as team2_name,
  t2.id as team2_id,
  
  -- Winner info
  tw.name as winner_name,
  tw.id as winner_id,
  
  -- Resource info
  r.name as resource_name,
  r.type as resource_type,
  r.location as resource_location,
  
  -- Category info
  c.name as category_name,
  
  g.created_at,
  g.updated_at
FROM public.games g
LEFT JOIN public.teams t1 ON g.team1_id = t1.id
LEFT JOIN public.teams t2 ON g.team2_id = t2.id
LEFT JOIN public.teams tw ON g.winner_id = tw.id
LEFT JOIN public.tournament_resources r ON g.resource_id = r.id
LEFT JOIN public.tournament_categories c ON g.category_id = c.id;

-- Grant access to the view
GRANT SELECT ON public.schedule_view TO authenticated;
GRANT SELECT ON public.schedule_view TO anon;

-- Success message
SELECT 'Scheduling system database schema created successfully!' as status; 