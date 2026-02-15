# DPIscord

DPIscord, Discord üzerindeki erişim engellerini ve bağlantı sorunlarını otomatik olarak çözen bir yardımcı araçtır.

## Ne Yapar?

* **En İyi Ayarı Bulur:** İnternet hattınıza en uygun bağlantı ayarını saniyeler içinde tespit eder.
* **DNS Kontrolü Yapar:** İnternet servis sağlayıcınızın bağlantınıza müdahale edip etmediğini kontrol eder.
* **Çakışmaları Giderir:** Bağlantıyı engelleyebilecek diğer araçları (GoodbyeDPI vb.) otomatik olarak kapatır ve temizler.
* **Kısayol Oluşturur:** Masaüstüne tek tıkla Discord'u sorunsuz açabileceğiniz bir kısayol ekler.

## Nasıl Kullanılır?

1. **DPIscord.bat** dosyasını çalıştırın.
2. Ekranda bir uyarı çıkarsa (GoodbyeDPI temizliği için) onay verin.
3. Program en iyi ayarı bulup "İşlem Tamamlandı" diyene kadar bekleyin.
4. Artık masaüstündeki **Discord (DPI)** kısayolunu kullanarak Discord'a giriş yapabilirsiniz.

## Dikkat Edilmesi Gerekenler

* Programı ilk kez çalıştırdığınızda, çakışan servisleri durdurabilmesi için yönetici izni isteyebilir.
* Masaüstündeki kısayol oluştuktan sonra ana klasördeki dosyaların yerini değiştirmeyin.

## Teknik Detaylar (Gelişmiş)

Bu bölüm, DPIscord'un çalışma mantığını merak eden teknik kullanıcılar içindir:

* **Servis ve Süreç Denetimi:** Sistemde `goodbyedpi.exe` sürecini ve `GoodbyeDPI` servisini sorgular. Eğer aktifse, ağ sürücüsü (`WinDivert`) ile birlikte sistemden tamamen arındırmak için geçici yönetici hakları talep eder.
* **DoH Destekli DNS Analizi:** Standart `nslookup` sonuçlarını, Cloudflare DoH (DNS over HTTPS) üzerinden alınan gerçek IP adresleri ile karşılaştırır. DNS zehirlenmesi (spoofing) tespit edilirse, güvenli bir DNS yapılandırmasına geçilene kadar işleme devam etmez.
* **Strateji Optimizasyonu:** `strategies.txt` içerisindeki ByeDPI parametrelerini tek tek deneyerek uygun olan stratejiyi bulur.
* **VBS ve Proxychains Entegrasyonu:** Belirlenen strateji, dinamik olarak oluşturulan bir VBS scriptine gömülür. Bu script, Discord'u doğrudan başlatmak yerine `proxychains_win32_x64.exe` aracılığıyla sarmalayarak tüm Discord trafiğini ByeDPI tüneline zorla (force) yönlendirir.
* **Dinamik EXE Takibi:** Oluşturulan başlatıcı, Discord'un versiyon güncellemelerinden etkilenmemek için kullanıcı dizinlerindeki `Discord.exe` konumunu her açılışta özyinelemeli (recursive) olarak tarar.
