#!/usr/bin/env bash
# ─────────────────────────────────────────────
# T0TAL1TY MEGA DEPLOY
# Cross-platform bootstrap (Termux + Linux)
# ─────────────────────────────────────────────

set -euo pipefail

log() { printf '[→] %s\n' "$1"; }
warn() { printf '[!] %s\n' "$1"; }

log "Launching T0TAL1TY Mega Deploy..."

if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
  warn "Python is not installed yet; dependency setup will attempt to install it."
fi

detect_pkg_manager() {
  for pm in pkg apt-get apt dnf yum pacman apk; do
    if command -v "$pm" >/dev/null 2>&1; then
      echo "$pm"
      return
    fi
  done
  echo ""
}

install_base_deps() {
  local pm
  pm="$(detect_pkg_manager)"

  case "$pm" in
    pkg)
      log "Detected Termux package manager (pkg)."
      pkg update -y
      pkg upgrade -y
      pkg install -y python git wget nano openssl curl tar unzip rsync
      ;;
    apt|apt-get)
      log "Detected apt package manager."
      if command -v sudo >/dev/null 2>&1; then
        sudo "$pm" update
        sudo "$pm" upgrade -y
        sudo "$pm" install -y python3 python3-pip git wget nano openssl curl tar unzip rsync
      else
        "$pm" update
        "$pm" upgrade -y
        "$pm" install -y python3 python3-pip git wget nano openssl curl tar unzip rsync
      fi
      ;;
    dnf|yum)
      log "Detected $pm package manager."
      if command -v sudo >/dev/null 2>&1; then
        sudo "$pm" install -y python3 python3-pip git wget nano openssl curl tar unzip rsync
      else
        "$pm" install -y python3 python3-pip git wget nano openssl curl tar unzip rsync
      fi
      ;;
    pacman)
      log "Detected pacman package manager."
      if command -v sudo >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm python python-pip git wget nano openssl curl tar unzip rsync
      else
        pacman -Sy --noconfirm python python-pip git wget nano openssl curl tar unzip rsync
      fi
      ;;
    apk)
      log "Detected apk package manager."
      if command -v sudo >/dev/null 2>&1; then
        sudo apk add --no-cache python3 py3-pip git wget nano openssl curl tar unzip rsync
      else
        apk add --no-cache python3 py3-pip git wget nano openssl curl tar unzip rsync
      fi
      ;;
    *)
      warn "No supported package manager found (pkg/apt/dnf/yum/pacman/apk)."
      ;;
  esac
}

install_python_deps() {
  local -a pip_cmd
  local py_bin="python3"
  if ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
    py_bin="python"
  fi

  if command -v pip3 >/dev/null 2>&1; then
    pip_cmd=(pip3)
  elif command -v pip >/dev/null 2>&1; then
    pip_cmd=(pip)
  else
    warn "pip not found. Attempting $py_bin -m ensurepip."
    "$py_bin" -m ensurepip --upgrade || true
    pip_cmd=($py_bin -m pip)
  fi
  log "Installing Python packages..."
  "${pip_cmd[@]}" install --upgrade pip
  "${pip_cmd[@]}" install flask web3 cryptography python-dotenv reportlab pandas matplotlib
}

write_env_file() {
  local env_file="$HOME/.t0tal1ty_env"
  if [[ -f "$env_file" ]]; then
    warn "Existing ~/.t0tal1ty_env found; leaving it in place."
    return
  fi

  cat > "$env_file" <<ENV
WALLET_ADDRESS=0xaDdA355265aEe4776D45f3F2f18f0c8396A7f14C
ENCRYPTED_KEY_FILE=$HOME/totality_termux/ai_models/totality_llm/wallet.enc
ETHEREUM_RPC=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
POLYGON_RPC=https://polygon-rpc.com
ARBITRUM_RPC=https://arb1.arbitrum.io/rpc
ENV
  chmod 600 "$env_file"
  log "Created $env_file"
}

