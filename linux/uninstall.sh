#!/usr/bin/env bash

# DPIscord Linux - Kaldırıcı
# Karakter kodlaması UTF-8 olarak varsayılır.

# --- TERMİNAL KONTROLÜ (Çift Tıklama Düzeltmesi) ---
# Script bir terminal (TTY) içinde çalışmıyorsa, kendini bir terminal ile yeniden başlatır.
if [ ! -t 0 ]; then
    if command -v x-terminal-emulator &>/dev/null; then
        exec x-terminal-emulator -e bash "$0" "$@"
    elif command -v gnome-terminal &>/dev/null; then
        exec gnome-terminal -- bash "$0" "$@"
    elif command -v konsole &>/dev/null; then
        exec konsole -e bash "$0" "$@"
    elif command -v xfce4-terminal &>/dev/null; then
        exec xfce4-terminal -e bash "$0" "$@"
    elif command -v mate-terminal &>/dev/null; then
        exec mate-terminal -e bash "$0" "$@"
    elif command -v lxterminal &>/dev/null; then
        exec lxterminal -e bash "$0" "$@"
    elif command -v xterm &>/dev/null; then
        exec xterm -e bash "$0" "$@"
    else
        # Hiçbir terminal bulunamazsa hata kaydı bırakıp çık
        echo "Terminal bulunamadı. Lütfen scripti terminal üzerinden çalıştırın." > "$HOME/dpiscord_error.log"
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================================="
echo " [+] DPIscord Kaldırılıyor..."
echo "=============================================================="
echo ""

# --- SÜREÇLERİ SONLANDIR ---
echo "[1] Arka plan işlemleri ve uygulamalar durduruluyor..."

# Discord'u kapat
killall -9 discord Discord discord-ptb DiscordPTB >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  [+] Discord başarıyla durduruldu."
else
    echo "  [-] Discord çalışmıyor veya zaten durdurulmuş."
fi

# Sober'i (Roblox) kapat
if command -v flatpak &> /dev/null; then
    flatpak kill org.vinegarhq.Sober >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "  [+] Sober (Roblox) başarıyla durduruldu."
    fi
fi

# Tünel uygulamalarını kapat
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

# Masaüstü Yolunu Bul
DESKTOP_DIR=""
if command -v xdg-user-dir &> /dev/null; then
    DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
fi
if [ -z "$DESKTOP_DIR" ] && [ -f "$HOME/.config/user-dirs.dirs" ]; then
    DESKTOP_DIR_RAW=$(grep "XDG_DESKTOP_DIR" "$HOME/.config/user-dirs.dirs" | cut -d'"' -f2)
    DESKTOP_DIR="${DESKTOP_DIR_RAW/\$HOME/$HOME}"
fi
if [ -z "$DESKTOP_DIR" ] || [ ! -d "$DESKTOP_DIR" ]; then
    if [ -d "$HOME/Masaüstü" ]; then
        DESKTOP_DIR="$HOME/Masaüstü"
    elif [ -d "$HOME/Desktop" ]; then
        DESKTOP_DIR="$HOME/Desktop"
    else
        DESKTOP_DIR="$HOME"
    fi
fi

# Masaüstü Kısayolları
rm -f "$DESKTOP_DIR/discord-dpi.desktop"
rm -f "$DESKTOP_DIR/sober-dpi.desktop"
echo "  [+] Masaüstü kısayolları silindi."

# Uygulamalar Menüsü (Applications) Kısayolları
rm -f "$HOME/.local/share/applications/discord-dpi.desktop"
rm -f "$HOME/.local/share/applications/sober-dpi.desktop"
echo "  [+] Sistem menüsü (Uygulamalar) kısayolları silindi."

# Başlangıç (Startup) Kısayolları
rm -f "$HOME/.config/autostart/discord-dpi.desktop"
rm -f "$HOME/.config/autostart/sober-dpi.desktop"
echo "  [+] Başlangıç (Startup) kısayolları silindi."

# Script Tarafından Oluşturulan Başlatıcılar
rm -f "$SCRIPT_DIR/dpiscord_run.sh"
rm -f "$SCRIPT_DIR/sober_dpi_run.sh"
echo "  [+] DPIscord yerel başlatıcı scriptleri (run.sh) silindi."
echo ""

# --- SONLANDIRMA UYARISI ---
echo "=============================================================="
echo " [+] İŞLEM TAMAMLANDI."
echo " DPIscord eklentileri sistemden tamamen temizlendi."
echo ""
echo " Şu anda bulunduğunuz bu klasörü (ve içindekileri) artık"
echo " güvenle silebilirsiniz."
echo "=============================================================="
echo ""
read -p "Çıkmak için ENTER'a basın..."
