# DPIscord v2.0 (Windows & Linux)

DPIscord, Discord üzerindeki erişim engellerini sistem ayarlarınızı bozmadan çözen yenilikçi bir yardımcı araçtır.

## Ne Yapar?

* **En Uygun Stratejiyi Seçer:** İnternet hattınızda sansürü aşacak en kararlı ByeDPI ayarını (`ciadpi`) tespit eder.
* **DNS Ayarlarınıza Dokunmaz:** Artık sistem DNS'inizi değiştirmekle veya ek yazılımlarla (YogaDNS vb.) uğraşmanıza gerek yok. DPIscord, kendi içinde güvenli ve şifreli bir DNS katmanı barındırır.
* **Çakışmaları Giderir:** Bağlantıyı engelleyebilecek diğer araçları (GoodbyeDPI, WinDivert vb.) otomatik olarak kapatır ve temizler.
* **Kısayol Oluşturur:** Masaüstünüze tek tıkla Discord'u sorunsuz açabileceğiniz bir kısayol ekler ve Discord güncellense bile çalışmaya devam eder.

---

## Nasıl Kullanılır? (Windows)

1. **DPIscord.bat** dosyasını çalıştırın.
2. Ekranda bir uyarı çıkarsa (GoodbyeDPI ve WinDivert temizliği için) onay verin.
3. Program en iyi ayarı bulup "İşlem Tamamlandı" diyene kadar bekleyin.
4. Artık masaüstündeki **Discord (DPI)** kısayolunu kullanarak Discord'a giriş yapabilirsiniz.

> **ÖNEMLİ:** Masaüstündeki kısayol oluştuktan sonra, DPIscord klasörünün veya içerisindeki dosyaların yerini değiştirmeyin.

## Nasıl Kullanılır? (Linux)
DPIscord; Debian/Mint (.deb), Fedora (RPM/DNF), Arch (Pacman), Flatpak ve Snap dahil olmak üzere tüm Linux dağıtımlarında sorunsuz çalışır.

1. Terminali açın ve `DPIscord` klasörünün içine gidin.
2. Kurulum betiğine çalıştırma izni verin:
   ```bash
   chmod +x DPIscord.sh
3. Kurulumu başlatın:
   ```bash
   ./DPIscord.sh

---

#### ⚠️ Handoff süreci notu:
Eğer Discord'u ilk defa açacaksanız veya yeni giriş yapacaksanız:
* **Windows sistemlerde:** Eğer tarayıcıda handoff süreci takılırsa, tarayıcınızın proxy ayarlarını geçici olarak `HTTP Proxy: 127.0.0.1` | `Port: 8849` yapın. Giriş tamamlandıktan sonra kapatabilirsiniz.
* **Geleneksel Kurulumlarda (.deb, .rpm, pacman):** Giriş yapmadan önce tüm tarayıcı pencerelerinizi tamamen kapatın. Discord handoff süreci için tarayıcınızı açtığında DPI tüneli tarayıcıya da aktarılır ve handoff sürecini sorunsuz geçersiniz.
* **Flatpak Kurulumlarında:** Sandbox izolasyonu nedeniyle tünel tarayıcıya otomatik aktarılamaz. Eğer tarayıcıda handoff süreci takılırsa, tarayıcınızın proxy ayarlarını geçici olarak `HTTP Proxy: 127.0.0.1` | `Port: 8849` yapın. Giriş tamamlandıktan sonra kapatabilirsiniz.

---

## Çalışma Mantığı (Teknik Şema)
### Windows Altyapısı
```text
[Discord.exe]
      │
      ▼  (version.dll ile Discord trafiği [gost - socks5://127.0.0.1:8849] adresine yönlendirilir)
      │
      ├─► [Gost - socks5://127.0.0.1:8849] (Tüm alan adlarını 1.1.1.1:853 şifreli DoT ile çözer ve ByeDPI'a [ciadpi - socks5://127.0.0.1:8848] iletir)
      │
      ▼  (Güvenli DNS ile çözülen trafik buraya tünellenir)
[ByeDPI (ciadpi)] (127.0.0.1:8848 - Belirlenen bypass stratejisiyle)
      │
      ▼  (Sansürsüz ve engelsiz)
[Discord Sunucuları]
```

### Linux Altyapısı
```text
[discord-dpi.desktop Kısayolu]
      │
      ▼ (Dinamik Başlatıcı: dpiscord_run.sh)
      │
      ├─► [Çevre Değişkeni: export https_proxy=[http://127.0.0.1:8849](http://127.0.0.1:8849)] (İnatçı Rust updater'ı ve Handoff tarayıcısını kurtarır)
      ├─► [Gost - [http://127.0.0.1:8849](http://127.0.0.1:8849)] (Gelen HTTP proxy isteklerini TLS DNS ile çözüp ByeDPI'a iletir)
      │
      ▼ (Güvenli DNS ile çözülen trafik buraya tünellenir)
[ByeDPI (ciadpi)] (127.0.0.1:8848 - Belirlenen bypass stratejisiyle)
      │
      ▼ (Sansürsüz ve engelsiz)
[Discord Sunucuları]
