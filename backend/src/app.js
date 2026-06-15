require('./db/schema'); // init tables

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const path = require('path');
const errorHandler = require('./middleware/error');

const app = express();

app.use(helmet({ crossOriginResourcePolicy: false })); // allow loading local images on mobile devices
app.use(cors());
app.use(express.json());

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/auth',                      require('./routes/auth.routes'));
app.use('/trips',                     require('./routes/trip.routes'));
app.use('/trips/:id/itinerary',       require('./routes/itinerary.routes'));
app.use('/trips/:id/bookings',        require('./routes/booking.routes'));
app.use('/trips/:id/documents',       require('./routes/document.routes'));
app.use('/trips/:id/budget',          require('./routes/budget.routes'));
app.use('/trips',                     require('./routes/collaboration.routes'));
app.use('/itinerary',                 require('./routes/comment.routes'));
app.use('/trips/:id/journal',         require('./routes/journal.routes'));
app.use('/trips/:id/packing',         require('./routes/packing.routes'));

app.use('/weather',                   require('./routes/weather.routes'));
app.use('/currency',                  require('./routes/currency.routes'));
app.use('/timezone',                  require('./routes/timezone.routes'));
app.use('/trips/:id/share',           require('./routes/share.routes'));
app.use('/shares',                    require('./routes/publicShare.routes'));
app.use('/trips/:id/checklist/documents', require('./routes/documentChecklist.routes'));
app.use('/trips/:id/notes',           require('./routes/notes.routes'));
app.use('/trips/:id/photos',          require('./routes/photos.routes'));

app.use(errorHandler);

module.exports = app;
