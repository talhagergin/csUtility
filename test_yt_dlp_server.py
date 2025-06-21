#!/usr/bin/env python3
"""
yt-dlp Web Server Test Script
Bu script, yt-dlp web sunucusunun düzgün çalışıp çalışmadığını test eder.
"""

import requests
import json
import time
import sys

# Sunucu URL'i
BASE_URL = "http://localhost:5001"

def test_health_check():
    """Sağlık kontrolü testi"""
    print("🔍 Sağlık kontrolü test ediliyor...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Sunucu sağlıklı: {data}")
            return True
        else:
            print(f"❌ Sağlık kontrolü başarısız: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Sağlık kontrolü hatası: {e}")
        return False

def test_video_formats():
    """Video formatları testi"""
    print("\n🔍 Video formatları test ediliyor...")
    # Test video ID (kısa bir YouTube videosu)
    test_video_id = "dQw4w9WgXcQ"  # Rick Roll
    
    try:
        response = requests.get(f"{BASE_URL}/formats/{test_video_id}")
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                formats = data.get('formats', [])
                print(f"✅ {len(formats)} format bulundu")
                print(f"📹 Video başlığı: {data.get('title', 'N/A')}")
                return True
            else:
                print(f"❌ Format listesi başarısız: {data.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ Format listesi hatası: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Format listesi hatası: {e}")
        return False

def test_video_download():
    """Video indirme testi"""
    print("\n🔍 Video indirme test ediliyor...")
    # Test video URL (kısa bir YouTube videosu)
    test_video_url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    
    try:
        # İndirme isteği gönder
        download_data = {
            "url": test_video_url,
            "format": "worst",  # En düşük kalite (hızlı test için)
            "output": "test_%(id)s.%(ext)s"
        }
        
        response = requests.post(
            f"{BASE_URL}/download",
            json=download_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                download_id = data.get('download_id')
                print(f"✅ İndirme başlatıldı: {download_id}")
                
                # İndirme durumunu takip et
                return monitor_download(download_id)
            else:
                print(f"❌ İndirme başlatma başarısız: {data.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ İndirme isteği hatası: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ İndirme testi hatası: {e}")
        return False

def monitor_download(download_id):
    """İndirme durumunu takip et"""
    print(f"📊 İndirme durumu takip ediliyor: {download_id}")
    
    max_attempts = 30  # Maksimum 30 deneme
    attempts = 0
    
    while attempts < max_attempts:
        try:
            response = requests.get(f"{BASE_URL}/status/{download_id}")
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    status = data.get('status', {})
                    download_status = status.get('status', 'unknown')
                    
                    if download_status == 'starting':
                        print("⏳ İndirme başlatılıyor...")
                    elif download_status == 'downloading':
                        progress = status.get('progress', 0) * 100
                        speed = status.get('speed', 0)
                        eta = status.get('eta', 0)
                        print(f"📥 İndiriliyor: %{progress:.1f} (Hız: {speed} B/s, Kalan: {eta}s)")
                    elif download_status == 'completed':
                        print("✅ İndirme tamamlandı!")
                        return True
                    elif download_status == 'error':
                        error = status.get('error', 'Unknown error')
                        print(f"❌ İndirme hatası: {error}")
                        return False
                    else:
                        print(f"❓ Bilinmeyen durum: {download_status}")
                        return False
                else:
                    print(f"❌ Durum kontrolü başarısız: {data.get('error', 'Unknown error')}")
                    return False
            else:
                print(f"❌ Durum kontrolü hatası: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Durum kontrolü hatası: {e}")
            return False
        
        attempts += 1
        time.sleep(2)  # 2 saniye bekle
    
    print("⏰ İndirme zaman aşımına uğradı")
    return False

def test_cleanup():
    """Temizlik testi"""
    print("\n🔍 Temizlik test ediliyor...")
    try:
        response = requests.post(f"{BASE_URL}/cleanup")
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                deleted_count = data.get('deleted_files', 0)
                print(f"✅ Temizlik tamamlandı: {deleted_count} dosya silindi")
                return True
            else:
                print(f"❌ Temizlik başarısız: {data.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ Temizlik hatası: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Temizlik hatası: {e}")
        return False

def main():
    """Ana test fonksiyonu"""
    print("🚀 yt-dlp Web Server Test Başlatılıyor...")
    print(f"📍 Sunucu URL: {BASE_URL}")
    print("=" * 50)
    
    tests = [
        ("Sağlık Kontrolü", test_health_check),
        ("Video Formatları", test_video_formats),
        ("Video İndirme", test_video_download),
        ("Temizlik", test_cleanup)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🧪 {test_name} testi...")
        if test_func():
            passed += 1
            print(f"✅ {test_name} başarılı")
        else:
            print(f"❌ {test_name} başarısız")
    
    print("\n" + "=" * 50)
    print(f"📊 Test Sonuçları: {passed}/{total} başarılı")
    
    if passed == total:
        print("🎉 Tüm testler başarılı! Sunucu düzgün çalışıyor.")
        return 0
    else:
        print("⚠️  Bazı testler başarısız. Sunucu yapılandırmasını kontrol edin.")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 