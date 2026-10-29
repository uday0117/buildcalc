# BuildCalc - Play Store Release Guide

## ✅ Completed Tasks

### 1. Splash Screen ✅
- **Custom animated splash screen** created with:
  - BuildCalc branding with logo and colors
  - Smooth fade-in and scale animations
  - Orange circular loader (brand color: #FF8C00)
  - Professional tagline: "Professional Construction Calculator"
  - Auto-navigates to home after 3 seconds
  - No images on native Android splash (just background color)

### 2. All Overflow Issues Fixed ✅
- Calculator cards optimized:
  - Reduced padding: 16px → 8px
  - Reduced icon size: 40px → 28px  
  - Reduced font size: 14px → 11px
  - Added Flexible widget with overflow handling
- **Result**: Zero overflow errors! ✅

### 3. Native Splash Cleaned ✅
- Removed flutter_native_splash package
- Removed all splash.png and android12splash.png images
- Updated Android 12+ splash to use app icon (@mipmap/ic_launcher)
- Clean solid color background with app icon

### 4. JKS Signing Configuration ✅ VERIFIED
- Location: `android/app/buildcalc-keystore.jks`
- Properties configured in: `android/key.properties`
- Build.gradle.kts configured for release signing
- **Ready for production builds!**

### 5. History & Saved Functionality ✅ WORKING
- **History Screen**:
  - Stores last 50 calculations automatically
  - Shows timestamp, type, inputs, and results
  - Clear all history option with confirmation
  - Uses SharedPreferences for persistence

- **Saved Screen**:
  - Save favorite calculations
  - View detailed breakdown
  - Remove saved items
  - Persists across app restarts

## 📦 Generate AAB File for Play Store

Run the following command to create the signed AAB file:

```bash
cd /Users/mac/Documents/uksolutions/buildcalc
flutter build appbundle --release
```

**Output location**: `build/app/outputs/bundle/release/app-release.aab`

## 📸 Take Play Store Screenshots

The app is currently running on device **2311DRN14I**. To take screenshots:

### Option 1: Using Android Device
1. Navigate through the app screens
2. Press **Power + Volume Down** simultaneously
3. Screenshots saved to device gallery

### Option 2: Using Flutter DevTools
1. Open DevTools: http://127.0.0.1:52654/qQiqvtWX0-M=/devtools/
2. Go to the Inspector tab
3. Take screenshots of different screens

### Required Screenshots for Play Store:
1. **Splash Screen** - Opening screen with BuildCalc branding
2. **Home Screen** - Calculator grid with all calculator types
3. **Cement Calculator** - Example calculator screen
4. **Brick Calculator** - Another calculator example
5. **History Screen** - With some sample calculations
6. **Saved Screen** - With saved calculations
7. **Calculation Result** - Show result screen

## 📋 Play Store Listing Information

### App Details:
- **App Name**: BuildCalc
- **Package Name**: com.uksolutions.buildcalc
- **Version**: 1.0.1+2
- **Compile SDK**: 36 (Android 16)
- **Target SDK**: 36 (Android 16)
- **Min SDK**: 21 (Android 5.0)
- **16 KB Memory Page Size Support**: Enabled (AGP 8.11.1, uncompressed page-aligned native libs)

### Description Suggestions:
**Short Description (80 chars)**:
Professional construction calculator for cement, brick, paint, steel & more.

**Full Description**:
BuildCalc is the ultimate construction calculator app designed for builders, contractors, architects, and DIY enthusiasts. Calculate material quantities quickly and accurately for your construction projects.

**Features:**
✓ Cement Calculator - Calculate cement bags needed
✓ Brick Calculator - Estimate brick quantities
✓ Sand Calculator - Compute sand requirements
✓ Paint Calculator - Calculate paint needed
✓ Steel/Rebar Calculator - Estimate steel quantities
✓ Tile Calculator - Calculate tiles needed
✓ Area Calculator - Measure construction areas
✓ Cost Estimator - Estimate project costs

✓ History - Automatic calculation history (last 50)
✓ Save Calculations - Bookmark important calculations
✓ Professional Design - Clean, modern interface
✓ Offline - Works without internet

Perfect for:
• Construction professionals
• Contractors and builders
• Architects and engineers
• Home renovation projects
• DIY construction work

## 🔧 Technical Details

### Colors:
- Primary (Dark Blue): #1E3A5F
- Secondary (Orange): #FF8C00
- Background: #F5F5F5

### Permissions:
- None required (offline app)

### Dependencies:
- shared_preferences: ^2.2.2 (Local storage)
- intl: ^0.18.1 (Date formatting)
- url_launcher: ^6.2.5 (External links - not yet used)
- cupertino_icons: ^1.0.8 (iOS icons)

## 🛡️ Android 16 (API 36) & 16 KB Page Support

### 1. Compile & Target SDK 36 (Android 16)
- Configured in `android/app/build.gradle.kts`:
  - `compileSdk = 36`
  - `targetSdk = 36`
- Ensures full compliance with Google Play's latest target API level requirements.

### 2. 16 KB Memory Page Size Support
- Modern Android devices (Android 15+ and 16) support 16 KB memory page sizes for improved performance and efficiency.
- Google Play requires all apps targeting Android 15+ with native libraries (`.so`) to support 16 KB page sizes.
- **Configured in this build:**
  - `useLegacyPackaging = false` in `android/app/build.gradle.kts` inside `packaging.jniLibs`
  - `android.bundle.enableUncompressedNativeLibs=true` in `android/gradle.properties`
  - Android Gradle Plugin `8.11.1` & Gradle `8.14` (both natively support 16 KB alignment)
- **Verification steps:**
  1. Build the App Bundle: `flutter build appbundle --release`
  2. Open Android Studio -> **Build** -> **Analyze APK...** -> select `app-release.aab`
  3. Inspect `lib/arm64-v8a/` binaries to verify 16 KB alignment (`LOAD` segments aligned to `0x4000` / 16384 bytes).

## 🚀 Build Commands Reference

### Debug APK (for testing):
```bash
flutter build apk --debug
```

### Release APK (unsigned):
```bash
flutter build apk --release
```

### Release AAB (signed - for Play Store):
```bash
flutter build appbundle --release
```

### Release APK (signed):
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## 📝 Next Steps

1. ✅ All code complete and tested
2. 🔄 **Generate AAB**: Run `flutter build appbundle --release`
3. 📸 **Take screenshots**: Use device or DevTools
4. 🎨 **Create feature graphic**: 1024x500px banner for Play Store
5. 📱 **Upload to Play Console**: Upload AAB and screenshots
6. ✍️ **Complete listing**: Add description, category, content rating
7. 🚀 **Submit for review**: Launch on Google Play Store!

## ⚠️ Important Notes

- The keystore file (`buildcalc-keystore.jks`) is essential - **keep it safe!**
- Store password: BuildCalc@2026
- Key password: BuildCalc@2026
- Never commit keystore or passwords to version control
- Backup the keystore in a secure location

## 🎯 Privacy Policy URL

The privacy policy HTML is ready at:
- File: `web/privacy.html`
- **TODO**: Host on a public URL (required by Play Store)
- Options:
  1. GitHub Pages
  2. Firebase Hosting
  3. Your domain website

## ✨ Great Job!

Your app is now ready for Play Store submission! 🎉
