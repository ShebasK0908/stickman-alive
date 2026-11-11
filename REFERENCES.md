# Referencias del usuario (2026-11-11) — cómo debe funcionar/moverse

Vídeos enviados por el usuario (verificados por título/descripción):
- Animator vs. Animation (HD) — https://youtu.be/Qb1VvUf21L4 (= AvA 1, 2006)
- Animator vs. Animation (original) — https://youtu.be/npTC6b5-yvM (= el mismo AvA 1)
- Animator vs. Animation 2 (HD) — https://youtu.be/WDIeS7NHTpU (The Chosen One)
- Animator vs. Animation 4 (original) — https://youtu.be/VufDd-QL1c0 (enviado dos veces; descripción verificada: el stickman resiste a su creador, viaja al iPhone por USB y dibuja animaciones propias para desmontar la interfaz)

## Patrones a aplicar (web y .ipa nativo)

### Interacción (el usuario reportó problemas para dibujar e interactuar — corregir)
- Separar gestos táctiles sin conflicto: modo Dibujar (lápiz) vs modo Cursor/animador.
- Dibujar: trazos libres persistentes con el dedo, físicos — el stickman camina/se agarra a las líneas; goma y deshacer.
- Agarrar: caja de selección / arrastre como AvA 1; el stickman se resiste, se agarra a bordes, al soltar sale lanzado con la velocidad del gesto. Área táctil amplia en móvil.
- El cursor/dedo es un objeto físico en su mundo: lo agarra, se cuelga, se pelea con él.

### Movimiento y vida
- AvA 1: escapa de la selección, roba herramientas de la barra (lápiz/goma) y las usa contra el animador; usa la línea de tiempo y la interfaz como terreno de juego/pelea.
- AvA 2: The Chosen One — superfuerza, poderes, usa el entorno/interfaz como arma, caos creativo.
- AvA 4: el stickman dibuja sus propias criaturas/objetos y COBRAN VIDA breve; se desplaza entre pantallas (en nuestra escala: dentro de la app, entre zonas de la interfaz).

### Ya pedido antes (mantener)
Libertad/autonomía, cerebro complejo siempre activo con descansos cada 2 min, poderes Chosen One (volar, fuego, láser, hielo, superpuñetazo, superfuerza, supervelocidad).

## Precisión del usuario y feedback de la v1 (2026-11-11, tras probar el .ipa)

- «Está mal hecho»: la toolbar izquierda no dejaba interactuar para dibujar/borrar, y las animaciones no se parecían a las del vídeo (el dibujo sí valía). Causa v1: toolbar de imágenes sin botones + gesto único que lo absorbía todo; poses con senos sin keyframes.
- Foco principal: «su MOVIMIENTO, cómo corre, cómo se mueve» — creado de forma DIFERENTE (locomoción con peso, aceleración, ciclos reales; ver README v2), copiando todas las animaciones de los vídeos.
- «Implementarle una pequeña IA para que pueda interactuar o defenderse un poco, como en el vídeo»: percepción del dedo (distancia/velocidad/acercamiento) → decisión (curioso, saludar, huir, esquivar agachándose/rodando/saltando, bloquear, agarrar el dedo, contraatacar, esconderse, escudo con objetos, mini-Chosen One) → clip; con aprendizaje en sesión (contador de acoso que decae y se calma con juego suave).
