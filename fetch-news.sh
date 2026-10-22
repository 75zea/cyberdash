#!/bin/bash
# fetch-news.sh — Récupère les actus cyber depuis des flux RSS et génère un fichier HTML statique.
# Aucune dépendance Python. Nécessite uniquement : curl, xmllint (libxml2-utils), date.
# À lancer via cron (ex: toutes les heures).

set -euo pipefail

OUT_DIR="/var/www/cyberdash"
OUT_FILE="$OUT_DIR/news.html"
TMP_FILE="$OUT_DIR/news.html.tmp"

# Flux RSS cyber (FR + EN)
FEEDS=(
  "https://www.cert.ssi.gouv.fr/alertes/feed/"
  "https://www.bleepingcomputer.com/feed/"
  "https://feeds.feedburner.com/TheHackersNews"
  "https://www.cisa.gov/uscert/ncas/alerts.xml"
)

MAX_ITEMS=20

echo "<!-- Généré le $(date '+%Y-%m-%d %H:%M:%S') -->" > "$TMP_FILE"

COUNT=0
for FEED in "${FEEDS[@]}"; do
  if [ "$COUNT" -ge "$MAX_ITEMS" ]; then
    break
  fi

  XML=$(curl -sL --max-time 15 --connect-timeout 10 "$FEED" 2>/dev/null || true)
  if [ -z "$XML" ]; then
    continue
  fi

  # Extraction des items avec xmllint (XPath)
  ITEMS=$(echo "$XML" | xmllint --xpath "//item[position()<=5]" - 2>/dev/null || true)
  if [ -z "$ITEMS" ]; then
    continue
  fi

  # Nom de la source (title du canal)
  SOURCE=$(echo "$XML" | xmllint --xpath "string(/rss/channel/title)" - 2>/dev/null || echo "RSS")

  echo "<div class=\"news-item\">" >> "$TMP_FILE"
  echo "  <div class=\"source\">$SOURCE</div>" >> "$TMP_FILE"

  while IFS= read -r ITEM; do
    TITLE=$(echo "$ITEM" | xmllint --xpath "string(title)" - 2>/dev/null || echo "Sans titre")
    LINK=$(echo "$ITEM" | xmllint --xpath "string(link)" - 2>/dev/null || echo "#")
    PUBDATE=$(echo "$ITEM" | xmllint --xpath "string(pubDate)" - 2>/dev/null || echo "")

    # Échappement basique pour HTML
    TITLE_ESC=$(printf '%s' "$TITLE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
    LINK_ESC=$(printf '%s' "$LINK" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')

    echo "  <a href=\"$LINK_ESC\" target=\"_blank\" rel=\"noopener\">$TITLE_ESC</a>" >> "$TMP_FILE"
    if [ -n "$PUBDATE" ]; then
      echo "  <div class=\"date\">$PUBDATE</div>" >> "$TMP_FILE"
    fi
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$MAX_ITEMS" ]; then
      break
    fi
  done <<< "$ITEMS"

  echo "</div>" >> "$TMP_FILE"
done

if [ "$COUNT" -eq 0 ]; then
  echo "<div class=\"news-item\">Aucune actu disponible pour le moment.</div>" >> "$TMP_FILE"
fi

mv "$TMP_FILE" "$OUT_FILE"
echo "News générées : $COUNT articles dans $OUT_FILE"
