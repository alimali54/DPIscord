#!/usr/bin/env bash

# DPIscord macOS Port (Akıllı Kısayollar ve Native .app Desteği)
# Karakter kodlaması UTF-8 olarak varsayılır.

# --- TERMİNAL KONTROLÜ (macOS Çift Tıklama Düzeltmesi) ---
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
if [ ! -t 0 ]; then
    osascript -e "tell application \"Terminal\"" -e "activate" -e "do script \"bash \\\"$SCRIPT_PATH\\\"\"" -e "end tell"
    exit 0
fi

# --- DİZİN VE YAPILANDIRMA ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DPI_SUBDIR="$SCRIPT_DIR/byedpi"
STRATEGY_FILE="$DPI_SUBDIR/strategies.txt"
CIADPI_BIN="$DPI_SUBDIR/ciadpi"
SINGBOX_BIN="$DPI_SUBDIR/sing-box"
SINGBOX_CONFIG="$DPI_SUBDIR/sing-box.json"
TEST_URL="https://updates.discord.com"
PORT=8848
SING_PORT=8849

echo "=============================================="
echo "           DPIscord macOS v2.4                "
echo "=============================================="

# --- DISCORD YÜKLÜ MÜ KONTROLÜ ---
echo "[+] Discord kurulumu kontrol ediliyor..."
DISCORD_APP="/Applications/Discord.app"
DISCORD_EXEC="$DISCORD_APP/Contents/MacOS/Discord"

sleep 1

if [ ! -d "$DISCORD_APP" ]; then
    echo "HATA: Sistemde kurulu bir Discord bulunamadı! (/Applications/Discord.app)"
    echo "Lütfen önce Discord'u yükleyin."
    read -p "Çıkmak için ENTER'a basın..."
    exit 1
else
    echo "[+] Discord bulundu: $DISCORD_APP"
fi

sleep 1

# --- KURULUM TEMİZLİĞİ ---
echo "[+] Port çakışmalarını önlemek için eski süreçler temizleniyor..."
pkill -9 -f "ciadpi" >/dev/null 2>&1
pkill -9 -f "sing-box" >/dev/null 2>&1
killall -9 Discord >/dev/null 2>&1

# --- ÇALIŞTIRILABİLİR KONTROLÜ VE GATEKEEPER İZNİ ---
chmod +x "$CIADPI_BIN" "$SINGBOX_BIN" 2>/dev/null
xattr -cr "$CIADPI_BIN" "$SINGBOX_BIN" 2>/dev/null

# --- STRATEJİ VE ARAÇ DENETİMİ ---
if [ ! -f "$STRATEGY_FILE" ]; then
    echo "HATA: $STRATEGY_FILE bulunamadı!"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "HATA: Sistemde kurulu 'curl' bulunamadı!"
    read -p "Çıkmak için ENTER'a basın..."
    exit 1
fi

# macOS Bash 3.2 uyumlu dosya okuma yöntemi
STRATEGIES=()
while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" ]] && continue
    STRATEGIES+=("$line")
done < <(tr -d '\r' < "$STRATEGY_FILE")

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

    # --- AGRESİF TEST TEMİZLİĞİ (macOS) ---
    pkill -9 -f "ciadpi" >/dev/null 2>&1
    pkill -9 -f "sing-box" >/dev/null 2>&1
    killall -9 Discord >/dev/null 2>&1

    sleep 1

    eval "\"$CIADPI_BIN\" $STRAT -p $PORT" >/dev/null 2>&1 &
    sleep 1.5

    curl -I --socks5 127.0.0.1:$PORT --doh-url https://1.1.1.1/dns-query "$TEST_URL" --connect-timeout 3 >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m[~] Ön test başarılı. Discord canlı doğrulaması başlatılıyor...\033[0m"

        cat << EOF > "$LAUNCHER_PATH"
