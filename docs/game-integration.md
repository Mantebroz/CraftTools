# Inspeccion del juego de referencia

Inspeccion directa del archivo binario proporcionado, sin ejecutar sus scripts.

## Datos observados

- `StarterGui.InventoryUI` contiene la interfaz personalizada, `UIScript.SlotButton`, `Handle.Frame.Hotbar` y `Handle.Frame.Bottom.InventoryFrame.InventoryScroll`.
- El control tactil propio incluye `InventoryUI.Right.JumpButton` y `PunchButton`.
- `Workspace.Hitbox` contiene una Part del jugador con `Anchored = true`, `CanCollide = false`, en Z=0 en este snapshot.
- Los objetos en `Workspace.Drops` tienen atributos `id` y `amount`; un ejemplo guardado es `id = "cloudfall_wings"`, `amount = 1`. Esto identifica un drop; no revela el metodo de recogida ni una clave unica para cada instancia.
- Existen los remotos `InventoryInitialize`, `InventorySetItem`, `InventorySetAmount`, `PlayerEquipItem`, `PlayerDrop` y `RequestItemData`. Sus nombres no prueban la direccion ni los argumentos de las llamadas.

## Codigo ausente

Las fuentes siguientes contienen comentarios con `-- decompilation panicked`, sin implementacion ejecutable:

- `ReplicatedStorage.Modules.Inventory`
- `ReplicatedStorage.Managers.ItemsManager`
- `ReplicatedStorage.Managers.PlayerClientManager`
- `ReplicatedStorage.Modules.AABB`
- `ReplicatedStorage.Modules.ScreenSpace`
- `ReplicatedStorage.Classes` y `WorldTiles`
- `StarterPlayer.StarterPlayerScripts.InventoryHandler`
- `StarterPlayer.StarterPlayerScripts.PlayerMovement`, sus hijos `PlayerMovementControl` y `PlayerMovementHandler`
- `StarterPlayer.StarterPlayerScripts.CameraHandler`

## Consecuencias para CraftTools

La hitbox anclada y los modulos de movimiento/AABB sugieren un controlador propio; su implementacion no se puede confirmar con este archivo. Mover el personaje o cambiar colisiones fisicas puede no modificar el estado que ese controlador utiliza. Conservar CanTouch tampoco demuestra que la recogida use Touched.

El prototipo no tiene una integracion verificada para movimiento, inventario o recogida. Para implementarla necesitamos las fuentes originales de los modulos cliente anteriores, especialmente Inventory, ItemsManager, InventoryHandler y PlayerMovement con sus controladores. No es necesario anadir codigo servidor a CraftTools para leer y adaptar esas APIs cliente.
