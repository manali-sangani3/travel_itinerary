/**
 * Travel Itinerary — V2 Enhancement Backend Unit Tests
 * =====================================================
 * Framework : Jest + Supertest
 * Scope     : V2 features only (Packing Generator, Document Checklist,
 *             Itinerary Sharing, Trip Notes, Photo Gallery, Bookings,
 *             Journal Entries, Collaboration Tasks)
 * Command   : npm test -- --testPathPattern=v2.test
 */

const request = require('supertest');
const path    = require('path');
const fs      = require('fs');
const app     = require('../src/app');

// ─── Shared state ─────────────────────────────────────────────────────────────
let ownerToken, editorToken, viewerToken;
let tripId;
let ownerId, editorId, viewerId;

// ─── Helpers ──────────────────────────────────────────────────────────────────
const auth  = (token) => ({ Authorization: `Bearer ${token}` });
const owner  = () => auth(ownerToken);
const editor = () => auth(editorToken);
const viewer = () => auth(viewerToken);

const TRIP_PAYLOAD = {
  destination : 'Paris',
  start_date  : '2024-10-12',
  end_date    : '2024-10-19',
  purpose     : 'leisure',
  companions  : [],
};

// ─── Global setup: three users + one shared trip ──────────────────────────────
beforeAll(async () => {
  const ts = Date.now();

  const ownerEmail  = `v2_owner_${ts}@test.com`;
  const editorEmail = `v2_editor_${ts}@test.com`;
  const viewerEmail = `v2_viewer_${ts}@test.com`;

  // Register users
  for (const email of [ownerEmail, editorEmail, viewerEmail]) {
    await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
  }

  // Login — owner
  const l1   = await request(app).post('/auth/login').send({ email: ownerEmail,  password: 'Test@1234' });
  ownerToken = l1.body.accessToken;
  const p1   = await request(app).get('/auth/profile').set(owner());
  ownerId    = p1.body.id;

  // Login — editor
  const l2    = await request(app).post('/auth/login').send({ email: editorEmail, password: 'Test@1234' });
  editorToken = l2.body.accessToken;
  const p2    = await request(app).get('/auth/profile').set(editor());
  editorId    = p2.body.id;

  // Login — viewer
  const l3    = await request(app).post('/auth/login').send({ email: viewerEmail, password: 'Test@1234' });
  viewerToken = l3.body.accessToken;
  const p3    = await request(app).get('/auth/profile').set(viewer());
  viewerId    = p3.body.id;

  // Create trip owned by owner
  const trip = await request(app).post('/trips').set(owner()).send(TRIP_PAYLOAD);
  tripId = trip.body.id;

  // Add editor and viewer as collaborators
  await request(app).post(`/trips/${tripId}/collaborators`).set(owner())
    .send({ email: editorEmail, role: 'editor' });
  await request(app).post(`/trips/${tripId}/collaborators`).set(owner())
    .send({ email: viewerEmail, role: 'viewer' });
});

// =============================================================================
//  SECTION 1 — PACKING CHECKLIST (CRUD)
// =============================================================================

describe('Packing Checklist — CRUD', () => {
  let packItemId;

  // PACK-V2-01
  test('PACK-V2-01 · GET /packing empty → 200 empty array', async () => {
    const res = await request(app).get(`/trips/${tripId}/packing`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // PACK-V2-02
  test('PACK-V2-02 · POST /packing with label → 201 item created', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/packing`)
      .set(owner())
      .send({ label: 'Passport', category: 'Documents' });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.label).toBe('Passport');
    expect(res.body.checked).toBe(0);
    packItemId = res.body.id;
  });

  // PACK-V2-03
  test('PACK-V2-03 · POST /packing without label → 4xx error', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/packing`)
      .set(owner())
      .send({ category: 'Toiletries' });
    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  // PACK-V2-04
  test('PACK-V2-04 · GET /packing after insert → item appears in list', async () => {
    const res = await request(app).get(`/trips/${tripId}/packing`).set(owner());
    expect(res.status).toBe(200);
    const found = res.body.find(i => i.id === packItemId);
    expect(found).toBeDefined();
    expect(found.label).toBe('Passport');
  });

  // PACK-V2-05
  test('PACK-V2-05 · PUT /packing/:itemId checked=1 → toggled', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/packing/${packItemId}`)
      .set(owner())
      .send({ checked: 1 });
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);

    const list = await request(app).get(`/trips/${tripId}/packing`).set(owner());
    const found = list.body.find(i => i.id === packItemId);
    expect(found.checked).toBe(1);
  });

  // PACK-V2-06
  test('PACK-V2-06 · PUT /packing/:itemId checked=0 → untoggled', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/packing/${packItemId}`)
      .set(owner())
      .send({ checked: 0 });
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);

    const list = await request(app).get(`/trips/${tripId}/packing`).set(owner());
    const found = list.body.find(i => i.id === packItemId);
    expect(found.checked).toBe(0);
  });

  // PACK-V2-07
  test('PACK-V2-07 · viewer cannot POST /packing → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/packing`)
      .set(viewer())
      .send({ label: 'Camera' });
    expect(res.status).toBe(403);
  });

  // PACK-V2-08
  test('PACK-V2-08 · DELETE /packing/:itemId → 204 and item gone', async () => {
    // Create a disposable item to delete
    const created = await request(app)
      .post(`/trips/${tripId}/packing`)
      .set(owner())
      .send({ label: 'Toothbrush', category: 'Toiletries' });
    const tempId = created.body.id;

    const del = await request(app)
      .delete(`/trips/${tripId}/packing/${tempId}`)
      .set(owner());
    expect([200, 204]).toContain(del.status);

    const list = await request(app).get(`/trips/${tripId}/packing`).set(owner());
    expect(list.body.find(i => i.id === tempId)).toBeUndefined();
  });

  // PACK-V2-09
  test('PACK-V2-09 · unauthenticated GET /packing → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/packing`);
    expect(res.status).toBe(401);
  });

  // PACK-V2-10
  test('PACK-V2-10 · editor can add packing item → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/packing`)
      .set(editor())
      .send({ label: 'Sunscreen', category: 'Toiletries' });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
  });
});

