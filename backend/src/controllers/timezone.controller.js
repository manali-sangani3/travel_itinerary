const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function getOffsetMinutes(timeZone) {
  try {
    const date = new Date();
    const utcStr = date.toLocaleString('en-US', { timeZone: 'UTC', timeZoneName: 'longOffset' });
    const tzStr = date.toLocaleString('en-US', { timeZone, timeZoneName: 'longOffset' });
    
    const parseOffset = (str) => {
      const match = str.match(/GMT([+-])(\d+):?(\d+)?/);
      if (!match) return 0;
      const sign = match[1] === '+' ? 1 : -1;
      const hours = parseInt(match[2], 10);
      const minutes = match[3] ? parseInt(match[3], 10) : 0;
      return sign * (hours * 60 + minutes);
    };

    return parseOffset(tzStr);
  } catch (e) {
    return 0;
  }
}

function getLocalTime(timeZone) {
  try {
    return new Date().toLocaleString('en-US', { timeZone });
  } catch (e) {
    return new Date().toLocaleString();
  }
}

exports.getDiff = wrap(async (req, res) => {
  const fromZone = req.query.from || 'UTC';
  const toZone = req.query.to || 'Asia/Kolkata';

  const fromOffset = getOffsetMinutes(fromZone);
  const toOffset = getOffsetMinutes(toZone);
  const offsetDiff = (toOffset - fromOffset) / 60; // in hours

  res.json({
    offsetDiff: offsetDiff,
    fromLocalTime: getLocalTime(fromZone),
    toLocalTime: getLocalTime(toZone),
    fromDst: false,
    toDst: false
  });
});
