const { v4: uuid } = require('uuid');
const repo = require('../repositories/budget.repository');

exports.getBudgets = (tripId) => repo.getBudgets(tripId);
exports.setBudgets = (tripId, categories) => {
  for (const [category, amount] of Object.entries(categories)) repo.upsertBudget(tripId, category, amount);
  return repo.getBudgets(tripId);
};

exports.getExpenses = (tripId) => repo.getExpenses(tripId);
exports.addExpense = (tripId, userId, data) => {
  const id = data.id || uuid(); // support client-provided UUID for offline dedup
  repo.createExpense({ id, trip_id: tripId, user_id: userId, ...data });
  return repo.getExpenses(tripId).find((e) => e.id === id);
};
exports.deleteExpense = (id) => repo.deleteExpense(id);
exports.getSummary = (tripId) => repo.getSummary(tripId);
