# CraftTools

Menu cliente para el movimiento 2D personalizado de Craft2 y pruebas de sus remotes:

- **Wall hack**: permite atravesar bloques de lado y hacia arriba. Conserva los choques que sostienen al jugador sobre el suelo y los limites del mundo que aplica `PlayerMovementHandler`.
- **Auditoria**: pruebas acotadas de doble drop, oferta repetida en trade, reclamo diario repetido, colocacion distante, slots invalidos y dano negativo. Las pruebas que pueden afectar recursos o salud exigen dos pulsaciones en seis segundos.

El toggle modifica temporalmente `ReplicatedStorage.Modules.AABB.SweepAABB` en el cliente. Si el entorno dispone de `getconnections`, tambien intenta suspender solo el listener de correccion `PlayerSetPosition` de `PlayerMovementHandler`. Restaura ambos cambios al apagarlo, destruir el menu o reaparecer. No cambia `CanCollide`, no modifica el inventario y no corta el envio normal de posicion por `PlayerMovementPackets`.

La suspension del listener depende del entorno cliente y no anula las validaciones del servidor. Si no puede identificarse el listener, el wall hack de colisiones sigue activo y se emite un aviso en la consola.

Usa Auditoria en un mundo privado con items prescindibles. El panel informa cambios observados, no certifica por si solo una vulnerabilidad. Consulta [el mapa de pruebas](docs/security-audit.md) para verificar resultados con otro cliente y despues de reconectar.

## Cargar desde GitHub

En un entorno que permita `loadstring` y `game:HttpGet`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mantebroz/CraftTools/main/StarterPlayer/StarterPlayerScripts/CraftTools.client.luau"))()
```

Tambien puedes colocar `StarterPlayer/StarterPlayerScripts/CraftTools.client.luau` como **LocalScript** en `StarterPlayerScripts` de Roblox Studio. Se necesita una sesion del juego para validar el comportamiento en movimiento; el archivo `.rbxl` permite inspeccionar el codigo, pero no ejecutarlo aqui.
