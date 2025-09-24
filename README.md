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

## 🐛 Known Issues & Solutions

### ✅ Scaling/Zooming Issue - FIXED

**Problem**: The app experienced scaling/zooming issues where UI elements appeared larger than intended, particularly affecting the dashboard.

**Root Cause**: The scaling issue was caused by incorrect layout constraints:
- Using `MediaQuery.of(context).size.height` in `ConstrainedBox` instead of `LayoutBuilder`
- Forcing full screen height constraints that caused content to scale improperly

**Solution Applied**:
```dart
// ❌ WRONG (Causing scaling issues):
ConstrainedBox(
  constraints: BoxConstraints(
    minHeight: MediaQuery.of(context).size.height, // This causes scaling!
  ),
  child: Column(...)
)

// ✅ CORRECT (Fixed scaling):
LayoutBuilder(
  builder: (context, constraints) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: constraints.maxHeight, // This is correct
        maxWidth: constraints.maxWidth,
      ),
      child: Column(...)
    );
  },
)
```

**Prevention Guidelines**:
1. **Always use `LayoutBuilder`** instead of `MediaQuery` for responsive constraints
2. **Avoid forcing dimensions** unless absolutely necessary
3. **Test on real devices** with different screen sizes
4. **Keep working backups** before making layout changes
5. **Use natural sizing** over forced sizing for better UX

## 🔧 Troubleshooting

### Layout Issues
If you encounter scaling or layout problems:

1. **Check LayoutBuilder Usage**:
   ```dart
   // ✅ Correct way
   LayoutBuilder(
     builder: (context, constraints) {
       return ConstrainedBox(
         constraints: BoxConstraints(
           minHeight: constraints.maxHeight,
           maxWidth: constraints.maxWidth,
         ),
         child: YourWidget(),
       );
     },
   )
   ```

2. **Avoid MediaQuery in Constraints**:
   ```dart
   // ❌ Don't do this
   ConstrainedBox(
     constraints: BoxConstraints(
       minHeight: MediaQuery.of(context).size.height,
     ),
   )
   ```

3. **Test on Real Devices**: Always test layout changes on actual devices, not just emulators.

4. **Keep Backups**: Maintain working code backups before making layout changes.

### Build Issues
- **Java Version**: Ensure Java 17 is installed and configured
- **Android SDK**: Use API level 34+ as specified
- **Clean Build**: Run `flutter clean` before building if issues persist

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