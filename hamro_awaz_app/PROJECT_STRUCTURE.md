# HamroAwaz - Civic Complaint & Governance Platform

## 🎨 Project Overview

A modern, government-grade Flutter mobile application for civic complaints and governance. Built with Material 3 design, supporting both light and dark modes.

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_colors.dart          # Brand color definitions
│   ├── navigation/
│   │   └── app_router.dart          # GoRouter configuration
│   ├── theme/
│   │   └── app_theme.dart           # Light & Dark theme setup
│   └── widgets/
│       ├── complaint_card.dart       # Reusable complaint card widget
│       ├── empty_state.dart         # Empty state widget
│       ├── skeleton_loader.dart      # Loading skeleton widget
│       ├── stat_card.dart            # Statistics card widget
│       └── status_chip.dart         # Status indicator chip
├── models/
│   ├── complaint.dart               # Complaint data model
│   └── user.dart                    # User data model
├── screens/
│   ├── auth/
│   │   ├── forgot_password_screen.dart
│   │   ├── login_screen.dart
│   │   └── otp_verification_screen.dart
│   └── citizen/
│       ├── create_complaint_screen.dart
│       ├── dashboard_screen.dart
│       ├── map_view_screen.dart
│       ├── my_complaints_screen.dart
│       ├── profile_screen.dart
│       └── settings_screen.dart
├── services/
│   ├── auth_service.dart            # Authentication service
│   └── complaint_service.dart       # Complaint management service
├── widgets/
│   └── main_navigation.dart         # Bottom navigation wrapper
└── main.dart                        # App entry point
```

## 🎨 Brand Colors

- **Primary**: `#0C1F2A` (Deep Navy)
- **Secondary**: `#07344E` (Teal Blue)
- **Success**: `#14A44D`
- **Warning**: `#F59E0B`
- **Error**: `#DC2626`

## ✨ Features Implemented

### Authentication
- ✅ Login screen (Email/Phone + Password)
- ✅ OTP verification screen
- ✅ Forgot password screen

### Citizen Module
- ✅ Dashboard with greeting and quick stats
- ✅ Create complaint with category, department, image upload
- ✅ My Complaints list with filtering
- ✅ Complaint voting (Yes/No)
- ✅ Map view (placeholder - ready for Google Maps integration)
- ✅ Profile screen
- ✅ Settings screen

### UI Components
- ✅ Reusable cards
- ✅ Status chips with color coding
- ✅ Skeleton loaders
- ✅ Empty state illustrations
- ✅ Confirmation dialogs

### Navigation
- ✅ Bottom navigation bar
- ✅ GoRouter for navigation
- ✅ Profile menu with logout

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Dart SDK

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## 📦 Dependencies

- `provider` - State management
- `go_router` - Navigation
- `image_picker` - Image selection
- `google_maps_flutter` - Map integration (configure API key)
- `shared_preferences` - Local storage
- `intl` - Date formatting
- `http` - API calls

## 🔧 Configuration Needed

### Google Maps Integration
To enable the map view:
1. Get a Google Maps API key
2. Add it to `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`
3. Replace the placeholder in `map_view_screen.dart` with actual Google Maps widget

### API Integration
The services (`auth_service.dart` and `complaint_service.dart`) currently use mock data. Replace with actual API calls:
- Update `AuthService` methods to call your backend
- Update `ComplaintService` methods to call your backend

## 🎯 Next Steps

1. **Backend Integration**: Connect services to your API
2. **Google Maps**: Add API key and implement map view
3. **State Management**: Consider adding a state management solution (Provider/Riverpod) for global state
4. **Localization**: Add English/Nepali language support
5. **Testing**: Add unit and widget tests
6. **Admin Module**: Implement admin screens (if needed)

## 📱 Screenshots & Features

### Dashboard
- Time-based greeting (Good Morning/Afternoon/Evening)
- Quick stats cards (Total, Resolved, In Progress, Escalated)
- Recent complaints list
- Floating action button to create complaint

### Create Complaint
- Category selector
- Department selector
- Image upload (Camera & Gallery)
- Location picker (ready for map integration)
- Form validation

### My Complaints
- Filter by status (All, Pending, In Progress, Resolved, Escalated)
- Card-based list UI
- Status chips with color codes
- Vote Yes/No buttons
- Pull to refresh

### Profile
- User information display
- Settings access
- Help & Support
- Logout functionality

## 🎨 Design Principles

- **Material 3**: Modern Material Design
- **Accessibility**: Large tap areas, readable fonts
- **Responsive**: Works on phones and tablets
- **Professional**: Government-grade UI/UX
- **Clean**: Minimal, intuitive interface

## 📝 Notes

- All screens are fully functional with mock data
- Replace mock services with actual API integration
- Add error handling and loading states as needed
- Consider adding analytics and crash reporting

