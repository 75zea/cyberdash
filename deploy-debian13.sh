#!/bin/bash
# deploy-debian13.sh — Déploie CyberDash sur un LXC Debian 13.
# Aucune dépendance Python, uv, uvicorn ou .venv.
# Seul nginx + bash + cron sont utilisés.
# À exécuter en root sur le LXC.

set -euo pipefail

echo "=== Déploiement CyberDash sur Debian 13 ==="

# 1. Installation des paquets système uniquement
apt-get update
apt-get install -y nginx libxml2-utils curl

# 2. Création des répertoires
WWW_ROOT="/var/www/cyberdash"
mkdir -p "$WWW_ROOT"
mkdir -p /var/www/cgi-bin

# 3. Copie des fichiers statiques (à adapter selon où vous placez le dossier cyberdash)
# Si ce script est lancé depuis le dossier contenant cyberdash/ :
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cyberdash"
cp -r "$SRC_DIR/index.html" "$SRC_DIR/style.css" "$SRC_DIR/script.js" "$WWW_ROOT/"
chown -R www-data:www-data "$WWW_ROOT"
chmod 755 "$WWW_ROOT"

# 4. Copie du CGI statut
cp "$SRC_DIR/cgi-bin/status.sh" /usr/lib/cgi-bin/status.sh
chmod 755 /usr/lib/cgi-bin/status.sh

# 5. Génération initiale des actus
bash "$SRC_DIR/fetch-news.sh"

# 6. Configuration nginx
cat > /etc/nginx/sites-available/cyberdash <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/cyberdash;
    index index.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # CGI pour le statut système
    location /cgi-bin/ {
        gzip off;
        alias /usr/lib/cgi-bin/;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }

    location ~ \.sh$ {
        include fastcgi_params;
        fastcgi_pass unix:/var/run/fcgiwrap.socket;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/cyberdash /etc/nginx/sites-enabled/cyberdash
rm -f /etc/nginx/sites-enabled/default

# 7. Installation de fcgiwrap pour le CGI bash
apt-get install -y fcgiwrap
systemctl enable --now fcgiwrap.socket
systemctl enable --now nginx

# 8. Cron : rafraîchissement des actus toutes les heures
(crontab -l 2>/dev/null | grep -v fetch-news.sh; echo "0 * * * * /root/cyberdash/fetch-news.sh >> /var/log/cyberdash-news.log 2>&1") | crontab -

# 9. Logrotate pour les logs news (optionnel)
cat > /etc/logrotate.d/cyberdash <<'LOGROTATE'
/var/log/cyberdash-news.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
LOGROTATE

echo "=== Installation terminée ==="
echo "Accédez à http://<IP-du-LXC>/"
echo "Les actus se rafraîchissent chaque heure via cron."
