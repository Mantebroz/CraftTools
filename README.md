# CraftTools

Menu cliente para el movimiento 2D personalizado de Craft2. Por ahora contiene una sola opcion:

- **Wall hack**: permite atravesar bloques de lado y hacia arriba. Conserva los choques que sostienen al jugador sobre el suelo y los limites del mundo que aplica `PlayerMovementHandler`.

El toggle modifica temporalmente `ReplicatedStorage.Modules.AABB.SweepAABB` en el cliente. Si el entorno dispone de `getconnections`, tambien intenta suspender solo el listener de correccion `PlayerSetPosition` de `PlayerMovementHandler`. Restaura ambos cambios al apagarlo, destruir el menu o reaparecer. No cambia `CanCollide`, no modifica el inventario y no corta el envio normal de posicion por `PlayerMovementPackets`.

La suspension del listener depende del entorno cliente y no anula las validaciones del servidor. Si no puede identificarse el listener, el wall hack de colisiones sigue activo y se emite un aviso en la consola.

## Cargar desde GitHub

En un entorno que permita `loadstring` y `game:HttpGet`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mantebroz/CraftTools/main/StarterPlayer/StarterPlayerScripts/CraftTools.client.luau"))()
```

Tambien puedes colocar `StarterPlayer/StarterPlayerScripts/CraftTools.client.luau` como **LocalScript** en `StarterPlayerScripts` de Roblox Studio. Se necesita una sesion del juego para validar el comportamiento en movimiento; el archivo `.rbxl` permite inspeccionar el codigo, pero no ejecutarlo aqui.
