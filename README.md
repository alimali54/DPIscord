# DPIscord (Windows & Linux)

DPIscord, Discord üzerindeki erişim engellerini sistem ayarlarınızı bozmadan çözen yenilikçi bir yardımcı araçtır.

Ayrıca Linux sürümünün **Sober (Roblox)** desteği de vardır. 

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

###  Tek Komutla Otomatik Kurulum

```bash
bash <(curl -sSL https://raw.githubusercontent.com/alimali54/DPIscord/main/linux/install.sh)
```

###  Manuel Kurulum
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
      ▼  (version.dll ile Discord trafiği [gost/sing-box - socks5://127.0.0.1:8849] adresine yönlendirilir)
      │
      ├─► [Gost/Sing-box- socks5://127.0.0.1:8849] (Tüm alan adlarını şifreli DoT ile çözer ve ByeDPI'a [ciadpi - socks5://127.0.0.1:8848] iletir)
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
      ├─► [Çevre Değişkeni: export https_proxy=[http://127.0.0.1:8849](http://127.0.0.1:8849)]
      ├─► [Gost/sing-box - [http://127.0.0.1:8849](http://127.0.0.1:8849)] (Gelen HTTP proxy isteklerini TLS DNS ile çözüp ByeDPI'a iletir)
      │
      ▼ (Güvenli DNS ile çözülen trafik buraya tünellenir)
[ByeDPI (ciadpi)] (127.0.0.1:8848 - Belirlenen bypass stratejisiyle)
      │
      ▼ (Sansürsüz ve engelsiz)
[Discord Sunucuları]
```

## Kullanılan Kaynaklar ve Teşekkür (Credits)

Bu projede, bağlantı sorunlarını çözmek ve tünelleme işlemlerini gerçekleştirmek için açık kaynaklı harika projelerden faydalanılmıştır. Projede kullanılan çalıştırılabilir (`.exe` ve binary) dosyalar aşağıda listelenmiştir. 

Dilerseniz mevcut dosyaları olduğu gibi kullanabilir, dilerseniz aşağıdaki resmi bağlantılardan bu projeleri inceleyerek kendi sürümlerinizi derleyebilir veya indirebilirsiniz:

* **ciadpi (ByeDPI):** DPI bypass işlemleri için.  
  [GitHub - hufrea/byedpi](https://github.com/hufrea/byedpi)

* **sing-box:** ciadpi'ın açtığı tünele DNS ekleyip kendi tünelini oluşturur. 
  [GitHub - sagernet/sing-box](https://github.com/sagernet/sing-box)

* **curl:** Ağ ve bağlantı testlerinin gerçekleştirilmesi için kullanılır.  
  [GitHub - curl/curl](https://github.com/curl/curl)

* **version.dll (discord-drover):** Discord uygulamasının yerel olarak proxy tüneline yönlendirilmesini sağlar.  
  [GitHub - hdrover/discord-drover](https://github.com/hdrover/discord-drover)
