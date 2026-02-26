#!/bin/bash

# --- AYARLAR ---
cd "$(dirname "$0")"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Git Güvenlik: Ana dal kontrolü
git checkout main || git checkout -b main

# Temizlik
mkdir -p playlist
rm -f playlist/*.m3u8

echo ">>> Kanallar taranıyor (Yüksek Kalite Modu)..."

# User-Agent tanımlayalım (Engellenmemek için)
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

cat link.json | jq -c '.[]' | while read -r i; do
    name=$(echo "$i" | jq -r '.name')
    target_url=$(echo "$i" | jq -r '.url')
    
    echo ">>> $name güncelleniyor..."

    # Linki çek ve temizle
    raw_manifest=$(curl -L -i -s --user-agent "$UA" --max-time 20 "$target_url" | grep -o "https://manifest.googlevideo.com[^[:space:]\"']*" | head -n 1 | tr -d '\r\n')

    if [[ "$raw_manifest" == http* ]]; then
        # EN YÜKSEK KALİTE AYARI: 
        # Master playlist içine en yüksek profili tanımlıyoruz.
        cat <<EOF > "playlist/${name}.m3u8"
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-STREAM-INF:BANDWIDTH=8000000,RESOLUTION=1920x1080,FRAME-RATE=60.000,CODECS="avc1.640028,mp4a.40.2"
$raw_manifest
EOF
        echo "   [OK] $name (1080p/60fps Hazır)"
    else
        echo "   [!] HATA: $name için manifest bulunamadı."
    fi
    
    sleep 1.5 # Sunucu sağlığı için biraz daha yavaş
done

# --- ANA M3U OLUŞTURMA ---
echo ">>> Ana playlist oluşturuluyor..."
echo "#EXTM3U" > playlist/playlist.m3u

for file in playlist/*.m3u8; do
    [ -s "$file" ] || continue
    fname=$(basename "$file" .m3u8)
    
    if grep -q "googlevideo" "$file"; then
        # IPTV oynatıcılarda logo ve grup görünmesi için zenginleştirilmiş format:
        echo "#EXTINF:-1 tvg-name=\"$fname\" group-title=\"Kanallar\",$fname" >> playlist/playlist.m3u
        # Cache kırma (Timestamp)
        echo "https://raw.githubusercontent.com/tecotv2025/tecotv/main/playlist/${fname}.m3u8?t=$(date +%s)" >> playlist/playlist.m3u
    fi
done

# --- GITHUB PUSH ---
git add .
if ! git diff-index --quiet HEAD --; then
    git commit -m "Auto-Refresh: $(date +'%d-%m-%Y %H:%M') - HQ"
    git push origin HEAD:main --force
else
    echo "Değişiklik yok."
fi
