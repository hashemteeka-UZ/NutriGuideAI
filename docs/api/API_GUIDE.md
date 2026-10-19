# NutriGuide API guide

For the Flutter app. The only contract is [`openapi.json`](openapi.json) in this folder (API `0.5.0`). If this guide and that file disagree, the file wins. Routes that are not implemented yet answer **501** `NOT_IMPLEMENTED`. That code is temporary and is not part of the lasting error list. Screen work can use the mock server below; the examples in the file are what it returns.

Base URL path prefix: `/api/v1`.

## 1. Generate the Dart client

Pin the wrapper and the generator:

```json
{
  "generator-cli": { "version": "7.26.0" }
}
```

Save that as `openapitools.json` in the directory you run the command from, then:

```bash
npx @openapitools/openapi-generator-cli@2.41.0 generate \
  -i docs/api/openapi.json \
  -g dart-dio \
  -o mobile/packages/nutriguide_api
```

`7.26.0` is the OpenAPI Generator release (2026-10-06). `@openapitools/openapi-generator-cli@2.41.0` is the Node wrapper that downloads it.

Each `operationId` is the method name (`get_day_view`, `create_consumption_log`, …). The generator groups methods by tag (`auth`, `account`, `profile`, `meals`, `plans`, …), so a call looks like the plans client’s `get_day_view`.

## 2. Mock server

From the repository root:

```bash
npx @stoplight/prism-cli@5 mock docs/api/openapi.json
```

Prism listens on port **4010**. It serves each operation’s example, so a screen can be built before the handler exists.

```bash
curl -H "Authorization: Bearer dev" http://127.0.0.1:4010/api/v1/days/2026-10-20
```

## 3. Auth

`GET /health`, `GET /reference`, and the four `/auth/*` routes are public. Everything else needs

```http
Authorization: Bearer <access_token>
```

1. `POST /auth/register` or `POST /auth/login` returns `access_token`, `refresh_token`, `token_type` (`bearer`), and `expires_in` (seconds). The access token lasts **15 minutes** (`expires_in` is 900). The refresh token lasts **30 days**.
2. Send the access token on later calls.
3. On **401** `UNAUTHORIZED`, call `POST /auth/refresh` with the refresh token and replace both tokens.
4. On **401** `TOKEN_REUSED`, the refresh token was already used. That revokes the whole family: log the user out. Do not keep retrying refresh.
5. `POST /auth/logout` sends the refresh token and returns **204**.
6. Each `/auth/*` route allows **10 requests per minute** from one client address. The next one is **429** `RATE_LIMITED` with `Retry-After`.

`GET /me` includes `has_profile`. False opens onboarding; true opens Home. `DELETE /me` deletes the account and its data (**204**).

## Onboarding flow

1. Call `GET /reference` with no token. It returns conditions, allergens, cuisines, and the closed lists. Names follow `Accept-Language` (Arabic when the header is missing).
2. Call `PUT /me/profile` with the choices and `current_weight_kg` on the first save. Read `screening` and `target` from that response. `screening.eligible: false` is a normal **200**: `target` is null, and a target that was already current is closed.
3. `GET /me` field `has_profile` decides the screen: false opens onboarding, true opens Home.

## 4. Language, time, and numbers

Send `Accept-Language: ar` (the default) or `en`. Response fields named `name`, and meal `steps`, use that language. Steps fall back to Arabic. Do not add the header as a generated parameter; send it on the Dio client.

| Value | Wire format |
|---|---|
| Date | `YYYY-MM-DD` |
| Instant | ISO-8601 with a timezone (`2026-10-20T08:15:00Z`) |
| Clock time | `HH:MM` |

Measured amounts are JSON numbers. The server will round them to 3 decimal places when the handlers exist. IDs are integers. `client_uuid` and `op_id` are UUIDs you generate on the device.

Query `from` and `to` are inclusive. Plans and the shopping list accept at most **31** days. Adherence and weights accept at most **92** days. A longer range is **422** `VALIDATION_ERROR`.

Lists that can grow take `limit` (default 20, maximum 50) and `offset` (default 0) and return `{ "items": [...], "total": N }`.

## 5. Offline and the planner

Write a new UUID into `client_uuid` (and `op_id` for sync) before the request leaves the phone. Retry the same body with the same id after a network failure. The same id and the same content come back **200** with `status: DUPLICATE`. The same id with different content is **409** `CLIENT_UUID_CONFLICT`.

`POST /sync/batch` sends 1 to 500 of those writes. `GET /sync/changes?since=` pulls what the server has stored since that instant.

`POST /plans/days` can answer **503** `PLANNER_BUSY` with a `Retry-After` header. Wait that long, then try the same day again. A week plan is seven `POST /plans/days` calls, one date at a time, so the UI can show progress. `GET /plans?from=&to=` reads the days that already have a plan.

Logging a plan item, swapping, and saving a meal preference also write learning events on the server. The app only posts `IMPRESSION`, `VIEW`, `SAVE`, `RATE`, `COOK`, and `SKIP` to `POST /interactions`. `RATE` must include `value` from 1 to 5.

