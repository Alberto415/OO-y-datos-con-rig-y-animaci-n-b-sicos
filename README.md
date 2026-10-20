# Tarea 2 · OO, datos, rig y animación

Entrega individual de Alberto. Proyecto Godot **4.7.2** (Godot 4.x), sin extensiones.
Se reutiliza el mensajero de [Tarea 1](https://github.com/Alberto415/Tarea-1-Escena-base-y-modelo-generado-con-IA).

## Abrir y ejecutar

Importar `project.godot` en Godot y pulsar **F5**. El botón de medición ejecuta
seis corridas y guarda CSV/JSON en `results/`; tarda aproximadamente **3 min 30 s**.
La ventana es de **1280 × 720**, Compatibility/OpenGL, con VSync desactivado.
Mantenerla visible y cerrar grabadores y otras cargas pesadas para repetir la medición.
El botón de animación abre el segundo laboratorio; también se puede ejecutar
`scenes/character.tscn` con F6. **1/2/3** eligen Idle/Walk/Jump, **A** alterna la
secuencia automática de 10 s por clip y **Esc** vuelve al benchmark.

## Reproducir una suite desde PowerShell

Instalar Godot 4.x y colocar su ejecutable en PATH, o sustituir `godot` por su ruta.
En este equipo se usó `C:\Users\gokuf\Downloads\Godot_v4.7.2-stable_win64_console.exe`.

```powershell
godot --headless --path . --import
godot --headless --path . --script scripts/verify.gd
godot --path . -- --suite
```

El primer paso importa el GLB; el segundo verifica equivalencia sin ventana.
**La suite se ejecuta con ventana y render normal.** No añadir `--headless`,
`--fixed-fps`, `--write-movie` ni `--disable-render-loop` a la medición.
Alternativa: `./tools/run_suite.ps1 -Godot 'ruta/al/godot.exe'`.
`--out=res://results/repeticion` guarda otra suite en otra carpeta.
`--smoke --out=res://tmp/smoke` prueba guardado en menos de 5 s: sus datos no son válidos para el informe.

Orden: **OO, DATOS, DATOS, OO, OO, DATOS** (tres pares con orden alternado).
Cada corrida reinicia semilla **20261016**, calienta **5 s** y captura **30 s**
con reloj monotónico. No escribir al disco hasta cerrar la corrida.
El tiempo real total puede exceder unos milisegundos por fronteras de fotograma
y escritura final. La actualización usa delta real; la prueba de equivalencia
usa 2 100 pasos idénticos de 1/60 s, incluidos cruces de bordes.

## Implementaciones y comparación justa

- `scripts/entity.gd`: Node por entidad, estado propio y método `advance()`.
- `scripts/simulation.gd`: ambas rutas; DATOS usa dos PackedVector2Array.
- `scripts/benchmark.gd`: temporización y dibujo compartidos.
- 1 000 entidades; p += v × delta; envoltura en un área de 1120 × 480 px.
- Ambos copian 1 000 posiciones y dibujan 1 000 círculos de radio 2.4 px con el
  mismo CanvasItem. Sin colisiones en ninguna variante. No se mide una versión
  con el dibujo o la física desactivados selectivamente.
- OO se actualiza con llamadas centralizadas a objetos; no hay 1 000 callbacks
  `_process`. Se estudia la representación de estado y el despacho, no el coste
  separado de esos callbacks o del batching visual.
- DATOS es orientación a datos de composición fija, **no un ECS completo**.
  No se usa PhysicsServer3D, que por sí mismo tampoco sería ECS.

## Datos y análisis

Cada CSV tiene un JSON del mismo nombre con motor, hardware, renderer, driver,
resolución, VSync, muestras y semilla. El prefijo identifica la sesión.

| Columna | Unidad | Significado |
| --- | --- | --- |
| frame | índice | Fotograma medido dentro de la corrida |
| elapsed_s | s | Tiempo monotónico desde el final del calentamiento |
| delta_ms | ms | Delta suministrado por Godot |
| frame_wall_ms | ms | Intervalo de reloj entre entradas a `_process` |
| movement_block_ms | ms | Sólo `advance(delta)`, incluido despacho OO |
| snapshot_ms | ms | Copia al buffer visual |
| draw_count | contador | Callbacks de dibujo acumulados en esa corrida |

**Ninguna columna es tiempo de CPU del profiler** ni tiempo exclusivo de GPU.
No se capturó una sesión del profiler; para estudiarla, activar Debugger/Profiler
en el editor y repetir aparte, conservando su sobrecarga como condición distinta.

```powershell
python -m pip install -r tools/requirements.txt
python tools/analyze.py
python tools/build_report.py
```

El análisis selecciona la suite completa más reciente, rechaza smoke y demo,
verifica las condiciones y produce `output/analysis/summary.csv`, `aggregate.csv`,
`analysis.json` y figuras PNG/SVG. Opciones: `--results ruta` y `--session prefijo`.
Se informa mediana e IQR por corrida y mediana de las tres medianas por variante.
Las barras de la figura son Q1-Q3 **entre medianas de corridas**, no entre todos
los fotogramas. Los cuantiles usan interpolación lineal. No se promete aceleración
ni se infieren cache misses. Sólo tres repeticiones limitan la inferencia.

## Rig e importación

`assets/source/courier_original.tscn` conserva el modelo de Tarea 1 sin su script
de pivotes anterior. `tools/build_rig.gd` hornea geometría y normales, asigna skin
rígida de peso 1 y seis huesos, crea los tres clips y exporta GLB. Para regenerar:

```powershell
godot --headless --path . --script tools/build_rig.gd
godot --headless --path . --import
godot --path . scenes/character.tscn -- --test-animation
```

La escena carga **el GLB reimportado**, no la fuente nativa de respaldo.
El controlador selecciona y mezcla los clips; no altera la geometría ni duplica
traslación. Todos los clips son in-place; Jump muestra la pose sin salto físico.
La prueba dura más de 60 s: cada clip acumula al menos 20 s, registra transiciones,
verifica poses finitas y deriva de raíz. Exporta tres capturas y
`output/evidence/animation_checks.json`. Revisar además el aspecto de la skin:
las comprobaciones numéricas no sustituyen observar el personaje.
Procedencia, prompts, licencia declarada y ajustes en `assets/character/PROCEDENCIA.md`.

## Videos y entregables

- `output/pdf/Informe_Tarea_2_Alberto.pdf`: informe de ocho páginas.
- `results/`: datos originales de las seis corridas finales.
- `output/analysis/`: gráficas, tabla resumen y análisis reproducible.
- `output/evidence/benchmark.mp4`: demostración de las 1 000 entidades y fases de medición.
- `output/evidence/animacion.mp4`: video separado de 70 s con clips y transiciones.
- `output/evidence/animation_checks.json`: prueba renderizada independiente.
- `docs/informe_editable.md` y `tools/build_report.py`: texto y fuente del PDF.
- `output/Entrega_Tarea_2_Alberto.zip`: copia transportable del proyecto y entregables.

Para regenerar los videos (con suficiente espacio para AVI intermedio):

```powershell
godot --path . --write-movie output/evidence/benchmark.avi --fixed-fps 30 -- --demo --out=res://tmp/video
godot --path . scenes/character.tscn --write-movie output/evidence/animacion.avi --fixed-fps 30 -- --animation-video
python tools/encode_videos.py
```

El benchmark de video usa tiempo simulado y un rótulo explícito de demostración.
Sus CSV quedan en `tmp/video` y se excluyen del análisis. El video muestra una
corrida OO completa (5 + 30 s) y el inicio de DATOS. Los AVI pueden borrarse
después de verificar los MP4. Las métricas del informe se capturan sin Movie Maker.

## Fuentes y asistencia

Documentación oficial de Godot: PackedVector2Array, Time, The Profiler,
Skeleton3D y Creating movies; enlaces y límites en el informe.
El [laboratorio de UAM](https://ubicua.cua.uam.mx/mod/resource/view.php?id=150718)
no respondió al intento de consulta; hace falta revisarlo si se dispone de acceso.
No se declara leído ni se inventa su contenido.

Se declara asistencia de **Codex** para código, rig, clips, mediciones automatizadas,
análisis y borrador de documentación. Los CSV son mediciones reales del equipo;
Alberto debe revisar y comprender el trabajo para su entrega individual.
