# yt-dlp Web Server

Bu sunucu, iOS uygulamasından gelen video indirme isteklerini yt-dlp ile işler.

## Kurulum

### 1. Python Gereksinimleri
```bash
# Python 3.8+ gerekli
python3 --version

# Gerekli paketleri yükle
pip3 install -r requirements.txt
```

### 2. yt-dlp Kurulumu
```bash
# yt-dlp'yi güncelleyin
pip3 install --upgrade yt-dlp
```

## Kullanım

### 1. Sunucuyu Başlat
```bash
python3 yt_dlp_server.py
```

Sunucu http://localhost:5001 adresinde çalışacak.

### 2. Sağlık Kontrolü
```bash
curl http://localhost:5001/health
```

### 3. Video İndirme
```bash
curl -X POST http://localhost:5001/download \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.youtube.com/watch?v=VIDEO_ID",
    "format": "best[height<=720]",
    "output": "%(id)s.%(ext)s"
  }'
```

### 4. İndirme Durumu Kontrolü
```bash
curl http://localhost:5001/status/DOWNLOAD_ID
```

### 5. İndirilen Dosyayı Al
```bash
curl http://localhost:5001/download/DOWNLOAD_ID -o video.mp4
```

## API Endpoints

### POST /download
Video indirme isteği gönder.

**Request Body:**
```json
{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID",
  "format": "best[height<=720]",
  "output": "%(id)s.%(ext)s"
}
```

**Response:**
```json
{
  "success": true,
  "download_id": "uuid-string",
  "message": "İndirme başlatıldı"
}
```

### GET /status/{download_id}
İndirme durumunu kontrol et.

**Response:**
```json
{
  "success": true,
  "status": {
    "status": "downloading",
    "progress": 0.5,
    "speed": 1024000,
    "eta": 30
  }
}
```

### GET /download/{download_id}
İndirilen dosyayı al.

### GET /health
Sunucu sağlık kontrolü.

### GET /formats/{video_id}
Video için mevcut formatları listele.

### POST /cleanup
Eski dosyaları temizle.

## iOS Uygulaması Entegrasyonu

VideoDownloadService.swift dosyasında `ytDlpServiceURL` değişkenini güncelleyin:

```swift
private let ytDlpServiceURL = "http://your-server-ip:5001"
```

## Güvenlik Notları

1. **Firewall:** Sunucuyu sadece güvenilir ağlarda çalıştırın
2. **Rate Limiting:** Çok fazla istek gönderilmesini engelleyin
3. **Authentication:** Gerekirse API key ekleyin
4. **HTTPS:** Prodüksiyonda HTTPS kullanın

## Sorun Giderme

### yt-dlp Hatası
```bash
# yt-dlp'yi güncelleyin
pip3 install --upgrade yt-dlp

# Test edin
yt-dlp --version
```

### Port Çakışması
```bash
# Farklı port kullanın
python3 yt_dlp_server.py --port 5001
```

### Dosya İzinleri
```bash
# downloads klasörü için izin verin
chmod 755 downloads/
```

## Prodüksiyon Dağıtımı

### Docker ile
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY yt_dlp_server.py .

EXPOSE 5001
CMD ["python", "yt_dlp_server.py"]
```

### Systemd Service
```ini
[Unit]
Description=yt-dlp Web Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/server
ExecStart=/usr/bin/python3 yt_dlp_server.py
Restart=always

[Install]
WantedBy=multi-user.target
``` 