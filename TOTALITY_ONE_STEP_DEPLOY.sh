#!/data/data/com.termux/files/usr/bin/bash
# ===========================================================
# TOTALITY ONE-STEP DEPLOY SCRIPT
# For new devices — verifies checksum, extracts, builds, and launches
# ===========================================================

echo
echo "🚀 TOTALITY — ONE-STEP DEPLOY"
echo

# 1️⃣ Ensure Termux storage and wake-lock
termux-setup-storage >/dev/null 2>&1 || true
termux-wake-lock
echo "🔹 Storage and wake-lock ready"

# 2️⃣ Check dependencies and install if missing
for pkg_name in python git wget curl unzip redis termux-api flutter rsync; do
    if ! command -v $pkg_name >/dev/null 2>&1; then
        echo "🔹 Installing missing package: $pkg_name"
        pkg install -y $pkg_name
    fi
done

# 3️⃣ Verify SHA256 checksum
if [ -f TOTALITY_RELEASE_PACKAGE.tar.gz ] && [ -f TOTALITY_RELEASE_PACKAGE.sha256 ]; then
    echo "🔹 Verifying SHA256 checksum..."
    sha256sum -c TOTALITY_RELEASE_PACKAGE.sha256
    if [ $? -ne 0 ]; then
        echo "❌ Checksum mismatch! Aborting deployment."
        exit 1
    fi
else
    echo "❌ TAR package or checksum not found in current folder. Place both and rerun."
    exit 1
fi

# 4️⃣ Extract package
echo "🔹 Extracting TOTALITY release..."
mkdir -p ~/TOTALITY_RELEASE_BUILD
tar -xzvf TOTALITY_RELEASE_PACKAGE.tar.gz -C ~/TOTALITY_RELEASE_BUILD

# 5️⃣ Fix permissions
chmod -R +x ~/TOTALITY_RELEASE_BUILD

# 6️⃣ Run master release script
MASTER_SCRIPT=~/TOTALITY_RELEASE_BUILD/TOTALITY_MASTER_RELEASE.sh
if [ -f "$MASTER_SCRIPT" ]; then
    echo "🔹 Launching TOTALITY..."
    nohup bash "$MASTER_SCRIPT" >/dev/null 2>&1 &
    echo "✅ TOTALITY launched successfully!"
else
    echo "❌ Master release script not found. Deployment failed."
    exit 1
fi

# 7️⃣ Summary
echo
echo "📦 TOTALITY is now live!"
echo "Logs: ~/TOTALITY_RELEASE_BUILD/logs/"
echo "Flutter APK: ~/TOTALITY_RELEASE_BUILD/app/build/app/outputs/flutter-apk/app-release.apk"
echo "PDF docs: ~/TOTALITY_RELEASE_BUILD/TOTALITY_FULL_BUILD.pdf"
echo
echo "💡 Use 'pkill -f python; pkill -f celery; pkill -f redis-server' to stop all processes"
