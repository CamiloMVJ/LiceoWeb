// Navegación móvil desplegable en el flujo de la página; no es un diálogo modal.
(() => {
    const button = document.getElementById('liceo-menu-toggle');
    const sidebar = document.getElementById('liceo-sidebar');
    if (!button || !sidebar) return;
    const mobile = window.matchMedia('(max-width: 767px)');
    const setOpen = open => { sidebar.hidden = !open; button.setAttribute('aria-expanded', String(open)); };
    const adapt = () => setOpen(!mobile.matches);
    button.hidden = false;
    button.addEventListener('click', () => setOpen(sidebar.hidden));
    sidebar.addEventListener('keydown', event => {
        if (event.key === 'Escape' && mobile.matches) { setOpen(false); button.focus(); }
    });
    mobile.addEventListener('change', adapt);
    adapt();
})();
