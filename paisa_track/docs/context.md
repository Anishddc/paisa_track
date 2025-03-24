# Paisa Track App - Flow and Features

A **local-only** money-tracking app built with Flutter. All data is stored on-device with no authentication required.

## Table of Contents
- [App Flow](#app-flow)
  - [Onboarding](#1-onboarding-screens)
  - [User Setup](#2-user-setup)
  - [Dashboard](#3-dashboard)
  - [Accounts](#4-accounts-section)
  - [Categories](#5-categories-section)
  - [Reports](#6-reports-section)
  - [Settings](#7-settings)
- [Technical Stack](#technical-stack)
- [Developer Notes](#developer-notes)

## App Flow

### 1. Onboarding Screens

#### Slider Sequence
1. **Welcome Screen**
   - Title: "Welcome to Paisa Track!"
   - Tagline: "Take control of your finances effortlessly"
   - Action: Get Started button

2. **Feature Highlights (Sliders 2-5)**
   - Expense Tracking
   - Budgeting
   - Multi-Account Support
   - Analytics and Reports

3. **Final Slide**
   - Title: "Ready to start your financial journey?"
   - Action: Get Started button → User Setup

#### Technical Implementation
- Package: `flutter_onboarding_slider`
- Storage: `SharedPreferences` for completion status

### 2. User Setup

#### Screen Flow
1. **Welcome & Name Input**
   - Prompt: "Hi! Welcome to Paisa Track. What should we call you?"
   - Component: Name input field

2. **Profile Image**
   - Feature: Image upload via `image_picker`
   - Option: Skip available

3. **Currency Selection**
   - Component: `DropdownButton` with currency list
   
4. **Account Setup**
   - Options: Bank, Cash, Digital Wallet
   - Component: `RadioListTile`

5. **Categories Setup**
   - Predefined: Food, Transport, Entertainment
   - Feature: Custom category addition

#### Technical Implementation
- State Management: `Provider`/`Riverpod`
- Storage: Hive database
- Data: User profile, currency, accounts, categories

### 3. Dashboard

#### Layout Components
- **Top Bar**
  - Logo
  - Balance visibility toggle
  - Search functionality
  - Settings access

- **User Section**
  - Greeting with username
  - Profile image display

- **Financial Overview**
  - Total Balance
  - Income
  - Expenses
  - Monthly comparison

- **Quick Access**
  - Budget
  - Goals
  - Loans
  - Recurring
  - Analytics
  - Scan Receipt
  - Transfer Money
  - Bill Reminders
  - Savings Goals
  - Currency Converter
  - Export Reports

#### Navigation
- Bottom bar with:
  - Home
  - Accounts
  - Categories
  - Reports

#### Technical Implementation
- Charts: `fl_chart`
- State: `Provider`

### 4. Accounts Section

#### Features
- **Account Management**
  - Display cards (Bank, Cash, Digital Wallet)
  - Balance tracking
  - Transaction history
  
- **Account Operations**
  - Add new accounts
  - Drag-and-drop reordering (`ReorderableListView`)

#### Technical Implementation
- Storage: Hive
- State: `Provider`

### 5. Categories Section

#### Components
- Category listing with statistics
- Spending visualization (`fl_chart`)
- Category management tools

#### Technical Implementation
- Storage: Hive
- State: `Provider`

### 6. Reports Section

#### Features
- **Advanced Filtering**
  - Date
  - Account
  - Category
  - Tags

- **Transaction Display**
  - Detailed history view
  - PDF export capability

#### Technical Implementation
- Display: `DataTable`/`ListView`
- Storage: Hive

### 7. Settings

#### Features
1. **Appearance**
   - Theme options (Dark/Light/System)
   - Dynamic color theming

2. **Interface**
   - FAB size toggle
   - Layout customization
   - Display preferences

3. **Localization**
   - Language selection
   - Date/time formats
   - Currency display

4. **Security**
   - Notification preferences
   - Biometric authentication
   
5. **Data**
   - Backup/Restore
   - Data clearing

6. **Support**
   - Donation options
   - App sharing
   - Feedback system

7. **Information**
   - Version details
   - Legal documentation
   - Attribution

#### Technical Implementation
- Storage: `SharedPreferences`
- Localization: `flutter_localizations`
- Security: `local_auth`

## Technical Stack

### Core Libraries
```dart
dependencies:
  provider: ^6.0.0        # State management
  hive: ^2.0.0           # Local database
  fl_chart: ^0.40.0      # Visualization
  image_picker: ^0.8.0   # Media handling
  local_auth: ^1.1.0     # Security
  pdf: ^3.6.0            # Document generation
```

## Developer Notes

### Best Practices
- Implement modular architecture
- Maintain constant definitions
- Ensure cross-platform testing
- Use Git for version control

### Code Structure
lib/
├── core/
│ ├── constants/
│ ├── themes/
│ └── utils/
├── data/
│ ├── models/
│ └── repositories/
├── presentation/
│ ├── screens/
│ └── widgets/
└── main.dart
```

## Database Schema

### User Profile
```dart
@HiveType(typeId: 0)
class UserProfile {
  @HiveField(0)
  String name;
  
  @HiveField(1)
  String? profileImagePath;
  
  @HiveField(2)
  String defaultCurrency;
  
  @HiveField(3)
  DateTime createdAt;
  
  @HiveField(4)
  Map<String, dynamic> preferences;
}
```

### Account
```dart
@HiveType(typeId: 1)
class Account {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  AccountType type; // enum: BANK, CASH, DIGITAL_WALLET
  
  @HiveField(3)
  double balance;
  
  @HiveField(4)
  String currency;
  
  @HiveField(5)
  bool isArchived;
  
  @HiveField(6)
  int displayOrder;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  DateTime? lastModified;
}
```

### Category
```dart
@HiveType(typeId: 2)
class Category {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String? icon;
  
  @HiveField(3)
  String? color;
  
  @HiveField(4)
  CategoryType type; // enum: EXPENSE, INCOME
  
  @HiveField(5)
  bool isDefault;
  
  @HiveField(6)
  int displayOrder;
  
  @HiveField(7)
  DateTime createdAt;
}
```

### Transaction
```dart
@HiveType(typeId: 3)
class Transaction {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  double amount;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  DateTime date;
  
  @HiveField(4)
  String accountId;
  
  @HiveField(5)
  String categoryId;
  
  @HiveField(6)
  TransactionType type; // enum: EXPENSE, INCOME, TRANSFER
  
  @HiveField(7)
  List<String> tags;
  
  @HiveField(8)
  String? attachmentPath;
  
  @HiveField(9)
  bool isRecurring;
  
  @HiveField(10)
  RecurringInfo? recurringInfo;
  
  @HiveField(11)
  DateTime createdAt;
  
  @HiveField(12)
  DateTime? lastModified;
}
```

### Budget
```dart
@HiveType(typeId: 4)
class Budget {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  double amount;
  
  @HiveField(3)
  BudgetPeriod period; // enum: DAILY, WEEKLY, MONTHLY, YEARLY
  
  @HiveField(4)
  List<String> categoryIds;
  
  @HiveField(5)
  DateTime startDate;
  
  @HiveField(6)
  DateTime? endDate;
  
  @HiveField(7)
  bool isActive;
  
  @HiveField(8)
  DateTime createdAt;
}
```

## Extended Folder Structure
lib/
├── core/
│ ├── constants/
│ │ ├── app_constants.dart
│ │ ├── color_constants.dart
│ │ ├── route_constants.dart
│ │ └── text_constants.dart
│ ├── themes/
│ │ ├── app_theme.dart
│ │ ├── dark_theme.dart
│ │ └── light_theme.dart
│ ├── utils/
│ │ ├── date_utils.dart
│ │ ├── currency_utils.dart
│ │ ├── number_utils.dart
│ │ └── validation_utils.dart
│ └── extensions/
│ ├── date_extensions.dart
│ ├── string_extensions.dart
│ └── number_extensions.dart
├── data/
│ ├── models/
│ │ ├── user_profile.dart
│ │ ├── account.dart
│ │ ├── category.dart
│ │ ├── transaction.dart
│ │ ├── budget.dart
│ │ └── enums/
│ │ ├── account_type.dart
│ │ ├── category_type.dart
│ │ └── transaction_type.dart
│ ├── repositories/
│ │ ├── user_repository.dart
│ │ ├── account_repository.dart
│ │ ├── category_repository.dart
│ │ ├── transaction_repository.dart
│ │ └── budget_repository.dart
│ └── services/
│ ├── hive_service.dart
│ ├── backup_service.dart
│ ├── notification_service.dart
│ └── pdf_service.dart
├── presentation/
│ ├── screens/
│ │ ├── onboarding/
│ │ ├── user_setup/
│ │ ├── dashboard/
│ │ ├── accounts/
│ │ ├── categories/
│ │ ├── transactions/
│ │ ├── reports/
│ │ └── settings/
│ ├── widgets/
│ │ ├── common/
│ │ │ ├── custom_button.dart
│ │ │ ├── custom_text_field.dart
│ │ │ └── loading_indicator.dart
│ │ ├── charts/
│ │ ├── cards/
│ │ └── dialogs/
│ └── providers/
│ ├── user_provider.dart
│ ├── theme_provider.dart
│ └── locale_provider.dart
├── config/
│ ├── routes.dart
│ ├── themes.dart
│ └── localization.dart
├── generated/
│ └── l10n/
└── main.dart

### Database Relationships

1. **One-to-Many**:
   - User → Accounts
   - User → Categories
   - Account → Transactions
   - Category → Transactions
   - User → Budgets

2. **Many-to-Many**:
   - Categories ↔ Budgets
   - Transactions ↔ Tags

### Data Storage Strategy

1. **Hive Boxes**:
   ```dart
   @HiveType(typeId: 5)
   class HiveBoxes {
     static const String userProfile = 'userProfile';
     static const String accounts = 'accounts';
     static const String categories = 'categories';
     static const String transactions = 'transactions';
     static const String budgets = 'budgets';
     static const String settings = 'settings';
   }
   ```

2. **Indexing**:
   - Transactions: date, accountId, categoryId
   - Categories: type
   - Accounts: type
   - Budgets: period

3. **Backup Strategy**:
   - JSON export/import
   - Automatic backups (optional)
   - Version control for schema updates

## Build Steps

### Phase 1: Project Setup and Core Infrastructure
1. **Project Creation and Dependencies**
   - Create Flutter project
   - Add essential dependencies in `pubspec.yaml`
   - Configure basic project structure

2. **Database Setup**
   - Initialize Hive
   - Create data models
   - Set up repositories
   - Implement basic CRUD operations

3. **Core Services**
   - Theme service
   - Localization service
   - Navigation service
   - Storage service

### Phase 2: User Onboarding and Setup
1. **Onboarding Screens**
   - Welcome screen
   - Feature highlight slides
   - Final call-to-action

2. **User Setup Flow**
   - Name input
   - Currency selection
   - Initial account setup
   - Basic categories setup

### Phase 3: Main Features Implementation
1. **Dashboard**
   - Top bar implementation
   - Financial overview cards
   - Quick access buttons
   - Navigation setup

2. **Accounts Management**
   - Account list view
   - Account creation/editing
   - Transaction history
   - Balance tracking

3. **Categories**
   - Category management
   - Spending visualization
   - Category-wise analytics

4. **Transactions**
   - Transaction entry form
   - Transaction list
   - Filtering and search
   - Recurring transactions

### Phase 4: Advanced Features
1. **Reports and Analytics**
   - Custom date range reports
   - Category-wise analysis
   - Income vs Expense trends
   - PDF export

2. **Budgeting**
   - Budget creation
   - Progress tracking
   - Alerts and notifications
   - Budget vs Actual analysis

### Phase 5: Settings and Customization
1. **App Settings**
   - Theme customization
   - Language selection
   - Currency formatting
   - Notification preferences

2. **Data Management**
   - Backup/Restore
   - Data export
   - Cache management
   - App reset

### Phase 6: Testing and Polish
1. **Testing**
   - Unit tests
   - Widget tests
   - Integration tests
   - Performance testing

2. **Final Polish**
   - UI/UX improvements
   - Performance optimization
   - Error handling
   - Documentation

### Development Timeline
- Phase 1: 1 week
- Phase 2: 1 week
- Phase 3: 2 weeks
- Phase 4: 1 week
- Phase 5: 1 week
- Phase 6: 1 week

Total estimated time: 7 weeks

### Getting Started
To begin development:
1. Clone the repository
2. Run `flutter pub get`
3. Configure your IDE (VS Code or Android Studio)
4. Start with Phase 1 tasks
