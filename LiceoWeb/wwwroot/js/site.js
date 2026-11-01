// Conservar el desplazamiento en navegación interna del sistema, por pestaña.
(() => {
    const key = 'liceo:navegacion:scroll:v1';
    const path = url => url.pathname + url.search;
    const read = () => { try { return JSON.parse(sessionStorage.getItem(key)); } catch { return null; } };
    const clear = () => { try { sessionStorage.removeItem(key); } catch { /* Almacenamiento no disponible. */ } };
    const point = node => ({ x: node?.scrollLeft || 0, y: node?.scrollTop || 0 });
    const valid = p => p && Number.isFinite(p.x) && Number.isFinite(p.y) && p.x >= 0 && p.y >= 0;
    let interrupted = false;
    for (const event of ['wheel', 'touchstart', 'pointerdown', 'keydown'])
        window.addEventListener(event, () => { interrupted = true; }, { once: true, passive: true });

    const pending = read();
    clear(); // Solo la navegación inmediata puede consumir este estado.
    const navigationType = performance.getEntriesByType('navigation')[0]?.type;
    if (pending && pending.target === path(new URL(location.href)) && !location.hash &&
        Date.now() - pending.time >= 0 && Date.now() - pending.time < 30000 &&
        navigationType !== 'back_forward' && navigationType !== 'reload' && valid(pending.window)) {
        const restore = () => {
            if (interrupted) return;
            window.scrollTo({ left: pending.window.x, top: pending.window.y, behavior: 'instant' });
            for (const selector of ['.liceo-sidebar', '.liceo-main']) {
                const position = pending.containers?.[selector];
                const node = document.querySelector(selector);
                if (node && valid(position)) node.scrollTo({ left: position.x, top: position.y, behavior: 'instant' });
            }
        };
        requestAnimationFrame(restore);
        if (document.readyState !== 'complete') window.addEventListener('load', () => requestAnimationFrame(restore), { once: true });
    }

    document.addEventListener('click', event => {
        if (event.defaultPrevented || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        const link = event.target.closest?.('.liceo-shell a[href]');
        if (!link || link.hasAttribute('download') || (link.target && link.target !== '_self')) return;
        const target = new URL(link.href, location.href);
        if (target.origin !== location.origin || target.hash || target.pathname === '/' || target.pathname.startsWith('/Identity/')) { clear(); return; }
        try {
            sessionStorage.setItem(key, JSON.stringify({
                target: path(target), time: Date.now(), window: { x: window.scrollX, y: window.scrollY },
                containers: { '.liceo-sidebar': point(document.querySelector('.liceo-sidebar')), '.liceo-main': point(document.querySelector('.liceo-main')) }
            }));
        } catch { /* Navegar normalmente si el navegador impide sessionStorage. */ }
    });
    // Atrás/adelante y BFCache conservan el comportamiento nativo del navegador.
    window.addEventListener('pageshow', event => { if (event.persisted) clear(); });
})();
