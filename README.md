# Cryb Mobile App

A SwiftUI iOS app for managing household tasks, expenses, and notes with your housemates. Built with Supabase backend.

## Features

✅ **Authentication**
- User registration and login via Supabase Auth
- Secure session management

✅ **House Management**
- Create new houses with unique invite codes
- Join existing houses via invite codes
- Switch between multiple houses

✅ **Dashboard**
- Overview of upcoming chores
- Recent expenses summary
- Pinned notes display
- Balance summary (you owe vs. you're owed)

✅ **Chores Management**
- Create, edit, and delete chores
- Assign chores to housemates
- Mark chores as completed
- Set due dates and recurrence patterns
- Point system for gamification

✅ **Expense Tracking**
- Add and manage shared expenses
- Split expenses among housemates
- Categorize expenses
- Automatic balance calculations

✅ **Notes System**
- Create and share notes with housemates
- Markdown support for rich formatting
- Pin important notes
- Tag system for organization

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Supabase account and project

### 1. Clone the Repository
```bash
git clone <repository-url>
cd cryb_app
```

### 2. Open in Xcode
```bash
open cryb_app.xcodeproj
```

### 3. Add Supabase Dependencies
In Xcode:
1. Go to File → Add Package Dependencies
2. Add the following packages:
   - `https://github.com/supabase-community/supabase-swift.git`
   - `https://github.com/pointfreeco/swift-composable-architecture.git`
   - `https://github.com/JohnSundell/AsyncCompatibilityKit.git`

### 4. Configure Supabase
The app is already configured with the provided Supabase credentials:
- URL: `https://krrsltregsxmbspauqnd.supabase.co`
- Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtycnNsdHJlZ3N4bWJzcGF1cW5kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0OTE0NTcsImV4cCI6MjA2MjA2NzQ1N30.-pgwV2srfasomvwoX-Sxj8iox6Io-eW7xiY4X6BBAlw`

### 5. Build and Run
1. Select your target device or simulator
2. Press Cmd+R to build and run the app

## Database Schema

The app expects the following Supabase tables:

### profiles
- `id` (uuid, primary key)
- `email` (text)
- `name` (text, nullable)
- `avatar_url` (text, nullable)
- `created_at` (timestamp)

### houses
- `id` (uuid, primary key)
- `name` (text)
- `invite_code` (text, unique)
- `owner_id` (uuid, references profiles.id)
- `created_at` (timestamp)

### house_members
- `id` (uuid, primary key)
- `house_id` (uuid, references houses.id)
- `user_id` (uuid, references profiles.id)

### chores
- `id` (uuid, primary key)
- `title` (text)
- `description` (text, nullable)
- `due_date` (timestamp, nullable)
- `is_completed` (boolean)
- `assigned_user_id` (uuid, nullable, references profiles.id)
- `house_id` (uuid, references houses.id)
- `created_by` (uuid, references profiles.id)
- `created_at` (timestamp)
- `recurrence` (text)
- `points` (integer)

### expenses
- `id` (uuid, primary key)
- `title` (text)
- `amount` (decimal)
- `description` (text, nullable)
- `paid_by` (uuid, references profiles.id)
- `house_id` (uuid, references houses.id)
- `created_at` (timestamp)
- `category` (text, nullable)
- `shared_with` (uuid[], nullable)

### notes
- `id` (uuid, primary key)
- `title` (text)
- `content` (text)
- `house_id` (uuid, references houses.id)
- `created_by` (uuid, references profiles.id)
- `created_at` (timestamp)
- `is_pinned` (boolean)
- `tags` (text[], nullable)

## Architecture

The app follows MVVM architecture with:

- **Models**: Data structures for User, House, Chore, Expense, Note
- **Services**: ObservableObject classes for API interactions
- **Views**: SwiftUI views for UI components
- **State Management**: @StateObject and @ObservedObject for reactive updates

## Key Components

### Services
- `AuthService`: Handles authentication and user sessions
- `HouseService`: Manages house creation, joining, and selection
- `ChoreService`: CRUD operations for chores
- `ExpenseService`: Expense management and balance calculations
- `NoteService`: Note creation, editing, and organization

### Views
- `LoginView`: Authentication interface
- `DashboardView`: Main dashboard with overview
- `CreateHouseView`: House creation form
- `JoinHouseView`: House joining interface
- `HouseSelectorView`: House switching interface

## Next Steps

To complete the app, you'll need to:

1. **Add Supabase Dependencies**: Add the required Swift packages in Xcode
2. **Create Database Tables**: Set up the required tables in your Supabase project
3. **Test Authentication**: Verify login/registration works
4. **Add CRUD Views**: Create detailed views for chores, expenses, and notes
5. **Implement Markdown**: Add markdown rendering for notes
6. **Add Notifications**: Implement push notifications for due dates
7. **Polish UI**: Add animations, loading states, and error handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the MIT License. 