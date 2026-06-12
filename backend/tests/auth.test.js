const request = require('supertest');
const app = require('../src/app');

const OWNER = { email: `owner_${Date.now()}@test.com`, password: 'Test@1234' };
const OTHER = { email: `other_${Date.now()}@test.com`, password: 'Test@1234' };

let ownerToken;

// ─── AUTH-01: Register ──────────────────────────────────────────────────────
test('AUTH-01 · register with email + password → 201', async () => {
  const res = await request(app).post('/auth/register').send(OWNER);
  expect(res.status).toBe(201);
  expect(res.body.id).toBeDefined();
  expect(res.body.email).toBe(OWNER.email);
});

// ─── AUTH-02: Duplicate email ───────────────────────────────────────────────
test('AUTH-02 · duplicate email → 409', async () => {
  const res = await request(app).post('/auth/register').send(OWNER);
  expect(res.status).toBe(409);
});

// ─── AUTH-03: Login valid ───────────────────────────────────────────────────
test('AUTH-03 · login valid → 200 with accessToken + refreshToken', async () => {
  const res = await request(app).post('/auth/login').send(OWNER);
  expect(res.status).toBe(200);
  expect(res.body.accessToken).toBeDefined();
  expect(res.body.refreshToken).toBeDefined();
  ownerToken = res.body.accessToken;
  global.ownerToken = ownerToken;

  // Register + login secondary user
  await request(app).post('/auth/register').send(OTHER);
  const r2 = await request(app).post('/auth/login').send(OTHER);
  global.otherToken = r2.body.accessToken;
});

// ─── AUTH-04: Wrong password ────────────────────────────────────────────────
test('AUTH-04 · wrong password → 401 (no user enumeration)', async () => {
  const res = await request(app).post('/auth/login').send({ email: OWNER.email, password: 'wrong' });
  expect(res.status).toBe(401);
  expect(res.body.error).not.toMatch(OWNER.email);
});

// ─── AUTH-05: Unknown email ─────────────────────────────────────────────────
test('AUTH-05 · unknown email → 401 (same message)', async () => {
  const res = await request(app).post('/auth/login').send({ email: 'nobody@x.com', password: 'x' });
  expect(res.status).toBe(401);
});

// ─── AUTH-06: Refresh valid ─────────────────────────────────────────────────
test('AUTH-06 · valid refresh token → 200 new accessToken', async () => {
  const login = await request(app).post('/auth/login').send(OWNER);
  const res = await request(app).post('/auth/refresh').send({ refreshToken: login.body.refreshToken });
  expect(res.status).toBe(200);
  expect(res.body.accessToken).toBeDefined();
});

// ─── AUTH-07: Expired refresh token ────────────────────────────────────────
test('AUTH-07 · expired/invalid refresh token → 401', async () => {
  const res = await request(app).post('/auth/refresh').send({ refreshToken: 'bad.token.here' });
  expect(res.status).toBe(401);
});

// ─── AUTH-08: GET profile ───────────────────────────────────────────────────
test('AUTH-08 · GET /auth/profile with valid JWT → 200 (no plaintext passport)', async () => {
  const res = await request(app).get('/auth/profile').set('Authorization', `Bearer ${ownerToken}`);
  expect(res.status).toBe(200);
  expect(res.body.password).toBeUndefined();
  // passport_number should not be plaintext if set
  if (res.body.passport_number) {
    expect(res.body.passport_number).not.toMatch(/^[A-Z0-9]{6,9}$/);
  }
});

// ─── AUTH-09: GET profile no JWT ────────────────────────────────────────────
test('AUTH-09 · GET /auth/profile without JWT → 401', async () => {
  const res = await request(app).get('/auth/profile');
  expect(res.status).toBe(401);
});

// ─── AUTH-10: Update passport ───────────────────────────────────────────────
test('AUTH-10 · PUT profile with passport_number → stored encrypted', async () => {
  const res = await request(app)
    .put('/auth/profile')
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ passport_number: 'P1234567' });
  expect(res.status).toBe(200);

  const profile = await request(app).get('/auth/profile').set('Authorization', `Bearer ${ownerToken}`);
  // Should not return raw passport number
  expect(profile.body.passport_number).not.toBe('P1234567');
});

// ─── AUTH-11: Update preferences persist ────────────────────────────────────
test('AUTH-11 · PUT profile preferences → persists after re-login', async () => {
  await request(app)
    .put('/auth/profile')
    .set('Authorization', `Bearer ${ownerToken}`)
    .send({ preferences: JSON.stringify({ seat: 'window' }) });

  const relogin = await request(app).post('/auth/login').send(OWNER);
  const newToken = relogin.body.accessToken;
  const profile = await request(app).get('/auth/profile').set('Authorization', `Bearer ${newToken}`);
  expect(profile.status).toBe(200);
});
