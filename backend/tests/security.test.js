const request = require('supertest');
const app = require('../src/app');

let ownerToken, tripId;

beforeAll(async () => {
  const ts = Date.now();
  const email = `sec_${ts}@test.com`;
  await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
  const r = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
  ownerToken = r.body.accessToken;
  const trip = await request(app).post('/trips').set('Authorization', `Bearer ${ownerToken}`)
    .send({ destination: 'Security Test', start_date: '2024-12-01', end_date: '2024-12-05', purpose: 'leisure', companions: [] });
  tripId = trip.body.id;
});

// ─── SEC-01: No JWT ──────────────────────────────────────────────────────────
test('SEC-01 · protected endpoint without JWT → 401', async () => {
  const endpoints = [
    () => request(app).get('/trips'),
    () => request(app).get('/auth/profile'),
    () => request(app).post('/trips').send({ destination: 'x' }),
  ];
  for (const fn of endpoints) {
    const res = await fn();
    expect(res.status).toBe(401);
  }
});

// ─── SEC-02: Malformed JWT ───────────────────────────────────────────────────
test('SEC-02 · malformed JWT → 401', async () => {
  const res = await request(app).get('/trips').set('Authorization', 'Bearer not.a.valid.jwt');
  expect(res.status).toBe(401);
});

// ─── SEC-03: Expired JWT ─────────────────────────────────────────────────────
test('SEC-03 · expired JWT → 401', async () => {
  // A pre-built expired JWT (signed with wrong secret or past exp)
  const expiredJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
    'eyJpZCI6InRlc3QiLCJpYXQiOjE2MDAwMDAwMDAsImV4cCI6MTYwMDAwMDAwMX0.' +
    'invalidsignature';
  const res = await request(app).get('/trips').set('Authorization', `Bearer ${expiredJwt}`);
  expect(res.status).toBe(401);
});

// ─── SEC-04: Passport not plaintext ─────────────────────────────────────────
test('SEC-04 · passport stored encrypted; not returned as plaintext', async () => {
  await request(app).put('/auth/profile')
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ passport_number: 'P9876543' });

  const res = await request(app).get('/auth/profile').set('Authorization', `Bearer ${ownerToken}`);
  expect(res.status).toBe(200);
  expect(res.body.passport_number).not.toBe('P9876543');
});

// ─── SEC-05: SQL injection ───────────────────────────────────────────────────
test('SEC-05 · SQL injection in trip ID → no DB error', async () => {
  const res = await request(app).get(`/trips/1' OR '1'='1`).set('Authorization', `Bearer ${ownerToken}`);
  expect([400, 404]).toContain(res.status);
  expect(res.body.stack).toBeUndefined(); // no stack trace exposed
});

// ─── SEC-06: Helmet headers ──────────────────────────────────────────────────
test('SEC-06 · helmet security headers present', async () => {
  const res = await request(app).get('/auth/profile').set('Authorization', `Bearer ${ownerToken}`);
  expect(res.headers['x-content-type-options']).toBe('nosniff');
  expect(res.headers['x-frame-options']).toBeDefined();
});

// ─── SEC-07: Cross-trip data isolation ───────────────────────────────────────
test('SEC-07 · another user cannot read trip items', async () => {
  const ts = Date.now();
  const intEmail = `intruder_${ts}@test.com`;
  await request(app).post('/auth/register').send({ email: intEmail, password: 'Test@1234' });
  const r = await request(app).post('/auth/login').send({ email: intEmail, password: 'Test@1234' });
  const intruderToken = r.body.accessToken;

  const res = await request(app).get(`/trips/${tripId}/itinerary`).set('Authorization', `Bearer ${intruderToken}`);
  expect(res.status).toBe(403);
});