deploy_node() {
  local node_path="$1"
  mkdir -p "$node_path"/{ai_models/totality_llm/datasets,config,dashboard,reports,logs,scripts}

  printf 'ALL_ACADEMIC_WORKS\n' > "$node_path/ai_models/totality_llm/datasets/academic.txt"
  printf 'ALL_OFFICIAL_WORKS\n' > "$node_path/ai_models/totality_llm/datasets/official.txt"
  printf 'ALL_CODING_PROJECTS\n' > "$node_path/ai_models/totality_llm/datasets/coding.txt"

  cat > "$node_path/config/chains.json" <<'JSON'
{
  "ethereum_mainnet": {"rpc": "https://mainnet.infura.io/v3/YOUR_INFURA_KEY", "chain_id": 1},
  "polygon_mainnet": {"rpc": "https://polygon-rpc.com", "chain_id": 137},
  "arbitrum_mainnet": {"rpc": "https://arb1.arbitrum.io/rpc", "chain_id": 42161}
}
JSON

  if [[ ! -f "$node_path/ai_models/totality_llm/wallet.enc" ]]; then
    printf 'encrypted_wallet_key\n' > "$node_path/ai_models/totality_llm/wallet.enc"
  fi
}

write_python_launcher() {
cat > global_ai_smart.py <<'PYEOF'
#!/usr/bin/env python3
import os
import subprocess
import threading
import time
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.pdfgen import canvas
from web3 import Web3

app = Flask(__name__)
load_dotenv(Path.home() / ".t0tal1ty_env")

BASE_PATH = Path.home() / "totality_termux"
REPORT_PATH = BASE_PATH / "reports" / "Totality_Report_Smart.pdf"
REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)

NODES = [{"name": "Node1", "path": str(BASE_PATH)}]
NODE_STATUS = {}
DATA_LOG = pd.DataFrame(columns=["timestamp", "node", "chain", "balance", "queries", "tx_sent"])

CHAINS = {
    "ethereum_mainnet": {"rpc": os.getenv("ETHEREUM_RPC", ""), "chain_id": 1},
    "polygon_mainnet": {"rpc": os.getenv("POLYGON_RPC", ""), "chain_id": 137},
    "arbitrum_mainnet": {"rpc": os.getenv("ARBITRUM_RPC", ""), "chain_id": 42161},
}
WEB3_INSTANCES = {
    chain: Web3(Web3.HTTPProvider(cfg["rpc"]))
    for chain, cfg in CHAINS.items()
    if cfg["rpc"]
}


def decrypt_wallet(enc_path: str, passphrase: str) -> str:
    if not enc_path or not Path(enc_path).expanduser().exists():
        return ""
    cmd = [
        "openssl",
        "aes-256-cbc",
        "-d",
        "-in",
        str(Path(enc_path).expanduser()),
        "-pass",
        f"pass:{passphrase}",
    ]
    return subprocess.check_output(cmd, text=True).strip()


def monitor_nodes() -> None:
    global DATA_LOG
    while True:
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        for node in NODES:
            balances = {}
            for chain_name, web3_inst in WEB3_INSTANCES.items():
                try:
                    raw_balance = web3_inst.eth.get_balance(os.getenv("WALLET_ADDRESS"))
                    balance_eth = float(web3_inst.from_wei(raw_balance, "ether"))
                    balances[chain_name] = balance_eth
                except Exception:
                    balances[chain_name] = 0.0

                DATA_LOG = pd.concat(
                    [
                        DATA_LOG,
                        pd.DataFrame(
                            [
                                {
                                    "timestamp": timestamp,
                                    "node": node["name"],
                                    "chain": chain_name,
                                    "balance": balances[chain_name],
                                    "queries": 0,
                                    "tx_sent": 0,
                                }
                            ]
                        ),
                    ],
                    ignore_index=True,
                )
            NODE_STATUS[node["name"]] = {
                "AI_status": "active",
                "LLM_loaded": True,
                "last_report": timestamp,
                "multi_chain_balance": balances,
            }
        time.sleep(10)


