(() => {
    'use strict';
    document.querySelectorAll('[data-fin-chart]').forEach(chart => {
        const periods = Array.from(chart.querySelectorAll('[data-fin-period]'));
        const tooltip = chart.querySelector('[data-fin-tooltip]');
        if (!tooltip || !periods.length) return;
        // Escapar del recorte del gráfico y de posibles contextos de apilamiento.
        document.body.appendChild(tooltip);
        const fields = ['date', 'entradas', 'devoluciones', 'neto'];
        let active = null;
        let pinned = false;

        const position = event => {
            if (!active) return;
            const rect = active.getBoundingClientRect();
            const point = event && event.pointerType !== 'touch' ?
                { x: event.clientX, y: event.clientY } :
                { x: rect.left + rect.width / 2, y: rect.top + 35 };
            const box = tooltip.getBoundingClientRect();
            const margin = 12;
            let x = point.x + 16;
            let y = point.y + 16;
            if (x + box.width > window.innerWidth - margin) x = point.x - box.width - 16;
            if (y + box.height > window.innerHeight - margin) y = point.y - box.height - 16;
            tooltip.style.left = `${Math.max(margin, Math.min(x, window.innerWidth - box.width - margin))}px`;
            tooltip.style.top = `${Math.max(margin, Math.min(y, window.innerHeight - box.height - margin))}px`;
        };
        const hide = () => {
            if (active) {
                active.classList.remove('is-active');
                active.setAttribute('aria-expanded', 'false');
                active.removeAttribute('aria-describedby');
            }
            active = null;
            pinned = false;
            tooltip.hidden = true;
        };
        const show = (period, event) => {
            if (active !== period) {
                hide();
                active = period;
            }
            fields.forEach(field => {
                tooltip.querySelector(`[data-fin-${field}]`).textContent = period.dataset[field] || '';
            });
            active.classList.add('is-active');
            active.setAttribute('aria-expanded', 'true');
            active.setAttribute('aria-describedby', tooltip.id);
            tooltip.hidden = false;
            position(event);
        };
        const toggle = (period, event) => {
            if (active === period && pinned) { hide(); return; }
            show(period, event);
            pinned = true;
        };
        const tabStop = period => periods.forEach(item => { item.tabIndex = item === period ? 0 : -1; });
        // Un solo punto de Tab por gráfico; las flechas recorren todas las fechas.
        tabStop(periods[0]);
        periods.forEach((period, index) => {
            // El title SVG queda como respaldo sin JavaScript, evitando dos tooltips a la vez.
            period.querySelector('title')?.remove();
            period.addEventListener('pointerenter', event => {
                if (event.pointerType !== 'touch' && !pinned) show(period, event);
            });
            period.addEventListener('pointermove', event => {
                if (active === period && !pinned && event.pointerType !== 'touch') position(event);
            });
            period.addEventListener('pointerleave', event => {
                if (event.pointerType !== 'touch' && !pinned && document.activeElement !== period && !tooltip.contains(event.relatedTarget)) hide();
            });
            period.addEventListener('focus', () => { tabStop(period); show(period); });
            period.addEventListener('blur', () => { if (!pinned) hide(); });
            period.addEventListener('click', event => {
                tabStop(period);
                // Un clic de teclado no proporciona coordenadas válidas del puntero.
                toggle(period, event.detail === 0 ? undefined : event);
            });
            period.addEventListener('keydown', event => {
                let next;
                if (event.key === 'ArrowRight' || event.key === 'ArrowDown') next = (index + 1) % periods.length;
                if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') next = (index + periods.length - 1) % periods.length;
                if (event.key === 'Home') next = 0;
                if (event.key === 'End') next = periods.length - 1;
                if (next !== undefined) {
                    event.preventDefault();
                    pinned = false;
                    tabStop(periods[next]);
                    periods[next].focus();
                }
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    toggle(period);
                }
            });
        });
        tooltip.addEventListener('pointerleave', event => {
            if (!pinned && !active?.contains(event.relatedTarget) && document.activeElement !== active) hide();
        });
        document.addEventListener('keydown', event => { if (event.key === 'Escape') hide(); });
        document.addEventListener('pointerdown', event => {
            if (!chart.contains(event.target) && !tooltip.contains(event.target)) hide();
        });
        const reflow = event => {
            if (event?.target && event.target !== window && tooltip.contains(event.target)) return;
            if (active && document.activeElement === active && !pinned) position();
            else hide();
        };
        window.addEventListener('resize', reflow);
        window.addEventListener('scroll', reflow, true);
    });
})();
