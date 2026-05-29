# RockFMTurkey · DNS Kayıtları

**Domain:** rockfmturkey.com
**Registrar:** IHS Telekom (panel: ihs.com.tr)
**Hedef sunucu:** Hetzner CPX22, Falkenstein
**Public IPv4:** `188.245.113.199`

---

## IHS Panel'de Eklenecek A Kayıtları

Abdullah Abi IHS panel girişinden veya bize panel erişimini paylaşırsa, aşağıdaki kayıtların eklenmesi gerekiyor:

| Name (Subdomain) | Type | Value | TTL | Açıklama |
|------------------|------|-------|-----|----------|
| `@` | A | `188.245.113.199` | 3600 | Ana domain (rockfmturkey.com → landing page) |
| `www` | A | `188.245.113.199` | 3600 | www.rockfmturkey.com → landing page |
| `stream` | A | `188.245.113.199` | 3600 | stream.rockfmturkey.com → Azuracast (canlı yayın + admin panel) |

## Mevcut Name Server'lar

```
NS1.IHSDNSW1.COM
NS2.IHSDNSW1.COM
```

Bunlar IHS'in kendi DNS'i — değişiklik gerekmiyor, kayıtları sadece IHS panel üzerinden ekleyeceğiz.

## Test Komutları (kayıt eklendikten sonra)

```bash
# A kaydı doğru çözünüyor mu?
dig +short rockfmturkey.com
dig +short www.rockfmturkey.com
dig +short stream.rockfmturkey.com

# Hepsi `188.245.113.199` döndürmeli
```

## DNS Yayılma Süresi

- Türkiye içinden: 5-15 dakika
- Dünya geneli: 24 saate kadar
- TTL 3600 saniye (1 saat) — değişiklikler ~1 saatte cache'lerden temizlenir

## SSL Sertifikası

DNS yayılması tamamlandıktan sonra, sunucuda Let's Encrypt sertifikası otomatik alınacak (Azuracast içinde built-in):
- `stream.rockfmturkey.com` → HTTPS
- `rockfmturkey.com` + `www.rockfmturkey.com` → HTTPS

---

## Abdullah Abi'ye İletilecek Mesaj Taslağı

> Abdullah Abi,
>
> Sunucu hazır, şimdi domain ayarlarını yapmamız lazım. IHS Telekom paneline (ihs.com.tr) girip aşağıdaki 3 kaydı eklemen veya panel giriş bilgilerini bana iletmen yeterli, ben de ekleyebilirim:
>
> 1. `@` (ana domain) → A → 188.245.113.199
> 2. `www` → A → 188.245.113.199
> 3. `stream` → A → 188.245.113.199
>
> Hepsinin TTL'i 3600. Bu kayıtlar eklenir eklenmez ~15 dakikada Türkiye'den erişilebilir olur, HTTPS sertifikası otomatik alınır.
>
> Panel'e nasıl ulaşacaksın bilmiyorsan IHS'in info@ihs.com.tr adresine "domain panel erişimi" diye yazabilirsin, sana e-posta atarlar.
>
> Hakan
