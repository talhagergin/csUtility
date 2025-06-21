# Firebase Functions Kurulum Rehberi

## 🚀 Firebase Projesi Oluşturma

### 1. Firebase Console'da Proje Oluştur
1. [Firebase Console](https://console.firebase.google.com/)'a git
2. "Create a project" tıkla
3. Proje adı: `csUtility-video-downloader`
4. Google Analytics'i kapat (opsiyonel)
5. "Create project" tıkla

### 2. Firebase CLI Kurulumu
```bash
npm install -g firebase-tools
```

### 3. Firebase'e Giriş
```bash
firebase login
```

### 4. Proje Başlatma
```bash
cd /Users/talhagergin/Desktop/Projects/csUtility
firebase init functions
```

**Seçenekler:**
- Use an existing project: `csUtility-video-downloader`
- Language: JavaScript
- ESLint: Yes
- Install dependencies: Yes

### 5. Proje Yapısı
```
csUtility/
├── firebase/
│   ├── .firebaserc
│   ├── firebase.json
│   └── functions/
│       ├── package.json
│       ├── index.js
│       └── node_modules/
└── csUtility/ (iOS app)
```

## 🔧 Firebase Functions Deployment

### 1. Dependencies Kurulumu
```bash
cd firebase/functions
npm install
```

### 2. Functions Deployment
```bash
firebase deploy --only functions
```

### 3. Deployment Sonrası URL'leri Al
Deployment tamamlandıktan sonra şu URL'leri alacaksınız:
- `https://us-central1-csUtility-video-downloader.cloudfunctions.net/downloadVideo`
- `https://us-central1-csUtility-video-downloader.cloudfunctions.net/getVideoInfo`
- `https://us-central1-csUtility-video-downloader.cloudfunctions.net/health`

## 📱 iOS App Entegrasyonu

### 1. URL'leri Güncelle
`VideoDownloadService.swift` dosyasında:
```swift
private let firebaseURL = "https://us-central1-csUtility-video-downloader.cloudfunctions.net"
```

### 2. Test Et
```bash
curl -X POST https://us-central1-csUtility-video-downloader.cloudfunctions.net/health
```

## 💰 Firebase Pricing

### Ücretsiz Plan (Spark):
- **Functions**: 125K çağrı/ay
- **Storage**: 5GB
- **Bandwidth**: 1GB/ay

### Ücretli Plan (Blaze):
- **Functions**: $0.40/milyon çağrı
- **Storage**: $0.026/GB/ay
- **Bandwidth**: $0.15/GB

## 🔒 Güvenlik

### 1. CORS Ayarları
Functions'da CORS zaten ayarlanmış.

### 2. Rate Limiting (Opsiyonel)
```javascript
// functions/index.js'e ekle
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100 // IP başına maksimum 100 istek
});

app.use(limiter);
```

## 🧪 Test

### 1. Health Check
```bash
curl https://us-central1-csUtility-video-downloader.cloudfunctions.net/health
```

### 2. Video Info Test
```bash
curl "https://us-central1-csUtility-video-downloader.cloudfunctions.net/getVideoInfo?url=https://www.youtube.com/watch?v=dQw4w9WgXcQ"
```

### 3. Download Test
```bash
curl -X POST https://us-central1-csUtility-video-downloader.cloudfunctions.net/downloadVideo \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.youtube.com/watch?v=dQw4w9WgXcQ"}'
```

## 🚨 Sorun Giderme

### 1. Functions Timeout
- Varsayılan: 60 saniye
- Video indirme için yeterli olabilir
- Gerekirse artır: `functions.runWith({timeoutSeconds: 300})`

### 2. Memory Limit
- Varsayılan: 256MB
- Video işleme için yeterli
- Gerekirse artır: `functions.runWith({memory: '512MB'})`

### 3. Cold Start
- İlk çağrı yavaş olabilir
- Warm-up fonksiyonu eklenebilir 