@app.route("/api/query", methods=["POST"])
def query_llm():
    global DATA_LOG
    payload = request.get_json(silent=True) or {}
    query = payload.get("query", "")
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

    for node in NODES:
        DATA_LOG = pd.concat(
            [
                DATA_LOG,
                pd.DataFrame(
                    [
                        {
                            "timestamp": timestamp,
                            "node": node["name"],
                            "chain": "LLM",
                            "balance": 0,
                            "queries": 1,
                            "tx_sent": 0,
                        }
                    ]
                ),
            ],
            ignore_index=True,
        )

    return jsonify({"result": f"LLM Response: '{query}'"})


@app.route("/api/nodes")
def api_nodes():
    return jsonify(NODE_STATUS)


@app.route("/")
def index():
    return """
<!DOCTYPE html>
<html>
<head><title>T0TAL1TY Mega Dashboard</title><script src="https://cdn.jsdelivr.net/npm/chart.js"></script></head>
<body>
<h1>T0TAL1TY Live Dashboard</h1>
<canvas id="balanceChart" width="800" height="400"></canvas>
<input type="text" id="queryBox" placeholder="Ask LLM">
<button onclick="submitQuery()">Query LLM</button>
<p id="queryResult"></p>
<script>
let chart;
async function updateChart(){
    const res = await fetch('/api/nodes');
    const data = await res.json();
    const labels = Object.keys(data);
    const balances = labels.map(n=>Object.values(data[n].multi_chain_balance || {}).reduce((a,b)=>a+b,0));
    const ctx = document.getElementById('balanceChart').getContext('2d');
    if (chart) chart.destroy();
    chart = new Chart(ctx,{type:'bar',data:{labels:labels,datasets:[{label:'Aggregate Balance (ETH)',data:balances,backgroundColor:'lime'}]}});
}
setInterval(updateChart,5000);
updateChart();
async function submitQuery(){
    const q = document.getElementById('queryBox').value;
    const res = await fetch('/api/query',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({query:q})});
    const json = await res.json();
    document.getElementById('queryResult').innerText = json.result;
}
</script>
</body>
</html>
"""


def generate_pdf_reports() -> None:
    global DATA_LOG
    while True:
        pdf = canvas.Canvas(str(REPORT_PATH), pagesize=A4)
        width, height = A4
        pdf.setFont("Helvetica-Bold", 18)
        pdf.drawCentredString(width / 2, height - 2 * cm, "T0TAL1TY Live Throughput + Smart Contract Report")
        pdf.setFont("Helvetica", 10)
        y = height - 3.5 * cm

        for _, row in DATA_LOG.tail(50).iterrows():
            line = f"{row['timestamp']} | {row['node']} | {row['chain']} | Balance: {row['balance']} | Queries: {row['queries']} | Tx: {row['tx_sent']}"
            pdf.drawString(1.5 * cm, y, line[:130])
            y -= 0.65 * cm
            if y < 2 * cm:
                pdf.showPage()
                pdf.setFont("Helvetica", 10)
                y = height - 2 * cm

        pdf.save()
        time.sleep(60)


if __name__ == "__main__":
    encrypted_key_file = os.getenv("ENCRYPTED_KEY_FILE", "")
    wallet_passphrase = os.getenv("WALLET_PASSPHRASE", "")
    if not wallet_passphrase:
        try:
            wallet_passphrase = input("Wallet passphrase for deploy (optional): ").strip()
        except EOFError:
            wallet_passphrase = ""
    if wallet_passphrase and encrypted_key_file:
        try:
            decrypt_wallet(encrypted_key_file, wallet_passphrase)
            print("Wallet key decrypt check: OK")
        except Exception as exc:
            print(f"Wallet key decrypt check failed: {exc}")

    threading.Thread(target=monitor_nodes, daemon=True).start()
    threading.Thread(target=generate_pdf_reports, daemon=True).start()
    app.run(host="0.0.0.0", port=5000)
PYEOF
chmod +x global_ai_smart.py
}

install_base_deps
install_python_deps
write_env_file

deploy_node "$HOME/totality_termux"
write_python_launcher

log "Starting global_ai_smart.py"
python3 global_ai_smart.py || python global_ai_smart.py
