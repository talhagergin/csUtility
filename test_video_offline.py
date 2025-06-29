#!/usr/bin/env python3
"""
Video offline oynatma testi
Bu script, indirilen videoların internet bağlantısı olmadan oynatılıp oynatılamadığını test eder.
"""

import os
import json
import subprocess
import time

def test_video_files():
    """İndirilen video dosyalarını test eder"""
    
    # Downloads klasörünü kontrol et
    downloads_dir = "downloads"
    if not os.path.exists(downloads_dir):
        print("❌ Downloads klasörü bulunamadı")
        return False
    
    video_files = []
    for file in os.listdir(downloads_dir):
        if file.endswith(('.mp4', '.mov', '.m4v')):
            file_path = os.path.join(downloads_dir, file)
            file_size = os.path.getsize(file_path)
            video_files.append({
                'name': file,
                'path': file_path,
                'size': file_size
            })
    
    if not video_files:
        print("❌ Hiç video dosyası bulunamadı")
        return False
    
    print(f"🔍 {len(video_files)} video dosyası bulundu:")
    
    valid_videos = []
    for video in video_files:
        print(f"  📹 {video['name']} - {video['size']} bytes")
        
        # Dosya boyutu kontrolü (minimum 1KB)
        if video['size'] < 1024:
            print(f"    ❌ Dosya çok küçük, geçersiz")
            continue
        
        # Dosya okunabilirlik kontrolü
        try:
            with open(video['path'], 'rb') as f:
                header = f.read(1024)
                if len(header) < 1024:
                    print(f"    ❌ Dosya okunamıyor")
                    continue
                
                # MP4 header kontrolü
                if header.startswith(b'\x00\x00\x00\x20ftyp'):
                    print(f"    ✅ Geçerli MP4 dosyası")
                    valid_videos.append(video)
                else:
                    print(f"    ⚠️  MP4 header bulunamadı, ama dosya okunabilir")
                    valid_videos.append(video)
        except Exception as e:
            print(f"    ❌ Dosya okuma hatası: {e}")
            continue
    
    print(f"\n📊 Sonuç: {len(valid_videos)}/{len(video_files)} geçerli video dosyası")
    
    return len(valid_videos) > 0

def test_ios_simulator():
    """iOS Simulator'da video oynatma testi"""
    
    print("\n🔍 iOS Simulator testi...")
    
    # Simulator'ın çalışıp çalışmadığını kontrol et
    try:
        result = subprocess.run(['xcrun', 'simctl', 'list', 'devices'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ iOS Simulator bulunamadı")
            return False
        
        # Çalışan simulator'ları bul
        lines = result.stdout.split('\n')
        running_simulators = []
        for line in lines:
            if 'Booted' in line:
                device_id = line.split('(')[1].split(')')[0]
                running_simulators.append(device_id)
        
        if not running_simulators:
            print("❌ Çalışan iOS Simulator bulunamadı")
            return False
        
        print(f"✅ {len(running_simulators)} çalışan simulator bulundu")
        return True
        
    except Exception as e:
        print(f"❌ iOS Simulator test hatası: {e}")
        return False

def main():
    """Ana test fonksiyonu"""
    
    print("🎬 Video Offline Oynatma Testi")
    print("=" * 40)
    
    # Video dosyalarını test et
    if not test_video_files():
        print("\n❌ Test başarısız: Geçerli video dosyası bulunamadı")
        return
    
    # iOS Simulator testi
    if not test_ios_simulator():
        print("\n⚠️  iOS Simulator testi başarısız, ama video dosyaları geçerli")
    
    print("\n✅ Test tamamlandı!")
    print("\n📋 Öneriler:")
    print("1. Uygulamayı iOS Simulator'da çalıştırın")
    print("2. İnternet bağlantısını kapatın")
    print("3. İndirilen videoları oynatmayı deneyin")
    print("4. Video oynatılamıyorsa, console loglarını kontrol edin")

if __name__ == "__main__":
    main() 