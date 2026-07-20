# Git Workflow Simülasyonu

Bu dosya, DevOps öğrenme sürecimin Git Professional bölümünde, `linux-monitoring-system` reposu üzerinde uyguladığım gerçek Git senaryolarını ve öğrendiklerimi belgeler.

## Yapılan Çalışmalar

1. Interactive rebase ile dağınık commit'lerin temizlenmesi
2. Merge conflict yaratma ve elle çözme
3. Cherry-pick ile tek commit taşıma
4. Reflog ile "kaybedilen" bir commit'in kurtarılması
5. pre-commit hook ile otomatik kod kontrolü


## 1. Interactive Rebase ile Commit Temizleme

`feature/log-rotation` branch'inde, `backup.sh`'e log rotasyonu eklerken bilerek 3 dağınık commit oluşturdum:

\`\`\`
5440c69 ilk deneme log rotasyon
095433b typo duzeltildi ve gzip eklendi
24e1475 esik degeri test edildi 50mb yapildi
\`\`\`

Bunları `git rebase -i HEAD~3` ile tek commit'e indirdim, ilk commit'i `pick`, diğer ikisini `fixup` işaretledim:

\`\`\`bash
git rebase -i HEAD~3
\`\`\`

Sonuç: tek commit (`8200835`). Ardından `git commit --amend` ile mesajını daha açıklayıcı hale getirdim (`ef5e801`).

**Öğrendiğim:** `fixup`, önceki commit'in mesajını korur ve eklenen commit'in mesajını tamamen atar — bu, "typo düzeltildi" gibi anlamsız ara commit'leri sessizce yutmak için idealdir. `squash` kullansaydım, her commit için mesaj onayı istenirdi.


## 2. Merge Conflict Yaratma ve Çözme

`main`'den açtığım `feature/readme-guncelleme` branch'inde README.md'nin "Sağlık İzleme" satırını değiştirdim. Aynı zamanda `main`'de de **aynı satırı** farklı şekilde değiştirdim. Bu iki branch'i merge etmeye çalışınca gerçek bir conflict oluştu:

\`\`\`bash
git merge feature/readme-guncelleme
# CONFLICT (content): Merge conflict in README.md
\`\`\`

Dosyayı açtığımda şu yapıyı gördüm:

\`\`\`
<<<<<<< HEAD
(main'deki versiyon)
=======
(feature/readme-guncelleme'deki versiyon)
>>>>>>> feature/readme-guncelleme
\`\`\`

İki değişikliğin farklı bilgiler içerdiğini fark edip (biri log dosyası yolunu, diğeri log boyutu ölçümünü vurguluyordu), ikisini **birleştiren** tek bir cümle yazarak conflict'i çözdüm, sonra:

\`\`\`bash
git add README.md
git commit
\`\`\`

ile merge'ü tamamladım (`452b763`, iki parent'lı bir merge commit).

**Öğrendiğim:** Conflict çözerken amacım "hangi taraf kazanacak" değil, "iki değişikliğin neden var olduğunu anlayıp doğru birleşimi bulmak" olmalı — bu genelde ne HEAD ne de gelen tarafın birebir aynısı olmuyor.


## 3. Cherry-pick Denemesi

`feature/log-rotation` branch'indeki log rotasyon commit'ini (`ef5e801`), tüm branch'i merge etmeden tek başına almak için cherry-pick kullandım:

\`\`\`bash
git checkout -b test/cherry-pick-deneme
git cherry-pick ef5e801
\`\`\`

Sonuç: aynı içerik, farklı bir commit hash'i (`07f218f`) ile yeni branch'e taşındı.

**Öğrendiğim:** Cherry-pick, orijinal commit'i "kopyalayıp" farklı bir soy ağacına uyguluyor — bu yüzden aynı değişiklik, iki farklı hash ile iki yerde var olabiliyor. Bu, merge'den temel farkı: merge tüm branch'i taşırken, cherry-pick sadece seçilen tek commit'i taşıyor. Deneme amaçlı olduğu için test branch'i sonrasında silindi.

## 4. Reflog ile Kayıp Commit Kurtarma

Bilerek bir commit'i (`d8c7ee1`) `git reset --hard HEAD~1` ile "sildim":

\`\`\`bash
git reset --hard HEAD~1
git log --oneline -3   # d8c7ee1 artık görünmüyor
\`\`\`

Sonra `git reflog` ile HEAD'in geçmiş konumlarını inceledim ve kayıp commit'i buldum:

\`\`\`bash
git reflog
# d8c7ee1 HEAD@{1}: commit: versiyon yorumu eklendi
git reset --hard d8c7ee1
\`\`\`

Commit başarıyla geri geldi.

**Öğrendiğim:** `git reset --hard`, bir commit'i gerçekten silmiyor — sadece hiçbir branch/referans ondan artık işaret etmiyor. Reflog, HEAD'in son birkaç ay içindeki tüm hareketini kaydettiği için, bu tür "yanlışlıkla silme" durumlarının büyük çoğunluğu kurtarılabiliyor. Reflog'un local olduğunu (push edilmediğini) de öğrendim.


## 3. Cherry-pick Denemesi

`feature/log-rotation` branch'indeki log rotasyon commit'ini (`ef5e801`), tüm branch'i merge etmeden tek başına almak için cherry-pick kullandım:

\`\`\`bash
git checkout -b test/cherry-pick-deneme
git cherry-pick ef5e801
\`\`\`

Sonuç: aynı içerik, farklı bir commit hash'i (`07f218f`) ile yeni branch'e taşındı.

**Öğrendiğim:** Cherry-pick, orijinal commit'i "kopyalayıp" farklı bir soy ağacına uyguluyor — bu yüzden aynı değişiklik, iki farklı hash ile iki yerde var olabiliyor. Bu, merge'den temel farkı: merge tüm branch'i taşırken, cherry-pick sadece seçilen tek commit'i taşıyor. Deneme amaçlı olduğu için test branch'i sonrasında silindi.

## 4. Reflog ile Kayıp Commit Kurtarma

Bilerek bir commit'i (`d8c7ee1`) `git reset --hard HEAD~1` ile "sildim":

\`\`\`bash
git reset --hard HEAD~1
git log --oneline -3   # d8c7ee1 artık görünmüyor
\`\`\`

Sonra `git reflog` ile HEAD'in geçmiş konumlarını inceledim ve kayıp commit'i buldum:

\`\`\`bash
git reflog
# d8c7ee1 HEAD@{1}: commit: versiyon yorumu eklendi
git reset --hard d8c7ee1
\`\`\`

Commit başarıyla geri geldi.

**Öğrendiğim:** `git reset --hard`, bir commit'i gerçekten silmiyor — sadece hiçbir branch/referans ondan artık işaret etmiyor. Reflog, HEAD'in son birkaç ay içindeki tüm hareketini kaydettiği için, bu tür "yanlışlıkla silme" durumlarının büyük çoğunluğu kurtarılabiliyor. Reflog'un local olduğunu (push edilmediğini) de öğrendim.
