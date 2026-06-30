#!/usr/bin/env node
// Minimal HTTP CONNECT proxy for testing WKWebView proxyConfigurations.
//
// It logs every request that flows through it, so you can confirm whether a
// given WKWebView is actually using the proxy or silently bypassing it.
//
//   node proxy.js            # listens on 0.0.0.0:9090
//   PORT=8888 node proxy.js  # custom port
//
// In WKWebView use httpCONNECTProxy pointing at this host:port.
// On a simulator use 127.0.0.1; on a real device use your Mac's LAN IP.

const http = require('http');
const net = require('net');
const { URL } = require('url');

const PORT = parseInt(process.env.PORT || '9090', 10);
const HOST = process.env.HOST || '0.0.0.0';

const ts = () => new Date().toISOString().slice(11, 23);
const log = (...a) => console.log(`[${ts()}]`, ...a);

const server = http.createServer((req, res) => {
  // Plain HTTP request proxied through us (absolute-form request URL).
  log('HTTP   ', req.method, req.url);
  let target;
  try {
    target = new URL(req.url);
  } catch {
    res.writeHead(400);
    res.end('bad request url (proxy expects absolute URL)');
    return;
  }

  const proxyReq = http.request(
    {
      hostname: target.hostname,
      port: target.port || 80,
      path: target.pathname + target.search,
      method: req.method,
      headers: req.headers,
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(res);
    }
  );
  proxyReq.on('error', (err) => {
    log('HTTP ERR', target.host, err.message);
    res.writeHead(502);
    res.end('upstream error: ' + err.message);
  });
  req.pipe(proxyReq);
});

// HTTPS tunneling via CONNECT — this is what httpCONNECTProxy uses.
server.on('connect', (req, clientSocket, head) => {
  const [host, portStr] = req.url.split(':');
  const port = parseInt(portStr || '443', 10);
  log('CONNECT', `${host}:${port}`);

  const upstream = net.connect(port, host, () => {
    clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
    upstream.write(head);
    upstream.pipe(clientSocket);
    clientSocket.pipe(upstream);
  });

  upstream.on('error', (err) => {
    log('CONNECT ERR', `${host}:${port}`, err.message);
    clientSocket.end('HTTP/1.1 502 Bad Gateway\r\n\r\n');
  });
  clientSocket.on('error', () => upstream.destroy());
});

server.on('clientError', (err, socket) => {
  if (socket.writable) socket.end('HTTP/1.1 400 Bad Request\r\n\r\n');
});

server.listen(PORT, HOST, () => {
  log(`proxy listening on ${HOST}:${PORT}`);
  log('point WKWebView httpCONNECTProxy here; every request is logged below');
});