// =============================================================================
//  SECTION 2 — PACKING TEMPLATE GENERATOR
// =============================================================================

describe('Packing Template Generator', () => {

  // PACK-TPL-01
  test('PACK-TPL-01 · GET /packing/templates → 200 with at least one template', async () => {
    const res = await request(app).get(`/trips/${tripId}/packing/templates`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });

  // PACK-TPL-02
  test('PACK-TPL-02 · template has id, name, tripType, items (array)', async () => {
    const res = await request(app).get(`/trips/${tripId}/packing/templates`).set(owner());
    const tpl = res.body[0];
    expect(tpl.id).toBeDefined();
    expect(tpl.name).toBeDefined();
    expect(tpl.tripType).toBeDefined();
    expect(Array.isArray(tpl.items)).toBe(true);
    expect(tpl.items.length).toBeGreaterThan(0);
  });

  // PACK-TPL-03
  test('PACK-TPL-03 · POST /packing/generate with valid templateId → 201 list created', async () => {
    const tmplRes = await request(app).get(`/trips/${tripId}/packing/templates`).set(owner());
    const templateId = tmplRes.body[0].id;

    const res = await request(app)
      .post(`/trips/${tripId}/packing/generate`)
      .set(owner())
      .send({ templateId });
    expect(res.status).toBe(201);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body[0].trip_id).toBe(tripId);
  });

  // PACK-TPL-04
  test('PACK-TPL-04 · generated items have correct category (template name)', async () => {
    const tmplRes = await request(app).get(`/trips/${tripId}/packing/templates`).set(owner());
    const tpl = tmplRes.body[0];

    await request(app).post(`/trips/${tripId}/packing/generate`).set(owner()).send({ templateId: tpl.id });
    const list = await request(app).get(`/trips/${tripId}/packing`).set(owner());

    const fromTemplate = list.body.filter(i => i.category === tpl.name);
    expect(fromTemplate.length).toBeGreaterThan(0);
  });

  // PACK-TPL-05
  test('PACK-TPL-05 · POST /generate with unknown templateId → falls back to default template (201)', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/packing/generate`)
      .set(owner())
      .send({ templateId: 'nonexistent-id-xyz' });
    // Backend falls back to first available template
    expect(res.status).toBe(201);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // PACK-TPL-06
  test('PACK-TPL-06 · viewer cannot POST /generate → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/packing/generate`)
      .set(viewer())
      .send({ templateId: 't1' });
    expect(res.status).toBe(403);
  });

  // PACK-TPL-07
  test('PACK-TPL-07 · "Beach Holiday" template contains beach-specific items', async () => {
    const res = await request(app).get(`/trips/${tripId}/packing/templates`).set(owner());
    const beach = res.body.find(t => t.tripType === 'beach');
    expect(beach).toBeDefined();
    const lower = beach.items.map(i => i.toLowerCase());
    // At least one of these should be in the beach template
    const beachItems = ['swimwear', 'sunscreen', 'sunglasses', 'beach towel', 'flip flops'];
    const hasBeachItem = beachItems.some(b => lower.some(l => l.includes(b)));
    expect(hasBeachItem).toBe(true);
  });
});

