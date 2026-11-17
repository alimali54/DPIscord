
#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/byedpi"
SHORTCUTS="$HOME/.shortcuts"

CIADPI_URL="https://github.com/alimali54/DPIscord/raw/refs/heads/main/ciadpi"
STRATEGIES_URL="https://raw.githubusercontent.com/alimali54/DPIscord/refs/heads/main/linux/byedpi/strategies.txt"

TEST_URL="https://roblox.com"
DOH_URL="https://1.1.1.1/dns-query"
PORT=8848

echo "================================"
echo "       ByeDPI for Termux"
echo "================================"

# Klasörleri oluştur
mkdir -p "$BASE" "$SHORTCUTS"
cd "$BASE" || exit 1

# ciadpi indir
echo "[1/5] ciadpi indiriliyor..."

if ! curl -fLsS "${CIADPI_URL}?nocache=$(date +%s)" -o ciadpi; then
    echo "HATA: ciadpi indirilemedi."
    exit 1
fi

chmod +x ciadpi

# Stratejileri indir
echo "[2/5] Stratejiler indiriliyor..."

if ! curl -fLsS "${STRATEGIES_URL}?nocache=$(date +%s)" -o strategies.txt; then
    echo "HATA: Stratejiler indirilemedi."
    exit 1
fi

# Stratejileri test et
echo "[3/5] Uygun strateji aranıyor..."

FOUND=0

while IFS= read -r strategy || [ -n "$strategy" ]; do
    [[ -z "$strategy" || "$strategy" == \#* ]] && continue

    echo "Test ediliyor: $strategy"

    ./ciadpi -p "$PORT" $strategy >/dev/null 2>&1 &
    PID=$!

    sleep 2

    if curl -I -sS \
        --socks5 127.0.0.1:"$PORT" \
        --doh-url "$DOH_URL" \
        "$TEST_URL" \
        --connect-timeout 3 \
        --max-time 8 >/dev/null 2>&1; then

        echo "BAŞARILI: $strategy"

        echo "$strategy" > selected.txt
        FOUND=1

        kill "$PID" 2>/dev/null
        wait "$PID" 2>/dev/null
        break
    fi

    kill "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null

done < strategies.txt

if [ "$FOUND" -ne 1 ]; then
    echo "HATA: Uygun strateji bulunamadı."
    exit 1
fi

# Widget kısayolu oluştur
echo "[4/5] Widget kısayolu oluşturuluyor..."

cat > "$SHORTCUTS/ByeDPI" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

cd "$HOME/byedpi" || exit 1

# Önceki ciadpi süreçlerini sonlandır
PIDS=$(pgrep -f '^\./ciadpi( |$)')

if [ -n "$PIDS" ]; then
    kill $PIDS 2>/dev/null
    sleep 1

    PIDS=$(pgrep -f '^\./ciadpi( |$)')

    if [ -n "$PIDS" ]; then
        kill -9 $PIDS 2>/dev/null
    fi
fi

# Yeni ciadpi sürecini başlat
./ciadpi $(cat selected.txt)
EOF

chmod +x "$SHORTCUTS/ByeDPI"

# Terminal alias oluştur
echo "[5/5] Terminal komutu oluşturuluyor..."

ALIAS_LINE='alias byedpi='\''bash "$HOME/.shortcuts/ByeDPI"'\'''

touch "$HOME/.bashrc"

if ! grep -Fqx "$ALIAS_LINE" "$HOME/.bashrc"; then
    echo "$ALIAS_LINE" >> "$HOME/.bashrc"
fi

# Bash açılışında .bashrc dosyasını yükle
PROFILE="$HOME/.bash_profile"

touch "$PROFILE"

if ! grep -Fq 'source "$HOME/.bashrc"' "$PROFILE"; then
    echo 'source "$HOME/.bashrc"' >> "$PROFILE"
fi

# Mevcut oturuma da yükle
source "$HOME/.bashrc"

echo
echo "================================"
echo "       Kurulum tamamlandı!"
echo "================================"
echo "Seçilen strateji: $(cat selected.txt)"
echo "Widget: ByeDPI"
echo "Terminal komutu: byedpi"
echo "================================"
