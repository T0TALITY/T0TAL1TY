module.exports = {
  apps: [
    {
      name: "codex-webhook-handler",
      script: "server.js",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      max_memory_restart: "256M",
      env: {
        NODE_ENV: "production",
        PORT: 5000,
        WEBHOOK_PATH: "/codex-webhook"
      }
    }
  ]
};