// =============================================================================
//  SECTION 3 — TRAVEL DOCUMENT CHECKLIST
// =============================================================================

describe('Document Checklist', () => {
  let checklistItemId;

  // DOC-CK-01
  test('DOC-CK-01 · GET /checklist/documents → 200, auto-seeds defaults', async () => {
    const res = await request(app)
      .get(`/trips/${tripId}/checklist/documents`)
      .set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    checklistItemId = res.body[0].id;
  });

  // DOC-CK-02
  test('DOC-CK-02 · default items include Passport and Visa', async () => {
    const res = await request(app)
      .get(`/trips/${tripId}/checklist/documents`)
      .set(owner());
    const labels = res.body.map(i => i.label);
    expect(labels).toContain('Passport');
    expect(labels).toContain('Visa');
  });

  // DOC-CK-03
  test('DOC-CK-03 · default items all start with checked = 0', async () => {
    const res = await request(app)
      .get(`/trips/${tripId}/checklist/documents`)
      .set(owner());
    res.body.forEach(item => expect(item.checked).toBe(0));
  });

  // DOC-CK-04
  test('DOC-CK-04 · PUT /checklist/documents checked=1 → 200 updated', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/checklist/documents`)
      .set(owner())
      .send({ itemId: checklistItemId, checked: true });
    expect(res.status).toBe(200);
  });

  // DOC-CK-05
  test('DOC-CK-05 · after PUT checked=1 GET reflects change', async () => {
    const res = await request(app)
      .get(`/trips/${tripId}/checklist/documents`)
      .set(owner());
    const updated = res.body.find(i => i.id === checklistItemId);
    expect(updated.checked).toBe(1);
  });

  // DOC-CK-06
  test('DOC-CK-06 · PUT /checklist/documents checked=0 → uncheck', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/checklist/documents`)
      .set(owner())
      .send({ itemId: checklistItemId, checked: false });
    expect(res.status).toBe(200);
  });

  // DOC-CK-07
  test('DOC-CK-07 · viewer cannot PUT checklist → 403', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/checklist/documents`)
      .set(viewer())
      .send({ itemId: checklistItemId, checked: true });
    expect(res.status).toBe(403);
  });

  // DOC-CK-08
  test('DOC-CK-08 · unauthenticated GET → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/checklist/documents`);
    expect(res.status).toBe(401);
  });

  // DOC-CK-09
  test('DOC-CK-09 · second GET does not re-seed (idempotent)', async () => {
    const r1 = await request(app).get(`/trips/${tripId}/checklist/documents`).set(owner());
    const r2 = await request(app).get(`/trips/${tripId}/checklist/documents`).set(owner());
    expect(r1.body.length).toBe(r2.body.length);
  });

  // DOC-CK-10
  test('DOC-CK-10 · editor can toggle checklist item', async () => {
    const list = await request(app).get(`/trips/${tripId}/checklist/documents`).set(owner());
    const itemId = list.body[1].id;

    const res = await request(app)
      .put(`/trips/${tripId}/checklist/documents`)
      .set(editor())
      .send({ itemId, checked: true });
    expect(res.status).toBe(200);
  });
});

// =============================================================================
//  SECTION 4 — ITINERARY SHARING (trip_shares)
// =============================================================================

