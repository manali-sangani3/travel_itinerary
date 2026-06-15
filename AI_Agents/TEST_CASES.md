# Test Cases — Travel Itinerary App

---

## 1. Authentication & Profiles

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| AUTH-01 | POST `/auth/register` | `{ email, password }` | 201 · user created · JWT returned |
| AUTH-02 | POST `/auth/register` | Duplicate email | 409 Conflict |
| AUTH-03 | POST `/auth/login` | Valid credentials | 200 · accessToken + refreshToken |
| AUTH-04 | POST `/auth/login` | Wrong password | 401 · no user enumeration in message |
| AUTH-05 | POST `/auth/login` | Unknown email | 401 · same generic message as AUTH-04 |
| AUTH-06 | POST `/auth/refresh` | Valid refresh token | 200 · new accessToken |
| AUTH-07 | POST `/auth/refresh` | Expired refresh token | 401 Unauthorized |
| AUTH-08 | GET `/auth/profile` | Valid JWT | 200 · user object (no plaintext passport) |
| AUTH-09 | GET `/auth/profile` | No JWT | 401 Unauthorized |
| AUTH-10 | PUT `/auth/profile` | `{ passport_number }` | 200 · stored encrypted; GET does not return plaintext |
| AUTH-11 | PUT `/auth/profile` | `{ preferences }` | 200 · persists after logout + re-login |

---

## 2. Trip Management

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| TRIP-01 | POST `/trips` | `{ destination, start_date, end_date, purpose, companions }` | 201 · trip object |
| TRIP-02 | POST `/trips` | Missing `destination` | 400 Validation error |
| TRIP-03 | GET `/trips` | Valid JWT | 200 · array of user's trips only |
| TRIP-04 | GET `/trips/:id` | Owner JWT | 200 · full trip object |
| TRIP-05 | GET `/trips/:id` | Different user JWT | 403 Forbidden |
| TRIP-06 | PUT `/trips/:id` | `{ status: "active" }` | 200 · status updated |
| TRIP-07 | PUT `/trips/:id` | `{ status: "completed" }` | 200 · status updated |
| TRIP-08 | DELETE `/trips/:id` | Owner JWT | 200 · trip removed |
| TRIP-09 | DELETE `/trips/:id` | Verify cascade | GET itinerary/bookings/documents → 404 or empty |
| TRIP-10 | GET `/trips/:id` | After DELETE | 404 Not Found |

---

## 3. Itinerary Planner

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| ITIN-01 | POST `/trips/:id/itinerary` | `{ title, location, start_time, day_index }` | 201 · item created |
| ITIN-02 | POST `/trips/:id/itinerary` | Missing `title` | 400 Validation error |
| ITIN-03 | GET `/trips/:id/itinerary` | Valid JWT | 200 · all items for trip |
| ITIN-04 | PUT `/trips/:id/itinerary/:itemId` | `{ title: "Updated" }` | 200 · title updated |
| ITIN-05 | PUT `/trips/:id/itinerary/reorder` | `{ items: [{id, order_index}] }` | 200 · order persists on next GET |
| ITIN-06 | DELETE `/trips/:id/itinerary/:itemId` | Owner JWT | 200 · item removed |
| ITIN-07 | POST `/trips/:id/itinerary` | `start_time: "23:30"` (spans midnight) | 201 · stored as ISO datetime |
| ITIN-08 | GET `/trips/:id/itinerary` | Viewer role JWT | 200 · read-only access allowed |
| ITIN-09 | DELETE `/trips/:id/itinerary/:itemId` | Viewer role JWT | 403 Forbidden |

---

## 4. Bookings

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| BOOK-01 | POST `/trips/:id/bookings` | `{ type: "flight", reference, details }` | 201 · booking created |
| BOOK-02 | POST `/trips/:id/bookings` | `{ type: "hotel" }` | 201 · booking created |
| BOOK-03 | POST `/trips/:id/bookings` | `{ type: "car_rental" }` | 201 · booking created |
| BOOK-04 | POST `/trips/:id/bookings` | `{ type: "activity" }` | 201 · booking created |
| BOOK-05 | GET `/trips/:id/bookings` | Valid JWT | 200 · list of bookings |
| BOOK-06 | PUT `/trips/:id/bookings/:bookingId` | `{ reference: "NEW123" }` | 200 · updated |
| BOOK-07 | DELETE `/trips/:id/bookings/:bookingId` | Owner JWT | 200 · removed |
| BOOK-08 | POST `/trips/:id/bookings` | Duplicate flight number | 200 · warning flag in response |

