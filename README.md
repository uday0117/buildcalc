# BuildCalc 🏗️📐

> **Professional Construction Calculator, 2D Floor Plan CAD Suite, 3D Visualizer & Material Estimator for Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android 16 Ready](https://img.shields.io/badge/Android%2016-Target%20SDK%2036-3DDC84.svg?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![16 KB Page Aligned](https://img.shields.io/badge/Memory-16%20KB%20Page%20Supported-blue.svg?style=for-the-badge)](https://developer.android.com/guide/practices/page-sizes)
[![Firebase](https://img.shields.io/badge/Firebase-Supported-FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Languages](https://img.shields.io/badge/Languages-24%20Locales-blueviolet.svg?style=for-the-badge)](#-internationalization-24-languages)

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
  - [1. Civil Engineering & Material Calculators](#1-civil-engineering--material-calculators)
  - [2. Interactive 2D Floor Plan CAD Editor](#2-interactive-2d-floor-plan-cad-editor)
  - [3. 3D Architectural Visualizer](#3-3d-architectural-visualizer)
  - [4. Architectural Elevation Studio](#4-architectural-elevation-studio)
  - [5. Automated BOQ & Material Estimator](#5-automated-boq--material-estimator)
  - [6. Project & Budget Management](#6-project--budget-management)
  - [7. Calculation History & Saved Bookmarks](#7-calculation-history--saved-bookmarks)
  - [8. Professional PDF & Image Export](#8-professional-pdf--image-export)
- [Internationalization (24 Languages)](#-internationalization-24-languages)
- [Project Architecture & File Structure](#-project-architecture--file-structure)
- [Technology Stack & Dependencies](#-technology-stack--dependencies)
- [Android 16 & 16 KB Page Size Compliance](#-android-16--16-kb-page-size-compliance)
- [Getting Started](#-getting-started)
- [Building for Production](#-building-for-production)
- [Google Play Store Release & Keystore](#-google-play-store-release--keystore)
- [License & Authors](#-license--authors)

---

## 🌟 Overview

**BuildCalc** is an all-in-one mobile suite engineered for civil engineers, building contractors, architects, site supervisors, and DIY home builders. It combines high-precision civil engineering calculation algorithms with a full-featured 2D CAD floor plan editor, live 3D plan visualization, parametric elevation generator, automated bill of quantities (BOQ) estimator, and multi-project budget tracking.

Designed for field and desktop workflows alike, BuildCalc works 100% offline for calculation logic while supporting PDF document generation, native sharing, dark/light themes, and 24 international languages.

---

## 🚀 Key Features

### 1. Civil Engineering & Material Calculators

BuildCalc features 10 specialized calculation modules adhering to industry standard civil engineering formulas:

| Calculator | What It Computes | Key Parameters & Formulae |
| :--- | :--- | :--- |
| **Cement Calculator** | Concrete & mortar cement bag requirements | Concrete mix ratios (1:1.5:3, 1:2:4, 1:3:6), dry volume coefficient ($1.54\times$), mortar joint multiplier ($1.33\times$), bag weight (50 kg). |
| **Brick Calculator** | Total brick counts & mortar consumption | Wall length, height, thickness (4", 9", 14"), brick sizes (standard modular / country), deduction of openings, wastage factor. |
| **Sand Calculator** | Fine aggregate volume & tonnage | Volume in $\text{m}^3$, $\text{ft}^3$ (cft), dry bulk density conversion to metric tonnes. |
| **Paint Calculator** | Interior/exterior paint liters & primer | Wall surface areas, deductions for doors/windows, number of coats (1, 2, 3), coverage rate ($\text{sq.ft/liter}$). |
| **Steel / Rebar Calculator** | Reinforcement weight & total tonnage | Standard diameters (6 mm, 8 mm, 10 mm, 12 mm, 16 mm, 20 mm, 25 mm, 32 mm), bar length, standard unit weight formula: $W = \frac{D^2}{162} \text{ kg/m}$. |
| **Tile Calculator** | Floor & wall tile count and boxes | Room dimensions, tile dimensions ($\text{cm}\times\text{cm}$ / $\text{ft}\times\text{ft}$), pieces per carton/box, customizable wastage cushion (typically 5–10%). |
| **Area & Geometry Calculator** | Built-up area & perimeters | Shapes: rectangles, squares, triangles, circles, trapezoids, complex site boundaries; unit conversions. |
| **Cost Estimator** | Overall project budget forecast | Built-up area input, quality tiers (*Basic, Standard, Premium, Luxury*), component breakdown (structure, finishing, electrical, plumbing). |
| **Staircase Calculator** | Riser, tread, waist slab & concrete volume | Total vertical rise, riser height, tread run, flight slope angle, waist slab thickness, live dynamic cross-section sketch painter. |
| **Excavation & Earthwork** | Foundation pit volume, soil swell & haulage | Length, width, depth, soil bulking/swell percentage, backfill volume, dump truck trip counts, live foundation trench diagram. |

---

### 2. Interactive 2D Floor Plan CAD Editor

- **Plot & Setback Setup**: Define boundary plot width, length, and mandatory setbacks (front, rear, sides) in either Imperial (feet/inches) or Metric (meters).
- **Interactive Canvas**: Smooth multi-touch pan, pinch-to-zoom, grid overlay, and snap-to-grid alignment.
- **Room Modeling**: Add, drag, resize, rotate, and rename rooms with distinct room categories (Master Bedroom, Living Room, Kitchen, Bathroom, Pooja, Balcony, Dining, Parking, Staircase).
- **Architectural Openings**: Place single doors, double doors, sliding doors, windows, and ventilators directly onto wall segments with interactive position offsets.
- **Ready-Made Templates**: Instant loading of pre-architected layouts (1 BHK, 2 BHK, 3 BHK, Duplex, Compact Studios) with auto-scaling to plot dimensions.
- **Real-Time Summary**: Live tracking of total plot area, total built-up area, carpet area, and ground coverage percentage.

---

### 3. 3D Architectural Visualizer

- Converts 2D room layouts into full 3D extruded polygonal environments.
- Wall extrusion with realistic ceiling heights, wall thickness, and opening punch-outs.
- Interactive camera controls: orbit around target, tilt angle adjustments, distance zoom.
- Floor texturing and depth rendering for immediate visual comprehension of spatial layouts.

---

### 4. Architectural Elevation Studio

- **2D/3D Elevation Generation**: Automatically builds front and side facade projections from the floor plan geometry.
- **Style Customization**: Modern, Contemporary, Classic, and Minimalist design palettes.
- **Structural Facade Elements**: Configurable roof types (flat terrace, parapet wall, pitched/gable roof), balcony balustrades, color schemes, and architectural accent bands.
- **Elevation Studio & Side-by-Side Comparison**: Compare different architectural variations before finalizing client presentations.

---

### 5. Automated BOQ & Material Estimator

- Automatically computes total quantities directly from the active floor plan:
  - **Brickwork / Masonry**: Wall surface area minus window/door openings $\times$ brick thickness.
  - **Plastering**: Internal and external wall surface areas with ceiling plaster allowances.
  - **Flooring Tiles**: Accurate carpet area breakdown by individual room types.
  - **Concrete Slab Volume**: Roof slab casting volume based on floor footprint.
  - **Paint Quantity**: Wall finish areas with standard multi-coat spread factors.
- Configurable material assumptions sheet allowing custom ratios and contingency factors.

---

### 6. Project & Budget Management

- **Multi-Project Workspace**: Create and track separate construction sites (e.g., "Villa Green", "Commercial Block B").
- **Material Line Items**: Add custom materials with unit prices, requested quantities, and scrap/wastage allowances.
- **Budget Tracking**: Visual progress bars showing cost utilization against total target budget with real-time status (*Within budget*, *At budget*, *Over budget*).
- **Audit History**: Chronological activity log for tracking modifications, site notes, and milestones.

---

### 7. Calculation History & Saved Bookmarks

- **Automatic History**: Automatically captures and records the last 50 calculations across all calculators with timestamp, input values, and detailed results.
- **Saved Favorites**: Bookmark frequently referenced calculations or client estimates with single-tap restore.
- **Persistence**: Powered by local `SharedPreferences`—persists across sessions without requiring internet connectivity.

---

### 8. Professional PDF & Image Export

- **Vector PDF Blueprints**: Generates vector-sharp multi-page documents containing:
  - Plot layout drawing with dimensions
  - Room schedule and area table
  - Door & window opening schedule
  - Complete Bill of Quantities (BOQ) with material breakdowns
  - Project metadata, date, engineer name, and client details
- **High-Resolution PNG/JPG Export**: Renders the floor plan canvas directly to high-DPI image files.
- **Native Sharing**: Instant export to WhatsApp, Email, AirDrop, Google Drive, or cloud storage via `share_plus` and `printing`.

---

## 🌐 Internationalization (24 Languages)

BuildCalc features native multi-lingual support across 24 global languages:

| Code | Language | Native Name | Code | Language | Native Name |
| :---: | :--- | :--- | :---: | :--- | :--- |
| `en` | English | English | `id` | Indonesian | Bahasa Indonesia |
| `es` | Spanish | Español | `tr` | Turkish | Türkçe |
| `hi` | Hindi | हिन्दी | `it` | Italian | Italiano |
| `ar` | Arabic | العربية | `vi` | Vietnamese | Tiếng Việt |
| `fr` | French | Français | `ko` | Korean | 한국어 |
| `pt` | Portuguese | Português | `pl` | Polish | Polski |
| `de` | German | Deutsch | `nl` | Dutch | Nederlands |
| `ru` | Russian | Русский | `fil` | Filipino | Filipino (Tagalog) |
| `zh` | Chinese | 简体中文 | `fa` | Persian | فارسی |
| `ja` | Japanese | 日本語 | `th` | Thai | ไทย |
| `bn` | Bengali | বাংলা | `ta` | Tamil | தமிழ் |
| `ur` | Urdu | اردو | `te` | Telugu | తెలుగు |

The app automatically selects the system device language, with an in-app selector in Settings for instant manual override.

---

## 📁 Project Architecture & File Structure

```
buildcalc/
├── android/                     # Android native platform files (API 36, 16KB alignment)
│   ├── app/
│   │   ├── build.gradle.kts     # SDK 36, AGP 8.11.1, JNI packaging
│   │   ├── buildcalc-keystore.jks # Production signing keystore
│   │   └── google-services.json # Firebase configuration
│   └── key.properties           # Keystore credentials reference
├── assets/images/               # App icons & store graphics
├── lib/
│   ├── main.dart                # Application entry point, themes, localization init
│   ├── app_localizations.dart   # 24-language localization dictionary & delegate
│   ├── app_settings.dart        # Global user settings model (theme, locale)
│   ├── firebase_options.dart    # Firebase options configuration
│   ├── models/
│   │   ├── calculation.dart     # History and saved calculation models
│   │   ├── calculator_item.dart # Calculator metadata, categories & search index
│   │   ├── project.dart         # Multi-project budget & material entity models
│   │   └── plan/                # 2D/3D CAD Plan domain models
│   │       ├── plan_models.dart # Plot, Room, Opening, Wall data structures
│   │       ├── plan_editor_controller.dart # Canvas state & editing actions
│   │       ├── plan_geometry.dart # Intersection, snap & boundary math
│   │       ├── plan_unit.dart   # Feet/Inches vs. Metric conversions
│   │       ├── plan_templates.dart # Ready-made floor plan layouts
│   │       ├── plan_3d_models.dart # 3D mesh & vertex definitions
│   │       ├── elevation_models.dart # Facade elevation profiles
│   │       └── material_estimation_models.dart # BOQ calculation structures
│   ├── screens/
│   │   ├── splash_screen.dart   # Animated brand splash screen
│   │   ├── home_screen.dart     # Grid dashboard, search & category navigation
│   │   ├── history_screen.dart  # 50-item calculation history with clear & inspect
│   │   ├── saved_screen.dart    # Bookmarked calculations
│   │   ├── settings_screen.dart # Theme (Light/Dark), Language, About
│   │   ├── project_management_screen.dart # Budget, materials & project audit
│   │   ├── calculators/         # Individual calculator view screens
│   │   │   ├── cement_calculator.dart
│   │   │   ├── brick_calculator.dart
│   │   │   ├── sand_calculator.dart
│   │   │   ├── paint_calculator.dart
│   │   │   ├── steel_calculator.dart
│   │   │   ├── tile_calculator.dart
│   │   │   ├── area_calculator.dart
│   │   │   ├── cost_estimator.dart
│   │   │   ├── staircase_calculator.dart
│   │   │   └── excavation_calculator.dart
│   │   └── plan/                # Plan suite view screens
│   │       ├── plan_editor_screen.dart # 2D interactive CAD workspace
│   │       ├── plan_3d_view_screen.dart # 3D interactive viewer
│   │       ├── plan_elevation_screen.dart # Architectural elevation studio
│   │       ├── plan_material_estimate_screen.dart # Plan BOQ bill of materials
│   │       ├── plan_templates_screen.dart # Architectural template picker
│   │       └── saved_plans_screen.dart # User saved floor plans
│   ├── services/
│   │   ├── ad_service.dart      # Google Mobile Ads (Banner, Interstitial)
│   │   ├── app_settings_service.dart # Theme & locale SharedPreferences cache
│   │   ├── storage_service.dart # Calculation history & bookmark persistence
│   │   ├── plan_storage_service.dart # Plan file I/O & persistence
│   │   ├── plan_pdf_export_service.dart # Professional PDF blueprint builder
│   │   ├── plan_image_export_service.dart # High-res image rendering
│   │   ├── plan_material_estimator.dart # BOQ computation engine from plan
│   │   ├── plan_3d_builder.dart # 2D-to-3D polygon translation engine
│   │   ├── elevation_builder.dart # Architectural elevation geometry builder
│   │   ├── review_service.dart  # In-app Google Play review prompt
│   │   └── update_service.dart  # Remote version check service
│   └── widgets/
│       ├── ad_banner.dart       # Smart banner AdMob widget
│       ├── calculator_card.dart # Responsive grid card widget
│       ├── input_field.dart     # Standardized numeric input with units
│       ├── result_card.dart     # Formatted calculation result display
│       ├── unit_selector.dart   # Unit toggle chips
│       ├── calculators/         # Visual sketch painters
│       │   ├── staircase_sketch_painter.dart
│       │   └── excavation_sketch_painter.dart
│       └── plan/                # Plan CAD canvas painters & bottom sheets
├── ios/                         # iOS native workspace
├── macos/                       # macOS native workspace
├── linux/                       # Linux native workspace
├── windows/                     # Windows native workspace
├── web/                         # Web build, PWA manifest & privacy policy
├── pubspec.yaml                 # Flutter package manifest & assets
└── PLAY_STORE_GUIDE.md          # Google Play launch checklist
```

---

## 🛠️ Technology Stack & Dependencies

| Dependency | Purpose |
| :--- | :--- |
| **Flutter 3.x / Dart 3.x** | Cross-platform core framework |
| **`shared_preferences`** (`^2.2.2`) | Local persistent storage for history, favorites & settings |
| **`pdf`** (`^3.12.0`) & **`printing`** (`^5.12.0`) | Architectural blueprint PDF document rendering & printing |
| **`path_provider`** (`^2.1.6`) | File system access for exports, backups, and caches |
| **`share_plus`** (`^7.2.1`) | Native cross-platform sharing intent |
| **`google_mobile_ads`** (`^9.2.0`) | AdMob banner and interstitial advertising integration |
| **`firebase_core`** (`^2.27.0`) | Firebase initialization & infrastructure |
| **`in_app_review`** (`^2.0.9`) | Google Play in-app store ratings and reviews |
| **`intl`** (`^0.20.2`) | Number formatting, currency, and date/time formatting |
| **`url_launcher`** (`^6.2.5`) | Web links for external documents and privacy policies |
| **`flutter_localizations`** | Official Flutter multi-locale delegate support |

---

## 🛡️ Android 16 & 16 KB Page Size Compliance

BuildCalc is fully compliant with the latest Google Play standards:

1. **Target & Compile SDK 36 (Android 16)**:
   - Configured in `android/app/build.gradle.kts` (`compileSdk = 36`, `targetSdk = 36`).
2. **16 KB Memory Page Size Support**:
   - Modern Android 15 and 16 hardware supports 16 KB physical memory page sizes.
   - BuildCalc enables uncompressed native library packaging:
     ```gradle
     // android/app/build.gradle.kts
     packaging {
         jniLibs {
             useLegacyPackaging = false
         }
     }
     ```
   - Enabled in `android/gradle.properties`:
     ```properties
     android.bundle.enableUncompressedNativeLibs=true
     ```
   - Native libraries (`.so`) are automatically page-aligned to `0x4000` (16384 bytes) via Android Gradle Plugin 8.11.1 and Gradle 8.14.

---

## 💻 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.10.4 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- Java 17+ (required for Android Gradle Plugin 8+)
- Android Studio / Xcode for platform-specific builds

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/buildcalc.git
   cd buildcalc
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run on an emulator or connected device:**
   ```bash
   flutter run
   ```

---

## 📦 Building for Production

### Android

- **Debug APK (for local testing):**
  ```bash
  flutter build apk --debug
  ```

- **Release APK (signed with keystore):**
  ```bash
  flutter build apk --release
  ```
  *Output: `build/app/outputs/flutter-apk/app-release.apk`*

- **Production Google Play App Bundle (AAB):**
  ```bash
  flutter build appbundle --release
  ```
  *Output: `build/app/outputs/bundle/release/app-release.aab`*

### iOS / macOS / Web

- **iOS Release IPA:**
  ```bash
  flutter build ipa --release
  ```
- **Web App (PWA):**
  ```bash
  flutter build web --release
  ```

---

## 🔐 Google Play Store Release & Keystore

- **Package Name / Application ID**: `com.uksolutions.buildcalc`
- **Keystore Location**: `android/app/buildcalc-keystore.jks`
- **Configuration**: `android/key.properties` (reads `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`)
- **Privacy Policy**: Static document provided at `privacy_policy.html` and `web/privacy.html`.

> [!IMPORTANT]
> Keep `buildcalc-keystore.jks` and `android/key.properties` secure. Never expose credentials in public source repositories.

---

## 🎨 Theme & Brand Palette

| Color Name | Hex Code | Purpose |
| :--- | :--- | :--- |
| **Deep Blue** | `#1E3A5F` | Primary brand color, headers, app bars, primary buttons |
| **Safety Orange** | `#FF8C00` | Accent color, highlights, active navigation icons |
| **Light Canvas** | `#F5F7FB` | Clean background for mobile layouts |
| **Dark Canvas** | `#121212` | Dark theme surface & background |

---

## 📄 License & Ownership

Developed by **UK Solutions**. All rights reserved. Designed for construction professionals worldwide.
