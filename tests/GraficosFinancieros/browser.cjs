// Requiere Node y Playwright. Prueba el componente con importes ficticios, sin SQL Server.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '../..');
const css = fs.readFileSync(path.join(root, 'LiceoWeb/wwwroot/css/site.css'), 'utf8');
const source = path.join(root, 'LiceoWeb/wwwroot/js/graficos-financieros.js');
const values = [
    ['lunes 09/11/2026', 'C$ 1,600.00', 'C$ 250.00', 'C$ 1,350.00'],
    ['martes 10/11/2026', 'C$ 0.00', 'C$ 150.00', 'C$ -150.00'],
    ['noviembre 2026', 'C$ 0.00', 'C$ 0.00', 'C$ 0.00']
];
const fixture = `<html lang="es"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:24px;font-family:system-ui}section{max-width:660px}svg{min-width:1000px}</style>
<h1 id="outside">Cobros y devoluciones</h1><section class="fin-chart" data-fin-chart>
<div class="fin-chart-scroll"><svg viewBox="0 0 1000 260" role="group">
${values.map((v, i) => `<g id="p${i}" class="fin-period" data-fin-period tabindex="0" role="button" aria-expanded="false" aria-controls="tip"
 data-date="${v[0]}" data-entradas="${v[1]}" data-devoluciones="${v[2]}" data-neto="${v[3]}">
<title>Respaldo sin JS</title><rect class="fin-period-hit" x="${26+i*48}" y="35" width="40" height="181" fill="transparent" />
<rect class="fin-period-bar" x="${30+i*48}" y="80" width="15" height="135" fill="#1b264f" /></g>`).join('')}
</svg></div><div class="fin-tooltip" data-fin-tooltip id="tip" role="tooltip" hidden>
<p class="fin-tooltip-date" data-fin-date></p><dl><div><dt>Entradas</dt><dd data-fin-entradas></dd></div><div><dt>Devoluciones</dt><dd data-fin-devoluciones></dd></div><div><dt>Neto</dt><dd data-fin-neto></dd></div></dl></div></section></html>`;
(async () => {
    const browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH } : {}) });
    const errors = [];
    try {
        const page = await browser.newPage({ viewport: { width: 1100, height: 700 } });
        page.on('pageerror', e => errors.push(e.message));
        await page.setContent(fixture);
        await page.addStyleTag({ content: css });
        // Sin JS: la descripción SVG sigue presente.
        assert.equal(await page.locator('#p0 title').count(), 1);
        await page.addScriptTag({ path: source });
        const tip = page.locator('#tip');
        await page.locator('#p0 .fin-period-bar').hover();
        assert(await tip.isVisible());
        assert.equal(await tip.locator('[data-fin-entradas]').textContent(), values[0][1]);
        assert.equal(await tip.locator('[data-fin-devoluciones]').textContent(), values[0][2]);
        assert.equal(await tip.locator('[data-fin-neto]').textContent(), values[0][3]);
        assert.equal(await page.locator('#p0').getAttribute('aria-describedby'), 'tip');
        assert.equal(await page.locator('#p0 title').count(), 0);
        console.log('PASS hover con fecha, entradas, devoluciones y neto; sin tooltip nativo duplicado.');
        await tip.hover();
        assert(await tip.isVisible());
        await page.locator('#outside').hover();
        assert(!(await tip.isVisible()));
        console.log('PASS detalle permanece al pasar el cursor sobre él y se cierra al salir.');
        await page.locator('#p0').focus();
        await page.keyboard.press('ArrowRight');
        assert.equal(await page.evaluate(() => document.activeElement.id), 'p1');
        assert.equal(await tip.locator('[data-fin-neto]').textContent(), 'C$ -150.00');
        await page.keyboard.press('End');
        assert.equal(await tip.locator('[data-fin-date]').textContent(), 'noviembre 2026');
        assert.equal(await tip.locator('[data-fin-neto]').textContent(), 'C$ 0.00');
        await page.keyboard.press('Escape');
        assert(!(await tip.isVisible()));
        assert.equal(await page.locator('[data-fin-period][tabindex="0"]').count(), 1);
        console.log('PASS teclado, neto negativo, período mensual, importes cero, Escape y foco único.');
        await page.keyboard.press('Home');
        await page.keyboard.press('Enter');
        await page.locator('#outside').hover();
        assert(await tip.isVisible());
        await page.keyboard.press('Escape');
        assert(!(await tip.isVisible()));
        console.log('PASS fijar detalle con Enter y cerrar con Escape.');
        await page.locator('#outside').click();
        await page.locator('#p0').dispatchEvent('pointerenter', { pointerType: 'mouse', clientX: 1095, clientY: 695 });
        const box = await tip.boundingBox();
        assert(box.x >= 0 && box.y >= 0 && box.x + box.width <= 1100 && box.y + box.height <= 700);
        await page.locator('.fin-chart-scroll').evaluate(el => { el.scrollLeft = 150; });
        await page.waitForFunction(() => document.querySelector('#tip').hidden);
        console.log('PASS detalle dentro de la pantalla y cierre al desplazar el gráfico.');
        const mobile = await browser.newPage({ viewport: { width: 390, height: 740 }, isMobile: true, hasTouch: true });
        mobile.on('pageerror', e => errors.push(e.message));
        await mobile.setContent(fixture);
        await mobile.addStyleTag({ content: css });
        await mobile.addScriptTag({ path: source });
        await mobile.locator('#p0 .fin-period-bar').tap();
        assert(await mobile.locator('#tip').isVisible());
        const mobileBox = await mobile.locator('#tip').boundingBox();
        assert(mobileBox.x >= 0 && mobileBox.x + mobileBox.width <= 390);
        await mobile.locator('#p0 .fin-period-bar').tap({ force: true });
        assert(!(await mobile.locator('#tip').isVisible()));
        await mobile.locator('#p0 .fin-period-bar').tap();
        await mobile.locator('#outside').tap();
        assert(!(await mobile.locator('#tip').isVisible()));
        console.log('PASS móvil: tocar para abrir/fijar, volver a tocar o tocar fuera para cerrar.');
        assert.deepEqual(errors, []);
        console.log('PASS sin errores JavaScript.');
    } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
