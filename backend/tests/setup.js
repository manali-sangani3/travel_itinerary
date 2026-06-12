const app = require('../src/app');

// Shared state across test files
global.app = app;
global.ownerToken = null;
global.otherToken = null;
global.viewerToken = null;
global.editorToken = null;
global.tripId = null;
global.itemId = null;
global.bookingId = null;
global.docId = null;
global.journalId = null;
global.collaboratorUserId = null;
