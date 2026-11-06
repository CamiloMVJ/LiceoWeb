(() => {
    const form = document.querySelector('[data-contexto-academico]');
    if (form) {
        form.addEventListener('change', event => {
            if (event.target.name === 'anio') { form.elements.pensum.value = '0'; form.elements.grupo.value = '0'; }
            if (event.target.name === 'pensum') form.elements.grupo.value = '0';
            form.requestSubmit();
        });
    }
    const modalidad = document.querySelector('[data-modalidad-plan]');
    const grado = document.querySelector('[data-grado-plan]');
    const grados = document.querySelector('[data-grados-plan]');
    if (modalidad && grado && grados) {
        const actualizarGrados = () => {
            const clave = modalidad.selectedOptions[0]?.dataset.modalidad;
            grado.replaceChildren(new Option(clave ? 'Seleccionar grado o nivel' : 'Primero selecciona una modalidad', ''));
            if (clave) {
                for (const opcion of grados.content.querySelectorAll('option')) {
                    if (opcion.dataset.modalidad === clave) grado.append(opcion.cloneNode(true));
                }
            }
            grado.disabled = !clave;
        };
        modalidad.addEventListener('change', actualizarGrados);
        modalidad.form.addEventListener('submit', event => {
            if (grado.disabled || !grado.value) {
                event.preventDefault();
                (grado.disabled ? modalidad : grado).reportValidity();
            }
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
