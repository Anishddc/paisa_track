# Paisa Track App - Changelog

## v0.1.0 (Initial Setup) - [Current Date]
- Created Flutter project structure
- Added required dependencies in pubspec.yaml
- Set up project folder organization
- Created initial project documentation
- Configured app description and version
- Created core constants (app, colors, routes, text)
- Set up theme configuration (light and dark themes)
- Added utility classes (date, currency, validation)
- Created splash screen
- Configured main app entry point

## v0.2.0 (Basic UI Implementation) - [Current Date]
- Created onboarding screens with slide-based tutorial
- Added home screen with dashboard UI
- Set up navigation between screens
- Implemented app initialization and first-launch detection
- Added bottom navigation bar for main app sections

## v0.3.0 (Data Model Implementation) - [Current Date]
- Created Hive database models for storing data
- Implemented enums for account types and transaction types
- Built data models for accounts, categories, transactions, and budgets
- Created user profile model for storing user preferences
- Implemented database service for initializing Hive and managing boxes
- Built repository classes for each model type to abstract database operations
- Added methods for CRUD operations on all model types
- Implemented logic for transaction handling and account balance management
- Added budget calculation and tracking functionality
- Configured data model initialization in app startup 

## v0.4.0 (Onboarding & User Setup UI Enhancement) - [Current Date]
- Redesigned onboarding screens with modern UI
- Replaced Lottie animations with built-in Flutter icons for better performance
- Enhanced onboarding screens with proper back button navigation
- Added swipe navigation between onboarding pages
- Implemented skip functionality for onboarding
- Created a beautiful step-based user setup flow with progress indicators
- Added themed color gradients for each setup step
- Enhanced form fields with better styling and visual feedback
- Implemented improved profile image picker with camera button overlay
- Redesigned currency selector with symbol display and Nepali Rupee (NPR) as default
- Enhanced account selection options with colored icons and better descriptions
- Updated Digital Wallet text to show local payment options (eSewa, Khalti, IMEPay)
- Fixed layout issues and implemented responsive design for all screens
- Added proper navigation handling with WillPopScope for system back button
- Enhanced loading indicators with themed colors
- Fixed overflow issues in account selection cards
- Improved button states based on form validation
- Added smooth transitions between pages with animations 