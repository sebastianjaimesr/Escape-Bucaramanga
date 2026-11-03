# Controles

Estado: Fase 2. Solo se listan como activos los controles que ya hacen algo.

## Teclado y ratón

| Acción | Tecla por defecto | Estado |
|---|---|---|
| Moverse | W A S D (también flechas) | Activo |
| Correr (gasta resistencia) | Shift | Activo |
| Saltar (mantener = más alto) | Espacio | Activo |
| Agacharse / levantarse | C | Activo |
| Mover la cámara | Ratón (haz clic en el juego para capturarlo) | Activo |
| Pausa | Esc | Activo |
| Medidor de rendimiento | F3 | Activo |
| Interactuar | E | Fase 3 |
| Entrar o salir de vehículos | F | Fase 7 |
| Inventario | Tab | Fase 9 |
| Mapa | M | Fase 9 |

En el navegador, Esc libera el ratón y abre la pausa. Para volver a capturarlo, pulsa **Continuar** o haz clic en el juego.

## Mando

| Acción | Botón (diseño Xbox) |
|---|---|
| Moverse | Palanca izquierda (la velocidad depende de cuánto se incline) |
| Cámara | Palanca derecha |
| Correr | Presionar palanca izquierda o LB |
| Saltar | A |
| Agacharse | B |
| Pausa | Start |

## Reasignar teclas

**Configuración → Controles**: haz clic en la tecla de una acción y pulsa la nueva. Esc cancela.

- Si la tecla ya la usa otra acción, las dos se intercambian, así ninguna queda sin tecla.
- Esc está reservada para la pausa.
- **Restaurar controles** vuelve a los valores por defecto.
- Los cambios se guardan en `user://settings.cfg` (ver `INSTALACION.md` para la ubicación).

## Detalles del movimiento

| Valor | Cantidad |
|---|---|
| Caminar | 2,6 m/s |
| Correr | 5,8 m/s |
| Agachado | 1,5 m/s |
| Altura del salto | ≈ 1,17 m (salto corto si se suelta antes) |
| Escalón máximo sin saltar | 36 cm |
| Pendiente máxima | 46° |
| Resistencia | ≈ 6 s corriendo; si se agota, no se corre hasta recuperar el 30 % |
