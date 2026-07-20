# Linux Sunucu Sağlık İzleme ve Otomatik Yedekleme Sistemi

Bu proje, bir Linux sunucusunun sağlık durumunu (CPU, RAM, disk) düzenli aralıklarla otomatik kontrol eden ve kritik veriyi otomatik olarak yedekleyen, production mantığıyla kurulmuş bir sistemdir. DevOps öğrenme sürecimin ilk uygulamalı projesi olarak, gerçek bir Ubuntu sunucusunda (Multipass ile oluşturulmuş VM) sıfırdan kuruldu ve test edildi.

## Özellikler

- **Sağlık İzleme:** CPU, RAM, disk ve şimdi log dosyası boyutunu da ölçer, belirlenen eşiği aşan durumları loglar
- **Otomatik Yedekleme:** Belirlenen dizini `tar.gz` ile sıkıştırıp tarih damgalı şekilde yedekler, 7 günden eski yedekleri otomatik temizler
- **Otomasyon:** Sağlık kontrolü systemd timer ile her 5 dakikada bir, yedekleme cron ile her gece 02:00'de otomatik çalışır
- **Güvenlik:** SSH key-based authentication zorunlu (şifreyle giriş kapalı), least privilege prensibiyle sınırlandırılmış sudo yetkileri

## Kullanılan Teknolojiler

- Bash scripting (`set -euo pipefail`, `getopts`, `trap`, fonksiyonlar)
- systemd (service + timer unit'leri)
- cron
- SSH (key-based auth, sshd_config hardening)
- Linux dosya izinleri ve sudo/visudo yapılandırması

## Neden Bu Şekilde Tasarladım?

**Neden cron yerine systemd timer kullandım (health check için)?**
systemd timer, journalctl ile entegre loglama sağlıyor ve `Persistent=true` ile sunucu kapalıyken kaçırılan bir çalışma zamanını, sunucu tekrar açıldığında telafi edebiliyor — cron'da bu özellik yok. Yine de yedekleme görevini bilinçli olarak cron ile bıraktım, çünkü ikisini de gerçek hayatta kullanabilmek ve farklarını görmek istedim.

**Neden `set -euo pipefail` kullandım?**
Production script'lerinde sessizce yarım kalan bir işlemin fark edilmemesi ciddi bir risktir. Bu satır, herhangi bir komut hata verirse script'i hemen durdurur, tanımsız değişken kullanımını yakalar ve pipe içindeki hataları görünür kılar.

**Neden yedekleme script'i çalışırken kendi kendini yedekleme sorunu yaşadım, nasıl çözdüm?**
İlk versiyonda `--exclude` yolunu mutlak yol (`/home/devopsuser/backups`) olarak verdim, ama tar arşiv içinde göreceli yol kullandığı için exclude eşleşmiyordu — yedek dosyası kendi kendini de arşivliyordu. Çözüm: exclude yolunu da tar'ın kullandığı göreceli formatla eşleştirdim. Bu, `tar -tzvf` ile arşiv içeriğini kontrol ederek fark ettiğim gerçek bir hataydı.

**Neden SSH şifre girişini tamamen kapattım?**
Şifreyle giriş, brute-force saldırılarına açık bir yüzey oluşturur. Key-based authentication kurduktan sonra şifre girişini kapatmak, production sunucularında standart bir güvenlik pratiğidir.

**Neden `devopsuser`'a sınırsız sudo yerine visudo ile özel bir kural tanımladım?**
Least privilege prensibi gereği, bir kullanıcının/servisin sadece gerçekten ihtiyacı olan yetkiye sahip olması gerekir. Bu projede `devopsuser`'a sadece kendi servisini yönetme (restart/status) yetkisini, şifre sormadan, ama başka hiçbir komuta genişletilmeyecek şekilde tanımladım.

## Kurulum

1. Bir Ubuntu sunucusu hazırlayın (bu proje Multipass ile oluşturulmuş bir Ubuntu 26.04 VM üzerinde geliştirilip test edilmiştir).

2. Script'leri `scripts/` dizininden sunucunuza kopyalayın ve çalıştırma izni verin:
   ```bash
   chmod +x scripts/health_check.sh scripts/backup.sh
   ```

3. Log dosyalarını oluşturun:
   ```bash
   sudo touch /var/log/health_alerts.log /var/log/backup.log /var/log/backup_cron.log
   sudo chown $USER:$USER /var/log/health_alerts.log /var/log/backup.log /var/log/backup_cron.log
   ```

4. systemd service ve timer dosyalarını kopyalayın:
   ```bash
   sudo cp systemd/health-check.service /etc/systemd/system/
   sudo cp systemd/health-check.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now health-check.timer
   ```

5. Yedekleme için crontab'a şu satırı ekleyin (`crontab -e`):
   ```
   0 2 * * * /path/to/scripts/backup.sh >> /var/log/backup_cron.log 2>&1
   ```

## Test Etme

```bash
# Health check'i manuel çalıştır (özel eşik ile)
./scripts/health_check.sh -t 90

# Timer durumunu kontrol et
systemctl list-timers --all | grep health-check

# Yedeklemeyi manuel test et
./scripts/backup.sh

# Yedeğin kendi kendini içermediğini doğrula
tar -tzvf "$(ls -t ~/backups/*.tar.gz | head -1)" | grep backups
```

## Karşılaşılan Zorluklar

- **PATH ve mutlak yol sorunları:** Cron ve systemd'nin minimal environment ile çalıştığını göz önünde bulundurup, script'lerde her yerde mutlak yol kullandım.
- **Log dosyası izin hataları:** `/var/log` dizinine normal kullanıcının yazamadığını, dosyaları önceden `sudo touch` + `chown` ile hazırlamam gerektiğini deneyerek öğrendim.
- **tar --exclude eşleşme sorunu:** Yukarıda "Neden Bu Şekilde Tasarladım" bölümünde detaylandırdım.

## Yazar

**Mehmet Can** — Yazılım Mühendisliği öğrencisi, DevOps alanına geçiş sürecinde.
GitHub: [mehmetcankavak](https://github.com/mehmetcankavak)
