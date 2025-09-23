# Astrologer App 🔮

A full-stack Flutter application for astrologers with a Node.js backend, featuring real-time OTP authentication, profile management, and earnings tracking.

## 🚀 Features

### Flutter App (Mobile)
- **📱 Real Twilio OTP Authentication** - SMS-based login/signup
- **👤 Profile Management** - Edit profile, upload photos, manage details
- **💰 Earnings Dashboard** - Track daily and total earnings
- **📊 Statistics** - View calls, ratings, and performance metrics
- **🎨 Beautiful UI** - Modern design with smooth animations
- **💾 Persistent Storage** - Auto-login with SharedPreferences
- **📸 Image Picker** - Profile photo upload functionality

### Backend (Node.js)
- **🔐 JWT Authentication** - Secure token-based auth
- **📲 Twilio SMS** - Real OTP sending via Twilio
- **🗄️ Data Management** - In-memory storage with user profiles
- **🛡️ Middleware** - Auth protection and validation
- **🌐 CORS Support** - Cross-origin resource sharing
- **📝 RESTful API** - Clean API endpoints

## 🛠️ Tech Stack

### Mobile App
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **BLoC** - State management
- **Dio** - HTTP client
- **SharedPreferences** - Local storage
- **Image Picker** - Photo selection

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **Twilio** - SMS service
- **JWT** - Authentication tokens
- **Cors** - Cross-origin requests

## 📦 Project Structure

```
astrologer_app/
├── lib/                     # Flutter source code
│   ├── app/                 # App-level configuration
│   ├── core/                # Core utilities and services
│   ├── features/            # Feature modules
│   │   ├── auth/            # Authentication
│   │   ├── dashboard/       # Main dashboard
│   │   ├── profile/         # User profile
│   │   ├── earnings/        # Earnings tracking
│   │   └── consultations/   # Consultations
│   └── shared/              # Shared widgets and themes
├── backend/                 # Node.js backend
│   ├── src/                 # Source code
│   │   ├── controllers/     # API controllers
│   │   ├── middleware/      # Custom middleware
│   │   ├── models/          # Data models
│   │   ├── routes/          # API routes
│   │   └── services/        # Business logic
│   └── package.json         # Dependencies
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
└── README.md               # This file
```

## 🔧 Prerequisites

### For Flutter App
- **Flutter SDK** (3.0+)
- **Dart SDK** (3.0+)
- **Android Studio** or **VS Code**
- **Android SDK** (API level 34+)
- **Java 17** (Required for compilation)

### For Backend
- **Node.js** (18+)
- **npm** or **yarn**
- **Twilio Account** (for SMS)

## ⚡ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/astrologer_app.git
cd astrologer_app
```

### 2. Backend Setup
```bash
cd backend
npm install

# Create .env file
cp .env.example .env
# Edit .env with your Twilio credentials
```

### 3. Flutter App Setup
```bash
cd ..
flutter pub get
flutter run
```

## 🔐 Environment Variables

Create `backend/.env` file:

```env
# Server Configuration
PORT=7566
NODE_ENV=production

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d

# Twilio Configuration
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number

# CORS Configuration
CORS_ORIGIN=http://your-frontend-domain.com
```

## 🚀 Deployment

### Backend Deployment on Railway

1. **Create Railway Account** at [railway.com](https://railway.com)

2. **Deploy from GitHub**:
   - Connect your GitHub repository
   - Select the `backend` folder as root
   - Railway will auto-detect Node.js

3. **Set Environment Variables** in Railway dashboard:
   ```
   PORT=7566
   TWILIO_ACCOUNT_SID=your_sid
   TWILIO_AUTH_TOKEN=your_token
   TWILIO_PHONE_NUMBER=your_number
   JWT_SECRET=your_secret
   ```

4. **Custom Domain** (optional):
   - Add your custom domain in Railway settings

### Flutter App Deployment
- **Android**: Build APK with `flutter build apk`
- **iOS**: Build IPA with `flutter build ios`
- **Play Store**: Follow Google Play Console guidelines
- **App Store**: Follow Apple App Store guidelines

## 📱 API Endpoints

### Authentication
- `POST /api/auth/send-otp` - Send OTP to phone
- `POST /api/auth/verify-otp` - Verify OTP and login
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/logout` - Logout user

