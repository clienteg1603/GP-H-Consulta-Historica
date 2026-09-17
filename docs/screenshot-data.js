// Monta a captura enviada pelo usuário a partir de partes de texto.
(async () => {
  try {
    const files = ['gph-img-1.txt','gph-img-2.txt','gph-img-3.txt','gph-img-4.txt'];
    const parts = await Promise.all(files.map(async (file) => {
      const response = await fetch(`${file}?v=20260917-6`, { cache: 'no-store' });
      if (!response.ok) throw new Error(`Falha ao carregar ${file}`);
      return (await response.text()).trim();
    }));
    const src = 'data:image/webp;base64,' + parts.join('');
    window.GPH_SCREENSHOT = src;
    const img = document.getElementById('gph-screenshot');
    if (img) {
      img.style.filter = 'none';
      img.src = src;
    }
  } catch (error) {
    console.error('Falha ao carregar a captura do GP-H:', error);
  }
})();
