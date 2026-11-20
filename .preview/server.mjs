import http from "node:http";

const port = Number(process.env.PORT) || 3000;

const html = `<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>iorg — Godot 4.7</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #0f172a;
      color: #f8fafc;
      font-family: system-ui, -apple-system, sans-serif;
      text-align: center;
      padding: 24px;
    }
    .card {
      max-width: 520px;
      background: #1e293b;
      border: 1px solid rgba(34, 211, 238, 0.45);
      border-radius: 12px;
      padding: 24px 28px;
    }
    h1 { margin: 0 0 8px; color: #22d3ee; font-size: 28px; }
    p { margin: 8px 0; line-height: 1.5; color: #cbd5e1; }
    code {
      display: inline-block;
      margin-top: 8px;
      padding: 6px 12px;
      background: #0f172a;
      border-radius: 6px;
      color: #f59e0b;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>IORG</h1>
    <p>Нативный проект на <strong>Godot 4.7</strong> (GDScript). Заглушка превью активна только для среды.</p>
    <code>godot --path .</code>
  </div>
</body>
</html>`;

const server = http.createServer((_req, res) => {
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(html);
});

server.listen(port, "0.0.0.0", () => {
  console.log(`Preview stub listening on http://0.0.0.0:${port}`);
});
