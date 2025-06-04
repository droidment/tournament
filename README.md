# Tournament Management App

A comprehensive tournament management application built with Flutter and Supabase, designed to help organizers create and manage tournaments efficiently.

## Features

### Authentication
- ✅ Email/password authentication
- ✅ Google Sign-In integration
- ✅ Password reset functionality
- ✅ User profile management

### Tournament Management
- 🚧 Tournament creation with multiple formats:
  - Round Robin
  - Swiss Ladder
  - Single Elimination
  - Double Elimination
  - Custom Bracket
- 🚧 Tournament categories and divisions
- 🚧 Team registration (manual and self-registration)
- 🚧 Tournament scheduling
- 🚧 Real-time results tracking

### Team Management
- 🚧 Team creation and management
- 🚧 Player roster management
- 🚧 Team seeding
- 🚧 Team logos and branding

### Scheduling & Results
- 🚧 Automated schedule generation
- 🚧 Manual schedule adjustments
- 🚧 Resource (courts/fields) management
- 🚧 Live scoring and results
- 🚧 Real-time standings

### UI/UX
- ✅ Material Design 3 interface
- ✅ Responsive design for mobile and desktop
- ✅ Dark/light theme support
- 🚧 Offline functionality

Legend: ✅ Implemented | 🚧 In Development | ❌ Not Started

## Technology Stack

- **Frontend**: Flutter 3.5.0+
- **Backend**: Supabase
- **Authentication**: Supabase Auth + Google Sign-In
- **Database**: PostgreSQL (via Supabase)
- **Storage**: Supabase Storage
- **Real-time**: Supabase Realtime
- **State Management**: BLoC/Cubit
- **Navigation**: GoRouter
- **UI Components**: Material Design 3
- **Deployment**: Netlify (web), Android APK

## Prerequisites

Before you begin, ensure you have:

- Flutter SDK 3.5.0 or later
- Dart SDK 3.5.0 or later
- A Supabase account and project
- Android Studio/VS Code with Flutter extensions
- Git

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd teamapp3
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Configuration

