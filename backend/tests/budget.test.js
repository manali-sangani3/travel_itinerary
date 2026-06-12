const request = require('supertest');
const app = require('../src/app');

let ownerToken, tripId, expenseId;

beforeAll(async () => {
  const ts = Date.now();
  const email = `bud_owner_${ts}@test.com`;
  await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
  const r = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
  ownerToken = r.body.accessToken;
  const trip = await request(app).post('/trips').set('Authorization', `Bearer ${ownerToken}`)
    .send({ destination: 'Tokyo', start_date: '2024-11-01', end_date: '2024-11-10', purpose: 'leisure', companions: [] });
  tripId = trip.body.id;
});

const auth = () => ({ Authorization: `Bearer ${ownerToken}` });

// ─── BUD-01 ──────────────────────────────────────────────────────────────────
test('BUD-01 · PUT /budget sets category budgets → 200', async () => {
  const res = await request(app).put(`/trips/${tripId}/budget`).set(auth())
    .send({ accommodation: 5000, food: 2000, transport: 3000, activities: 1000, misc: 500 });
  expect(res.status).toBe(200);
});

// ─── BUD-02 ──────────────────────────────────────────────────────────────────
test('BUD-02 · GET /budget/summary → 200 planned vs actual', async () => {
  const res = await request(app).get(`/trips/${tripId}/budget/summary`).set(auth());
  expect(res.status).toBe(200);
  expect(Array.isArray(res.body)).toBe(true);
  res.body.forEach(item => {
    expect(item).toHaveProperty('category');
    expect(item).toHaveProperty('planned');
    expect(item).toHaveProperty('actual');
  });
});

// ─── BUD-03 ──────────────────────────────────────────────────────────────────
test('BUD-03 · POST expense INR → 201', async () => {
  const res = await request(app).post(`/trips/${tripId}/budget/expenses`).set(auth())
    .send({ amount: 500, category: 'food', currency: 'INR', note: 'Lunch' });
  expect(res.status).toBe(201);
  expenseId = res.body.id;
});

// ─── BUD-04 ──────────────────────────────────────────────────────────────────
test('BUD-04 · POST expense USD → 201', async () => {
  const res = await request(app).post(`/trips/${tripId}/budget/expenses`).set(auth())
    .send({ amount: 20, category: 'food', currency: 'USD', note: 'Coffee' });
  expect(res.status).toBe(201);
});

// ─── BUD-05 ──────────────────────────────────────────────────────────────────
test('BUD-05 · POST expense unknown currency XYZ → 201', async () => {
  const res = await request(app).post(`/trips/${tripId}/budget/expenses`).set(auth())
    .send({ amount: 100, category: 'misc', currency: 'XYZ', note: 'unknown currency test' });
  expect(res.status).toBe(201);
});

// ─── BUD-06 ──────────────────────────────────────────────────────────────────
test('BUD-06 · GET summary after expenses → actual > 0', async () => {
  const res = await request(app).get(`/trips/${tripId}/budget/summary`).set(auth());
  expect(res.status).toBe(200);
  const food = res.body.find(i => i.category === 'food');
  expect(food?.actual).toBeGreaterThan(0);
});

// ─── BUD-07 ──────────────────────────────────────────────────────────────────
test('BUD-07 · DELETE expense → 200, summary updated', async () => {
  const before = await request(app).get(`/trips/${tripId}/budget/summary`).set(auth());
  const foodBefore = before.body.find(i => i.category === 'food')?.actual ?? 0;

  await request(app).delete(`/trips/${tripId}/budget/expenses/${expenseId}`).set(auth());

  const after = await request(app).get(`/trips/${tripId}/budget/summary`).set(auth());
  const foodAfter = after.body.find(i => i.category === 'food')?.actual ?? 0;
  expect(foodAfter).toBeLessThan(foodBefore);
});
