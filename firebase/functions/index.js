const functions = require('firebase-functions');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const cors = require('cors')({ origin: true });

// yt-dlp kurulumu (Firebase Functions'da)
const ytDlpPath = '/tmp/yt-dlp';

// yt-dlp'yi indir ve kur
async function setupYtDlp() {
    if (!fs.existsSync(ytDlpPath)) {
        await new Promise((resolve, reject) => {
            exec('curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /tmp/yt-dlp && chmod +x /tmp/yt-dlp', (error) => {
                if (error) reject(error);
                else resolve();
            });
        });
    }
}

// Video indirme fonksiyonu
exports.downloadVideo = functions.https.onRequest(async (req, res) => {
    cors(req, res, async () => {
        try {
            const { url, format = 'best[height<=720]' } = req.body;
            
            if (!url) {
                return res.status(400).json({ 
                    success: false, 
                    error: 'URL gerekli' 
                });
            }

            // yt-dlp'yi kur
            await setupYtDlp();
            
            // Benzersiz dosya adı oluştur
            const videoId = Date.now().toString();
            const outputPath = `/tmp/${videoId}.%(ext)s`;
            
            // Video indir
            const downloadPromise = new Promise((resolve, reject) => {
                const command = `${ytDlpPath} -f ${format} -o "${outputPath}" "${url}"`;
                
                exec(command, { timeout: 300000 }, (error, stdout, stderr) => {
                    if (error) {
                        reject(error);
                    } else {
                        resolve(stdout);
                    }
                });
            });
            
            const result = await downloadPromise;
            
            // İndirilen dosyayı bul
            const files = fs.readdirSync('/tmp');
            const videoFile = files.find(file => file.startsWith(videoId) && (file.endsWith('.mp4') || file.endsWith('.webm')));
            
            if (!videoFile) {
                return res.status(500).json({ 
                    success: false, 
                    error: 'Video dosyası bulunamadı' 
                });
            }
            
            const videoPath = `/tmp/${videoFile}`;
            const videoBuffer = fs.readFileSync(videoPath);
            
            // Dosyayı sil
            fs.unlinkSync(videoPath);
            
            // Video'yu döndür
            res.set({
                'Content-Type': 'video/mp4',
                'Content-Length': videoBuffer.length,
                'Content-Disposition': `attachment; filename="${videoFile}"`
            });
            
            res.send(videoBuffer);
            
        } catch (error) {
            console.error('Download error:', error);
            res.status(500).json({ 
                success: false, 
                error: error.message 
            });
        }
    });
});

// Video bilgilerini alma fonksiyonu
exports.getVideoInfo = functions.https.onRequest(async (req, res) => {
    cors(req, res, async () => {
        try {
            const { url } = req.query;
            
            if (!url) {
                return res.status(400).json({ 
                    success: false, 
                    error: 'URL gerekli' 
                });
            }

            // yt-dlp'yi kur
            await setupYtDlp();
            
            // Video bilgilerini al
            const infoPromise = new Promise((resolve, reject) => {
                const command = `${ytDlpPath} --dump-json "${url}"`;
                
                exec(command, { timeout: 30000 }, (error, stdout, stderr) => {
                    if (error) {
                        reject(error);
                    } else {
                        resolve(stdout);
                    }
                });
            });
            
            const result = await infoPromise;
            const videoInfo = JSON.parse(result);
            
            res.json({
                success: true,
                data: {
                    title: videoInfo.title,
                    duration: videoInfo.duration,
                    thumbnail: videoInfo.thumbnail,
                    formats: videoInfo.formats?.slice(0, 5) || [] // İlk 5 format
                }
            });
            
        } catch (error) {
            console.error('Info error:', error);
            res.status(500).json({ 
                success: false, 
                error: error.message 
            });
        }
    });
});

// Sağlık kontrolü
exports.health = functions.https.onRequest((req, res) => {
    cors(req, res, () => {
        res.json({
            success: true,
            status: 'healthy',
            timestamp: new Date().toISOString()
        });
    });
}); 