describe('Itinerary Sharing', () => {
  let shareId, shareToken;

  // SHARE-01
  test('SHARE-01 · POST /share with role=viewer → 201 shareUrl', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/share`)
      .set(owner())
      .send({ role: 'viewer', expiresInDays: 7 });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
    expect(res.body.shareUrl).toBeDefined();
    expect(res.body.role).toBe('viewer');
    shareId    = res.body.id;
    shareToken = res.body.token;
  });

  // SHARE-02
  test('SHARE-02 · POST /share with role=editor → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/share`)
      .set(owner())
      .send({ role: 'editor', expiresInDays: 3 });
    expect(res.status).toBe(201);
    expect(res.body.role).toBe('editor');
  });

  // SHARE-03
  test('SHARE-03 · POST /share with invalid role → 400', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/share`)
      .set(owner())
      .send({ role: 'superadmin', expiresInDays: 7 });
    expect(res.status).toBe(400);
  });

  // SHARE-04
  test('SHARE-04 · GET /share → 200 lists all shares for trip', async () => {
    const res = await request(app).get(`/trips/${tripId}/share`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    const found = res.body.find(s => s.id === shareId);
    expect(found).toBeDefined();
  });

  // SHARE-05
  test('SHARE-05 · share has expires_at in the future', async () => {
    const res = await request(app).get(`/trips/${tripId}/share`).set(owner());
    const share = res.body.find(s => s.id === shareId);
    expect(share).toBeDefined();
    expect(new Date(share.expires_at).getTime()).toBeGreaterThan(Date.now());
  });

  // SHARE-06
  test('SHARE-06 · GET /shares/:token → 200 returns trip + itinerary', async () => {
    const res = await request(app).get(`/shares/${shareToken}`);
    expect(res.status).toBe(200);
    expect(res.body.trip).toBeDefined();
    expect(res.body.trip.id).toBe(tripId);
    expect(Array.isArray(res.body.itinerary)).toBe(true);
  });

  // SHARE-07
  test('SHARE-07 · GET /shares/invalid-token → 404', async () => {
    const res = await request(app).get('/shares/totally-invalid-token-xyz123');
    expect(res.status).toBe(404);
  });

  // SHARE-08
  test('SHARE-08 · public share response contains role field', async () => {
    const res = await request(app).get(`/shares/${shareToken}`);
    expect(res.status).toBe(200);
    expect(['viewer', 'editor']).toContain(res.body.role);
  });

  // SHARE-09
  test('SHARE-09 · viewer cannot POST /share → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/share`)
      .set(viewer())
      .send({ role: 'viewer', expiresInDays: 1 });
    expect(res.status).toBe(403);
  });

  // SHARE-10
  test('SHARE-10 · DELETE /share/:shareId → 204 link revoked', async () => {
    const res = await request(app)
      .delete(`/trips/${tripId}/share/${shareId}`)
      .set(owner());
    expect([200, 204]).toContain(res.status);

    // Verify the token is now dead
    const check = await request(app).get(`/shares/${shareToken}`);
    expect(check.status).toBe(404);
  });

  // SHARE-11
  test('SHARE-11 · share token is unique per creation', async () => {
    const r1 = await request(app).post(`/trips/${tripId}/share`).set(owner())
      .send({ role: 'viewer', expiresInDays: 1 });
    const r2 = await request(app).post(`/trips/${tripId}/share`).set(owner())
      .send({ role: 'viewer', expiresInDays: 1 });
    expect(r1.body.token).not.toBe(r2.body.token);

    // cleanup
    await request(app).delete(`/trips/${tripId}/share/${r1.body.id}`).set(owner());
    await request(app).delete(`/trips/${tripId}/share/${r2.body.id}`).set(owner());
  });

  // SHARE-12
  test('SHARE-12 · unauthenticated GET /share → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/share`);
    expect(res.status).toBe(401);
  });
});

// =============================================================================
//  SECTION 5 — TRIP NOTES & MEMORIES
// =============================================================================

describe('Trip Notes & Memories', () => {
  let noteId;

  // NOTE-01
  test('NOTE-01 · GET /notes empty → 200 empty array', async () => {
    const res = await request(app).get(`/trips/${tripId}/notes`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // NOTE-02
  test('NOTE-02 · POST /notes with content → 201 note created', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/notes`)
      .set(owner())
      .send({ content: 'Wonderful sunset at Eiffel Tower!', locationTag: 'Eiffel Tower' });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.content).toBe('Wonderful sunset at Eiffel Tower!');
    expect(res.body.location_tag).toBe('Eiffel Tower');
    noteId = res.body.id;
  });

  // NOTE-03
  test('NOTE-03 · POST /notes without content → 400 error', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/notes`)
      .set(owner())
      .send({ locationTag: 'Louvre' });
    expect(res.status).toBe(400);
  });

  // NOTE-04
  test('NOTE-04 · POST /notes with dayDate → stored correctly', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/notes`)
      .set(owner())
      .send({ content: 'Day 2 notes', dayDate: '2024-10-13' });
    expect(res.status).toBe(201);
    expect(res.body.day_date).toBe('2024-10-13');
  });

  // NOTE-05
  test('NOTE-05 · GET /notes → includes created note', async () => {
    const res = await request(app).get(`/trips/${tripId}/notes`).set(owner());
    expect(res.status).toBe(200);
    const found = res.body.find(n => n.id === noteId);
    expect(found).toBeDefined();
    expect(found.content).toBe('Wonderful sunset at Eiffel Tower!');
  });

  // NOTE-06
  test('NOTE-06 · GET /notes ordered newest first', async () => {
    const res = await request(app).get(`/trips/${tripId}/notes`).set(owner());
    if (res.body.length > 1) {
      const dates = res.body.map(n => new Date(n.created_at).getTime());
      expect(dates[0]).toBeGreaterThanOrEqual(dates[1]);
    }
  });

  // NOTE-07
  test('NOTE-07 · PUT /notes/:noteId → 200 content updated', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/notes/${noteId}`)
      .set(owner())
      .send({ content: 'Updated: Amazing Eiffel Tower experience!' });
    expect(res.status).toBe(200);
    expect(res.body.content).toBe('Updated: Amazing Eiffel Tower experience!');
  });

  // NOTE-08
  test('NOTE-08 · PUT /notes/:noteId without content → 400', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/notes/${noteId}`)
      .set(owner())
      .send({});
    expect(res.status).toBe(400);
  });

  // NOTE-09
  test('NOTE-09 · viewer cannot POST /notes → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/notes`)
      .set(viewer())
      .send({ content: 'Hacked note' });
    expect(res.status).toBe(403);
  });

  // NOTE-10
  test('NOTE-10 · viewer can GET /notes → 200', async () => {
    const res = await request(app).get(`/trips/${tripId}/notes`).set(viewer());
    expect(res.status).toBe(200);
  });

  // NOTE-11
  test('NOTE-11 · editor can POST and DELETE /notes', async () => {
    const create = await request(app)
      .post(`/trips/${tripId}/notes`)
      .set(editor())
      .send({ content: 'Editor note' });
    expect(create.status).toBe(201);

    const del = await request(app)
      .delete(`/trips/${tripId}/notes/${create.body.id}`)
      .set(editor());
    expect([200, 204]).toContain(del.status);
  });

  // NOTE-12
  test('NOTE-12 · DELETE /notes/:noteId → 204 note removed', async () => {
    const create = await request(app)
      .post(`/trips/${tripId}/notes`)
      .set(owner())
      .send({ content: 'Temporary note to delete' });
    const tempId = create.body.id;

    const del = await request(app)
      .delete(`/trips/${tripId}/notes/${tempId}`)
      .set(owner());
    expect([200, 204]).toContain(del.status);

    const list = await request(app).get(`/trips/${tripId}/notes`).set(owner());
    expect(list.body.find(n => n.id === tempId)).toBeUndefined();
  });

  // NOTE-13
  test('NOTE-13 · unauthenticated GET /notes → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/notes`);
    expect(res.status).toBe(401);
  });
});

