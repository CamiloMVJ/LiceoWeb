// Prueba de eventos y accesibilidad con Node, sin dependencias ni base de datos.
// La geometría se simula aquí; browser.cjs cubre el navegador cuando esté disponible.
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync(path.resolve(__dirname, '../../LiceoWeb/wwwroot/js/graficos-financieros.js'), 'utf8');
class Element {
    constructor() {
        this.events = {}; this.attrs = {}; this.dataset = {}; this.style = {};
        this.classes = new Set(); this.hidden = true; this.parent = null;
        this.classList = { add: c => this.classes.add(c), remove: c => this.classes.delete(c) };
    }
    addEventListener(name, action) { (this.events[name] ||= []).push(action); }
    fire(name, data = {}) { for (const action of this.events[name] || []) action({ target: this, preventDefault() {}, ...data }); }
    setAttribute(name, value) { this.attrs[name] = value; }
    removeAttribute(name) { delete this.attrs[name]; }
    contains(target) { for (let n = target; n; n = n.parent) if (n === this) return true; return false; }
    getBoundingClientRect() { return this.box || { left: 0, top: 0, width: 280, height: 200 }; }
}
const chart = new Element(), tooltip = new Element(), document = new Element(), window = new Element();
const fields = Object.fromEntries(['date','entradas','devoluciones','neto'].map(key => [key, { textContent: '' }]));
const periods = [0,1,2].map(i => {
    const item = new Element(); item.parent = chart;
    item.dataset = [
        { date: 'lunes 09/11/2026', entradas: 'C$ 1,600.00', devoluciones: 'C$ 250.00', neto: 'C$ 1,350.00' },
        { date: 'martes 10/11/2026', entradas: 'C$ 0.00', devoluciones: 'C$ 150.00', neto: 'C$ -150.00' },
        { date: 'noviembre 2026', entradas: 'C$ 0.00', devoluciones: 'C$ 0.00', neto: 'C$ 0.00' }
    ][i];
    item.box = { left: 30+i*48, top: 100, width: 40, height: 200 };
    item.titleRemoved = false;
    item.querySelector = name => name === 'title' ? { remove: () => { item.titleRemoved = true; } } : null;
    item.focus = () => {
        document.activeElement?.fire('blur'); document.activeElement = item; item.fire('focus');
    };
    return item;
});
chart.querySelectorAll = () => periods;
chart.querySelector = () => tooltip;
tooltip.id = 'detalle'; tooltip.parent = chart;
tooltip.querySelector = selector => fields[selector.match(/data-fin-(\w+)/)[1]];
document.querySelectorAll = () => [chart]; document.activeElement = null;
document.body = new Element(); document.body.appendChild = element => { element.parent = document.body; };
window.innerWidth = 1100; window.innerHeight = 700;
vm.runInNewContext(source, { document, window });
const check = (name, action) => { action(); console.log('PASS '+name); };
const mouse = { pointerType: 'mouse', clientX: 100, clientY: 200 };
const key = value => { const data = { key: value }; document.activeElement?.fire('keydown', data); document.fire('keydown', data); };
check('un solo punto de Tab y sin title duplicado', () => {
    assert.equal(periods.filter(p => p.tabIndex === 0).length, 1);
    assert(periods.every(p => p.titleRemoved));
});
check('hover muestra fecha, entradas, devoluciones y neto', () => {
    periods[0].fire('pointerenter', mouse);
    assert.equal(tooltip.hidden, false);
    for (const field of Object.keys(fields)) assert.equal(fields[field].textContent, periods[0].dataset[field]);
    assert.equal(periods[0].attrs['aria-describedby'], 'detalle');
    assert.equal(periods[0].attrs['aria-expanded'], 'true');
});
check('contenido del tooltip se puede recorrer con el puntero', () => {
    periods[0].fire('pointerleave', { ...mouse, relatedTarget: tooltip });
    assert.equal(tooltip.hidden, false);
    tooltip.fire('pointerleave', { relatedTarget: document.body });
    assert.equal(tooltip.hidden, true);
    assert.equal(periods[0].attrs['aria-expanded'], 'false');
});
check('foco y flechas actualizan el detalle, incluido neto negativo', () => {
    periods[0].focus(); key('ArrowRight');
    assert.equal(document.activeElement, periods[1]);
    assert.equal(fields.neto.textContent, 'C$ -150.00');
    assert.equal(periods.filter(p => p.tabIndex === 0).length, 1);
});
check('Home/End, mes agregado e importes cero', () => {
    key('End'); assert.equal(document.activeElement, periods[2]);
    assert.equal(fields.date.textContent, 'noviembre 2026');
    assert.equal(fields.neto.textContent, 'C$ 0.00');
    key('Home'); assert.equal(document.activeElement, periods[0]);
});
check('Enter fija el detalle y Escape lo cierra', () => {
    key('Enter'); periods[0].fire('pointerleave', mouse);
    assert.equal(tooltip.hidden, false);
    key('Escape'); assert.equal(tooltip.hidden, true);
    assert.equal(periods[0].attrs['aria-describedby'], undefined);
});
check('toque abre y segundo toque cierra', () => {
    document.activeElement = null;
    periods[0].fire('pointerenter', { pointerType: 'touch' });
    assert.equal(tooltip.hidden, true);
    periods[0].fire('click', { pointerType: 'touch', detail: 1 });
    assert.equal(tooltip.hidden, false);
    periods[0].fire('click', { pointerType: 'touch', detail: 1 });
    assert.equal(tooltip.hidden, true);
});
check('clic fuera cierra el detalle fijado', () => {
    periods[0].fire('click', { detail: 0 });
    document.fire('pointerdown', { target: document.body });
    assert.equal(tooltip.hidden, true);
});
check('posicionamiento limitado al viewport, incluso móvil', () => {
    periods[0].fire('pointerenter', { pointerType: 'mouse', clientX: 1095, clientY: 695 });
    assert(Number.parseFloat(tooltip.style.left)+280 <= 1100);
    assert(Number.parseFloat(tooltip.style.top)+200 <= 700);
    window.innerWidth = 390; window.innerHeight = 740;
    periods[0].fire('pointermove', { pointerType: 'mouse', clientX: 385, clientY: 735 });
    assert(Number.parseFloat(tooltip.style.left) >= 12);
    assert(Number.parseFloat(tooltip.style.left)+280 <= 390);
    assert(Number.parseFloat(tooltip.style.top)+200 <= 740);
});
check('scroll cierra con ratón; foco de teclado se reposiciona', () => {
    window.fire('scroll'); assert.equal(tooltip.hidden, true);
    periods[1].focus(); window.fire('scroll'); assert.equal(tooltip.hidden, false);
    window.fire('resize'); assert.equal(tooltip.hidden, false);
});
check('datos se insertan como texto, sin interpretar HTML', () => {
    periods[2].dataset.date = '<img src=x onerror=alert(1)>';
    periods[2].focus(); assert.equal(fields.date.textContent, '<img src=x onerror=alert(1)>');
});
