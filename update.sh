#!/bin/bash

# Playlist klasörünü tazele
mkdir -p playlist
rm -f playlist/*.m3u8

echo "🚀 Yayın linkleri YouTube üzerinden taranıyor..."

# Kanal listesini oku
cat link.json | jq -c '.[]' | while read -r i; do
    name=$(echo "$i" | jq -r '.name')
    target_url=$(echo "$i" | jq -r '.url')
    
    echo "🔍 $name için link aranıyor..."

    # YouTube sayfasından manifest linkini cımbızla çek
    raw_manifest=$(curl -sL "$target_url" | grep -o "https://manifest.googlevideo.com[^[:space:]\"']*" | head -n 1)

    if [[ "$raw_manifest" == http* ]]; then
        cat <<EOF > "playlist/${name}.m3u8"
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720
$raw_manifest
EOF
        echo "   ✅ $name başarıyla oluşturuldu."
    else
        echo "   ❌ $name için link bulunamadı!"
    fi
    sleep 1
done

# Ana Playlisti Oluştur
echo "#EXTM3U" > playlist/playlist.m3u
for file in playlist/*.m3u8; do
    [ -e "$file" ] || continue
    fname=$(basename "$file" .m3u8)
    echo "#EXTINF:-1,$fname" >> playlist/playlist.m3u
    echo "https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/main/${file}?t=$(date +%s)" >> playlist/playlist.m3u
done
