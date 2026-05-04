# SourceHub Admin

Flutter Web Admin Panel for SourceHub e-commerce platform.

## Project Structure

```
SourceHubAdmin/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── core/
│   │   ├── theme.dart                # App theming (colors, typography)
│   │   ├── router.dart              # Navigation/routing
│   │   └── firebase_options.dart    # Firebase config
│   ├── models/                      # Data models
│   │   ├── order.dart              # Order & OrderItem
│   │   ├── product.dart            # Product & ProductItem
│   │   ├── category.dart           # Category
│   │   └── discount.dart           # Discount
│   ├── features/
│   │   ├── auth/
│   │   │   └── login_screen.dart   # Admin login
│   │   ├── dashboard/
│   │   │   ├── admin_shell.dart     # Main layout scaffold
│   │   │   └── dashboard_view.dart # Dashboard overview
│   │   ├── orders/
│   │   │   ├── orders_view.dart    # Orders list
│   │   │   └── widgets/
│   │   │       └── order_details_dialog.dart
│   │   ├── products/
│   │   │   ├── products_view.dart   # Products management
│   │   │   └── widgets/
│   │   │       └── product_dialog.dart
│   │   ├── categories/
│   │   │   ├── categories_view.dart
│   │   │   └── widgets/
│   │   │       └── category_dialog.dart
│   │   ├── discounts/
│   │   │   ├── discounts_view.dart
│   │   │   └── widgets/
│   │   │       └── discount_dialog.dart
│   │   └── shared/
│   │       └── services/
│   │           ├── auth_service.dart     # Auth logic
│   │           ├── firestore_service.dart # Firestore CRUD
│   │           └── providers.dart      # Riverpod providers
│   └── test/
├── web/                             # Web assets
├── pubspec.yaml                     # Dependencies
└── README.md
```

## Architecture

- **State Management**: Riverpod
- **Backend**: Firebase Firestore
- **Pattern**: Feature-based with shared services
- **UI**: Material Design

## Project Tasks

| Phase | Task | Status |
|-------|------|--------|
| 1 | Project Initialization & Core Setup | ✅ |
| 2 | Data Models & Services | ✅ |
| 3 | UI Features | ✅ |
| 4 | Test Firebase connectivity | ⏳ |
| 4 | Verify Admin role check | ⏳ |
| 4 | Final UI/UX polish | ⏳ |