1. Create a new project at [supabase.com](https://supabase.com)
2. Navigate to your project settings > API
3. Copy your project URL and anon key
4. Create your environment file:

```bash
# Copy the example environment file
cp lib/core/config/env.example.dart lib/core/config/env.dart
```

5. Update `lib/core/config/env.dart` with your actual credentials:

```dart
class Environment {
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-actual-anon-key-here';
  static const String environment = 'development';
}
```

**🔐 Security Note**: The `env.dart` file is automatically ignored by git to protect your credentials.

### 4. Database Schema

Run the following SQL in your Supabase SQL editor to create the necessary tables:

```sql
-- Enable RLS
ALTER TABLE IF EXISTS auth.users ENABLE ROW LEVEL SECURITY;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournaments table
CREATE TABLE IF NOT EXISTS tournaments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  organizer_id UUID REFERENCES users(id) NOT NULL,
  format TEXT NOT NULL CHECK (format IN ('round_robin', 'swiss_ladder', 'single_elimination', 'double_elimination', 'custom_bracket')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'upcoming', 'active', 'completed', 'cancelled')),
  description TEXT,
  location TEXT,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  registration_deadline TIMESTAMP WITH TIME ZONE,
  max_teams INTEGER,
  entry_fee DECIMAL(10,2),
  rules TEXT,
  welcome_message TEXT,
  image_url TEXT,
  is_public BOOLEAN DEFAULT true,
  allow_self_registration BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Teams table
CREATE TABLE IF NOT EXISTS teams (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES users(id),
  category_id UUID,
  logo_url TEXT,
  description TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  seed INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Games table
CREATE TABLE IF NOT EXISTS games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  team1_id UUID REFERENCES teams(id),
  team2_id UUID REFERENCES teams(id),
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'forfeit')),
  category_id UUID,
  round INTEGER,
  scheduled_at TIMESTAMP WITH TIME ZONE,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  team1_score INTEGER,
  team2_score INTEGER,
  winner_id UUID REFERENCES teams(id),
  resource_id UUID,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('avatars', 'avatars', true),
  ('team-logos', 'team-logos', true),
  ('tournament-images', 'tournament-images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Public tournaments are viewable by everyone" ON tournaments
  FOR SELECT USING (is_public = true OR organizer_id = auth.uid());

CREATE POLICY "Organizers can manage their tournaments" ON tournaments
  FOR ALL USING (organizer_id = auth.uid());
```

### 5. Google Sign-In Configuration (Optional)

1. Go to the [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Enable the Google Sign-In API
4. Create credentials (OAuth 2.0 client IDs) for Android/iOS
5. Configure the OAuth consent screen
6. Add the configuration to your platform-specific files

### 6. Run the Application

```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── config/           # Environment configuration (env.dart ignored by git)
│   ├── constants/        # App constants and configuration
│   ├── models/          # Data models with JSON serialization
│   ├── router/          # App routing configuration
│   └── services/        # Core services (Supabase, etc.)
├── features/
│   ├── authentication/ # Authentication feature
│   │   ├── bloc/       # Authentication state management
│   │   ├── data/       # Repositories and data sources
│   │   └── presentation/ # UI screens and widgets
│   ├── dashboard/      # Dashboard feature
│   ├── tournaments/    # Tournament management feature
│   ├── teams/         # Team management feature
│   └── profile/       # User profile feature
├── l10n/              # Localization files
└── main.dart          # App entry point
```

## Development Guidelines

### Code Style
- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Write comprehensive comments for complex logic
- Maintain consistent file and folder naming

### Security
- Never commit `lib/core/config/env.dart` to version control
- Use different API keys for different environments
- Keep example files updated but without real credentials
- Review .gitignore regularly

### Testing
- Write unit tests for business logic
- Create widget tests for UI components
- Add integration tests for critical user flows

### State Management
- Use BLoC pattern for complex state management
- Keep business logic separate from UI components
- Use events to trigger state changes
- Emit new states for UI updates

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Copy `env.example.dart` to `env.dart` and configure your credentials
4. Commit your changes: `git commit -am 'Add new feature'`
5. Push to the branch: `git push origin feature/new-feature`
6. Submit a pull request

## User Stories Implementation Status

### Authentication ✅
- [x] User sign up with email
- [x] Google sign-in integration
- [x] Email sign-in
- [x] Sign out functionality
- [x] Password reset
- [x] User profile management

### Tournament Creation 🚧
- [ ] Basic tournament creation
- [ ] Tournament format selection
- [ ] Category creation
- [ ] Rules and information setup
- [ ] Tournament customization

### Team Management 🚧
- [ ] Manual team creation
- [ ] Self-registration
- [ ] Team member management
- [ ] Team categorization
- [ ] Team seeding

### Scheduling 🚧
- [ ] Resource management
- [ ] Automatic schedule generation
- [ ] Manual schedule adjustments
- [ ] Schedule publishing

### Results & Standings 🚧
- [ ] Game result entry
- [ ] Automatic standings calculation
- [ ] Bracket visualization
- [ ] Results history

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Check the documentation in the `/docs` folder
- Review the user stories in `cursor/Tournament Management App - Cursor Rules.md`

## Roadmap

### Phase 1 (Current)
- ✅ Basic authentication system
- ✅ User profile management
- ✅ App structure and navigation
- ✅ Secure environment configuration

### Phase 2 (Next)
- 🚧 Tournament creation and management
- 🚧 Team registration system
- 🚧 Basic scheduling

### Phase 3 (Future)
- 🚧 Advanced tournament formats
- 🚧 Real-time scoring
- 🚧 Mobile notifications
- 🚧 Offline functionality

## Deployment

### Web Deployment (Netlify)

This app includes a `netlify.toml` configuration file for easy deployment to Netlify:

1. **Connect Repository**: Link your GitHub repository to Netlify
2. **Automatic Build**: Netlify will automatically detect the configuration and run `flutter build web --release`
3. **Environment Variables**: Set your Supabase credentials in the Netlify dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. **Deploy**: Your app will be automatically deployed with optimal performance and security settings

### Android APK Build

To build an Android APK for distribution:

```bash
# Debug build (for testing)
flutter build apk --debug

# Release build (for production)
flutter build apk --release
```

APK files will be generated in `build/app/outputs/flutter-apk/`

---

**Built with ❤️ using Flutter and Supabase**
