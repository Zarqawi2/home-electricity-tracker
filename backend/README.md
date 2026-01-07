# Home Electricity Tracker Backend (Laravel)

Laravel 12 REST API (no auth) powering the Flutter frontend. Uses MySQL with progressive IQD tariffs.

## Setup
1) Copy `.env.example` to `.env` and set MySQL:
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=home_electricity
DB_USERNAME=your_user
DB_PASSWORD=your_pass
```

2) Install deps (already installed if using this repo):
```
composer install
```

3) Generate app key (if not set):
```
php artisan key:generate
```

4) Migrate & seed (creates tariff tiers, default appliances, 30 days usage logs):
```
php artisan migrate:fresh --seed
```

5) Run API:
```
php artisan serve --port=8000
```

CORS is open for `api/*` so Flutter can call directly.

## Tariff
Progressive monthly tariff (IQD/kWh):
- 1-400: 72
- 401-800: 108
- 801-1200: 175
- 1201-1600: 265
- 1601+: 350

Billing applies slabs sequentially; result rounded to integer IQD.

## Endpoints (prefix `/api`)
- `GET /api/appliances`
- `POST /api/appliances`
- `GET /api/appliances/{id}`
- `PUT /api/appliances/{id}`
- `DELETE /api/appliances/{id}`
- `PATCH /api/appliances/{id}/toggle`

- `GET /api/usage?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `POST /api/usage`
```json
{
  "date": "2025-12-01",
  "items": [
    {"appliance_id": "...", "kwh": 1.2},
    {"appliance_id": "...", "kwh": 0.3}
  ]
}
```
(Upserts by appliance+date.)

- `GET /api/dashboard?date=YYYY-MM-DD`
Returns:
```json
{
  "summary": {
    "daily_kwh": 13.0,
    "monthly_estimate_kwh": 390,
    "monthly_cost_iqd": 28080,
    "daily_change_pct": 8.2,
    "cost_change_pct": -3.5
  },
  "line_chart": {"mode":"daily","points":[{"x":"2025-11-28","y":13.0}, ...]},
  "pie_chart": [
    {"appliance_id":"...","name":"Air Conditioner","pct":92},
    {"appliance_id":"...","name":"Microwave","pct":4},
    {"appliance_id":"...","name":"LED TV","pct":4}
  ],
  "appliances": [
    {
      "id":"...",
      "name":"Air Conditioner",
      "category":"Climate Control",
      "power_watts":1500,
      "daily_use_hours":8,
      "is_on":true,
      "monthly_cost_iqd": 25920
    }
  ],
  "tips": [
    "Turn off appliances when not in use to reduce standby power consumption",
    "Use LED bulbs which consume 75% less energy than incandescent bulbs",
    "Set your thermostat 2-3 degrees lower in winter and higher in summer",
    "Use energy-efficient appliances with high Energy Star ratings",
    "Regular maintenance of AC units can improve efficiency by up to 15%"
  ]
}
```

## Sample curl
```sh
curl http://localhost:8000/api/dashboard
curl http://localhost:8000/api/appliances
curl -X POST http://localhost:8000/api/appliances \
  -H "Content-Type: application/json" \
  -d '{"name":"Fan","category":"Climate Control","power_watts":60,"daily_use_hours":6,"is_on":true}'
```
