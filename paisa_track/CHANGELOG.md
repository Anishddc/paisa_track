# Changelog

## 1.0.0-beta.5+5 (2025-04-10)

### Added
- Complete currency conversion functionality
- Currency converter utility for accurately converting between currencies
- Support for storing and displaying transaction amounts in their original currency
- Enhanced transaction details screen showing both original and converted amounts

### Fixed
- Fixed issue where changing currency would display amounts as 0
- Fixed currency display inconsistencies across the app
- Ensured transaction amounts maintain their value when currency is changed

### Changed
- Improved transaction repository to store currency information
- Updated CurrencyProvider to handle currency conversion more effectively
- Enhanced notification system with comprehensive notification management

## 1.0.0-beta.2+2 (2025-03-25)

### Added
- Complete dark mode support throughout the app
- Proper theming for all screens, cards, and UI components
- Theme respects system settings automatically

### Fixed
- Fixed accounts screen UI issues in dark mode
- Fixed categories screen UI issues in dark mode
- Fixed reports screen UI issues in dark mode
- Ensured all text is readable in both light and dark themes

### Changed
- Updated theme implementation to properly use Consumer pattern with ThemeProvider
- Refactored hardcoded colors to use theme-aware colors

## 0.9.0+1 (2025-03-20)

### Added
- Initial beta release with core functionality
- Transaction tracking
- Multiple account support
- Category management
- Basic reporting 