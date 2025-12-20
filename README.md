# 📄 Document Companion

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)

A powerful Flutter application for scanning documents, organizing them into folders, and converting images to PDF with ease.

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Contributing](#-contributing) • [License](#-license)

</div>

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Installation](#-installation)
- [Usage](#-usage)
- [Project Structure](#-project-structure)
- [Development](#-development)
- [Contributing](#-contributing)
- [Design Guidelines](#-design-guidelines)
- [License](#-license)

## 🎯 About

Document Companion is a modern, cross-platform document management application built with Flutter. It allows users to:

- 📸 Scan documents using device camera
- 📁 Organize documents into folders with tags
- 🔍 Filter and search documents by tags
- 📄 Convert images to PDF format
- ✏️ Edit and enhance scanned documents
- 🎨 Beautiful, modern UI with dark mode support

## ✨ Features

### Core Features

- **📸 Document Scanner**
  - High-quality document scanning using device camera
  - Automatic edge detection and cropping
  - Image enhancement and filters
  - Multiple image capture support

- **📁 Folder Management**
  - Create custom folders for organization
  - Tag-based folder categorization
  - Filter folders by tags
  - Sort and organize documents efficiently

- **📄 PDF Conversion**
  - Convert multiple images to PDF
  - Batch processing support
  - Print and share PDFs

- **🎨 User Interface**
  - Modern, intuitive design
  - Dark mode support
  - Smooth animations and transitions
  - Responsive layout for all screen sizes

### Planned Features

- PDF Editor and Creator
- Advanced folder tagging system
- Cloud storage integration
- OCR (Optical Character Recognition)
- Document sharing and collaboration

## 📸 Screenshots

> **Note:** Screenshots coming soon. Check out the [Design Guidelines](#-design-guidelines) for UI reference.

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** [Dart](https://dart.dev/)
- **State Management:** [BLoC](https://bloclibrary.dev/)
- **Local Database:** [SQLite](https://www.sqlite.org/) via `sqflite`
- **Camera:** [camera](https://pub.dev/packages/camera)
- **PDF Generation:** [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing)
- **Permissions:** [permission_handler](https://pub.dev/packages/permission_handler)
- **Internationalization:** [intl](https://pub.dev/packages/intl)

## 📦 Installation

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode (for mobile development)
- Git

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/document_companion.git
   cd document_companion
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate localization files** (if needed)
   ```bash
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android

- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Ensure camera and storage permissions are configured in `android/app/src/main/AndroidManifest.xml`

#### iOS

- Minimum iOS version: 12.0
- Configure camera and photo library permissions in `ios/Runner/Info.plist`

#### Web

- Currently supported with limited camera functionality
- PDF generation works on web

## 🚀 Usage

### Scanning Documents

1. Tap the **Create** button on the home screen
2. Select **Scan Document**
3. Grant camera permissions if prompted
4. Position the document within the frame
5. Tap the capture button
6. Adjust crop area if needed
7. Apply filters or enhancements
8. Save the document

### Creating Folders

1. Tap the **Create** button
2. Select **New Folder**
3. Enter folder name
4. Optionally add tags
5. Tap **Create**

### Converting to PDF

1. Open a folder
2. Select images you want to convert
3. Tap the **PDF** icon
4. Choose export options
5. Save or share the PDF

## 📁 Project Structure

```
lib/
├── config/              # App configuration
│   ├── custom_colors.dart
│   ├── custom_key.dart
│   ├── custom_theme.dart
│   └── route_generator.dart
├── generated/          # Generated files (l10n)
│   └── intl/
├── l10n/               # Localization files
│   └── intl_en.arb
├── local_database/      # Database layer
│   ├── handler/        # Database handlers
│   └── models/         # Database models
├── main.dart           # App entry point
├── modules/            # Feature modules
│   ├── home/           # Home screen
│   │   ├── bloc/       # Business logic
│   │   ├── models/     # View models
│   │   └── view/       # UI components
│   ├── scan/           # Scan feature
│   └── scanner/        # Document scanner
│       ├── bloc/       # Scanner BLoCs
│       ├── models/     # Scanner models
│       ├── ui/         # Scanner UI
│       └── utils/      # Scanner utilities
└── utils/              # Utility functions
    ├── constants/
    └── models/
```

## 💻 Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

### Code Style

This project follows the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide. Run the formatter:

```bash
flutter format .
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Reporting Issues

Found a bug? Have a feature request? Please [open an issue](https://github.com/yourusername/document_companion/issues) with:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Device/OS information

## 🎨 Design Guidelines

The app design follows the guidelines available at:
[Adobe XD Design](https://xd.adobe.com/view/391c110a-5b76-4bc5-bd93-438ad9b5706b-6c4f/)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All contributors and open-source packages used
- Design inspiration from the community

## 📞 Contact & Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/document_companion/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/document_companion/discussions)

---

<div align="center">

Made with ❤️ using Flutter

⭐ Star this repo if you find it helpful!

</div>
