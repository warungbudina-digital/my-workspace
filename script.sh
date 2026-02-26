#!/bin/bash

echo "🔧 Menyetel parameter sistem..."
sudo sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "🔍 Verifikasi BBR..."
lsmod | grep bbr
sysctl net.ipv4.tcp_congestion_control
echo 3 | sudo tee /proc/sys/net/ipv4/tcp_fastopen

echo "📦 Install tools pendukung (htop, jq)..."
sudo apt update
sudo apt install -y htop jq

echo "⬇️ Install rclone..."
curl https://rclone.org/install.sh | sudo bash

# ========================
# Bagian: RCLONE CONF
# ========================
REMOTE_NAME="gdrive"
TOKEN_FILE="./token.json"
RCLONE_CONF_PATH="$HOME/.config/rclone/rclone.conf"
DEST_FOLDER="$(pwd)"
GDRIVE_FOLDER="Project-Tutorial/layer-miner/layer-bot"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "❌ File token.json tidak ditemukan di path: $TOKEN_FILE"
  exit 1
fi

echo "⚙️ Menyiapkan rclone.conf..."
mkdir -p "$(dirname "$RCLONE_CONF_PATH")"
TOKEN=$(jq -c . "$TOKEN_FILE")

cat > "$RCLONE_CONF_PATH" <<EOF
[$REMOTE_NAME]
type = drive
scope = drive
token = $TOKEN
EOF

echo "✅ rclone.conf berhasil dibuat."

echo "📁 Menyalin file layer-miner dari Drive ke $DEST_FOLDER ..."
rclone copy --config="$RCLONE_CONF_PATH" "$REMOTE_NAME:$GDRIVE_FOLDER" "$DEST_FOLDER" --progress

# ========================
# Bagian: DOCKER & CHROMIUM
# ========================
echo "🐳 Menyiapkan kontainer Chromium..."

docker load -i chromium-stable.tar
sudo tar -xzvf chromium-data.tar.gz -C ~/
#sudo tar -xzvf chromium-data.tar.gz -C ~/

docker run -d \
  --name chromium-node \
  -v ~/chromium-data:/config \
  -p 3040:3040 \
  chromium-stable:latest

echo "🧹 Membersihkan file yang tidak dibutuhkan..."
sudo rm -f chromium-stable.tar
sudo rm -f chromium-data.tar.gz
#sudo rm -f chromium-data.tar.gz
#sudo rm -f chromium-data-ori2.tar.gz
#sudo rm -f chromium-data-single.tar.gz

echo "✅ Selesai setup. Memulai penambangan..."

# ========================
# Bagian: Ping agar Cloud Shell tetap aktif
# ========================
ping 8.8.8.8
