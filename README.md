# Madhwa Panchanga Calendar

A high-performance, offline-first Flutter application designed to provide accurate daily Panchanga details specifically curated for the Madhwa community.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## 🌟 Features

* **Daily Panchanga Details:** View Samvastara, Ayana, Rutu, Masa, Paksha, Tithi, Nakshatra, Yoga, and Karana.
* **Multi-Language Support:** Fully localized UI and data in **Kannada**, **Sanskrit**, and **English**.
* **Offline First:** Built-in Firestore persistence ensures that once data is viewed, it remains accessible without an internet connection.
* **Daily Morning Alerts:** Automatic notifications at 6:00 AM providing a complete descriptive summary of the day's Panchanga.
* **Smart Monthly View:** Interactive calendar that automatically greys out and disables dates outside the valid data range.
* **Dark Mode Support:** Seamless switching between light and dark themes.

## 🚀 Tech Stack

* **Framework:** Flutter (Dart)
* **Backend:** Google Cloud Firestore
* **State Management:** Provider
* **Local Notifications:** flutter_local_notifications
* **Timezone Handling:** timezone (IANA database)
* **Fonts:** Google Fonts (Noto Sans Kannada)

## 🛠️ Setup & Installation

### Prerequisites
* Flutter SDK installed.
* A Firebase project created in the [Firebase Console](https://console.firebase.google.com/).

### Steps

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/YOUR_USERNAME/madhwa-panchanga-calendar.git](https://github.com/YOUR_USERNAME/madhwa-panchanga-calendar.git)
    cd madhwa-panchanga-calendar
    ```

2.  **Add Firebase Configuration:**
    * Download your `google-services.json` from Firebase and place it in the `android/app/` directory.

3.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Bulk Upload Data:**
    Use the provided `upload_panchanga.py` script to populate your Firestore collection from a CSV:
    ```bash
    pip install firebase-admin pandas
    python upload_panchanga.py
    ```

5.  **Build and Run:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

* `lib/main.dart`: The core file containing state logic, translation dictionaries, and UI components.
* `upload_panchanga.py`: Python script for database population.
* `android/app/build.gradle.kts`: Configured for release-ready APK generation and Proguard rules.

## 📦 Build Release APK
To generate a compact, optimized APK:
```bash
flutter build apk --release --split-per-abi
```

### Created by @techiemonk
