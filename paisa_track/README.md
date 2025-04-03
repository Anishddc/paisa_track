# Paisa Track

A comprehensive personal finance and expense tracking application built with Flutter.

## Description

Paisa Track is a privacy-focused, offline-first money management app designed to help users track expenses, manage budgets, and gain insights into their financial habits. All data is stored locally on the device - no account creation or internet connection required.

## Features

### Transaction Management
- Track income, expenses, and transfers between accounts
- Categorize transactions with customizable categories
- Add notes, images, and detailed descriptions to transactions
- Support for recurring transactions

### Account Management
- Support for multiple accounts (cash, bank, credit card, etc.)
- Track balances across all accounts
- Transfer funds between accounts

### Budgeting
- Create monthly budgets by category
- Track spending against budget limits
- Visual progress indicators for budget utilization

### Reporting and Analysis
- Transaction history with filtering and search
- Spending breakdowns by category, account, and time period
- Export transaction data to PDF
- Visualize income and expenses with charts

### Additional Features
- Currency support for multiple regions
- Customizable themes (light and dark mode)
- Local notifications for bill reminders
- Data backup and restore functionality
- Privacy features including biometric authentication

## Screenshots

[Screenshots to be added]

## Getting Started

### Prerequisites
- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio / VS Code with Flutter plugins

### Installation

1. Clone the repository:
```
git clone https://github.com/yourusername/paisa_track.git
```

2. Navigate to the project directory:
```
cd paisa_track
```

3. Install dependencies:
```
flutter pub get
```

4. Run the app:
```
flutter run
```

## Building for Production

### Android
```
flutter build apk --release
```

### iOS
```
flutter build ios --release
```

## Project Structure

- `lib/core` - Core utilities, constants, and helper functions
- `lib/data` - Data layer (models, repositories, services)
- `lib/presentation` - UI layer (screens, widgets)
- `lib/providers` - State management

## Latest Updates

**Version 1.0.0-beta.6+6**
- Added transaction history export to PDF
- Redesigned transactions screen UI
- Fixed currency display issues
- See [CHANGELOG.md](CHANGELOG.md) for complete version history

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Made with ❤️ from Nepal by Aneesh

Thank you for using Paisa Track!
