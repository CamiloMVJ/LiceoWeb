(() => {
    const form = document.querySelector('[data-contexto-academico]');
    if (form) {
        form.addEventListener('change', event => {
            if (event.target.name === 'anio') { form.elements.pensum.value = '0'; form.elements.grupo.value = '0'; }
            if (event.target.name === 'pensum') form.elements.grupo.value = '0';
            form.requestSubmit();
        });
    }
    const modo = document.querySelector('[data-modo-evaluacion]');
    if (modo) {
        const actualizar = () => {
            document.querySelectorAll('[data-modo-campos]').forEach(panel => {
                panel.hidden = panel.dataset.modoCampos !== modo.value;
                panel.querySelectorAll('input,textarea,select').forEach(input => { input.disabled = panel.hidden; });
            });
        };
        modo.addEventListener('change', actualizar);
        actualizar();
    }
})();
