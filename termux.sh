#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

BASE="$HOME/byedpi"
ARCHIVE_URL="https://github.com/hufrea/byedpi/releases/download/v0.17.3/byedpi-17.3-aarch64.tar.gz"
SOURCE_URL="https://github.com/hufrea/byedpi/archive/refs/tags/v0.17.3.tar.gz"
STRATEGIES_URL="https://raw.githubusercontent.com/alimali54/DPIscord/refs/heads/main/linux/byedpi/strategies.txt"

ARCHIVE="$BASE/byedpi-17.3-aarch64.tar.gz"
SOURCE_ARCHIVE="$BASE/byedpi-source.tar.gz"
STRATEGY_FILE="$BASE/strategies.txt"
BIN="$BASE/ciadpi"
PORT=8848
TEST_URL="https://updates.discord.com"
DOH_URL="https://1.1.1.1/dns-query"

mkdir -p "$BASE" "$HOME/.shortcuts"
cd "$BASE"

for cmd in curl tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "HATA: $cmd bulunamadı. Önce Termux'ta kur: pkg install $cmd"
        exit 1
    fi
done

if ! curl --help all 2>/dev/null | grep -q -- '--doh-url'; then
    echo "HATA: Bu curl sürümünde --doh-url desteği görünmüyor."
    echo "curl --version çıktısını kontrol et; DoH desteği olmadan aynı test yapılamaz."
    exit 1
fi

echo "[1/4] ByeDPI arşivi indiriliyor..."
curl -fL --retry 3 "$ARCHIVE_URL" -o "$ARCHIVE"

echo "[2/4] Arşiv açılıyor..."
TMP_DIR="$BASE/.extract_tmp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

RELEASE_BIN="$(find "$TMP_DIR" -type f \( -name 'ciadpi-aarch64' -o -name 'ciadpi' \) -print -quit)"
if [ -z "$RELEASE_BIN" ]; then
    echo "HATA: Arşiv içinde ciadpi-aarch64 veya ciadpi bulunamadı."
    exit 1
fi

cp "$RELEASE_BIN" "$BIN"
chmod +x "$BIN"
rm -rf "$TMP_DIR"

# Android'de Linux release ELF'i çalışmayabilir. PHDR/linker hatası varsa
# Termux'un kendi clang'i ile aynı sürümün kaynak kodundan derle.
PROBE_ERR="$BASE/.ciadpi_probe.err"
"$BIN" --help >/dev/null 2>"$PROBE_ERR" || true

if grep -Eiq 'PHDR|broken executable|Exec format error|cannot locate symbol|not found' "$PROBE_ERR"; then
    echo
    echo "İndirilen hazır binary Android linker ile uyumlu görünmüyor."
    echo "Termux için v0.17.3 kaynak kodu clang ile derlenecek."

    if ! command -v clang >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
        echo "clang/make kuruluyor..."
        pkg install -y clang make
    fi

    if ! command -v clang >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
        echo "HATA: clang ve make gerekli. Kurulum tamamlanamadı."
        exit 1
    fi

    curl -fL --retry 3 "$SOURCE_URL" -o "$SOURCE_ARCHIVE"
    SRC_DIR="$BASE/.byedpi-src"
    rm -rf "$SRC_DIR"
    mkdir -p "$SRC_DIR"
    tar -xzf "$SOURCE_ARCHIVE" --strip-components=1 -C "$SRC_DIR"
    make -C "$SRC_DIR" clean >/dev/null 2>&1 || true
    make -C "$SRC_DIR" CC=clang
    cp "$SRC_DIR/ciadpi" "$BIN"
    chmod +x "$BIN"

    "$BIN" --help >/dev/null 2>"$PROBE_ERR" || true
    if grep -Eiq 'PHDR|broken executable|Exec format error|cannot locate symbol|not found' "$PROBE_ERR"; then
        echo "HATA: Termux için derlenen ciadpi de başlatılamadı:"
        cat "$PROBE_ERR"
        exit 1
    fi
fi
rm -f "$PROBE_ERR"

echo "[3/4] Stratejiler indiriliyor..."
curl -fL --retry 3 "$STRATEGIES_URL" -o "$STRATEGY_FILE"

echo
echo "Stratejiler sırayla test edilecek."
echo "Hedef: $TEST_URL"
echo "SOCKS5: 127.0.0.1:$PORT | DNS-over-HTTPS: $DOH_URL"
echo

CURRENT=0
TOTAL="$(grep -cvE '^[[:space:]]*$|^[[:space:]]*#' "$STRATEGY_FILE" || true)"
SAVED=0
CIADPI_PID=""

stop_test_proxy() {
    if [ -n "${CIADPI_PID:-}" ]; then
        kill "$CIADPI_PID" >/dev/null 2>&1 || true
        wait "$CIADPI_PID" >/dev/null 2>&1 || true
        CIADPI_PID=""
    fi
}
trap stop_test_proxy EXIT INT TERM

while IFS= read -r STRATEGY || [ -n "$STRATEGY" ]; do
    STRATEGY="${STRATEGY%$'\r'}"
    [[ -z "$STRATEGY" || "$STRATEGY" =~ ^[[:space:]]*# ]] && continue

    CURRENT=$((CURRENT + 1))
    read -r -a STRATEGY_ARGS <<< "$STRATEGY"

    echo "[$CURRENT/$TOTAL] deneniyor: $STRATEGY"
    stop_test_proxy

    "$BIN" "${STRATEGY_ARGS[@]}" -p "$PORT" >"$BASE/ciadpi-test.log" 2>&1 &
    CIADPI_PID=$!
    sleep 1

    if curl -I -sS \
        --socks5 "127.0.0.1:$PORT" \
        --doh-url "$DOH_URL" \
        "$TEST_URL" \
        --connect-timeout 3 \
        --max-time 8 >/dev/null 2>&1; then

        echo
        echo "BAŞARILI: $STRATEGY"
        echo "İlk başarılı strateji otomatik olarak kaydediliyor..."

        # Termux:Widget kısayolları doğrudan Termux ana dizinindeki ~/.shortcuts içine yazılır.
        SHORTCUT_DIR="$HOME/.shortcuts"
        mkdir -p "$SHORTCUT_DIR"
        SHORTCUT_FILE="$SHORTCUT_DIR/byedpi"

        {
            printf '%s\n' '#!/data/data/com.termux/files/usr/bin/bash'
            printf 'cd %q\n' "$BASE"
            printf 'export PATH=%q:"$PATH"\n' "$BASE"
            printf 'exec ciadpi'
            for ARG in "${STRATEGY_ARGS[@]}"; do
                printf ' %q' "$ARG"
            done
            printf ' -p %q\n' "$PORT"
        } > "$SHORTCUT_FILE"

        chmod +x "$SHORTCUT_FILE"
        printf 'ciadpi %s\n' "$STRATEGY" > "$SHORTCUT_DIR/byedpi.txt"
        echo
        echo "Kaydedildi: $SHORTCUT_FILE"
        echo "Kısayol adı: byedpi"
        SAVED=1
        break
    else
        echo "Başarısız."
    fi

    stop_test_proxy
    echo
done < "$STRATEGY_FILE"

if [ "$SAVED" -eq 0 ]; then
    echo "Kaydedilen bir strateji yok."
    echo "Hiçbiri başarılı olmadıysa ağ bağlantını ve ciadpi-test.log dosyasını kontrol et."
fi

echo
echo "[4/4] İşlem tamamlandı."
