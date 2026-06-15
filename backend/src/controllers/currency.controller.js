const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

const RATES = {
  USD: 1.0,
  INR: 83.0,
  EUR: 0.92,
  GBP: 0.79,
  AUD: 1.50,
  CAD: 1.36,
  JPY: 155.0
};

exports.convert = wrap(async (req, res) => {
  const base = (req.query.base || 'USD').toUpperCase();
  const target = (req.query.target || 'INR').toUpperCase();
  const amount = parseFloat(req.query.amount || 1);

  const baseRate = RATES[base] || 1.0;
  const targetRate = RATES[target] || 1.0;

  // conversion formula: amount * (targetRate / baseRate)
  const rate = targetRate / baseRate;
  const convertedAmount = amount * rate;

  res.json({
    amount: convertedAmount,
    rate: rate,
    timestamp: new Date().toISOString()
  });
});
