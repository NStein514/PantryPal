// Minimal AI proxy for local development. Node 18+.
//   ANTHROPIC_API_KEY=sk-ant-... node tools/proxy.mjs
// Keeps your API key off the device. Add auth + rate limiting before deploying publicly.
import http from 'node:http';

http.createServer(async (req, res) => {
  if (req.method !== 'POST' || req.url !== '/v1/messages') { res.writeHead(404).end(); return; }
  let body = '';
  for await (const chunk of req) body += chunk;
  const upstream = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': process.env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body,
  });
  res.writeHead(upstream.status, { 'content-type': 'application/json' });
  res.end(await upstream.text());
}).listen(8787, () => console.log('PantryPal AI proxy on :8787'));
