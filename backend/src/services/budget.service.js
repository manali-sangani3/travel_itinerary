const { v4: uuid } = require('uuid');
const repo = require('../repositories/budget.repository');

exports.getBudgets = (tripId) => {
  const breakdown = repo.getSummary(tripId);
  const plannedTotal = breakdown.reduce((sum, item) => sum + (item.planned || 0), 0);
  const actualTotal = breakdown.reduce((sum, item) => sum + (item.actual || 0), 0);
  
  const db = require('../db');
  const trip = db.prepare('SELECT home_currency FROM trips WHERE id = ?').get(tripId);
  const currency = trip ? (trip.home_currency || 'USD') : 'USD';

  return {
    plannedTotal,
    actualTotal,
    categoryBreakdown: breakdown,
    currency
  };
};
exports.setBudgets = (tripId, categories) => {
  for (const [category, amount] of Object.entries(categories)) repo.upsertBudget(tripId, category, amount);
  return exports.getBudgets(tripId);
};

exports.getExpenses = (tripId) => repo.getExpenses(tripId);
exports.addExpense = (tripId, userId, data) => {
  const id = data.id || uuid(); // support client-provided UUID for offline dedup
  repo.createExpense({ id, trip_id: tripId, user_id: userId, ...data });
  return repo.getExpenses(tripId).find((e) => e.id === id);
};
exports.deleteExpense = (id) => repo.deleteExpense(id);
exports.getSummary = (tripId) => repo.getSummary(tripId);