// =============================================================================
//  SECTION 6 — PHOTO GALLERY (trip_photos)
// =============================================================================

describe('Photo Gallery', () => {
  let photoId;

  // Minimal valid image bytes (1×1 white PNG)
  const PNG_1X1 = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg==',
    'base64'
  );

  // PHOTO-01
  test('PHOTO-01 · GET /photos empty → 200 empty array', async () => {
    const res = await request(app).get(`/trips/${tripId}/photos`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // PHOTO-02
  test('PHOTO-02 · POST /photos with multipart image → 201 photo record', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/photos`)
      .set(owner())
      .field('locationTag', 'Eiffel Tower')
      .field('dateTaken', '2024-10-12')
      .attach('photo', PNG_1X1, { filename: 'test.png', contentType: 'image/png' });

    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.location_tag).toBe('Eiffel Tower');
    expect(res.body.date_taken).toBeDefined();
    photoId = res.body.id;
  });

  // PHOTO-03
  test('PHOTO-03 · POST /photos without file → 400', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/photos`)
      .set(owner())
      .send({});
    expect(res.status).toBe(400);
  });

  // PHOTO-04
  test('PHOTO-04 · GET /photos → includes created photo', async () => {
    const res = await request(app).get(`/trips/${tripId}/photos`).set(owner());
    expect(res.status).toBe(200);
    const found = res.body.find(p => p.id === photoId);
    expect(found).toBeDefined();
    expect(found.file_path).toBeDefined();
  });

  // PHOTO-05
  test('PHOTO-05 · GET /photos ordered newest date_taken first', async () => {
    const res = await request(app).get(`/trips/${tripId}/photos`).set(owner());
    if (res.body.length > 1) {
      const dates = res.body.map(p => p.date_taken);
      expect(dates[0] >= dates[1]).toBe(true);
    }
  });

  // PHOTO-06
  test('PHOTO-06 · viewer can GET /photos → 200', async () => {
    const res = await request(app).get(`/trips/${tripId}/photos`).set(viewer());
    expect(res.status).toBe(200);
  });

  // PHOTO-07
  test('PHOTO-07 · viewer cannot POST /photos → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/photos`)
      .set(viewer())
      .attach('photo', PNG_1X1, { filename: 'hack.png', contentType: 'image/png' });
    expect(res.status).toBe(403);
  });

  // PHOTO-08
  test('PHOTO-08 · photo stored with trip_id', async () => {
    const res = await request(app).get(`/trips/${tripId}/photos`).set(owner());
    const photo = res.body.find(p => p.id === photoId);
    expect(photo.trip_id).toBe(tripId);
  });

  // PHOTO-09
  test('PHOTO-09 · DELETE /photos/:photoId → 204 photo removed', async () => {
    // Upload a fresh photo to delete
    const upload = await request(app)
      .post(`/trips/${tripId}/photos`)
      .set(owner())
      .field('dateTaken', '2024-10-14')
      .attach('photo', PNG_1X1, { filename: 'del_test.png', contentType: 'image/png' });
    const tempId = upload.body.id;

    const del = await request(app)
      .delete(`/trips/${tripId}/photos/${tempId}`)
      .set(owner());
    expect([200, 204]).toContain(del.status);

    const list = await request(app).get(`/trips/${tripId}/photos`).set(owner());
    expect(list.body.find(p => p.id === tempId)).toBeUndefined();
  });

  // PHOTO-10
  test('PHOTO-10 · DELETE non-existent photoId → 404', async () => {
    const res = await request(app)
      .delete(`/trips/${tripId}/photos/non-existent-photo-id`)
      .set(owner());
    expect(res.status).toBe(404);
  });

  // PHOTO-11
  test('PHOTO-11 · unauthenticated GET /photos → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/photos`);
    expect(res.status).toBe(401);
  });
});

