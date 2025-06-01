-- Quick fix for missing columns in users table
-- Run this in your Supabase SQL Editor

-- Add missing columns to public.users if they don't exist
DO $$ 
BEGIN
  -- Check and add location column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'location') THEN
    ALTER TABLE public.users ADD COLUMN location TEXT;
    RAISE NOTICE 'Added location column to public.users';
  ELSE
    RAISE NOTICE 'Location column already exists in public.users';
  END IF;
  
  -- Check and add bio column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'bio') THEN
    ALTER TABLE public.users ADD COLUMN bio TEXT;
    RAISE NOTICE 'Added bio column to public.users';
  ELSE
    RAISE NOTICE 'Bio column already exists in public.users';
  END IF;
  
  -- Check and add phone column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'phone') THEN
    ALTER TABLE public.users ADD COLUMN phone TEXT;
    RAISE NOTICE 'Added phone column to public.users';
  ELSE
    RAISE NOTICE 'Phone column already exists in public.users';
  END IF;
  
  -- Check and add date_of_birth column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'date_of_birth') THEN
    ALTER TABLE public.users ADD COLUMN date_of_birth DATE;
    RAISE NOTICE 'Added date_of_birth column to public.users';
  ELSE
    RAISE NOTICE 'Date_of_birth column already exists in public.users';
  END IF;
  
  -- Check and add avatar_url column (if missing)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'avatar_url') THEN
    ALTER TABLE public.users ADD COLUMN avatar_url TEXT;
    RAISE NOTICE 'Added avatar_url column to public.users';
  ELSE
    RAISE NOTICE 'Avatar_url column already exists in public.users';
  END IF;
END $$;

-- Also add to auth.users if missing
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'location') THEN
    ALTER TABLE auth.users ADD COLUMN location TEXT;
    RAISE NOTICE 'Added location column to auth.users';
  ELSE
    RAISE NOTICE 'Location column already exists in auth.users';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'bio') THEN
    ALTER TABLE auth.users ADD COLUMN bio TEXT;
    RAISE NOTICE 'Added bio column to auth.users';
  ELSE
    RAISE NOTICE 'Bio column already exists in auth.users';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'phone') THEN
    ALTER TABLE auth.users ADD COLUMN phone TEXT;
    RAISE NOTICE 'Added phone column to auth.users';
  ELSE
    RAISE NOTICE 'Phone column already exists in auth.users';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'date_of_birth') THEN
    ALTER TABLE auth.users ADD COLUMN date_of_birth DATE;
    RAISE NOTICE 'Added date_of_birth column to auth.users';
  ELSE
    RAISE NOTICE 'Date_of_birth column already exists in auth.users';
  END IF;
END $$;

SELECT 'Missing columns fix completed!' as status; 