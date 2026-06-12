const request = require('supertest');
const app = require('../src/app');

let ownerToken, viewerToken, tripId, itemId;

beforeAll(async () => {
  const ts = Date.now();
  const ownerEmail  = `itin_owner_${ts}@test.com`;
  const viewerEmail = `itin_viewer_${ts}@test.com`;

  await request(app).post('/auth/register').send({ email: ownerEmail,  password: 'Test@1234' });
  await request(app).post('/auth/register').send({ email: viewerEmail, password: 'Test@1234' });

  const r1 = await request(app).post('/auth/login').send({ email: ownerEmail,  password: 'Test@1234' });
  ownerToken  = r1.body.accessToken;
  const r2 = await request(app).post('/auth/login').send({ email: viewerEmail, password: 'Test@1234' });
  viewerToken = r2.body.accessToken;

  const trip = await request(app).post('/trips').set('Authorization', `Bearer ${ownerToken}`)
    .send({ destination: 'Paris', start_date: '2024-10-12', end_date: '2024-10-19', purpose: 'leisure', companions: [] });
  tripId = trip.body.id;

  // Add viewer as collaborator
  await request(app).post(`/trips/${tripId}/collaborators`).set('Authorization', `Bearer ${ownerToken}`)
    .send({ email: viewerEmail, role: 'viewer' });
});

// ─── ITIN-01 ────────────────────────────────────────────────────────────────
test('ITIN-01 · POST itinerary item → 201', async () => {
  const res = await request(app).post(`/trips/${tripId}/itinerary`)
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ title: 'Petit Dejeuner', location: 'Place des Vosges', start_time: '09:00', end_time: '10:00', day_index: 0, order_index: 0 });
  expect(res.status).toBe(201);
  itemId = res.body.id;
});

// ─── ITIN-02 ────────────────────────────────────────────────────────────────
test('ITIN-02 · POST missing title → 4xx error', async () => {
  const res = await request(app).post(`/trips/${tripId}/itinerary`)
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ day_index: 0, order_index: 1 });
  expect(res.status).toBeGreaterThanOrEqual(400);
  expect(res.body.error).toBeDefined();
});

// ─── ITIN-03 ────────────────────────────────────────────────────────────────
test('ITIN-03 · GET /itinerary → 200 array', async () => {
  const res = await request(app).get(`/trips/${tripId}/itinerary`).set('Authorization', `Bearer ${ownerToken}`);
  expect(res.status).toBe(200);
  expect(Array.isArray(res.body)).toBe(true);
});

// ─── ITIN-04 ────────────────────────────────────────────────────────────────
test('ITIN-04 · PUT item update title → 200', async () => {
  const res = await request(app).put(`/trips/${tripId}/itinerary/${itemId}`)
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ title: 'Updated Title' });
  expect(res.status).toBe(200);
});

// ─── ITIN-05 ────────────────────────────────────────────────────────────────
test('ITIN-05 · PUT reorder → 2xx, order persists', async () => {
  const res = await request(app).put(`/trips/${tripId}/itinerary/reorder`)
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ items: [{ id: itemId, order_index: 0 }] });
  expect(res.status).toBeLessThan(300);

  const get = await request(app).get(`/trips/${tripId}/itinerary`).set('Authorization', `Bearer ${ownerToken}`);
  const found = get.body.find(i => i.id === itemId);
  expect(found?.order_index).toBe(0);
});

// ─── ITIN-07 ────────────────────────────────────────────────────────────────
test('ITIN-07 · POST item spanning midnight (23:30) → 201', async () => {
  const res = await request(app).post(`/trips/${tripId}/itinerary`)
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ title: 'Night Event', location: 'Night Club', start_time: '23:30', end_time: '01:00', day_index: 0, order_index: 99 });
  expect(res.status).toBe(201);
});

// ─── ITIN-08 ────────────────────────────────────────────────────────────────
test('ITIN-08 · GET itinerary as viewer → 200', async () => {
  const res = await request(app).get(`/trips/${tripId}/itinerary`).set('Authorization', `Bearer ${viewerToken}`);
  expect(res.status).toBe(200);
});

// ─── ITIN-09 ────────────────────────────────────────────────────────────────
test('ITIN-09 · DELETE item as viewer → 403', async () => {
  const res = await request(app).delete(`/trips/${tripId}/itinerary/${itemId}`).set('Authorization', `Bearer ${viewerToken}`);
  expect(res.status).toBe(403);
});

// ─── ITIN-06 ────────────────────────────────────────────────────────────────
test('ITIN-06 · DELETE item as owner → 2xx', async () => {
  const res = await request(app).delete(`/trips/${tripId}/itinerary/${itemId}`).set('Authorization', `Bearer ${ownerToken}`);
  expect([200, 204]).toContain(res.status);
});
