# Quick Setup Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Configure Environment

1. **Create Supabase Project**: Go to [supabase.com](https://supabase.com) and create a new project
2. **Get Project Details**: Copy your project URL and anon key from Settings > API
3. **Setup Environment File**: 
   ```bash
   # Copy the example environment file
   cp lib/core/config/env.example.dart lib/core/config/env.dart
   ```
4. **Update Credentials**: Edit `lib/core/config/env.dart` with your actual Supabase credentials:

```dart
class Environment {
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-actual-anon-key-here';
  static const String environment = 'development';
}
```

### Step 2: Setup Database

Run this SQL in your Supabase SQL Editor:

```sql
-- Create users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to manage their own data
CREATE POLICY "Users can manage own data" ON users
  FOR ALL USING (auth.uid() = id);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;
```

### Step 3: Run the App

```bash
flutter pub get
flutter run
```

## 🎯 Test the App

1. **Sign Up**: Create a new account with email/password
2. **Sign In**: Test the authentication flow
3. **Dashboard**: View the main dashboard after signing in
4. **Profile**: Access profile settings from the dashboard

## ⚠️ Important Notes

- **Development Mode**: The app is in development mode. Some features are placeholder screens.
- **Internet Required**: Authentication requires internet connection.
- **Demo Data**: No sample tournaments are included yet.
- **Environment File**: The `env.dart` file is ignored by git for security. Never commit your credentials!

## 🛠️ Current Features

✅ **Working Features**:
- Email authentication (sign up, sign in, sign out)
- User profile management
- Dashboard with navigation
- Responsive Material Design 3 UI

🚧 **Coming Soon**:
- Tournament creation
- Team management
- Scheduling system
- Real-time updates

## 🆘 Common Issues

### "Invalid Supabase URL"
- Double-check your URL and anon key in `lib/core/config/env.dart`
- Ensure your Supabase project is active
- Make sure you copied `env.example.dart` to `env.dart`

### "File not found: env.dart"
```bash
# Copy the example file first
cp lib/core/config/env.example.dart lib/core/config/env.dart
# Then edit with your credentials
```

### "Build Errors"
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build
```

### "Google Sign-In Not Working"
- Google Sign-In requires additional platform-specific setup
- For now, use email authentication which works out of the box

## 🔐 Security Best Practices

- ✅ Environment file is in `.gitignore`
- ✅ No credentials in source code
- ✅ Separate example file for reference
- ⚠️ Never commit `env.dart` to version control
- ⚠️ Use different keys for different environments

## 📧 Need Help?

Check the full [README.md](README.md) for comprehensive setup instructions or create an issue in the repository.

---

**Happy Tournament Managing! 🏆** 

## 📁 **File Structure**

```
lib/core/config/
├── env.dart          # Real credentials (ignored by git)
└── env.example.dart  # Template file (committed to git)
```

## ⚠️ **Important Notes**

- The actual `env.dart` file is now ignored by git for security
- The `env.example.dart` file serves as a template for new developers
- Never commit real credentials to version control
- Each developer needs to create their own `env.dart` file locally

Your Tournament Management App is now much more secure and follows industry best practices for credential management! 🔒✨ 