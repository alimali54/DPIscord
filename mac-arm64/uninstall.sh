#!/usr/bin/env bash

# DPIscord macOS - Kaldırıcı
# Karakter kodlaması UTF-8 olarak varsayılır.

# --- TERMİNAL KONTROLÜ (macOS Çift Tıklama Düzeltmesi) ---
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
if [ ! -t 0 ]; then
    osascript -e "tell application \"Terminal\"" -e "activate" -e "do script \"bash \\\"$SCRIPT_PATH\\\"\"" -e "end tell"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================================="
echo " [+] DPIscord macOS Kaldırılıyor..."
echo "=============================================================="
echo ""

# --- SÜREÇLERİ SONLANDIR ---
echo "[1] Arka plan işlemleri ve Discord durduruluyor..."

killall -9 Discord >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  [+] Discord başarıyla durduruldu."
else
    echo "  [-] Discord çalışmıyor veya zaten durdurulmuş."
fi

pkill -9 -f "sing-box" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  [+] sing-box başarıyla durduruldu."
else
    echo "  [-] sing-box çalışmıyor veya zaten durdurulmuş."
fi

pkill -9 -f "ciadpi" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  [+] ciadpi başarıyla durduruldu."
else
    echo "  [-] ciadpi çalışmıyor veya zaten durdurulmuş."
fi
echo ""

# --- KISAYOLLARI VE BAŞLATICILARI TEMİZLE ---
echo "[2] Kısayollar ve başlatıcı dosyalar temizleniyor..."

# Masaüstü ve Uygulamalar Klasöründeki .app Dosyalarını Sil
rm -rf "$HOME/Desktop/Discord (DPI).app"
rm -rf "/Applications/Discord (DPI).app"
echo "  [+] Masaüstü ve Launchpad (Applications) kısayolları silindi."

# Script Tarafından Oluşturulan Başlatıcıyı Sil
rm -f "$SCRIPT_DIR/dpiscord_run.sh"
echo "  [+] DPIscord yerel başlatıcı scripti (run.sh) silindi."
echo ""

# --- BAŞLANGIÇ (STARTUP) TEMİZLİĞİ ---
echo "[3] Başlangıç (Login Items) ayarları temizleniyor..."
# AppleScript ile Mac Login Items listesinden Discord DPI'ı siliyoruz
osascript -e 'tell application "System Events" to delete login item "Discord (DPI)"' >/dev/null 2>&1
echo "  [+] Mac Oturum Açma Öğelerinden (Startup) kaldırıldı."
echo ""

# --- SONLANDIRMA UYARISI ---
echo "=============================================================="
echo " [+] İŞLEM TAMAMLANDI."
echo " DPIscord macOS eklentileri sistemden tamamen temizlendi."
echo ""
echo " Şu anda bulunduğunuz bu klasörü (ve içindekileri) artık"
echo " güvenle silebilirsiniz."
echo "=============================================================="
echo ""
read -p "Çıkmak için ENTER'a basın..."