---

## 5. Documents

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| DOC-01 | POST `/trips/:id/documents` | PDF file + `{ doc_type: "confirmation" }` | 201 · document record |
| DOC-02 | POST `/trips/:id/documents` | JPEG image | 201 · document record |
| DOC-03 | POST `/trips/:id/documents` | `.exe` file | 415 Unsupported Media Type |
| DOC-04 | POST `/trips/:id/documents` | File > 20 MB | 413 Payload Too Large |
| DOC-05 | GET `/trips/:id/documents` | Owner JWT | 200 · list including passport docs |
| DOC-06 | GET `/trips/:id/documents` | Viewer role JWT | 200 · passport doc_type excluded |
| DOC-07 | GET `/trips/:id/documents/:docId` | Non-member JWT | 403 Forbidden |
| DOC-08 | DELETE `/trips/:id/documents/:docId` | Owner JWT | 200 · removed |

---

## 6. Budget Tracking

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| BUD-01 | PUT `/trips/:id/budget` | `{ accommodation: 5000, food: 2000 }` | 200 · budgets saved |
| BUD-02 | GET `/trips/:id/budget/summary` | Valid JWT | 200 · planned vs actual per category |
| BUD-03 | POST `/trips/:id/budget/expenses` | `{ amount: 500, category: "food", currency: "INR" }` | 201 · expense logged |
| BUD-04 | POST `/trips/:id/budget/expenses` | `{ currency: "USD" }` | 201 · foreign currency accepted |
| BUD-05 | POST `/trips/:id/budget/expenses` | `{ currency: "XYZ" }` (unknown) | 201 · flagged as unknown in summary |
| BUD-06 | GET `/trips/:id/budget/summary` | After logging expenses | 200 · actual matches sum of expenses |
| BUD-07 | DELETE `/trips/:id/budget/expenses/:expId` | Owner JWT | 200 · expense removed; summary updated |

---

## 7. Collaboration

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| COLLAB-01 | POST `/trips/:id/collaborators` | `{ email, role: "viewer" }` | 201 · collaborator added |
| COLLAB-02 | POST `/trips/:id/collaborators` | `{ email, role: "editor" }` | 201 · collaborator added |
| COLLAB-03 | POST `/trips/:id/collaborators` | `{ email, role: "admin" }` | 201 · collaborator added |
| COLLAB-04 | PUT `/trips/:id/collaborators/:userId` | `{ role: "editor" }` | 200 · role updated |
| COLLAB-05 | DELETE `/trips/:id/collaborators/:userId` | Owner removes editor | 200 · access revoked immediately |
| COLLAB-06 | DELETE `/trips/:id/collaborators/:userId` | Owner removes self (no other admin) | 403 · blocked |
| COLLAB-07 | PUT `/trips/:id/itinerary/:itemId` | Viewer JWT | 403 Forbidden |
| COLLAB-08 | PUT `/trips/:id/itinerary/:itemId` | Editor JWT | 200 · update allowed |
| COLLAB-09 | PUT `/trips/:id/collaborators/:userId` | Editor tries to change role | 403 Forbidden |
| COLLAB-10 | GET `/trips/:id/expenses/splits` | Valid JWT | 200 · balances sum to zero |
| COLLAB-11 | POST `/trips/:id/tasks` | `{ title, assigned_to }` | 201 · task created |
| COLLAB-12 | PUT `/trips/:id/tasks/:taskId` | `{ status: "done" }` | 200 · updated |
| COLLAB-13 | POST `/itinerary/:itemId/comments` | `{ text }` | 201 · comment posted |
| COLLAB-14 | GET `/itinerary/:itemId/comments` | Valid JWT | 200 · comment list |

---

## 8. Travel Journal

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| JOUR-01 | POST `/trips/:id/journal` | `{ content, date }` | 201 · entry created |
| JOUR-02 | GET `/trips/:id/journal` | Valid JWT | 200 · list of entries |
| JOUR-03 | PUT `/trips/:id/journal/:entryId` | `{ content: "Updated" }` | 200 · content updated |
| JOUR-04 | POST `/trips/:id/journal/:entryId/photos` | JPEG image | 201 · photo attached |
| JOUR-05 | POST `/trips/:id/journal/:entryId/photos` | With GPS metadata | 201 · geo-tag stored |
| JOUR-06 | POST `/trips/:id/journal/:entryId/photos` | No GPS metadata | 201 · falls back to entry location |
| JOUR-07 | DELETE `/trips/:id/journal/:entryId` | Owner JWT | 200 · entry removed |

