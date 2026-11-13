# Arquitectura de la primera escena

## DDD aplicado de forma gradual

La primera versión separa las reglas que expresan el juego de las herramientas que lo muestran y almacenan. Es una base de DDD para el prototipo; no se presenta como una implementación completa de la arquitectura de toda la campaña.

El vocabulario de esta entrega es héroe, guardia, desarme, encuentro, acceso a Shalem, pareja, actividad completada y recompensa reclamada. Un acceso no es energía de combate. Ganar un encuentro y reclamar una recompensa son transiciones diferentes.

```text
src/
  domain/
    combat/hero_state.gd
    progression/campaign.gd
    activities/memory_board.gd
    story/chapter_progress.gd
    story/narrative_sequence.gd
  application/
    adventure_session.gd
    story_director.gd
  infrastructure/
    persistence/local_save_repository.gd
    content/narrative_repository.gd
    audio/sound_adapter.gd
  presentation/godot/
    game.gd
    actor_view.gd
    enemy_view.gd
    village_view.gd
    game_interface.gd
assets/narrative/
tests/
tools/
```

## Dominio

`HeroState` es una entidad mutable de combate: posee salud, guardia y estado del arma. Decide si un impacto se esquiva, se bloquea, se desvía con parry, rompe la guardia o causa daño. La geometría y la lectura del teclado se resuelven fuera de ella.

`Campaign` es el agregado pequeño de progreso de esta escena. Controla XP, límite de accesos, recompensa única y banderas de misión. Su método de reclamación impide gastar dos accesos o conceder dos copias del mismo recuerdo. Su snapshot duplica los datos para que el almacenamiento no modifique el agregado por referencia.

`MemoryBoard` conserva cartas, selección actual y parejas encontradas. Rechaza seleccionar la misma carta dos veces, una carta resuelta o una tercera carta mientras se compara. La vista decide cuánto mostrar un fallo y qué ayuda visual ofrecer.

`ChapterProgress` mide hitos por acto y define cuándo se puede partir. La XP y las actividades opcionales no completan esos hitos. `NarrativeSequence` mantiene páginas y navegación; avanzar y saltar resuelven el mismo final lógico sin depender del tiempo de lectura.

Estas clases usan `RefCounted` de GDScript. No crean nodos, no leen entrada, no abren archivos y no necesitan una escena para sus pruebas. Siguen requiriendo el runtime de Godot; no son una biblioteca independiente de motor.

## Aplicación y puertos

`AdventureSession` coordina empezar, recuperar checkpoint, terminar encuentro y reclamar actividad. Recibe un repositorio por constructor. El contrato de almacenamiento es `write(snapshot) -> bool` y `read() -> Variant`; los tests lo sustituyen por un repositorio en memoria.

El controlador de la escena conecta las acciones de la interfaz con estos casos de uso. Define un único modo activo para aventura, diálogo, memoria, pausa, derrota o cierre. El reloj de la aventura solo avanza en modo aventura. La interfaz mantiene su propio estado visual para presentar ese modo.

La reclamación conserva una instantánea previa. Si el repositorio no confirma la escritura, la aplicación restaura esa instantánea, conserva el acceso y presenta el reintento. La concesión repetida sigue siendo idempotente.

`StoryDirector` coordina apertura e interludio. La apertura no modifica el progreso. Partir requiere conversación, sendero despejado y Morwenna retirada; el viaje solo cambia al Acto II si el checkpoint se guarda. Repetir una secuencia vuelve al diario sin volver a conceder progreso. La regla de Malphas requiere la huida, aunque ese encuentro aún no exista en esta demo.

## Infraestructura

`LocalSaveRepository` escribe JSON con versión a un archivo temporal y conserva un respaldo del checkpoint anterior. La carga prueba primero el principal y después el respaldo. Los errores se comunican mediante un resultado y mensaje; el adaptador no concede recompensas.

`NarrativeRepository` carga datos de diálogo y nomenclatura desde JSON. Los textos originales se conservan fuera de los métodos de combate. `SoundAdapter` asigna cues a efectos temporales sintetizados y limita voces simultáneas. La salida de audio puede sustituirse cuando se produzcan los assets del guion.

## Presentación y simulación espacial

`ActorView` adapta el estado del héroe a un `CharacterBody2D` y dibuja su figura. `EnemyView` contiene la máquina temporal y espacial del acechador. `VillageView` construye el fondo determinista. `GameInterface` presenta HUD, menús, conversaciones y memoria, delegando las reglas de cartas al dominio.

`NarrativeScreen` presenta imágenes y texto separados, con revelado gradual, navegación, salto y movimiento reducido. `ShalemPortrait` aporta el retrato animado. `LondiniumView` representa la primera zona de llegada; se desactivan los obstáculos de Oakhaven para evitar colisiones invisibles.

`game.gd` es la composición inicial: instancia adaptadores, cuerpos y vistas; traduce entradas y controla cámara, proyectiles y oleadas. La geometría y el director de encuentros siguen concentrados ahí. Al añadir más enemigos se extraerán como componentes específicos, conservando las reglas del dominio ya probadas. Crear más carpetas ahora no sustituiría esa separación de responsabilidades.

## Contratos de progresión

- El encuentro concede su acceso una sola vez, incluso si se repite su caso de uso.
- Salir de memoria conserva el acceso y no concede la recompensa.
- El final de memoria reclama el recuerdo una sola vez y guarda el checkpoint.
- Reiniciar restaura salud y equipo del encuentro; conserva el progreso narrativo del checkpoint.
- Continuar vuelve a un lugar seguro, con los objetivos ya completados conservados.

## Verificación

Hay pruebas de dominio para daño, invulnerabilidad, parry, rotura de guardia, memoria, acceso, idempotencia, guardado y recuperación. Una prueba de integración carga la escena y recorre movimiento físico, cambio de héroe, conversación pausada, lanzamiento/recuperación, cuatro enemigos, actividad de ocho cartas y retorno a aventura.

`check_architecture.py` impide dependencias del dominio hacia aplicación, infraestructura o presentación, impide acceso a nodos/entrada/archivos en dominio y aplicación, y comprueba referencias de recursos. El build detiene la entrega ante errores de parseo, errores de script o pruebas fallidas.

La integración usa un bot determinista y no equivale a una prueba humana de dificultad, controles de mando, interpretación sonora o rendimiento mínimo. Los resultados de ejecución se conservan fuera de las fuentes junto a las exportaciones.

La integración de historia comprueba apertura, diario, prototipo de Morwenna, tres ilustraciones, cambio real a Londinium, persistencia de llegada, reproducción sin alterar el estado y uso de un acceso pendiente de Shalem en el Acto II. Las notas locales de progreso y validación permanecen fuera del repositorio publicado.
