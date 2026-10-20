# Registro de aceptación

## Simulación equivalente

`scripts/verify.gd`: 1 000 posiciones comparadas después de cada uno de 2 100 pasos
idénticos a 1/60 s. Error máximo observado: 0.0; tolerancia 0.001 px.
Incluye velocidad constante, integración y envoltura en ambos ejes.
Ambas variantes alimentan exactamente el mismo `_draw()` con 1 000 posiciones.
No hay física en ninguna. Las condiciones se registran y se comparan al analizar.

## Datos reproducibles

`tools/analyze.py` exige seis corridas completas con 5 + 30 s, compara semilla,
entidades, versión del motor, renderer, resolución, VSync y hardware;
verifica muestras, marcas de tiempo crecientes, duración y callbacks de dibujo.
Un conjunto smoke prueba el guardado y el arranque en otra copia, sin incorporarse
al informe. La reproducción completa se documenta en README.

Los tiempos del bloque no sustituyen al tiempo de CPU del profiler; este último
no se capturó. Los videos a paso fijo tampoco sustituyen a los CSV del reloj real.

## Personaje

Escena separada que instancia el GLB exportado/reimportado. Prueba renderizada
de más de 60 s registrada en `output/evidence/animation_checks.json`:
tres clips, seis huesos, poses finitas, transiciones de 0.20 s, raíz inmóvil.
Inspección de capturas Idle, Walk y Jump: sin estiramientos o colapsos graves.
La influencia por pieza es rígida; no se promete deformación orgánica.

## Material de entrega

PDF de ocho páginas, CSV originales y JSON por corrida, tablas CSV y gráficos
PNG/SVG con unidades, fuentes editables Python/Markdown, GLB y escena nativa,
dos MP4 separados, procedencia y declaración de asistencia de IA.
`media_validation.json` registra decodificación completa y duración de ambos MP4.
`manifest.json` registra tamaño y SHA-256 de los archivos de la entrega.

El repositorio Git se preparó localmente. Publicarlo en GitHub y subir los archivos
a la plataforma académica no se realizó desde esta sesión.
El laboratorio enlazado por UAM no fue accesible; se declara esa limitación.
