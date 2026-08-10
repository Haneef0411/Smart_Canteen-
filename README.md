# Smart Canteen

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Authentication%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Platforms](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)

Smart Canteen is a cross-platform Flutter application that lets students order meals before arriving at the canteen. Customers can explore the live menu, customize quantities, select a pickup time, and follow order progress. Staff receive a dedicated workspace for managing orders, menu items, prices, and availability.

> **Order ahead. Skip the queue.**

## Features

### For students

- Email and password registration, login, and password reset
- Searchable menu with Meals, Snacks, Drinks, and Desserts categories
- Live prices and availability from Cloud Firestore
- Food images, descriptions, and preparation estimates
- Separate fresh-juice varieties and adjustable item quantities
- Persistent cart storage between app sessions
- Pickup-time selection, order notes, and order summaries
- Sequential order numbers such as `SC0001`
- Active and previous order tracking
- Editable user profile

### For canteen staff

- Staff access controlled through a registration code
- Live incoming-order dashboard
- Order status workflow and cancellation support
- Add, edit, and remove menu items
- Update prices and item availability in real time

## Built with

| Technology | Purpose |
| --- | --- |
| Flutter and Dart | Cross-platform UI and application logic |
| Firebase Authentication | User registration, login, and password recovery |
| Cloud Firestore | Menu, profiles, categories, counters, and order data |
| Firebase Storage | Staff-managed menu image uploads |
| Shared Preferences | Local cart persistence |

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with Dart 3.12 or newer
- A Firebase project
- Chrome for web development, Android Studio for Android, or Xcode for iOS

Confirm your environment:

```bash
flutter doctor
```

### Installation

```bash
git clone https://github.com/Haneef0411/Smart_Canteen-.git
cd Smart_Canteen-
flutter pub get
```

### Firebase configuration

This repository contains configuration for the original Firebase project. To use your own backend:

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Enable **Email/Password** under Authentication → Sign-in method.
3. Create a **Cloud Firestore** database.
4. Install and sign in to the FlutterFire CLI.
5. Generate platform configuration from the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Public registration always creates a student account. Create trusted staff/admin accounts normally, then assign `role: "staff"` or `role: "admin"` in their `users/{uid}` document from the Firebase console. Never expose privileged role assignment in public registration.

Deploy the included security rules after reviewing the Firebase project ID:

```bash
firebase deploy --only firestore:rules,storage
```

### Run the app

Web:

```bash
flutter run -d chrome
```

Local web server on a fixed port:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Android or iOS:

```bash
flutter devices
flutter run -d <device-id>
```

## Testing and code quality

```bash
flutter analyze
flutter test
```

The test suite covers cart quantities, totals, sold-out items, persistent storage, menu synchronization, juice varieties, and the splash-screen experience.

## Project structure

```text
lib/
├── main.dart                 # Firebase initialization and app entry point
├── firebase_options.dart     # Generated FlutterFire configuration
├── models/                   # Menu, user, availability, and order models
├── screens/                  # Authentication, menu, cart, orders, and staff UI
├── services/                 # Authentication and Firestore operations
├── state/                    # Persistent cart state
├── theme/                    # Application theme
└── widgets/                  # Shared UI components

assets/images/menu/           # Menu item artwork
test/                         # Unit and widget tests
```

## Firestore data model

| Path | Description |
| --- | --- |
| `users/{uid}` | Profile and role for each account |
| `menu/{itemId}` | Menu details, price, preparation time, and availability |
| `orders/{orderId}` | Customer order, pickup details, totals, and status |
| `counters/orders` | Transactional sequence used for order numbers |
| `categories/{categoryId}` | Active menu categories |

## Production checklist

- Add strict Firestore Security Rules for student and staff roles.
- Restrict Firebase API keys to the intended apps, domains, and APIs.
- Add authorized production domains in Firebase Authentication.
- Configure Firebase App Check.
- Test authentication, ordering, and status updates on every target platform.
- Use a trusted server or Cloud Function for sensitive authorization and payment processing.

## Contributing

1. Fork the repository.
2. Create a branch: `git checkout -b feature/your-feature`.
3. Commit your changes: `git commit -m "Add your feature"`.
4. Push the branch: `git push origin feature/your-feature`.
5. Open a pull request.

## Author

Created by [Haneef0411](https://github.com/Haneef0411).

If this project helps you, consider giving the repository a star.
