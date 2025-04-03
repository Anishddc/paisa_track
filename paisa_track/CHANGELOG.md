# Changelog

## [Unreleased]

### Added
- Added swipe-to-edit (right) and swipe-to-delete (left) functionality for loans
- Improved loan card UI with dismissible actions and confirmation dialogs
- Made bank account selection optional when adding loans
- Added ability to enter custom bank/lender names when no account is selected
- Modernized Bills screen UI with enhanced design and interaction patterns
- Added swipe-to-edit and swipe-to-delete functionality for bills

### Fixed
- **Critical Bill Management Fixes**:
  - Fixed "Cannot write, unknown type: BillModel" error when adding bills
  - Implemented robust BillModelAdapter registration with enhanced error handling
  - Created CustomBillModelAdapter as a fallback solution for serialization issues
  - Fixed BillModel type registration in Hive by ensuring adapter registration order
  - Added robust field-by-field error handling in custom adapter
  - Optimized adapter registration sequence to handle dependencies properly
  - Added detailed error reporting for adapter registration problems
  - Created test utility to verify bill creation and storage functionality

- **Loan Management Fixes**:
  - Fixed provider access issues in LoanDetailsScreen
  - Added proper error handling for loan payment operations
  - Improved UI feedback for error states
  - Fixed null safety issues with loan data access

- **Repository and Provider Fixes**:
  - Fixed initialization issues with BillRepository
  - Added proper null checking in DatabaseService
  - Improved provider state management across screens
  - Enhanced error reporting for repository operations

### Changed
- Updated UI components across bill and loan screens
- Improved error messaging and user feedback
- Enhanced database integrity verification

## 1.0.0-beta.7+7 (April 15, 2025)

### Added
- **Update Settings Screen**: Added a dedicated screen for managing app updates
- **GitHub Repository Configuration**: Added ability to configure the GitHub repository for app updates
- **Update Check Controls**: Added toggle for enabling/disabling automatic update checks
- **Manual Update Check**: Added option to manually check for updates

### Improved
- **Enhanced Update Service**: Improved internet connectivity checks and error handling
- **Multiple Domain Testing**: App now tries multiple domains to verify internet connectivity
- **Retry Mechanism**: Added retry logic for GitHub API requests with exponential backoff
- **Better Error Messages**: More descriptive error messages for update failures

### Fixed
- Fixed "Update check failed" dialog appearing when there's no internet connection
- Fixed "No route defined for /settings/updates" error when navigating to update settings
- Fixed GitHub repository details to correctly match the actual repository

## 1.0.0-beta.6+6 (April 3, 2025)

### New Features
- **Transaction History Export**: Added PDF export functionality for transaction history
  - Customizable date range selection
  - Filtering by transaction type, category, and account
  - PDF includes summary statistics and detailed transaction list
  - User details in PDF export for personalization
  - Support for downloading or sharing the generated PDF

### Improvements
- **All Transactions Screen**: Completely redesigned top bar with improved UI
  - Modern date range filter with intuitive date picker
  - Enhanced filter chips with better visual design
  - Improved search functionality
  - More consistent display of transaction data
  - Proper currency symbol display based on user settings

### Bug Fixes
- Fixed incorrect currency symbol in transaction list
- Resolved routing issues with transaction export screen
- Fixed PDF export currency display issues for non-Latin characters
- Added proper handling of special currency symbols in PDF exports

## 1.0.0-beta.5+5 (March 15, 2025)

### Initial Beta Release
- Core financial tracking functionality
- Transaction management
- Account management
- Budget tracking
- Category management
- Basic reporting features

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

## [Previous Versions]

<!-- Previous changelog entries go here --> 