// =============================================================================
//  SECTION 7 — BOOKINGS
// =============================================================================

describe('Bookings', () => {
  let bookingId;

  // BOOK-01
  test('BOOK-01 · GET /bookings empty → 200 empty array', async () => {
    const res = await request(app).get(`/trips/${tripId}/bookings`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // BOOK-02
  test('BOOK-02 · POST /bookings flight → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/bookings`)
      .set(owner())
      .send({
        type             : 'flight',
        reference_number : 'AI-202',
        details          : { airline: 'Air India', flight_number: 'AI202', departure: '2024-10-12T06:00:00' },
      });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.type).toBe('flight');
    expect(res.body.reference_number).toBe('AI-202');
    bookingId = res.body.id;
  });

  // BOOK-03
  test('BOOK-03 · POST /bookings hotel → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/bookings`)
      .set(owner())
      .send({
        type             : 'hotel',
        reference_number : 'HTL-77',
        details          : { hotel_name: 'Le Meurice', check_in: '2024-10-12', check_out: '2024-10-19' },
      });
    expect(res.status).toBe(201);
    expect(res.body.type).toBe('hotel');
  });

  // BOOK-04
  test('BOOK-04 · POST /bookings car_rental → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/bookings`)
      .set(owner())
      .send({
        type             : 'car_rental',
        reference_number : 'CAR-55',
        details          : { company: 'Europcar', pickup: 'CDG Airport' },
      });
    expect(res.status).toBe(201);
    expect(res.body.type).toBe('car_rental');
  });

  // BOOK-05
  test('BOOK-05 · POST /bookings activity → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/bookings`)
      .set(owner())
      .send({
        type             : 'activity',
        reference_number : 'ACT-01',
        details          : { name: 'Louvre Museum Tour', date: '2024-10-13' },
      });
    expect(res.status).toBe(201);
  });

  // BOOK-06
  test('BOOK-06 · GET /bookings → returns all booking types', async () => {
    const res = await request(app).get(`/trips/${tripId}/bookings`).set(owner());
    expect(res.status).toBe(200);
    const types = res.body.map(b => b.type);
    expect(types).toContain('flight');
    expect(types).toContain('hotel');
  });

  // BOOK-07
  test('BOOK-07 · booking details JSON is returned as object', async () => {
    const res = await request(app).get(`/trips/${tripId}/bookings`).set(owner());
    const flight = res.body.find(b => b.id === bookingId);
    expect(flight).toBeDefined();
    // Details should be parseable
    const details = typeof flight.details === 'string'
      ? JSON.parse(flight.details)
      : flight.details;
    expect(details.airline).toBe('Air India');
  });

  // BOOK-08
  test('BOOK-08 · PUT /bookings/:id → 200 updated', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/bookings/${bookingId}`)
      .set(owner())
      .send({ reference_number: 'AI-303' });
    expect(res.status).toBe(200);
    expect(res.body.reference_number).toBe('AI-303');
  });

  // BOOK-09
  test('BOOK-09 · viewer cannot POST /bookings → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/bookings`)
      .set(viewer())
      .send({ type: 'flight', reference_number: 'HACK-01', details: {} });
    expect(res.status).toBe(403);
  });

  // BOOK-10
  test('BOOK-10 · viewer can GET /bookings → 200', async () => {
    const res = await request(app).get(`/trips/${tripId}/bookings`).set(viewer());
    expect(res.status).toBe(200);
  });

  // BOOK-11
  test('BOOK-11 · DELETE /bookings/:id → 204 removed', async () => {
    const create = await request(app)
      .post(`/trips/${tripId}/bookings`)
      .set(owner())
      .send({ type: 'activity', reference_number: 'DEL-01', details: {} });
    const tempId = create.body.id;

    const del = await request(app)
      .delete(`/trips/${tripId}/bookings/${tempId}`)
      .set(owner());
    expect([200, 204]).toContain(del.status);

    const list = await request(app).get(`/trips/${tripId}/bookings`).set(owner());
    expect(list.body.find(b => b.id === tempId)).toBeUndefined();
  });

  // BOOK-12
  test('BOOK-12 · unauthenticated GET /bookings → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/bookings`);
    expect(res.status).toBe(401);
  });
});

