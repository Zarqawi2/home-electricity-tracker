# Home Electricity Consumption Tracker

A local-first Flutter app with an optional Laravel backend for tracking household electricity usage, estimating costs with progressive IQD tariffs, and managing appliances.

![Flutter](https://img.shields.io/badge/Flutter-UI-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-API-FF2D20?logo=laravel&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-Backend-777BB4?logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?logo=mysql&logoColor=white)

## Highlights

- Responsive light UI with Overview, Appliances, Records, and Tools navigation
- Daily and monthly consumption metrics with cost estimates
- Appliance management (add, edit, delete, toggle)
- Line chart trends and appliance breakdown pie chart
- Energy and electrical calculators, saved meter readings, and outage records
- Connectivity-aware actions with status feedback
- Daily local reminder notifications
- Outage-aware billing (set outage minutes and auto-adjust cost/kWh)
- RTL-first UI with Kurdish (ckb) and English support
- Local-only mode available for Android publishing without hosting/domain

## Screenshots

Captured from the current Flutter web app using illustrative sample data at desktop (1440 × 1000) and mobile (390 × 844) viewport sizes.

<table>
  <tr>
    <td align="center">
      <img src="screenshots/dashboard-overview.png" width="460" alt="Desktop overview with household consumption and cost estimates" />
      <br/>Overview — consumption and cost estimates
    </td>
    <td align="center">
      <img src="screenshots/appliances-grid.png" width="460" alt="Desktop appliance management with usage settings" />
      <br/>Appliances — household devices and usage
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="screenshots/records.png" width="460" alt="Desktop records section with meter readings and outage history access" />
      <br/>Records — meter readings and outage history
    </td>
    <td align="center">
      <img src="screenshots/tools.png" width="460" alt="Desktop tools section with calculators, monthly budget, and outage tracking" />
      <br/>Tools — calculators, budget, and outage tracking
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="screenshots/energy-calculator.png" width="460" alt="Desktop energy calculator for electricity usage and cost estimates" />
      <br/>Energy and cost calculator
    </td>
    <td align="center">
      <img src="screenshots/add-appliance-dialog.png" width="460" alt="Desktop dialog for adding an appliance and its usage details" />
      <br/>Add an appliance
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="screenshots/mobile-dashboard.png" width="240" alt="Flutter web overview at a mobile viewport size" />
      <br/>Mobile web overview
    </td>
    <td align="center">
      <img src="screenshots/mobile-appliances.png" width="240" alt="Flutter web appliance management at a mobile viewport size" />
      <br/>Mobile web appliances
    </td>
  </tr>
</table>

## Tech Stack
**Frontend**
- Flutter, Dart
- Riverpod (state), GoRouter (navigation)
- SQLite (sqflite local persistence), fl_chart (charts)

**Backend**
- Laravel 12 REST API
- MySQL

## Project Structure
- `backend/` Laravel API
- `frontend/` Flutter app
- `screenshots/` README assets

## Getting Started

### Backend (Laravel)
1) Copy `.env.example` to `.env` and set MySQL credentials:
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=home_electricity
DB_USERNAME=your_user
DB_PASSWORD=your_pass
```
2) Install dependencies:
```
composer install
```
3) Generate app key (if not set):
```
php artisan key:generate
```
4) Migrate & seed (tariff tiers, default appliances, 30 days usage logs):
```
php artisan migrate:fresh --seed
```
5) Run the API:
```
php artisan serve --port=8000
```

### Frontend (Flutter)
1) Install packages:
```
cd frontend
flutter pub get
```
2) Run the app:
```
flutter run
```

This app can run fully local on device (no API host/domain required). Backend setup is optional.

## Tariff Logic (IQD per kWh)
- 1-400: 72
- 401-800: 108
- 801-1200: 175
- 1201-1600: 265
- 1601+: 350

## API Reference
See `backend/README.md` for full endpoint details and sample requests.
