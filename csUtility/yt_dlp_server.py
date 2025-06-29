#!/usr/bin/env python3
"""
yt-dlp Web Server for iOS App
Bu sunucu, iOS uygulamasından gelen video indirme isteklerini yt-dlp ile işler.
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import yt_dlp
import os
import tempfile
import uuid
import threading
import time
from pathlib import Path

app = Flask(__name__)
CORS(app)  # Cross-origin requests için

# İndirilen videoların geçici olarak saklanacağı klasör
DOWNLOAD_DIR = Path("downloads")
DOWNLOAD_DIR.mkdir(exist_ok=True)

# İndirme durumlarını takip etmek için
download_status = {}

class ProgressHook:
    def __init__(self, download_id):
        self.download_id = download_id
    
    def __call__(self, d):
        if d['status'] == 'downloading':
            progress = d.get('downloaded_bytes', 0) / max(d.get('total_bytes', 1), 1)
            download_status[self.download_id] = {
                'status': 'downloading',
                'progress': progress,
                'speed': d.get('speed', 0),
                'eta': d.get('eta', 0)
            }
        elif d['status'] == 'finished':
            download_status[self.download_id] = {
                'status': 'finished',
                'filename': d.get('filename', '')
            }

@app.route('/download', methods=['POST'])
def download_video():
    """Video indirme endpoint'i"""
    try:
        data = request.get_json()
        video_url = data.get('url')
        format_option = data.get('format', 'best[height<=720]')
        output_template = data.get('output', '%(id)s.%(ext)s')
        
        print(f"🔍 DEBUG: Gelen istek - URL: {video_url}")
        print(f"🔍 DEBUG: Format: {format_option}")
        print(f"🔍 DEBUG: Output template: {output_template}")
        
        if not video_url:
            print("❌ DEBUG: URL eksik")
            return jsonify({'success': False, 'error': 'URL gerekli'}), 400
        
        # Benzersiz indirme ID'si oluştur
        download_id = str(uuid.uuid4())
        print(f"🔍 DEBUG: Download ID oluşturuldu: {download_id}")
        
        # yt-dlp options
        ydl_opts = {
            'format': format_option,
            'outtmpl': str(DOWNLOAD_DIR / output_template),
            'progress_hooks': [ProgressHook(download_id)],
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
        }
        
        print(f"🔍 DEBUG: yt-dlp options: {ydl_opts}")
        
        # İndirme durumunu başlat
        download_status[download_id] = {
            'status': 'starting',
            'progress': 0.0
        }
        
        # Arka planda indirme işlemini başlat
        def download_thread():
            try:
                print(f"🔍 DEBUG: İndirme başlatılıyor...")
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    info = ydl.extract_info(video_url, download=True)
                    filename = ydl.prepare_filename(info)
                    print(f"🔍 DEBUG: İndirme tamamlandı - Dosya: {filename}")
                    print(f"🔍 DEBUG: Dosya boyutu: {os.path.getsize(filename) if os.path.exists(filename) else 'Dosya yok'}")
                    
                    download_status[download_id] = {
                        'status': 'completed',
                        'filename': filename,
                        'title': info.get('title', ''),
                        'duration': info.get('duration', 0),
                        'view_count': info.get('view_count', 0)
                    }
                    print(f"🔍 DEBUG: Status güncellendi: {download_status[download_id]}")
            except Exception as e:
                print(f"❌ DEBUG: İndirme hatası: {e}")
                download_status[download_id] = {
                    'status': 'error',
                    'error': str(e)
                }
        
        thread = threading.Thread(target=download_thread)
        thread.start()
        
        response_data = {
            'success': True,
            'download_id': download_id,
            'message': 'İndirme başlatıldı'
        }
        print(f"🔍 DEBUG: Response gönderiliyor: {response_data}")
        return jsonify(response_data)
        
    except Exception as e:
        print(f"❌ DEBUG: Genel hata: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/status/<download_id>', methods=['GET'])
def get_download_status(download_id):
    """İndirme durumunu kontrol et"""
    if download_id not in download_status:
        return jsonify({'success': False, 'error': 'İndirme bulunamadı'}), 404
    
    status = download_status[download_id]
    return jsonify({
        'success': True,
        'status': status
    })

@app.route('/download/<download_id>', methods=['GET'])
def get_downloaded_file(download_id):
    """İndirilen dosyayı al"""
    print(f"🔍 DEBUG: Dosya indirme isteği - ID: {download_id}")
    
    if download_id not in download_status:
        print(f"❌ DEBUG: Download ID bulunamadı: {download_id}")
        return jsonify({'success': False, 'error': 'İndirme bulunamadı'}), 404
    
    status = download_status[download_id]
    print(f"🔍 DEBUG: Status: {status}")
    
    if status['status'] != 'completed':
        print(f"❌ DEBUG: İndirme henüz tamamlanmadı - Status: {status['status']}")
        return jsonify({'success': False, 'error': 'İndirme henüz tamamlanmadı'}), 400
    
    filename = status.get('filename')
    print(f"🔍 DEBUG: Dosya yolu: {filename}")
    
    if not filename or not os.path.exists(filename):
        print(f"❌ DEBUG: Dosya bulunamadı: {filename}")
        return jsonify({'success': False, 'error': 'Dosya bulunamadı'}), 404
    
    file_size = os.path.getsize(filename)
    print(f"🔍 DEBUG: Dosya boyutu: {file_size} bytes")
    print(f"🔍 DEBUG: Dosya gönderiliyor...")
    
    return send_file(filename, as_attachment=True)

@app.route('/health', methods=['GET'])
def health_check():
    """Sunucu sağlık kontrolü"""
    return jsonify({
        'success': True,
        'status': 'healthy',
        'yt_dlp_version': yt_dlp.version.__version__
    })

@app.route('/formats/<video_id>', methods=['GET'])
def get_available_formats(video_id):
    """Video için mevcut formatları listele"""
    try:
        video_url = f"https://www.youtube.com/watch?v={video_id}"
        
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'extract_flat': True,
        }
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(video_url, download=False)
            formats = info.get('formats', [])
            
            # Format bilgilerini temizle
            clean_formats = []
            for fmt in formats:
                clean_formats.append({
                    'format_id': fmt.get('format_id', ''),
                    'ext': fmt.get('ext', ''),
                    'resolution': fmt.get('resolution', ''),
                    'filesize': fmt.get('filesize', 0),
                    'vcodec': fmt.get('vcodec', ''),
                    'acodec': fmt.get('acodec', ''),
                    'height': fmt.get('height', 0),
                    'width': fmt.get('width', 0),
                })
            
            return jsonify({
                'success': True,
                'formats': clean_formats,
                'title': info.get('title', ''),
                'duration': info.get('duration', 0),
                'view_count': info.get('view_count', 0)
            })
            
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/cleanup', methods=['POST'])
def cleanup_old_files():
    """Eski dosyaları temizle"""
    try:
        # 24 saatten eski dosyaları sil
        current_time = time.time()
        deleted_count = 0
        
        for file_path in DOWNLOAD_DIR.glob('*'):
            if file_path.is_file():
                file_age = current_time - file_path.stat().st_mtime
                if file_age > 86400:  # 24 saat
                    file_path.unlink()
                    deleted_count += 1
        
        return jsonify({
            'success': True,
            'deleted_files': deleted_count
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    print("yt-dlp Web Server başlatılıyor...")
    print("Sunucu: http://localhost:5001")
    print("Sağlık kontrolü: http://localhost:5001/health")
    
    # Geliştirme sunucusu
    app.run(host='0.0.0.0', port=5001, debug=True) 