#!/usr/bin/env bash
pkill -9 -f "ciadpi" >/dev/null 2>&1
pkill -9 -f "sing-box" >/dev/null 2>&1
killall -9 Discord >/dev/null 2>&1
sleep 0.5
export HTTPS_PROXY="http://127.0.0.1:$SING_PORT"
"$CIADPI_BIN" $STRAT -p $PORT >/dev/null 2>&1 &
sleep 0.1
"$SINGBOX_BIN" run -c "$SINGBOX_CONFIG" >/dev/null 2>&1 &
sleep 0.5
"$DISCORD_EXEC" --proxy-server="http://127.0.0.1:$SING_PORT" >/dev/null 2>&1 &
EOF
        
        chmod +x "$LAUNCHER_PATH"

        "$LAUNCHER_PATH" >/dev/null 2>&1 &

        echo "--> Discord açılıyor, lütfen kontrol edin (Bağlantı kuruluyor mu?)"
        echo ""

        read -p "[?] Discord SORUNSUZ AÇILDI ve bağlandı mı? (e/h): " user_ans
        if [[ "$user_ans" =~ ^[Ee]$ ]]; then
            echo ""
            echo "[+] KULLANICI DOĞRULADI! ÇALIŞAN STRATEJİ: $STRAT"
            BEST_STRAT="$STRAT"
            break
        else
            echo -e "\033[1;31m[-] Strateji başarısız sayıldı. Süreçler temizleniyor...\033[0m"
            pkill -9 -f "ciadpi" >/dev/null 2>&1
            pkill -9 -f "sing-box" >/dev/null 2>&1
            killall -9 Discord >/dev/null 2>&1
            echo ""
        fi
    fi
done

if [ -z "$BEST_STRAT" ]; then
    echo "HATA: Hiçbir strateji başarılı olamadı!"
    read -p "Çıkmak için ENTER'a basın..."
    exit 1
fi

# --- AKILLI BAŞLATICIYI OLUŞTUR (Kalıcı) ---
cat << EOF > "$LAUNCHER_PATH"
#!/usr/bin/env bash
# Bu dosya DPIscord tarafından otomatik oluşturulmuştur.

killall -9 Discord >/dev/null 2>&1
sleep 0.2

export HTTPS_PROXY="http://127.0.0.1:$SING_PORT"

if ! ps aux | grep -F "$CIADPI_BIN $BEST_STRAT -p $PORT" | grep -v grep > /dev/null; then
    pkill -9 -f "ciadpi" >/dev/null 2>&1
    "$CIADPI_BIN" $BEST_STRAT -p $PORT >/dev/null 2>&1 &
    sleep 0.1
fi

if ! ps aux | grep -F "$SINGBOX_BIN run -c $SINGBOX_CONFIG" | grep -v grep > /dev/null; then
    pkill -9 -f "sing-box" >/dev/null 2>&1
    "$SINGBOX_BIN" run -c "$SINGBOX_CONFIG" >/dev/null 2>&1 &
    sleep 0.3
fi

"$DISCORD_EXEC" --proxy-server="http://127.0.0.1:$SING_PORT" >/dev/null 2>&1 &
EOF

chmod +x "$LAUNCHER_PATH"

# --- MAC NATIVE .APP KISAYOLU OLUŞTURMA ---
DESKTOP_DIR="$HOME/Desktop"
APPS_DIR="/Applications"
APP_NAME="Discord (DPI).app"

echo "[+] macOS için Native Application (.app) üretiliyor..."
osacompile -e "do shell script \"bash \\\"$LAUNCHER_PATH\\\" >/dev/null 2>&1 &\"" -o "$DESKTOP_DIR/$APP_NAME" >/dev/null 2>&1

if [ -f "$DISCORD_APP/Contents/Resources/electron.icns" ]; then
    cp "$DISCORD_APP/Contents/Resources/electron.icns" "$DESKTOP_DIR/$APP_NAME/Contents/Resources/applet.icns"
    touch "$DESKTOP_DIR/$APP_NAME"
fi

cp -R "$DESKTOP_DIR/$APP_NAME" "$APPS_DIR/" 2>/dev/null

echo "[+] Kısayol oluşturuldu: Masaüstü ve Launchpad (/Applications)"

# --- SYSTEM STARTUP (BAŞLANGIÇTA ÇALIŞTIRMA) ---
echo ""
sleep 1
read -p "[?] Discord kısayolunu sistem açılışına (Startup) eklemek ister misiniz? (e/h): " ans
if [[ "$ans" =~ ^[Ee]$ ]]; then
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$APPS_DIR/$APP_NAME\", hidden:false, name:\"Discord DPI\"}" >/dev/null 2>&1
    echo "[+] Discord (DPI) Mac Oturum Açma Öğelerine (Login Items) eklendi."
fi

echo ""
echo "=============================================="
echo "               İŞLEM TAMAMLANDI!              "
echo "=============================================="
echo "Artık Launchpad'deki veya Masaüstünüzdeki 'Discord DPI' uygulamasını kullanabilirsiniz."
echo ""
sleep 1
read -p "Çıkmak için ENTER'a basın..."