// =============================================================================
//  SECTION 8 — JOURNAL ENTRIES (V2 enhancements)
// =============================================================================

describe('Journal Entries', () => {
  let entryId;

  const PNG_1X1 = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg==',
    'base64'
  );

  // JOUR-01
  test('JOUR-01 · GET /journal empty → 200 empty array', async () => {
    const res = await request(app).get(`/trips/${tripId}/journal`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // JOUR-02
  test('JOUR-02 · POST /journal with body → 201 entry created', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/journal`)
      .set(owner())
      .send({ entry_date: '2024-10-12', body: 'Arrived in Paris. The city is breathtaking!' });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.body).toBe('Arrived in Paris. The city is breathtaking!');
    expect(res.body.entry_date).toBe('2024-10-12');
    entryId = res.body.id;
  });

  // JOUR-03
  test('JOUR-03 · GET /journal → entry appears in list', async () => {
    const res = await request(app).get(`/trips/${tripId}/journal`).set(owner());
    const found = res.body.find(e => e.id === entryId);
    expect(found).toBeDefined();
  });

  // JOUR-04
  test('JOUR-04 · PUT /journal/:entryId → 200 body updated', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/journal/${entryId}`)
      .set(owner())
      .send({ body: 'Updated: Paris day 1 was magical!' });
    expect(res.status).toBe(200);
    expect(res.body.body).toBe('Updated: Paris day 1 was magical!');
  });

  // JOUR-05
  test('JOUR-05 · viewer can GET /journal → 200', async () => {
    const res = await request(app).get(`/trips/${tripId}/journal`).set(viewer());
    expect(res.status).toBe(200);
  });

  // JOUR-06
  test('JOUR-06 · viewer cannot POST /journal → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/journal`)
      .set(viewer())
      .send({ entry_date: '2024-10-13', body: 'Hacked entry' });
    expect(res.status).toBe(403);
  });

  // JOUR-07
  test('JOUR-07 · POST /journal/:entryId/photos → 200 photo linked to entry', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/journal/${entryId}/photos`)
      .set(owner())
      .field('location', 'Montmartre')
      .attach('photo', PNG_1X1, { filename: 'journal_photo.png', contentType: 'image/png' });
    expect([200, 201]).toContain(res.status);
  });

  // JOUR-08
  test('JOUR-08 · DELETE /journal/:entryId → 204 entry removed', async () => {
    const create = await request(app)
      .post(`/trips/${tripId}/journal`)
      .set(owner())
      .send({ entry_date: '2024-10-14', body: 'Disposable entry' });
    const tempId = create.body.id;

    const del = await request(app)
      .delete(`/trips/${tripId}/journal/${tempId}`)
      .set(owner());
    expect([200, 204]).toContain(del.status);

    const list = await request(app).get(`/trips/${tripId}/journal`).set(owner());
    expect(list.body.find(e => e.id === tempId)).toBeUndefined();
  });

  // JOUR-09
  test('JOUR-09 · unauthenticated GET /journal → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/journal`);
    expect(res.status).toBe(401);
  });

  // JOUR-10
  test('JOUR-10 · multiple journal entries ordered newest first', async () => {
    await request(app).post(`/trips/${tripId}/journal`).set(owner())
      .send({ entry_date: '2024-10-15', body: 'Day 4' });
    await request(app).post(`/trips/${tripId}/journal`).set(owner())
      .send({ entry_date: '2024-10-16', body: 'Day 5' });

    const res = await request(app).get(`/trips/${tripId}/journal`).set(owner());
    if (res.body.length > 1) {
      const dates = res.body.map(e => e.entry_date);
      expect(dates[0] >= dates[1]).toBe(true);
    }
  });
});

// =============================================================================
//  SECTION 9 — COLLABORATION TASKS (V2 coverage)
// =============================================================================

