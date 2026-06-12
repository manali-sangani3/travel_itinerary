require('./db/schema'); // init tables

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const errorHandler = require('./middleware/error');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use('/auth',                   require('./routes/auth.routes'));
app.use('/trips',                  require('./routes/trip.routes'));
app.use('/trips/:id/itinerary',    require('./routes/itinerary.routes'));
app.use('/trips/:id/bookings',     require('./routes/booking.routes'));
app.use('/trips/:id/documents',    require('./routes/document.routes'));
app.use('/trips/:id/budget',       require('./routes/budget.routes'));
app.use('/trips',                  require('./routes/collaboration.routes'));
app.use('/itinerary',              require('./routes/comment.routes'));
app.use('/trips/:id/journal',      require('./routes/journal.routes'));
app.use('/trips/:id/packing',      require('./routes/packing.routes'));

app.use(errorHandler);

module.exports = app;
