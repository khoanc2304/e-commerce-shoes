# 👟 Shoes X - Flutter E-Commerce App

Shoes X is a mobile e-commerce application specializing in sneaker retail, built using **Flutter**. Designed and developed by a 4-member team, the project focuses on delivering an optimized user experience (smooth UI/UX) while adhering to a clean, highly scalable codebase.

---

## 🚀 Tech Stack & Tools

* **Frontend Mobile:** Flutter (**Dart** language) - Multi-platform support (Android & iOS).
* **Backend-as-a-Service (BaaS):** **Firebase** (Google's cloud ecosystem).
    * *Firebase Authentication:* Secure user login and account management.
    * *Cloud Firestore:* Real-time NoSQL database for products, carts, and order data.
    * *Firebase Storage:* High-quality product image hosting.
* **State Management:** BLoC/Cubit (or Riverpod/Provider - *Replace with your team's choice*).
* **IDE & Tools:** Android Studio, Git/GitHub, Figma (UI/UX Design).

---
How to run the project using this configuration file:
To pass the keys securely from .env.json when building or running your Flutter project, run the command with the --dart-define-from-file parameter:
flutter run --dart-define-from-file=.env.json
# or for web specifically:
flutter run -d chrome --dart-define-from-file=.env.json


## 🏗