# CyberDash

Dashboard de sécurité cyber statique et fiable, conçu pour tourner sur un LXC Debian 13 sous Proxmox.

## Philosophie

- **Aucune dépendance Python** : pas de `uv`, pas de `uvicorn`, pas de `.venv`.
- **Stack minimale** : HTML/CSS/JS pur + `nginx` + `bash` + `cron`.
- **Fiable** : pas de runtime à maintenir, pas de dépendances à mettre à jour, le site est servi en statique par nginx.

## Contenu du projet

| Fichier | Rôle |
|---------|------|
| `index.html` | Page dashboard principale |
| `style.css` | Styles (thème sombre, responsive) |
| `script.js` | Horloge, chargement des actus, statut système |
| `fetch-news.sh` | Script bash qui récupère les flux RSS cyber et génère `news.html` |
| `cgi-bin/status.sh` | CGI bash retournant le statut LXC en JSON |
| `deploy-debian13.sh` | Script d'installation complète sur Debian 13 |

## Fonctionnalités

1. **Actus cyber** : agrégation de plusieurs flux RSS (CERT-FR, BleepingComputer, The Hacker News, CISA). Générée côté serveur par `fetch-news.sh` via cron, servie en statique.
2. **Outils métiers** : grille d'outils classés par catégorie (reconnaissance, vulnérabilités, exploitation, mots de passe, forensique, réseau).
3. **Liens rapides** : CISA, CERT-FR, BleepingComputer, The Hacker News, VirusTotal, abuse.ch.
4. **Statut LXC** : uptime, charge CPU, mémoire, disque via un CGI bash léger.

## Déploiement rapide (sur le LXC Debian 13)

```bash
# En root sur le LXC
apt-get update && apt-get install -y git nginx libxml2-utils curl fcgiwrap
git clone <votre-depot> /root/cyberdash   # ou copiez les fichiers manuellement
cd /root/cyberdash
bash deploy-debian13.sh
```

Puis accédez à : `http://<IP-du-LXC>/`

## Mise à jour des actus

Les actus sont régénérées toutes les heures par cron. Pour forcer un rafraîchissement manuel :

```bash
bash /root/cyberdash/fetch-news.sh
```

## Personnalisation

- **Flux RSS** : éditez le tableau `FEEDS` dans `fetch-news.sh`.
- **Outils** : modifiez la grille dans `index.html` (section `.tools`).
- **Port / domaine** : adaptez `/etc/nginx/sites-available/cyberdash`.

## Aucun build requis

Ouvrez directement `index.html` dans un navigateur pour tester localement, ou déployez avec nginx sur le LXC. Pas de `npm install`, pas de `pip`, pas de compilation.
