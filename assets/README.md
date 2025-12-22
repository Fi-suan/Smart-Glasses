# Assets Directory

This directory contains all static assets used in the application.

## Structure

```
assets/
├── images/          # PNG, JPG images
├── icons/           # SVG icons
├── sounds/          # Audio files for notifications
└── fonts/           # Custom fonts
```

## Images
Place app images here:
- Splash screen images
- Onboarding images
- Feature illustrations
- Background images

## Icons
Place SVG icons here:
- Feature icons
- Navigation icons
- Status icons

## Sounds
Place audio files here:
- Notification sounds
- Voice prompts
- UI feedback sounds

## Fonts
Place custom font files here if using custom fonts (currently using Google Fonts which are downloaded automatically).

## Usage

Reference assets in code:
```dart
Image.asset('assets/images/logo.png')
SvgPicture.asset('assets/icons/navigation.svg')
```

All assets must be declared in `pubspec.yaml` under the `flutter > assets` section.

