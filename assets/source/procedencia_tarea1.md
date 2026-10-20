# SKYLINE / Rooftop Run

Actualización del 6 de octubre de 2026 para Alberto.

Arte original de práctica creado mediante código con asistencia de Codex.
Herramienta: Python (tools/build_parkour.py) y primitivas nativas de Godot 4.7.2.
No usa Tripo, Meshy, imágenes descargadas, texturas externas ni plugins.
Geometría y materiales originales disponibles bajo CC0 1.0.

Personaje: mensajero con casco, visor oscuro, ojos cian, traje marfil,
guantes y pantalón azul oscuro, mochila de energía y bufanda naranja.
Altura aproximada: 1.9 m; unidades métricas; frente -Z, arriba +Y.
La cápsula del controlador mide 1.8 m. Casco y accesorios pueden sobresalir
visualmente; no tienen colisiones independientes.

El modelo se encuentra en scenes/courier_visual.tscn. Todas las piezas se pueden
editar en 3D. Usa normales y materiales generados por las primitivas del motor,
sin UV de textura externa, esqueleto o deformación. courier_visual.gd anima
pivotes de brazos y piernas. Este movimiento rígido no equivale a un rig con skin.
El controlador conserva su escena y FSM independientes.

Escenario: 16 plataformas (cinco rectangulares y once circulares), tres puntos
de control intermedios, inicio, meta, quince cristales, ciudad de fondo y sol.
La ciudad y los accesorios son decorativos. Las superficies transitables usan
StaticBody3D y colisiones de caja o cilindro correspondientes a su forma.

Comprobación: recorrido automático con saltos físicos reales, recolección,
aterrizaje, final y caída/reaparición. Ver output/evidence/parkour_results.json.
El laboratorio anterior y su recurso glTF siguen disponibles en scenes/level.tscn.
