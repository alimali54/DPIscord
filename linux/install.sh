#!/usr/bin/env bash

# --- BAĞIMLILIK KONTROLÜ ---
echo "[1/4] Paket yöneticisi ve unzip kontrolü yapılıyor..."
if ! command -v unzip >/dev/null; then
    if command -v pacman >/dev/null; then
        sudo pacman -Sy --noconfirm unzip
    elif command -v dnf >/dev/null; then
        sudo dnf install -y unzip
    else
        sudo apt-get update && sudo apt-get install -y unzip
    fi
fi

# --- İNDİRME VE ZIP AÇMA ---
echo "[2/4] DPIscord zip dosyası indiriliyor..."
wget -O DPIscord-linux.zip "https://github.com/alimali54/DPIscord/releases/download/v2.4/DPIscord.v2.4-linux.zip"

echo "[3/4] Dosyalar zipten çıkartılıyor..."
unzip -o DPIscord-linux.zip
rm -f DPIscord-linux.zip

# --- KURULUMU TETİKLEME ---
echo "[4/4] Klasöre giriliyor ve script başlatılıyor..."

# DPIscord.sh dosyasını nerede olursa olsun bulup o dizine geçer
TARGET_SCRIPT=$(find . -name "DPIscord.sh" | head -n 1)

if [ -z "$TARGET_SCRIPT" ]; then
    echo "HATA: DPIscord.sh bulunamadı!"
    exit 1
fi

cd "$(dirname "$TARGET_SCRIPT")" || exit 1
chmod +x DPIscord.sh uninstall.sh 2>/dev/null
./DPIscord.sh
