# DPIscord v2.0

DPIscord, Discord üzerindeki erişim engellerini sistem ayarlarınızı bozmadan çözen yenilikçi bir yardımcı araçtır.

## Ne Yapar?

* **En Uygun Stratejiyi Seçer:** İnternet hattınızda sansürü aşacak en kararlı ByeDPI ayarını (`ciadpi`) tespit eder.
* **DNS Ayarlarınıza Dokunmaz:** Artık sistem DNS'inizi değiştirmekle veya ek yazılımlarla (YogaDNS vb.) uğraşmanıza gerek yok. DPIscord, kendi içinde güvenli ve şifreli bir DNS katmanı barındırır.
* **Çakışmaları Giderir:** Bağlantıyı engelleyebilecek diğer araçları (GoodbyeDPI, WinDivert vb.) otomatik olarak kapatır ve temizler.
* **Kısayol Oluşturur:** Masaüstünüze tek tıkla Discord'u sorunsuz açabileceğiniz bir kısayol ekler ve Discord güncellense bile çalışmaya devam eder.

---

## Nasıl Kullanılır?

1. **DPIscord.bat** dosyasını çalıştırın.
2. Ekranda bir uyarı çıkarsa (GoodbyeDPI ve WinDivert temizliği için) onay verin.
3. Program en iyi ayarı bulup "İşlem Tamamlandı" diyene kadar bekleyin.
4. Artık masaüstündeki **Discord (DPI)** kısayolunu kullanarak Discord'a giriş yapabilirsiniz.

> **ÖNEMLİ:** Masaüstündeki kısayol oluştuktan sonra, DPIscord klasörünün veya içerisindeki dosyaların yerini değiştirmeyin.

---

## Çalışma Mantığı (Teknik Şema)

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
