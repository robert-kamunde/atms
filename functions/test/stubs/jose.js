/* Test-only stand-in for the ESM-only `jose` package (see jest.config.js integration project). */
const unavailable = () => {
  throw new Error('jose is stubbed in integration tests: token verification is not available');
};
module.exports = new Proxy({}, { get: (_t, key) => (key === '__esModule' ? false : unavailable) });
