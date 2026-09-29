#!/usr/bin/env bash

# DPIscord macOS Otomatik Kurulum Betiği
# Tek satır kurulum: bash <(curl -sSL https://raw.githubusercontent.com/alimali54/DPIscord/main/mac/install.sh | tr -d '\r')

echo "=============================================="
echo "          DPIscord macOS Installer            "
echo "=============================================="
echo ""

# --- 1. MİMARİ TESPİTİ ---
echo "[1/4] Sistem mimarisi tespit ediliyor..."
ARCH="$(uname -m)"
VERSION="v2.4"

if [ "$ARCH" = "arm64" ]; then
    echo "  [+] Apple Silicon (M serisi) mimarisi tespit edildi."
    RELEASE_FILE="DPIscord.${VERSION}-mac-arm64.zip"
else
    echo "  [+] Intel (x86_64) mimarisi tespit edildi."
    RELEASE_FILE="DPIscord.${VERSION}-mac-amd64.zip"
fi

DOWNLOAD_URL="https://github.com/alimali54/DPIscord/releases/download/${VERSION}/${RELEASE_FILE}"

# --- 2. İNDİRME ---
echo "[2/4] DPIscord dosyaları indiriliyor..."
INSTALL_DIR="$HOME/DPIscord"
mkdir -p "$INSTALL_DIR"
cd "$HOME" || exit 1

curl -fL --progress-bar -o "$RELEASE_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "[-] HATA: İndirme başarısız oldu! URL kontrol edin: $DOWNLOAD_URL"
    exit 1
fi

# --- 3. ZIP ÇIKARTMA ---
echo "[3/4] Dosyalar çıkartılıyor..."
unzip -q -o "$RELEASE_FILE" -d "$INSTALL_DIR"
rm -f "$RELEASE_FILE"

# --- 4. İZİNLER VE BAŞLATMA ---
echo "[4/4] İzinler yapılandırılıyor ve kurulum başlatılıyor..."

# DPIscord.sh dosyasının çıkartıldığı gerçek dizini bul
TARGET_SCRIPT=$(find "$INSTALL_DIR" -name "DPIscord.sh" | head -n 1)

if [ -z "$TARGET_SCRIPT" ]; then
    echo "[-] HATA: Çıkartılan dosyalar arasında DPIscord.sh bulunamadı!"
    exit 1
fi

TARGET_DIR="$(dirname "$TARGET_SCRIPT")"
cd "$TARGET_DIR" || exit 1

chmod +x DPIscord.sh 2>/dev/null
xattr -cr . 2>/dev/null

./DPIscord.sh