---

## 9. Security

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| SEC-01 | Any protected endpoint | No Authorization header | 401 Unauthorized |
| SEC-02 | Any protected endpoint | Malformed JWT | 401 Unauthorized |
| SEC-03 | Any protected endpoint | Expired JWT | 401 · client must refresh |
| SEC-04 | GET `/auth/profile` | Valid JWT | Passport number AES-encrypted; not visible in response |
| SEC-05 | Any endpoint | SQL injection in params | 400 or sanitised · no DB error exposed |
| SEC-06 | Any response | Check headers | `helmet` headers present (X-Content-Type-Options, etc.) |
| SEC-07 | Socket.IO `join_trip` | Trip room A token used for room B | Event not received in room B |

---

## 10. Performance

| ID | Endpoint | Input | Expected |
|---|---|---|---|
| PERF-01 | GET `/trips` | 50 trips in DB | Response < 300 ms |
| PERF-02 | GET `/trips/:id/itinerary` | 30 items | Response < 300 ms |
| PERF-03 | POST `/trips/:id/documents` | 9 MB PDF | Upload completes < 5 s on LTE simulation |
| PERF-04 | Flutter cold start | Mid-range Android emulator | Home screen visible < 2 s |
| PERF-05 | Drag-and-drop reorder | 10 items in list | No frame drops; 60 fps maintained |

---

## 11. V2 Enhancement Features

| ID | Feature / Endpoint | Input | Expected |
|---|---|---|---|
| PACK-01 | GET `/trips/:id/packing/templates` | Valid JWT | 200 · list of available templates (e.g. beach, business) |
| PACK-02 | POST `/trips/:id/packing/generate` | `{ templateId, durationDays }` | 201 · generated packing list populated with template items |
| PACK-03 | PUT `/trips/:id/packing/:itemId` | `{ checked: 1 }` | 200 · check/uncheck template checklist items |
| DOC-V2-01 | GET `/trips/:id/checklist/documents` | Valid JWT | 200 · pre-populated checklist of essential travel documents |
| DOC-V2-02 | PUT `/trips/:id/checklist/documents` | `{ itemId, isChecked }` | 200 · checked status updated |
| SHARE-01 | POST `/trips/:id/share` | `{ role: "view\|edit", expiresInDays }` | 201 · returns cryptographically random token URL |
| SHARE-02 | GET `/trips/:id/share` | Owner JWT | 200 · list of active share links and invited collaborators |
| SHARE-03 | DELETE `/trips/:id/share/:shareId` | Owner JWT | 200 · share link revoked immediately |
| SHARE-04 | GET `/shares/:token` | Guest user (anonymous) | 200 · retrieves public read-only itinerary |
| NOTE-01 | POST `/trips/:id/notes` | `{ content, locationTag, dayDate }` | 201 · note created successfully |
| NOTE-02 | GET `/trips/:id/notes` | Valid JWT | 200 · chronological list of notes |
| NOTE-03 | PUT `/trips/:id/notes/:noteId` | `{ content }` | 200 · note content updated |
| NOTE-04 | DELETE `/trips/:id/notes/:noteId` | Valid JWT | 204 · note deleted |
| PHOTO-01 | POST `/trips/:id/photos` | Multipart: image file + locationTag | 201 · photo uploaded and saved |
| PHOTO-02 | GET `/trips/:id/photos` | Group by location/date | 200 · photos grouped and organized for gallery view |
| PHOTO-03 | DELETE `/trips/:id/photos/:photoId` | Valid JWT | 204 · photo deleted |
| WEATH-01 | GET `/weather/:destination/:date` | Valid JWT | 200 · forecast (temp, condition, precipitation) |
| CURR-01 | GET `/currency/convert` | `base=USD&target=INR&amount=100` | 200 · converted amount and exchange rate |
| TZ-01 | GET `/timezone/diff` | `from=Asia/Kolkata&to=Europe/Paris` | 200 · time difference, DST status, and local times |
| BUD-V2-01 | PUT `/trips/:id/budget` | `{ accommodation, food, transport, activities, misc }` | 200 · planned budgets updated instantly on screen |

