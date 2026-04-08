const http = require('http');

const port = process.env.PORT || 3000;

const req = http.get(
  {
    host: '127.0.0.1',
    port,
    path: '/healthcheck',
  },
  (res) => {
    process.exit(res.statusCode === 200 ? 0 : 1);
  }
);

req.on('error', () => {
  process.exit(1);
});