describe('Collaboration Tasks', () => {
  let taskId;

  // TASK-01
  test('TASK-01 · GET /tasks empty → 200 array', async () => {
    const res = await request(app).get(`/trips/${tripId}/tasks`).set(owner());
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  // TASK-02
  test('TASK-02 · POST /tasks → 201 task created', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/tasks`)
      .set(owner())
      .send({ title: 'Book museum tickets', assigned_to: editorId, completed: 0 });
    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    expect(res.body.title).toBe('Book museum tickets');
    expect(res.body.completed).toBe(0);
    taskId = res.body.id;
  });

  // TASK-03
  test('TASK-03 · GET /tasks → includes created task', async () => {
    const res = await request(app).get(`/trips/${tripId}/tasks`).set(owner());
    const found = res.body.find(t => t.id === taskId);
    expect(found).toBeDefined();
    expect(found.title).toBe('Book museum tickets');
  });

  // TASK-04
  test('TASK-04 · PUT /tasks/:taskId completed=1 → 200 done', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/tasks/${taskId}`)
      .set(owner())
      .send({ completed: 1 });
    expect(res.status).toBe(200);
  });

  // TASK-05
  test('TASK-05 · PUT /tasks/:taskId completed=0 → undo done', async () => {
    const res = await request(app)
      .put(`/trips/${tripId}/tasks/${taskId}`)
      .set(owner())
      .send({ completed: 0 });
    expect(res.status).toBe(200);
  });

  // TASK-06
  test('TASK-06 · editor can create a task → 201', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/tasks`)
      .set(editor())
      .send({ title: 'Arrange airport transfer' });
    expect(res.status).toBe(201);
  });

  // TASK-07
  test('TASK-07 · viewer cannot POST /tasks → 403', async () => {
    const res = await request(app)
      .post(`/trips/${tripId}/tasks`)
      .set(viewer())
      .send({ title: 'Unauthorized task' });
    expect(res.status).toBe(403);
  });

  // TASK-08
  test('TASK-08 · viewer can GET /tasks → 200', async () => {
    const res = await request(app).get(`/trips/${tripId}/tasks`).set(viewer());
    expect(res.status).toBe(200);
  });

  // TASK-09
  test('TASK-09 · unauthenticated GET /tasks → 401', async () => {
    const res = await request(app).get(`/trips/${tripId}/tasks`);
    expect(res.status).toBe(401);
  });
});

// =============================================================================
//  SECTION 10 — ACCESS CONTROL MATRIX (Cross-feature permission tests)
// =============================================================================

describe('Access Control — V2 Cross-Feature', () => {

  // ACL-01
  test('ACL-01 · random user cannot GET /packing of another trip → 403', async () => {
    const ts = Date.now();
    const email = `acl_random_${ts}@test.com`;
    await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
    const login = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
    const token = login.body.accessToken;

    const res = await request(app).get(`/trips/${tripId}/packing`)
      .set({ Authorization: `Bearer ${token}` });
    expect(res.status).toBe(403);
  });

  // ACL-02
  test('ACL-02 · random user cannot GET /notes of another trip → 403', async () => {
    const ts = Date.now();
    const email = `acl_notes_${ts}@test.com`;
    await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
    const login = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
    const token = login.body.accessToken;

    const res = await request(app).get(`/trips/${tripId}/notes`)
      .set({ Authorization: `Bearer ${token}` });
    expect(res.status).toBe(403);
  });

  // ACL-03
  test('ACL-03 · random user cannot GET /photos of another trip → 403', async () => {
    const ts = Date.now();
    const email = `acl_photo_${ts}@test.com`;
    await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
    const login = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
    const token = login.body.accessToken;

    const res = await request(app).get(`/trips/${tripId}/photos`)
      .set({ Authorization: `Bearer ${token}` });
    expect(res.status).toBe(403);
  });

  // ACL-04
  test('ACL-04 · random user cannot GET /bookings of another trip → 403', async () => {
    const ts = Date.now();
    const email = `acl_book_${ts}@test.com`;
    await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
    const login = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
    const token = login.body.accessToken;

    const res = await request(app).get(`/trips/${tripId}/bookings`)
      .set({ Authorization: `Bearer ${token}` });
    expect(res.status).toBe(403);
  });

  // ACL-05
  test('ACL-05 · random user cannot GET /share of another trip → 403', async () => {
    const ts = Date.now();
    const email = `acl_share_${ts}@test.com`;
    await request(app).post('/auth/register').send({ email, password: 'Test@1234' });
    const login = await request(app).post('/auth/login').send({ email, password: 'Test@1234' });
    const token = login.body.accessToken;

    const res = await request(app).get(`/trips/${tripId}/share`)
      .set({ Authorization: `Bearer ${token}` });
    expect(res.status).toBe(403);
  });
});
