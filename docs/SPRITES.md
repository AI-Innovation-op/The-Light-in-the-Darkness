# Personajes: primera entrega de sprites

[Abrir catálogo visual](sprites.html). Puede abrirse directamente en un navegador desde las fuentes.

Las imágenes originales se conservan en `assets/sprites`, con sus márgenes y canal alfa. El catálogo de Godot recorta únicamente el margen al dibujar, guarda las texturas en caché y establece altura y pivote por pose. El cambio de imagen no modifica alcance, velocidad, salud ni colisiones.

| Archivo | Uso actual |
| --- | --- |
| `thomas_idle.png` | Reposo y desplazamiento equipado. |
| `thomas_attack.png` | Pose durante el ataque con espada. |
| `thomas_disarmed.png` | Combate a puños y desplazamiento sin arma. |
| `portrait_thomas.png` | Diálogos de Thomas y barra de vida. |
| `khaterine_idle.png` | Reposo y desplazamiento; también desarmada. |
| `khaterine_attack.png` | Canalización durante el ataque equipado. |
| `portrait_khaterine.png` | Diálogos de Khaterine y barra de vida. |
| `shalem_cat.png` | Compañero felino en el mundo, ordenado por profundidad. |
| `portrait_shalem.png` | Apertura y diálogos de Shalem. |
| `elowen_npc.png` | Elowen junto al huerto. |
| `ash_prowler.png` | Acechadores de Ceniza, con señal de ataque independiente. |
| `boss_morwenna.png` | Prototipo de Madre Morwenna con incensario. |
| `boss_malphas.png` | Recurso preparado para producción del Acto II; no se añade su combate. |

## Producción y límites

Se usó la herramienta integrada `image_gen`, con la lámina de Kevin como referencia de diseño y las poses de reposo como referencia adicional para los ataques y retratos. Los prompts se conservan en [prompts.json](../assets/sprites/prompts.json). La pose final del acechador evita humo exterior para obtener un recorte transparente limpio.

Esta entrega contiene **poses estáticas**, no animaciones dibujadas fotograma a fotograma. El motor invierte la dirección horizontal, conserva el anclaje de los pies y aplica un pequeño desplazamiento al caminar. El pixel art detallado procede de generación de imágenes y todavía requiere una pasada artística manual para una cuadrícula de píxeles y animaciones definitivas.

No se necesita instalar software adicional para usar estos PNG en Godot. El proyecto actual ya admite PNG y transparencia. No se añadió un servicio de pago, plugin ni dependencia al juego.