### Profile
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update user profile
- `POST /api/profile/upload` - Upload profile picture

### Dashboard
- `GET /api/dashboard/stats` - Get dashboard statistics

## 🧪 Testing

### Backend
```bash
cd backend
npm test
```

### Flutter
```bash
flutter test
```

## 🔧 Build Configuration

**IMPORTANT**: This project uses specific versions to avoid dependency conflicts:

- **Java 17** (Required - do not change)
- **Android SDK 34** (Required - do not change)
- **Gradle 8.x** (Auto-configured)
- **Kotlin 1.9.x** (Auto-configured)

⚠️ **Do not modify these versions** as they are part of a tested dependency chain.

## 🐛 Known Issues & Fixes

### Scaling/Zooming Issue Fix

**Problem**: The app experienced scaling/zooming issues where UI elements appeared larger than intended, particularly affecting the dashboard and OTP verification screen.

**Root Cause**: The scaling issue was caused by several factors:

1. **Layout Constraint Issues**: 
   - Incorrect use of `Expanded` widgets with `flex` properties
   - Missing `ConstrainedBox` constraints in dashboard layout
   - Improper `Column` sizing with `mainAxisSize: MainAxisSize.min`

2. **Text Scaling Interference**:
   - Global `TextScaler.linear(1.0)` was applied incorrectly
   - System text scaling was interfering with custom layouts

3. **Theme Integration Conflicts**:
   - Dashboard screen was not properly integrated with `ThemeService`
   - Hardcoded colors conflicted with dynamic theme system

**Solution Applied**:

```dart
// ❌ BEFORE (Causing scaling issues):
Column(
  mainAxisSize: MainAxisSize.min,  // This caused layout problems
  children: [
    Expanded(flex: 2, child: HeaderWidget()),  // flex caused issues
    Expanded(flex: 3, child: ContentWidget()),
  ],
)

// ✅ AFTER (Fixed scaling):
Column(
  children: [
    HeaderWidget(),  // Natural sizing
    Expanded(child: ContentWidget()),  // Only one Expanded needed
  ],
)
```

**Key Changes Made**:

1. **Layout Structure**:
   - Removed unnecessary `flex` properties from `Expanded` widgets
   - Restored proper `ConstrainedBox` with `maxWidth` constraints
   - Fixed `Column` sizing to use natural layout flow

2. **Text Scaling**:
   - Removed global `TextScaler.linear(1.0)` override
   - Let system handle text scaling naturally
   - Used `MediaQuery` for responsive design instead

3. **Theme Integration**:
   - Added `Consumer<ThemeService>` wrapper to dashboard
   - Updated all hardcoded colors to use `themeService` properties
   - Ensured consistent theming across all screens

**Files Modified**:
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/auth/screens/otp_verification_screen.dart`
- `lib/app/app.dart`
- `lib/main.dart`

**Result**: 
- ✅ Scaling issues completely resolved
- ✅ Consistent UI across all screen sizes
- ✅ Proper theme integration maintained
- ✅ Responsive design working correctly

**Prevention**: 
- Always test layout changes on different screen sizes
- Avoid unnecessary `flex` properties in `Expanded` widgets
- Use `ConstrainedBox` for layout constraints instead of forcing sizes
- Test theme changes across all screens to ensure consistency

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, email support@yourapp.com or join our Discord server.

## 🙏 Acknowledgments

- **Flutter Team** - Amazing framework
- **Twilio** - Reliable SMS service
- **Railway** - Excellent hosting platform
- **Node.js Community** - Great ecosystem

---

**Made with ❤️ for astrologers worldwide** 🌟