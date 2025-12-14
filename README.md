# LocalPass 🎟️

LocalPass is a mobile event ticketing application built with **Flutter** and **Firebase**. It allows users to discover local events, purchase digital passes using an in-app wallet, and securely check in at venues using geolocation.

## 📺 Project Demo

A complete walkthrough of the app features is available in the presentation file included in this repository:
* **[LocalPass.pptx](LocalPass.pptx)** – Contains video demos for each feature (Authentication, Wallet, Check-In, Admin Panel).

## 🚀 Key Features

* **User Authentication:** Secure Login and Sign-up via Firebase Auth.
* **Event Discovery:** Browse upcoming events with **Search** and **Category Filters**.
* **Smart Wallet System:** Users can add funds and purchase tickets.
    * *Purchase Logic:* Prevents duplicate purchases and blocks sales 1 hour before the event.
* **Geofenced Check-In:**
    * Validates user location (must be within 150m of venue).
    * Enforces time windows (check-in available 2 hours before event start).
* **Pass Management:**
    * **Upcoming:** Auto-expires passes if unused after the event.
    * **History:** View used and expired passes.
* **Admin Dashboard:** Hidden interface for authorized admins to publish new events directly from the app.

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase Firestore (NoSQL Database)
* **Auth:** Firebase Authentication
* **Location:** `geolocator` package for GPS validation

## ⚙️ Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/gbpatil151/localpass.git](https://github.com/gbpatil151/localpass.git)
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Firebase Setup:**
    * Add your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to the project.
4.  **Run the app:**
    ```bash
    flutter run
    ```

## 📝 Author

**Gaurav Patil**
Master's Student, Computer Science
California State University, Chico