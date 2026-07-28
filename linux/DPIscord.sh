#!/usr/bin/env bash

# DPIscord Linux Port (Discord & Sober Destekli, Akıllı Kısayollar)
# Karakter kodlaması UTF-8 olarak varsayılır.

# --- DİZİN VE YAPILANDIRMA ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DPI_SUBDIR="$SCRIPT_DIR/byedpi"
STRATEGY_FILE="$DPI_SUBDIR/strategies.txt"
CIADPI_BIN="$DPI_SUBDIR/ciadpi"
SINGBOX_BIN="$DPI_SUBDIR/sing-box"
SINGBOX_CONFIG="$DPI_SUBDIR/sing-box.json"
CURL_BIN="$DPI_SUBDIR/curl"
TEST_URL="https://updates.discord.com"
PORT=8848
SING_PORT=8849

echo "=============================================="
echo "            DPIscord Linux v2.2               "
echo "=============================================="

# --- YÜKLÜ UYGULAMALARI KONTROL ET ---
echo "[+] Sistemdeki uygulamalar taranıyor..."
DISCORD_CMD=""
SOBER_CMD=""

sleep 1

# 1. Discord Kontrolü
if command -v discord &> /dev/null; then
    DISCORD_CMD="discord"
elif command -v Discord &> /dev/null; then
    DISCORD_CMD="Discord"
elif [ -f "/usr/bin/discord" ]; then
    DISCORD_CMD="/usr/bin/discord"
elif [ -f "/usr/bin/Discord" ]; then
    DISCORD_CMD="/usr/bin/Discord"
elif command -v flatpak &> /dev/null && flatpak list | grep -iq "discord"; then
    DISCORD_CMD="flatpak run com.discordapp.Discord"
fi

# 2. Sober (Roblox) Kontrolü
if command -v flatpak &> /dev/null && flatpak list | grep -iq "vinegarhq.Sober"; then
    SOBER_CMD="flatpak run org.vinegarhq.Sober"
fi

if [ -z "$DISCORD_CMD" ] && [ -z "$SOBER_CMD" ]; then
    echo "HATA: Sistemde kurulu bir Discord veya Sober (Roblox) bulunamadı!"
    read -p "Çıkmak için ENTER'a basın..."
    exit 1
fi

TEST_APP=""

if [ -n "$DISCORD_CMD" ]; then
    echo "[+] Discord bulundu: $DISCORD_CMD"
    TEST_APP="discord"
fi

if [ -n "$SOBER_CMD" ]; then
    echo "[+] Sober (Roblox) bulundu."
    [ -z "$TEST_APP" ] && TEST_APP="sober" # Eğer Discord yoksa testi Sober ile yap
fi

sleep 1

# --- KURULUM TEMİZLİĞİ (Sadece kurulum aşamasında portları boşaltmak için) ---
echo "[+] Port çakışmalarını önlemek için eski süreçler temizleniyor..."
pkill -9 -f "ciadpi" >/dev/null 2>&1
pkill -9 -f "sing-box" >/dev/null 2>&1
killall -9 discord Discord discord-ptb DiscordPTB 2>/dev/null
flatpak kill org.vinegarhq.Sober >/dev/null 2>&1

# --- ÇALIŞTIRILABİLİR KONTROLÜ ---
chmod +x "$CIADPI_BIN" "$SINGBOX_BIN" "$CURL_BIN" 2>/dev/null

# --- STRATEJİ DENEME ---
if [ ! -f "$STRATEGY_FILE" ]; then
    echo "HATA: $STRATEGY_FILE bulunamadı!"
    exit 1
fi

if [ ! -f "$CURL_BIN" ]; then
    echo "HATA: Yerel curl bulunamadı! Yol: $CURL_BIN"
    exit 1
fi

