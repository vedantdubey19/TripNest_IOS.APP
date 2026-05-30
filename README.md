# 🏡 TripNest

A modern, high-fidelity iOS travel booking and accommodation application built natively with **SwiftUI** and **MapKit**. TripNest provides users with a seamless experience to discover unique stays, locate accommodations on an interactive map, read & write reviews, and host their own properties.

---

## ✨ Features

- **🔐 Premium Authentication Flow**
  - Sleek and secure **Login** and **Registration** screens.
  - Secure session storage utilizing iOS **Keychain Services** via `KeychainManager` for persistent JWT tokens.
  
- **🔍 Browse & Filter Stays**
  - A beautiful explore feed with smooth animations.
  - Instant text-based searching (by city, country, or title).
  - Horizontal category selector with dynamic gradient states for refined filtering.
  - Pull-to-refresh integration for real-time listing updates.

- **🗺️ Interactive Map Exploration**
  - Live map displaying listed properties with custom annotations.
  - Quick geolocation context allowing users to visually find stays.

- **🏡 Detailed Listing Spotlights**
  - Engaging detail screens featuring **animated image carousels**.
  - Detailed host information, pricing breakdown, and descriptive write-ups.

- **✍️ Community Reviews**
  - Review feed showing feedback, user ratings, and comments.
  - Seamless interface to add or delete listing reviews.

- **➕ Host Listing Creator**
  - Interactive property creation form.
  - Inputs for title, description, price, location, country, and image uploads (integrated with Cloudinary via the backend).

---

## 🛠️ Architecture & Tech Stack

The application is modularized and follows clean code practices:

* **Frameworks**: SwiftUI, MapKit
* **Deployment Target**: iOS 17.0+ / macOS 14.0+
* **Design Pattern**: Model-View-ViewModel (MVVM) for clear separation of concerns.
* **Networking**: Native asynchronous networking (`async/await`) using a custom `APIClient` and type-safe `APIEndpoint` enum.
* **Data Flow**: Environment-driven state sharing using `@StateObject` and `@EnvironmentObject`.
* **Dependency & Project Management**: Swift Package Manager (SPM) with targets split into:
  - `TripNestLib`: Modular library containing components, core layers, models, repositories, and view models.
  - `TripNest`: Executable application wrapper setup for swift compilation.

---

## 📁 Directory Structure

```text
TripNest/
├── App/                       # App entry point & main ContentView container
├── Core/                      # Shared framework logic
│   ├── Network/               # APIClient, Endpoint router, and NetworkError configurations
│   ├── Storage/               # Keychain wrapper for secure credentials
│   └── ViewExtensions.swift   # Common design layout helpers
├── Models/                    # Decodable models (User, Listing, Review, AuthResponse)
├── Repositories/              # Network layer abstracts fetching data (Listing, Auth, Review)
├── ViewModels/                # State management and presentation logic
├── Views/                     # UI Layouts grouped by functional flows
│   ├── Auth/                  # Login and Sign-up interfaces
│   ├── Create/                # Listing creation sheets
│   ├── Detail/                # Spotlight, Reviews, and Carousels
│   ├── Home/                  # Home feed scroll view and listings cards
│   ├── Map/                   # MapKit geolocations
│   └── Profile/               # Host profiles and listings management
├── Package.swift              # Swift Package Manager manifest
└── generate_xcodeproj.py      # Script to generate a native Xcode project
```

---

## 🚀 Getting Started

### Prerequisites
* **macOS** with **Xcode 15.0+** installed.
* **Python 3** (used to run the Xcode project generator).
* A running **TripNest Backend API** (Node.js REST API).

### 1. Set Up the Backend Connection
By default, the client directs traffic to `http://localhost:3000/api`. To point the app to another host or production endpoint, open and modify `baseURLString` in:
👉 [`Core/Network/APIEndpoint.swift`](file:///Users/vedantdubey_20/TripNest/Core/Network/APIEndpoint.swift)

```swift
static var baseURLString: String = "http://YOUR_SERVER_IP:3000/api"
```

### 2. Generate Xcode Project
The codebase uses a Python script to scan directories and automatically build a standard, deterministic Xcode project structure. Run the following command in the root directory:

```bash
python3 generate_xcodeproj.py
```

This generates `TripNest.xcodeproj` in the workspace root.

### 3. Build & Run
1. Open the generated `TripNest.xcodeproj` in Xcode.
2. Select your target (e.g. `TripNest` executable) and destination (an iOS Simulator or connected device running iOS 17+).
3. Press `⌘ + R` (or click the Run button) to build and launch the application!
