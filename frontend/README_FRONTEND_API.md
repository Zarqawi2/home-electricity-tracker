# Frontend API Setup

This Flutter app talks to the Laravel backend in `backend/`.

## Configure API base URL
1) Copy `.env.example` to `.env`:
```
cp .env.example .env
```
2) Set `API_BASE_URL`:
- Default/local: `http://localhost:8000`
- Android emulator: change to `http://10.0.2.2:8000`
- Physical device on same LAN: `http://<your-machine-ip>:8000`

## Run
```
flutter pub get
flutter run
```
Ensure the backend is running (e.g. `php artisan serve --port=8000`).

## Endpoints the app calls
- `GET /api/dashboard?date=YYYY-MM-DD&mode=daily|monthly`
- `GET /api/appliances`
- `POST /api/appliances`
- `PUT /api/appliances/{id}`
- `DELETE /api/appliances/{id}`
- `PATCH /api/appliances/{id}/toggle`

## Common issues
- **CORS**: Backend CORS must allow your device host (backend config already set to `*`).
- **Wrong host**: For Android emulator use `10.0.2.2`, not `localhost`.
- **No internet**: The app shows "No internet connection" when offline and keeps the last loaded data.
