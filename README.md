# Pocket Planner

A high-performance personal finance and budget planning Android application built with Flutter. Designed for seamless expenditure logging, Pocket Planner empowers users to track transaction histories, set localized monthly targets, visualize category analytics, and scan physical receipts instantly using on-device machine learning.

The application is fully optimized for Android platforms and published on the Google Play Store.
---

### Application Preview
<table>
  <tr>
    <td width="25%"><img src="https://github.com/user-attachments/assets/b6bf9cc6-2003-482c-b4d5-a59ad5802166" alt="View 1" width="100%"/></td>
    <td width="25%"><img src="https://github.com/user-attachments/assets/322fb1a6-46cc-47ab-b42b-952b47a8c526" alt="View 2" width="100%"/></td>
    <td width="25%"><img src="https://github.com/user-attachments/assets/12fb8876-a96b-4143-8a17-eb92754ac43a" alt="View 3" width="100%"/></td>
    <td width="25%"><img src="https://github.com/user-attachments/assets/69cfbe63-f271-4014-a99e-2932f7f4fe2c" alt="View 4" width="100%"/></td>
  </tr>
</table>

---

## Key Features
- **On-Device Receipt Scanning (OCR):** Uses Google ML Kit Text Recognition to scan and automatically extract transaction dates and pricing totals from physical receipts.
- **Smart Filtering System:** Real-time, instant search capabilities parsing across transaction names, categories, amounts, payment methods, and fully formatted calendar dates.
- **Dynamic Data Visualization:** Implements smooth visual summaries to easily review total expenditures, payment options (Cash, Online, Card), and categorical breakdowns.
- **Budget Configuration:** Organize expenses into clean structural categories, configure custom monthly expenditure limits, and review relative remaining balance.
- **Localized Settings:** Offers on-the-fly local currency conversion configurations ($, €, £, ৳, ₹, ¥) and system-wide Dark/Light Mode adaptive theme states.

## Tech Stack & Architecture

The application is structured following clean coding architectures separating UI views, reusable components, and reactive background services.

### Core Architecture
- **Language:** Dart
- **Framework:** Flutter (SDK: ^3.9.0)
- **Target Platform:** Android (Min SDK: 21)
- **Local Storage System:** Uses key-value caching models via `shared_preferences` to persist local transaction indices, historical themes, and selected currency states.
- **State Management:** Reactive component state design utilizing `StatefulBuilder` and customized model triggers to refresh local viewports instantly.

### Package Integrations
- **OCR Engine (`google_mlkit_text_recognition`):** Handles text parsing structures directly on-device without needing external cloud APIs.
- **Camera Bridge (`image_picker`):** Bridges Android native camera hardware interfaces to snap and select receipt images directly.
- **Analytical Charting (`fl_chart`):** Renders highly customizable categorical pie charts and transactional progress indicators.
- **Feature Walkthroughs (`showcaseview`):** Integrates visual highlighting flows to introduce new elements cleanly to first-time users.
- **Asset Rendering (`flutter_svg`):** Lightweight processing of custom UI design elements.

## Installation & Environment Setup

### Prerequisites
- Flutter SDK installed.
- Android SDK (for Android compilation).

### Step-by-Step Installation
1. Clone the repository:
   ```bash
   git clone [https://github.com/topmasum/Monthly-expense-tracker-app.git](https://github.com/topmasum/Monthly-expense-tracker-app.git)
   cd Monthly-expense-tracker-app
   cd Monthly-expense-tracker-app