mapfile -t STRATEGIES < <(tr -d '\r' < "$STRATEGY_FILE")
TOTAL_STRATS=${#STRATEGIES[@]}

sleep 1
echo "[$TOTAL_STRATS] adet strateji taranacak..."
echo ""
sleep 1

BEST_STRAT=""
CURRENT_INDEX=0
LAUNCHER_PATH="$SCRIPT_DIR/dpiscord_run.sh"

for STRAT in "${STRATEGIES[@]}"; do
    [[ -z "$STRAT" ]] && continue

    CURRENT_INDEX=$((CURRENT_INDEX + 1))
    echo "Deneniyor ($CURRENT_INDEX/$TOTAL_STRATS): $STRAT"

    # --- AGRESİF TEST TEMİZLİĞİ ---
    pkill -9 -f "ciadpi" >/dev/null 2>&1
    pkill -9 -f "sing-box" >/dev/null 2>&1
    killall -9 discord Discord discord-ptb DiscordPTB 2>/dev/null
    flatpak kill org.vinegarhq.Sober >/dev/null 2>&1

    sleep 1

    eval "$CIADPI_BIN $STRAT -p $PORT" >/dev/null 2>&1 &
    sleep 1.5

    "$CURL_BIN" -I --socks5 127.0.0.1:$PORT --doh-url https://1.1.1.1/dns-query "$TEST_URL" --connect-timeout 3 >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        if [ "$TEST_APP" == "discord" ]; then
            DISPLAY_NAME="Discord"
        else
            DISPLAY_NAME="Sober (Roblox)"
        fi

        echo -e "\033[1;32m[~] Ön test başarılı. $DISPLAY_NAME canlı doğrulaması başlatılıyor...\033[0m"

        # Geçici başlatıcı script oluştur
        cat << EOF > "$LAUNCHER_PATH"
#!/usr/bin/env bash
pkill -9 -f "ciadpi" >/dev/null 2>&1
pkill -9 -f "sing-box" >/dev/null 2>&1
EOF

        # Test edilecek uygulamaya göre sadece onu kapat
        if [ "$TEST_APP" == "discord" ]; then
            echo "killall -9 discord Discord 2>/dev/null" >> "$LAUNCHER_PATH"
        else
            echo "flatpak kill org.vinegarhq.Sober >/dev/null 2>&1" >> "$LAUNCHER_PATH"
        fi

        cat << EOF >> "$LAUNCHER_PATH"
sleep 0.5
export https_proxy=http://127.0.0.1:$SING_PORT
$CIADPI_BIN $STRAT -p $PORT >/dev/null 2>&1 &
sleep 0.1
$SINGBOX_BIN run -c $SINGBOX_CONFIG >/dev/null 2>&1 &
sleep 0.5
EOF

        if [ "$TEST_APP" == "discord" ]; then
            echo "$DISCORD_CMD --proxy-server=\"socks5://127.0.0.1:$SING_PORT\" >/dev/null 2>&1 &" >> "$LAUNCHER_PATH"
        else
            echo "flatpak run --env=all_proxy=socks5h://127.0.0.1:$SING_PORT org.vinegarhq.Sober >/dev/null 2>&1 &" >> "$LAUNCHER_PATH"
        fi

        chmod +x "$LAUNCHER_PATH"

        "$LAUNCHER_PATH" >/dev/null 2>&1 &

        echo "--> $DISPLAY_NAME açılıyor, lütfen kontrol edin (Bağlantı kuruluyor mu?)"
        echo ""

        read -p "[?] $DISPLAY_NAME SORUNSUZ AÇILDI ve bağlandı mı? (e/h): " user_ans
        if [[ "$user_ans" =~ ^[Ee]$ ]]; then
            echo ""
            echo "[+] KULLANICI DOĞRULADI! ÇALIŞAN STRATEJİ: $STRAT"
            BEST_STRAT="$STRAT"
            break
        else
            echo -e "\033[1;31m[-] Strateji başarısız sayıldı. Süreçler temizleniyor...\033[0m"
            pkill -9 -f "ciadpi" >/dev/null 2>&1
            pkill -9 -f "sing-box" >/dev/null 2>&1
            killall -9 discord Discord 2>/dev/null
            flatpak kill org.vinegarhq.Sober >/dev/null 2>&1
            echo ""
        fi
    fi
done

if [ -z "$BEST_STRAT" ]; then
    echo "HATA: Hiçbir strateji başarılı olamadı!"
    exit 1
fi

# --- MASAÜSTÜ YOLUNU BULMA ---
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

AUTOSTART_DIR="$HOME/.config/autostart"
MENU_DIR="$HOME/.local/share/applications"
mkdir -p "$MENU_DIR"

# AKILLI BAŞLATICI OLUŞTURMA FONKSİYONU (Discord ve Sober İçin Ortak)
create_launcher() {
    local target_app="$1"
    local script_out="$2"

    cat << EOF > "$script_out"
#!/usr/bin/env bash
# Bu dosya DPIscord tarafından otomatik oluşturulmuştur.

# 1. Sadece hedeflenen uygulamayı kapat (Diğerlerine dokunma)
EOF

    if [ "$target_app" == "discord" ]; then
        echo "killall -9 discord Discord discord-ptb DiscordPTB 2>/dev/null" >> "$script_out"
    else
        echo "flatpak kill org.vinegarhq.Sober >/dev/null 2>&1" >> "$script_out"
    fi

    cat << EOF >> "$script_out"
sleep 0.2
export https_proxy=http://127.0.0.1:$SING_PORT

# 2. Tünel servisleri kontrolü (Tam eşleşme araması)
if ! ps aux | grep -F "$CIADPI_BIN $BEST_STRAT -p $PORT" | grep -v grep > /dev/null; then
    pkill -9 -f "ciadpi" >/dev/null 2>&1
    $CIADPI_BIN $BEST_STRAT -p $PORT >/dev/null 2>&1 &
    sleep 0.1
fi

if ! ps aux | grep -F "$SINGBOX_BIN run -c $SINGBOX_CONFIG" | grep -v grep > /dev/null; then
    pkill -9 -f "sing-box" >/dev/null 2>&1
    $SINGBOX_BIN run -c $SINGBOX_CONFIG >/dev/null 2>&1 &
    sleep 0.3
fi
EOF

    if [ "$target_app" == "discord" ]; then
        echo "$DISCORD_CMD --proxy-server=\"socks5://127.0.0.1:$SING_PORT\" >/dev/null 2>&1 &" >> "$script_out"
    else
        echo "flatpak run --env=all_proxy=socks5h://127.0.0.1:$SING_PORT org.vinegarhq.Sober >/dev/null 2>&1 &" >> "$script_out"
    fi
    chmod +x "$script_out"
}

# --- DISCORD KISAYOL İŞLEMLERİ ---
if [ -n "$DISCORD_CMD" ]; then
    DISCORD_LAUNCHER="$SCRIPT_DIR/dpiscord_run.sh"
    create_launcher "discord" "$DISCORD_LAUNCHER"

    ICON_PATH="discord"
    if [[ "$DISCORD_CMD" == *"flatpak"* ]]; then
        FLATPAK_ICON=$(find /var/lib/flatpak/app/com.discordapp.Discord/current/active/files/share/icons -name "com.discordapp.Discord.*" 2>/dev/null | head -n 1)
        if [ -z "$FLATPAK_ICON" ]; then
            FLATPAK_ICON=$(find "$HOME/.local/share/flatpak/app/com.discordapp.Discord/current/active/files/share/icons" -name "com.discordapp.Discord.*" 2>/dev/null | head -n 1)
        fi
        [ -n "$FLATPAK_ICON" ] && ICON_PATH="$FLATPAK_ICON"
    fi

    DESKTOP_FILE="$DESKTOP_DIR/discord-dpi.desktop"
    MENU_FILE="$MENU_DIR/discord-dpi.desktop"

    cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Discord (DPI)
Comment=DPI Bypass ile Discord'u Başlat
Exec=$DISCORD_LAUNCHER
Icon=$ICON_PATH
Terminal=false
Categories=Network;InstantMessaging;
EOF
    chmod +x "$DESKTOP_FILE"
    cp "$DESKTOP_FILE" "$MENU_FILE"

    echo ""
    echo "[+] Discord kısayolu oluşturuldu."
fi

# --- SOBER KISAYOL İŞLEMLERİ ---
if [ -n "$SOBER_CMD" ]; then
    CREATE_SOBER="e"

    if [ -n "$DISCORD_CMD" ]; then
        echo ""
        read -p "[?] Sober (Roblox) kullandığınızı görüyorum. Sober için de DPI kısayolu ayarlansın mı? (e/h): " ans_sober
        CREATE_SOBER="$ans_sober"
    fi

    if [[ "$CREATE_SOBER" =~ ^[Ee]$ ]]; then
        SOBER_LAUNCHER="$SCRIPT_DIR/sober_dpi_run.sh"
        create_launcher "sober" "$SOBER_LAUNCHER"

        SOBER_DESKTOP="$DESKTOP_DIR/sober-dpi.desktop"
        SOBER_MENU="$MENU_DIR/sober-dpi.desktop"
        SOBER_ICON="org.vinegarhq.Sober"

        cat << EOF > "$SOBER_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=Sober (DPI)
Comment=DPI Bypass ile Sober (Roblox) Başlat
Exec=$SOBER_LAUNCHER
Icon=$SOBER_ICON
Terminal=false
Categories=Game;
EOF
        chmod +x "$SOBER_DESKTOP"
        cp "$SOBER_DESKTOP" "$SOBER_MENU"

        echo "[+] Sober (Roblox) kısayolu oluşturuldu."
    fi
fi

# --- SYSTEM STARTUP (BAŞLANGIÇTA ÇALIŞTIRMA) SADECE DISCORD İÇİN ---
if [ -n "$DISCORD_CMD" ]; then
    echo ""
    sleep 1
    read -p "[?] Discord kısayolunu sistem açılışına (Startup) eklemek ister misiniz? (e/h): " ans
    if [[ "$ans" =~ ^[Ee]$ ]]; then
        mkdir -p "$AUTOSTART_DIR"
        cp "$MENU_DIR/discord-dpi.desktop" "$AUTOSTART_DIR/"
        echo "[+] Discord (DPI) başlangıç klasörüne eklendi."
    else
        rm -f "$AUTOSTART_DIR/discord-dpi.desktop"
    fi
fi

echo ""
echo "=============================================="
echo "               İŞLEM TAMAMLANDI!              "
echo "=============================================="
echo "Artık oluşturulan kısayolları kullanabilirsiniz."
echo ""
sleep 1

if [ -n "$DISCORD_CMD" ]; then
    echo -e "\033[1;33m⚠️  ÖNEMLİ HANDOFF (GİRİŞ) UYARISI (Discord İçin):\033[0m"
    echo "Discord'u ilk defa açacaksanız veya yeni giriş yapacaksanız:"
    if [[ "$DISCORD_CMD" == *"flatpak"* ]]; then
        echo "1. Tarayıcınızın proxy ayarlarını (veya eklentisini) gecici olarak"
        echo "   HTTP Proxy: 127.0.0.1 | Port: $SING_PORT yapın."
        echo "2. Giriş yaptıktan sonra ayarı kapatabilirsiniz."
    else
        echo "1. Önce açık olan tüm tarayıcı pencerelerinizi tamamen kapatın."
        echo "2. 'Discord (DPI)' kısayolunu çalıştırın, tünel tarayıcıya otomatik geçer."
    fi
    echo ""
fi

read -p "Çıkmak için ENTER'a basın..."
