// CyberDash — JavaScript pur, aucune dépendance

(function () {
  const NEWS_ENDPOINT = './news.html';  // généré par fetch-news.sh
  const REFRESH_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

  // Horloge
  function updateClock() {
    const now = new Date();
    const options = { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' };
    document.getElementById('clock').textContent = now.toLocaleString('fr-FR', options);
  }
  setInterval(updateClock, 1000);
  updateClock();

  // Chargement des actus (fichier HTML statique généré côté serveur)
  async function loadNews() {
    const container = document.getElementById('news-list');
    try {
      const resp = await fetch(NEWS_ENDPOINT + '?t=' + Date.now(), { cache: 'no-store' });
      if (!resp.ok) throw new Error('HTTP ' + resp.status);
      const html = await resp.text();
      container.innerHTML = html;
      document.getElementById('last-update').textContent = 'Dernière mise à jour : ' + new Date().toLocaleTimeString('fr-FR');
    } catch (err) {
      container.innerHTML = '<div class="news-item">Impossible de charger les actus. Vérifiez fetch-news.sh.</div>';
      console.error(err);
    }
  }

  document.getElementById('refresh-news').addEventListener('click', loadNews);

  // Statut système (via un petit endpoint CGI ou valeurs statiques)
  async function loadStatus() {
    try {
      const resp = await fetch('/cgi-bin/status.sh', { cache: 'no-store' });
      if (!resp.ok) return;
      const data = await resp.json();
      if (data.uptime) document.getElementById('stat-uptime').textContent = data.uptime;
      if (data.load) document.getElementById('stat-load').textContent = data.load;
      if (data.mem) document.getElementById('stat-mem').textContent = data.mem;
      if (data.disk) document.getElementById('stat-disk').textContent = data.disk;
    } catch (err) {
      // silencieux si CGI non configuré
    }
  }

  loadNews();
  loadStatus();
  setInterval(loadNews, REFRESH_INTERVAL_MS);
  setInterval(loadStatus, REFRESH_INTERVAL_MS);
})();
