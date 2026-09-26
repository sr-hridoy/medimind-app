````markdown
# MediMind 💊

MediMind is a mobile application designed to enhance medication adherence and health management by providing a reliable, inclusive, and user-friendly digital platform tailored for patients and caregivers.

Built to support elderly and chronically ill individuals, MediMind helps bridge the gap between individual treatment and collaborative family support.

---

## 🚀 Features

- **Dual-Mode Interface:** Specialized dashboards for both Patients and Monitors (caregivers), allowing users to access features based on their role.

- **Precise Scheduling & Tracking:** Patients can add medications, configure dosages, and set specific times for daily or weekly reminders.

- **Offline Alerts:** Medication reminders can be triggered directly on the device, helping users receive alerts even without an active internet connection.

- **Caregiver Synchronization:** Up to five family members or caregivers can be linked to a patient to monitor daily medication adherence and check whether doses were taken or missed.

- **Secure Cloud Data:** Firebase is used for user authentication and cloud-based data storage and synchronization.

---

## 🛠️ Tech Stack

- **Frontend:** Flutter, Dart
- **Backend & Database:** Firebase Authentication, Firebase Realtime Database / Cloud Firestore
- **Architecture:** Object-Oriented System Architecture
- **Target Platform:** Android

---

## 📸 Mobile UI Screenshots

Add your Android emulator/device screenshots to the `assets/screenshots/` folder.

```text
assets/
└── screenshots/
    ├── login.png
    ├── patient_dashboard.png
    └── monitor_dashboard.png
````

<div align="center">
  <img src="assets/screenshots/login.png" width="200" alt="Login Screen"/>
  <img src="assets/screenshots/patient_dashboard.png" width="200" alt="Patient Dashboard"/>
  <img src="assets/screenshots/monitor_dashboard.png" width="200" alt="Monitor Dashboard"/>
</div>

---

## 💻 Getting Started

### Prerequisites

Before running MediMind, make sure you have:

* Flutter SDK (latest stable version)
* Dart SDK
* Android Studio or Visual Studio Code
* An Android device or emulator
* A Firebase account and configured Firebase project

### Installation

#### 1. Clone the repository

```bash
git clone https://github.com/sr-hridoy/medimind_app.git
```

#### 2. Navigate to the project directory

```bash
cd medimind_app
```

#### 3. Install dependencies

```bash
flutter pub get
```

#### 4. Firebase Configuration

1. Create or open the MediMind project in the Firebase Console.
2. Download the `google-services.json` file.
3. Place the file inside:

```text
android/app/google-services.json
```

> **Note:** Do not upload sensitive Firebase configuration files or private credentials if your project configuration contains information that should remain private.

#### 5. Run the application

Connect an Android device or start an Android emulator, then run:

```bash
flutter run
```

---

## 📁 Documentation & Artifacts

### 📄 Project Report

The complete project report contains detailed documentation about the system, including:

* System Architecture
* Use Case Diagrams
* Data Flow Diagrams (DFD)
* Entity Relationship Diagrams (ERD)
* System Design
* Project Implementation
* Testing and Results

The project report is available here:

[**📄 View Project Report**](./Project_Report.pdf)

> Make sure `Project_Report.pdf` is uploaded to the root directory of this repository.

### 📱 App Download

If a compiled APK is available, you can download it from the repository's Releases section:

[**📥 Download APK from Releases**](../../releases)

---

## 👥 Contributors

This project was developed as a 3rd-year academic project for the Department of Computer Science and Engineering at Leading University.

### Team Members

* **Ispak Jahan Ispa**
* **M. M. Asif Bin A. Rahman**
* **Md. Shaifur Rahman Hridoy**

### Project Supervisor

**Md. Jamaner Rahaman**

Assistant Professor

Department of Computer Science and Engineering

Leading University

---

## 🎓 Academic Project

**Department:** Computer Science and Engineering

**University:** Leading University

**Project Type:** Academic Mobile Application

**Platform:** Android

---

## 📄 License

This project is licensed under the MIT License.

See the [LICENSE](./LICENSE) file for more information.

---

## 📌 Project Structure

```text
medimind_app/
│
├── android/
├── assets/
│   └── screenshots/
│       ├── login.png
│       ├── patient_dashboard.png
│       └── monitor_dashboard.png
│
├── lib/
│   ├── ...
│
├── Project_Report.pdf
├── pubspec.yaml
├── README.md
└── LICENSE
```

---

## 🔐 Security Note

Firebase is used to provide authentication and cloud-based data management.

For security reasons, avoid committing private credentials, API keys with restricted access, or other sensitive configuration files to a public repository.

---

## ❤️ About MediMind

MediMind was developed with the goal of making medication management easier for patients while giving caregivers a simple way to stay informed about medication schedules and adherence.

The application focuses on combining **medication reminders, patient management, caregiver monitoring, and cloud synchronization** into a single mobile platform.

```
```
