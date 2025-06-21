#!/bin/bash

# yt-dlp Web Server Başlatma Scripti

echo "🚀 yt-dlp Web Server başlatılıyor..."

# Python versiyonunu kontrol et
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 bulunamadı. Lütfen Python3'ü yükleyin."
    exit 1
fi

echo "✅ Python3 bulundu: $(python3 --version)"

# Gerekli paketleri kontrol et ve yükle
echo "📦 Gerekli paketler kontrol ediliyor..."

if ! python3 -c "import flask" &> /dev/null; then
    echo "📥 Flask yükleniyor..."
    pip3 install flask flask-cors
fi

if ! python3 -c "import yt_dlp" &> /dev/null; then
    echo "📥 yt-dlp yükleniyor..."
    pip3 install yt-dlp
fi

echo "✅ Tüm paketler hazır"

# downloads klasörünü oluştur
mkdir -p downloads
echo "✅ downloads klasörü oluşturuldu"

# Sunucuyu başlat
echo "🌐 Sunucu başlatılıyor: http://localhost:5001"
echo "📋 Sağlık kontrolü: http://localhost:5001/health"
echo "🛑 Durdurmak için Ctrl+C"
echo ""

python3 yt_dlp_server.py 