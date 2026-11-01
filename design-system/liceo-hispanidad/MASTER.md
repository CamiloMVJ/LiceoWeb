# Liceo Hispanidad — sistema visual

## Origen y criterio
Se aplicó UI/UX Pro Max de https://github.com/nextlevelbuilder/ui-ux-pro-max-skill, leyendo SKILL.md y referencias de accesibilidad, interacción y diseño web. Consultas ejecutadas: `school administration dashboard accessible --design-system` y `enterprise operations dashboard --design-system`. Los estilos Accessible & Ethical y Minimalism & Swiss Style son adecuados; los patrones comerciales Single Column/Hero no se trasladaron al panel administrativo. No existe stack Razor/Bootstrap en el catálogo: la implementación usa el HTML semántico y Bootstrap existentes. No se importan Tailwind, React, GSAP ni fuentes remotas.

## Decisiones
- Colores institucionales preservados: azul #1B264F, fondo #F4F6F8 y dorado #C99700. El dorado es acento, no texto pequeño sobre blanco.
- Texto secundario #536176; superficies blancas y bordes #DCE2EA. Controles #7C899B para distinguirlos del fondo.
- Fuente local Segoe UI/Arial, base 16px, interlineado 1.6. Títulos compactos, etiquetas visibles y alineación consistente.
- Botones de acción principal en azul con texto blanco. El dorado destaca la marca y la selección sin depender solo del color.
- Objetivos táctiles de 44px y foco visible. Enlace para saltar al contenido, menú móvil desplegable en el flujo sin overlay ni trampa de foco. Escape lo cierra y devuelve foco al botón.
- Menú de escritorio persistente, navegación móvil plegable. Sin JavaScript el menú sigue visible y usable.
- Tablas legibles y con desplazamiento horizontal dentro de su contenedor, no de toda la página. Sin truncar importes ni ocultar acciones importantes.
- Inicio con accesos reales por rol; no hay métricas, gráficos ni cifras inventadas.
- Movimiento mínimo y respeto de prefers-reduced-motion. Se conserva la lógica de restauración del desplazamiento existente.

## Implementación
`ui-system.css` se carga después de los estilos existentes. Los cambios administrativos se limitan a `.liceo-app`, preservando la portada pública y el documento de impresión independiente. Layout conserva RenderBody, Scripts, rutas y LoginPartial. No cambia autorizaciones, repositorios ni SQL. Se mejora también el foco y la presentación compartida de autenticación.

No declarar certificación WCAG: se verifican pares de colores y comportamientos concretos, pero falta auditoría completa con lectores de pantalla, datos reales y todos los formularios autenticados.
