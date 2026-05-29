# RockFMTurkey · Hetzner Cloud Firewall Kuralları

**Server:** rockfm-stream-01 (188.245.113.199)
**Hetzner Console:** Cloud → Firewalls → New Firewall

---

## Inbound Rules (Gelen Trafik)

| Source | Port | Protocol | Açıklama |
|--------|------|----------|----------|
| `0.0.0.0/0, ::/0` | `22` | TCP | SSH (admin erişimi) |
| `0.0.0.0/0, ::/0` | `80` | TCP | HTTP (Azuracast + Let's Encrypt verify) |
| `0.0.0.0/0, ::/0` | `443` | TCP | HTTPS (Azuracast admin + landing page) |
| `0.0.0.0/0, ::/0` | `8000` | TCP | Azuracast varsayılan radyo stream portu |
| `0.0.0.0/0, ::/0` | `8005-8015` | TCP | Ek istasyon stream portları (rezerve) |
| `0.0.0.0/0, ::/0` | `2022` | TCP | Azuracast SFTP (admin mp3 yükleme — opsiyonel) |

## Outbound Rules

Tüm outbound trafiği aç (Docker image pull, Let's Encrypt request, vs).
Default: Allow All.

## Önemli Notlar

- **SSH portu:** Üretimde değiştirebiliriz (örn. 2222) ama şimdilik 22 — fail2ban + key-only auth yeterli koruma
- **Stream portları:** Azuracast her istasyon için 2 port kullanır (broadcast + admin/listen). 8000 ana istasyon, 8005-8015 rezerve
- **ICMP (ping):** Default açık — debug için faydalı, kapatmaya gerek yok
- **Cloud Firewall vs UFW:** Hetzner Cloud Firewall yeterli, sunucuda UFW kurmamıza gerek yok (çift güvenlik bazen sorun çıkarır)

## Hetzner Console'da Oluşturma

1. Sol menü: **Cloud → Firewalls**
2. **Create Firewall**
3. Name: `rockfm-firewall`
4. Yukarıdaki tabloya göre Inbound Rules ekle
5. Apply To: **rockfm-stream-01** sunucusunu seç
6. **Create Firewall**

Firewall uygulanır uygulanmaz aktif olur, downtime yok.
