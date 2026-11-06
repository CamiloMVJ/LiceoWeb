(() => {
    const endpoint = document.currentScript?.dataset.sugerencias;
    for (const grado of document.querySelectorAll('[data-grado-escolar]')) {
        const modalidad = grado.form?.querySelector('[data-modalidad-escolar]');
        if (!modalidad) continue;
        const actualizar = () => {
            modalidad.textContent = grado.selectedOptions[0]?.dataset.modalidad || 'Se asigna al elegir el grado';
        };
        grado.addEventListener('change', actualizar);
        actualizar();
    }
    if (!endpoint) return;

    for (const campo of document.querySelectorAll('input[data-buscar-estudiante]')) {
        const libre = campo.hasAttribute('data-busqueda-libre');
        const visible = libre ? campo : document.createElement('input');
        if (!libre) {
            visible.id = campo.id;
            campo.removeAttribute('id');
            visible.className = campo.className;
            visible.required = campo.required;
            visible.value = campo.value;
            campo.type = 'hidden';
            campo.before(visible);
        }
        visible.type = 'search';
        visible.maxLength = 100;
        visible.placeholder = 'Escribe el nombre del estudiante';
        visible.autocomplete = 'off';
        if (!visible.id && !visible.hasAttribute('aria-label'))
            visible.setAttribute('aria-label', 'Buscar estudiante por nombre');

        const lista = document.createElement('div');
        lista.className = 'list-group mb-2';
        lista.setAttribute('aria-label', 'Estudiantes encontrados');
        const estado = document.createElement('div');
        estado.className = 'small';
        estado.setAttribute('role', 'status');
        const grupo = document.createElement('div');
        grupo.className = 'flex-grow-1';
        visible.before(grupo);
        grupo.append(visible, lista, estado);

        let espera, solicitud;
        visible.addEventListener('input', () => {
            clearTimeout(espera);
            solicitud?.abort();
            lista.replaceChildren();
            estado.textContent = '';
            if (!libre) {
                campo.value = '';
                visible.setCustomValidity(visible.value.trim() ? 'Selecciona un estudiante de los resultados.' : '');
            }
            const nombre = visible.value.trim();
            if (nombre.length < 2) return;
            espera = setTimeout(async () => {
                const actual = new AbortController();
                solicitud = actual;
                try {
                    const url = new URL(endpoint, location.href);
                    url.searchParams.set('nombre', nombre);
                    const respuesta = await fetch(url, { signal: actual.signal, headers: { Accept: 'application/json' } });
                    if (!respuesta.ok || respuesta.redirected) throw new Error();
                    const resultados = await respuesta.json();
                    if (actual.signal.aborted) return;
                    estado.textContent = resultados.length ? 'Selecciona una coincidencia.' : 'No se encontraron estudiantes activos.';
                    for (const estudiante of resultados) {
                        const opcion = document.createElement('button');
                        opcion.type = 'button';
                        opcion.className = 'list-group-item list-group-item-action';
                        opcion.textContent = `${estudiante.nombre} · ${estudiante.grado} · ${estudiante.registro}`;
                        opcion.addEventListener('click', () => {
                            campo.value = estudiante.registro;
                            visible.value = libre ? estudiante.registro : estudiante.nombre;
                            visible.setCustomValidity('');
                            lista.replaceChildren();
                            estado.textContent = 'Seleccionado: ' + estudiante.nombre;
                            visible.focus();
                        });
                        lista.append(opcion);
                    }
                } catch {
                    if (!actual.signal.aborted) estado.textContent = 'No se pudo consultar. Intenta de nuevo.';
                }
            }, 250);
        });
        visible.addEventListener('keydown', evento => {
            if (evento.key === 'Escape') {
                clearTimeout(espera);
                solicitud?.abort();
                lista.replaceChildren();
                estado.textContent = '';
            }
            if (evento.key === 'ArrowDown' && lista.firstElementChild) {
                evento.preventDefault();
                lista.firstElementChild.focus();
            }
        });
    }
})();
