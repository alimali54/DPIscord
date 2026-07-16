> [!WARNING]
> ## REDDIT'TEN GELENLERİN DİKKATİNE
> 
> Öncelikle insan banlamadan önce anlayıp dinlemeniz gerekir. Biraz eski paylaşımlarıma baksanız hakkımda az çok fikriniz oluşurdu.
> 
> **ByeDPI**'ın Türkiye'de sadece Android'de var olduğu zannedilirken, tanıtımını ve nasıl kullanıldığını YouTube'da Windows, Linux ve macOS için **ilk ben anlattım**. Açın bakın, benim videolarımdan önce kullanıldığını bulabilecek misiniz? `-r 1+s` parametresi bile benden çıktı; öncesini araştırın, bulamazsınız. Çok matah bir şey yapmış gibi söylemiyorum, sadece durumu belirtiyorum.
> 
> Sonrasında bu konulara ilgim arttı. ByeDPI Linux üzerinde sistem geneli yapılamıyordu; bunun yöntemini az araştırmadım ve yine **ilk ben paylaştım**. Hatta buradaki *byedpi-Turkey* paylaşımı da benim videomdan ilhamla ortaya çıktı. 
> 
> Aynı şekilde **B4**'ü de kimse bilmezken yine ilk ben gösterdim.
> 
> İlgi alanımı az çok anlamışsınızdır. Ben de bu doğrultuda ufak tefek, işi kolaylaştıran programlar yapayım dedim. Daha önce yapmıştım ama o sürümde sistemde DNS değiştirmek gerekiyordu.
> 
> ### Gelelim işin patladığı yere: `gost`
> DNS zorunluluğunu `gost` ile kaldırabildiğimi fark ettiğimde büyük bir heyecanla bunu paylaşmak istedim. Sadece Windows için olan programımı Linux için de port ettim. Yapay zeka yardımı almış olsam bile, sisteme "al sıfırdan yap" demedim; çalışma mantığına ve mimarisine tamamen ben hakimim.
> 
> **gost** büyük bir proje ve GitHub'da 18 bin yıldızı var. Bilen bilir ama bilmeyenler işte böyle VirusTotal sonuçlarına bakarak insanı kolayca töhmet altında bırakabiliyor.
> 
> **O gördüğünüz uyarıların tamamı `gost` kullanımından kaynaklanmaktadır.** Durum buyken, burada çıkıp benim programımı hedef göstererek *"Bu virüslü, uzak durun"* demek hiç yakışmıyor.
> 
> Artık projede `gost` yerine **sing-box** kullanıyorum ve aynı etkiyi bu şekilde elde ediyorum. Yoksa bu asılsız iddialar başımı çok ağrıtacaktı.
> 
> **Sizden bir özür ve bu haksız ithamlar için düzeltme bekliyorum.**



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
      ├─► [Çevre Değişkeni: export https_proxy=[http://127.0.0.1:8849](http://127.0.0.1:8849)]
      ├─► [Gost/sing-box - [http://127.0.0.1:8849](http://127.0.0.1:8849)] (Gelen HTTP proxy isteklerini TLS DNS ile çözüp ByeDPI'a iletir)
      │
      ▼ (Güvenli DNS ile çözülen trafik buraya tünellenir)
[ByeDPI (ciadpi)] (127.0.0.1:8848 - Belirlenen bypass stratejisiyle)
      │
      ▼ (Sansürsüz ve engelsiz)
[Discord Sunucuları]
