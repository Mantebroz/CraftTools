# CraftTools

Menu cliente para el movimiento 2D personalizado de Craft2. Por ahora contiene una sola opcion:

- **Wall hack**: permite atravesar bloques de lado y hacia arriba. Conserva los choques que sostienen al jugador sobre el suelo y los limites del mundo que aplica `PlayerMovementHandler`.

El toggle modifica temporalmente `ReplicatedStorage.Modules.AABB.SweepAABB` en el cliente y restaura la funcion original al apagarlo o destruir el menu. No cambia `CanCollide`, no modifica el inventario y no llama remotos de servidor.

## Cargar desde GitHub

En un entorno que permita `loadstring` y `game:HttpGet`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mantebroz/CraftTools/main/StarterPlayer/StarterPlayerScripts/CraftTools.client.luau"))()
```

Tambien puedes colocar `StarterPlayer/StarterPlayerScripts/CraftTools.client.luau` como **LocalScript** en `StarterPlayerScripts` de Roblox Studio. Se necesita una sesion del juego para validar el comportamiento en movimiento; el archivo `.rbxl` permite inspeccionar el codigo, pero no ejecutarlo aqui.
