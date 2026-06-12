const db = require('../db');

exports.getBudgets = (tripId) => db.prepare('SELECT * FROM budgets WHERE trip_id = ?').all(tripId);
exports.upsertBudget = (tripId, category, amount) =>
  db.prepare('INSERT INTO budgets (id, trip_id, category, amount) VALUES (?, ?, ?, ?) ON CONFLICT(trip_id, category) DO UPDATE SET amount = excluded.amount')
    .run(require('crypto').randomUUID(), tripId, category, amount);

exports.getExpenses = (tripId) => db.prepare('SELECT * FROM expenses WHERE trip_id = ?').all(tripId);
exports.createExpense = (e) => db.prepare('INSERT INTO expenses (id, trip_id, user_id, category, amount, currency, note) VALUES (@id, @trip_id, @user_id, @category, @amount, @currency, @note)').run(e);
exports.deleteExpense = (id) => db.prepare('DELETE FROM expenses WHERE id = ?').run(id);

exports.getSummary = (tripId) => {
  const budgets = db.prepare('SELECT category, amount as planned FROM budgets WHERE trip_id = ?').all(tripId);
  const expenses = db.prepare('SELECT category, SUM(amount) as actual FROM expenses WHERE trip_id = ? GROUP BY category').all(tripId);
  const expMap = Object.fromEntries(expenses.map((e) => [e.category, e.actual]));
  return budgets.map((b) => ({ ...b, actual: expMap[b.category] || 0 }));
};
