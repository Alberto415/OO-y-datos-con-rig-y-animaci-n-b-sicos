# Procedencia del mensajero

Autor de entrega: Alberto. Fuente indicada por el usuario:
https://github.com/Alberto415/Tarea-1-Escena-base-y-modelo-generado-con-IA
Commit consultado: `3800517dbe27de3c0f72e1b68a289f06d8bea216`.
Archivo original: `scenes/courier_visual.tscn`, actualización SKYLINE.
La procedencia original declara geometría y materiales CC0 1.0,
creados con Python y primitivas de Godot, con asistencia de Codex.
Se conservan escena, declaración y prompt histórico en `assets/source/`.

## Adaptación de Tarea 2 (16 de octubre de 2026)

Herramienta: Godot 4.7.2, GDScript, `tools/build_rig.gd`.
No se usaron Mixamo, Blender, Tripo, Meshy, texturas externas o extensiones.
Entrada: consigna de Tarea 2 facilitada por Alberto y enlace a Tarea 1.
Decisión de autoría: reutilizar las 30 piezas del mensajero, crear seis huesos,
skin rígida de peso 1 por pieza y clips Idle, Walk y Jump; exportar a GLB e
importarlo en Godot. El código del generador conserva todos los ajustes.

- Root y cinco huesos hijos (brazos, piernas, bufanda); reposos en pivotes originales.
- Transformaciones originales horneadas; normales con inversa transpuesta.
- Sin deformación blanda de rodillas/codos: todo vértice conserva una única influencia.
- Idle 1.0 s, Walk 1.0 s, Jump 1.2 s; bucles explícitos y crossfade de 0.20 s.
- Walk ±0.48 rad; brazos de Jump hasta -1.1 rad; sin traslación de raíz.
- Jump es un clip de pose in-place; el laboratorio no simula un salto balístico.
- Recurso visual independiente: `courier_rig.glb`. Fuente nativa: `courier_rig.tscn`.
- Controlador de selección: `scripts/character_lab.gd`.

Verificaciones: GLB importado con seis huesos y tres clips; poses finitas durante
más de 60 s; deriva de raíz cero. Ver `output/evidence/animation_checks.json`.
Revisión visual: piezas unidas en Idle/Walk/Jump, sin estiramientos ni colapsos
graves observados en las capturas y muestras del video. Esta revisión no es
una evaluación de deformación orgánica, porque el personaje es segmentado.

La asistencia de IA abarcó implementación, rig, clips, documentación y análisis.
Los números del benchmark proceden de CSV medidos; los videos a paso fijo
son demostraciones y no entran en el análisis estadístico.