## Offline catalog

`GET /catalog/snapshot` returns every active meal and a strong `ETag`. Store the body and the tag on the phone. On the next launch send that tag as `If-None-Match`. **304** with an empty body means the catalog has not changed: keep the local copy. **200** means replace the local copy and store the new tag. The response may be gzip-compressed. The snapshot's `dataset_version` is the catalog version; each meal's `dataset_version` is its own batch.

## 6. Errors

Every error body is `application/problem+json`:

```json
{
  "type": "about:blank",
  "title": "Validation error",
  "status": 422,
  "code": "VALIDATION_ERROR",
  "request_id": "...",
  "errors": [{ "loc": ["body", "password"], "msg": "...", "type": "..." }]
}
```

Branch on `code`, not on the title. `errors` is present for `VALIDATION_ERROR`. `reasons` is present for `NOT_ELIGIBLE` and `SWAP_REJECTED`. An ineligible user is not an error on `PUT /me/profile`: the body comes back with `screening.eligible: false` and the app shows the general mode.

Statuses already produced by the server, and the statuses later passes will use for the codes in the contract:

| Code | HTTP |
|---|---|
| UNAUTHORIZED | 401 |
| INVALID_CREDENTIALS | 401 |
| TOKEN_INVALID | 401 |
| TOKEN_REUSED | 401 |
| FORBIDDEN | 403 |
| NOT_FOUND | 404 |
| PROFILE_NOT_FOUND | 404 |
| MEAL_NOT_FOUND | 404 |
| FOOD_NOT_FOUND | 404 |
| LOG_NOT_FOUND | 404 |
| PLAN_ITEM_NOT_FOUND | 404 |
| METHOD_NOT_ALLOWED | 405 |
| EMAIL_TAKEN | 409 |
| NOT_ELIGIBLE | 409 |
| NO_TARGET | 409 |
| NO_WEIGHT | 409 |
| CONDITION_CONFLICT | 409 |
| PLAN_ITEM_ALREADY_LOGGED | 409 |
| CLIENT_UUID_CONFLICT | 409 |
| VALIDATION_ERROR | 422 |
| UNKNOWN_CODE | 422 |
| NO_FEASIBLE_PLAN | 422 |
| INCOMPLETE_NUTRITION | 422 |
| SWAP_REJECTED | 422 |
| CLOCK_SKEW | 422 |
| TARGET_VALIDATION | 422 |
| INVALID_TIMEZONE | 422 |
| RATE_LIMITED | 429 |
| INTERNAL_ERROR | 500 |
| NOT_IMPLEMENTED | 501 |
| DATABASE_UNAVAILABLE | 503 |
| PLANNER_BUSY | 503 |
| SERVICE_UNAVAILABLE | 503 |

`NOT_IMPLEMENTED` goes away as each route is filled in. Each operation’s description ends with `Error codes:` listing the codes it will return after that. Those lists do not include 501.

## 7. Screens

Paths are under `/api/v1`. This is the plan’s screen table, with food search replaced by ingredient search.

| Screen | Endpoints |
|---|---|
| Sign in and register | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout` |
| Where to open | `GET /me` (`has_profile`) |
| Onboarding | `GET /reference`, `GET /ingredients?q=`, `PUT /me/profile` |
| Screening and targets | `GET /me/targets` |
| Home (today) | `GET /days/{date}` |
| Meal detail | `GET /meals/{meal_id}`, `GET /plan-items/{plan_item_id}/alternatives`, `POST /plan-items/{plan_item_id}/swap` |
| Log food | `POST /consumption-logs`, `POST /consumption-logs/{log_id}/correction`, `DELETE /consumption-logs/{log_id}`, `GET /ingredients?q=`, `GET /meals?q=` |
| Week plan | `GET /plans?from=&to=`, `POST /plans/days` once per day |
| Progress | `GET /adherence?from=&to=`, `GET /weights?from=&to=` |
| Log weight | `PUT /weights/{measured_on}` |
| Water | `GET /water?date=`, `POST /water-logs`, `DELETE /water-logs/{log_id}` |
| Reminders | Nothing stored on the server. Read `reminders_default_off` on the water goal. |
| Profile | `GET /me/profile`, `PUT /me/profile`. Language and dark mode stay on the phone. |
| Meal preferences | `GET /me/meal-prefs`, `PUT /me/meal-prefs/{meal_id}`, `DELETE /me/meal-prefs/{meal_id}` |
| Shopping list | `GET /shopping-list?from=&to=` |
| Learning events | `POST /interactions` |
| Delete account | `DELETE /me` |
| Offline | `POST /sync/batch`, `GET /sync/changes?since=`, `GET /catalog/snapshot` |

`DIABETES_INSULIN` is in `GET /reference` with `is_supported: false`. Ask it only as the insulin question. The supported conditions are `DIABETES_T2`, `HYPERTENSION`, and `HEART_DISEASE`. There is no pregnancy, lactation, or kidney-disease field.
