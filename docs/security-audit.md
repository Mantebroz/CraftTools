# Auditoria cliente-servidor de Craft2

Base: inspeccion estatica de `Craft2_Luna.rbxl`. El archivo contiene codigo cliente descompilado, pero no la implementacion ejecutable de los manejadores del servidor. Por eso cada punto es una hipotesis a probar, no una vulnerabilidad confirmada.

## Modelo observado

- `PlayerMovementHandler` calcula posiciones en el cliente y las envia mediante el remote individual de `PlayerMovementPackets`. `PlayerSetPosition` puede corregir la posicion local. Apagar el envio y volver a la posicion anterior demuestra que el servidor conserva otra posicion; no demuestra si valida paquetes falsificados.
- `InventoryHandler` recibe `InventoryInitialize`, `InventorySetItem` e `InventorySetAmount` y actualiza `Inventory.Stacks`. Es un espejo cliente del estado, no una funcion para conceder items.
- `PlacementHandler` aplica alcance, seleccion de tile y una cadencia de 0.15 s antes de llamar `PlayerPlaceItem` o `PlayerFist`. No sabemos si el servidor repite esas comprobaciones.
- `PlayerTrade` recibe acciones numericas: 1 agrega un slot, 2 retira una oferta, 3 marca listo y -2 cancela.
- `CustomFunctionRemote` recibe, entre otras acciones, `CompleteDailyQuest`. `RequestBuyShopItem` recibe un ID de producto. La validacion de recompensa y precio es desconocida.
- `PlayerHurtMe` recibe un numero proporcionado por el cliente. Hay llamadas con `100` y con el valor `Hurt` de un tile; falta verificar que el servidor rechace negativos, no finitos y valores fuera de rango.

## Pruebas del panel

| Prueba | Llamadas | Indicador observado | Confirmacion necesaria |
| --- | --- | --- | --- |
| Doble drop | `PlayerDrop(slot)` dos veces seguidas | Compara cantidad del item en inventario con drops visibles | Ver que ambos drops existen para otro cliente y que el saldo persiste al reconectar |
| Oferta repetida | `PlayerTrade(1, slot)` dos veces, luego `-2` | Cuenta las respuestas de oferta propia | Dos respuestas muestran ofertas repetidas, no duplicacion; haria falta revisar el cierre de trade en un ensayo separado |
| Reclamo repetido | `CompleteDailyQuest` dos veces | Cuenta items nuevos, eventos de gemas y slots cambiados | Comparar con recompensa esperada y reconectar; requiere una mision reclamable |
| Colocar distante | `PlayerPlaceItem(Vector2, slot)` fuera del alcance cliente | Consulta el tile y cantidad del stack despues de 2 s | Otro cliente debe ver el tile persistente |
| Slots invalidos | `PlayerDrop` y `PlayerItemTrash` con `0` y `MaxSlots+1` | Compara el inventario antes/despues | Sin cambio no prueba ausencia de errores en logs del servidor |
| Dano negativo | `PlayerHurtMe(-1)` una vez | Compara `Humanoid.Health` antes/despues | Un aumento debe confirmarse tras unos segundos y en el estado del servidor |

Cada accion automatica envia como maximo cuatro llamadas mutantes. No hay bucles de spam ni ejecucion al cargar el script. Las pruebas que podrian afectar recursos o salud exigen confirmacion. Conviene usar items de prueba y un servidor privado.
El panel requiere Wall hack apagado para que las comparaciones de posicion e inventario partan de un estado normal.

## Lectura de resultados

1. Registra inventario y mundo antes de la prueba en dos clientes.
2. Ejecuta una accion y observa la respuesta inmediata, el inventario del otro cliente y el estado del mundo.
3. Reconecta y comprueba persistencia. Un estado solo visible localmente es desincronizacion, no un exploit confirmado.
4. Si una prueba parece positiva, repitela una vez de forma controlada y revisa los logs del servidor para encontrar la validacion ausente o el orden de operaciones incorrecto.

## Rutas que requieren revision del servidor

| Remote | Dato controlado por cliente | Validacion que hay que localizar en servidor |
| --- | --- | --- |
| `PlayerMovementPackets/<jugador>` | Posicion `Vector2` | Tipo y finitud, velocidad maxima, limites, colisiones y orden temporal; no basta con retransmitir la ultima posicion |
| `PlayerPlaceItem` | Coordenada y slot | Propiedad del slot, cantidad disponible, alcance, permiso de construir y estado del tile; decremento y colocacion atomicos |
| `PlayerFist` | Coordenada | Alcance, cadencia, tile valido y recompensa de rotura entregada una sola vez |
| `PlayerDrop`, `PlayerItemTrash` | Slot | Indice entero dentro del inventario, propiedad actual y operacion atomica frente a dos llamadas concurrentes |
| `PlayerTrade` | Accion numerica y slot | Una oferta por stack, bloqueo de items ofrecidos, invalidacion de ready ante cambios y transferencia atomica con rollback |
| `RequestBuyShopItem` | ID de producto | Precio y disponibilidad calculados en servidor, saldo suficiente y proteccion ante compras concurrentes |
| `CustomFunctionRemote` | Nombre de accion y parametros | `CompleteDailyQuest` elegible una vez; `ChangeColor`, reportes y leaderboard con tipos, permisos y limites propios |
| `PlayerHurtMe` | Cantidad de dano | Numero finito, no negativo, dentro de rango y procedente de una causa de dano valida |
| `PlayerEquipItem` | Slot | Item poseido, restricciones de equipamiento y estado actualizado despues de mover/tradear/dropear |
| `PlayerTileButton` | Posicion `Vector2` | Distancia real del jugador, tile y permisos para la accion correspondiente |
| `UIManager.UIPromptClickPlayer` | Instancia `Player` | Distancia, misma sesion/mundo y consentimiento para interacciones o trade |

Los remotes `InventoryInitialize`, `InventorySetItem`, `InventorySetAmount`, `WorldSetTile` y `PlayerSetPosition` se observan como actualizaciones del servidor al cliente. Su mera existencia no permite conceder items ni editar el mundo desde cliente; los manejadores `OnServerEvent`, si existen, tendrian que revisarse por separado.

El panel no dispara compras reales, no completa trades y no intenta conceder items al cliente. Esas rutas tienen riesgo de gastar moneda o transferir objetos y necesitan instrumentacion del servidor o una cuenta de pruebas antes de automatizarse.
