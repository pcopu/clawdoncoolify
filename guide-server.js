const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const PORT = Number.parseInt(process.env.CLAWDBOT_GATEWAY_PORT || "18789", 10);
const GUIDE_PATH = process.env.CLAWDBOT_GUIDE_PATH || "/usr/local/share/clawd-guide/index.html";

const authChoice = process.env.CLAWDBOT_AUTH_CHOICE || "";
const missingReason = process.env.CLAWDBOT_MISSING_REASON || "Provider key missing";

function renderTemplate(template) {
  return template
    .replace(/{{AUTH_CHOICE}}/g, authChoice || "(auto)")
    .replace(/{{MISSING_REASON}}/g, missingReason);
}

const server = http.createServer((req, res) => {
  if (req.url && req.url.startsWith("/health")) {
    res.writeHead(200, { "content-type": "application/json" });
    res.end(JSON.stringify({ status: "setup-required" }));
    return;
  }

  let html = "";
  try {
    const template = fs.readFileSync(GUIDE_PATH, "utf8");
    html = renderTemplate(template);
  } catch (err) {
    html = `<!doctype html><html><body><h1>Setup required</h1><p>${missingReason}</p></body></html>`;
  }

  res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  res.end(html);
});

server.listen(PORT, "0.0.0.0", () => {
  // eslint-disable-next-line no-console
  console.log(`Setup guide available on port ${PORT}.`);
});
