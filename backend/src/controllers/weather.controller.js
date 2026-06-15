const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.getForecast = wrap(async (req, res) => {
  const { destination, date } = req.params;
  // Basic mock weather forecast based on destination name length and date
  const hash = (destination.length + new Date(date).getDate()) % 5;
  const conditions = ['Sunny', 'Cloudy', 'Rainy', 'Windy', 'Snowy'];
  const temps = [28, 20, 15, 18, -2];
  const precips = [5, 20, 80, 15, 90];

  res.json({
    temp: temps[hash],
    condition: conditions[hash],
    precipitation: precips[hash]
  });
});
