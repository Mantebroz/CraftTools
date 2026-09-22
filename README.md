# CraftTools

Herramientas de prueba para un juego Roblox con vista lateral. Esta version funciona solo en el cliente y muestra dos toggles para movil y escritorio:

- **Teleport**: toca o haz clic en la escena. El personaje se mueve a esa posicion X/Y y conserva su profundidad Z.
- **Infinite jump**: usa el control de salto del juego repetidamente, incluso en el aire.

## Cargar desde GitHub

En un entorno que permita `loadstring` y `game:HttpGet`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mantebroz/CraftTools/main/StarterPlayer/StarterPlayerScripts/CraftTools.client.luau"))()
```

Tambien puedes colocar `StarterPlayer/StarterPlayerScripts/CraftTools.client.luau` como **LocalScript** en `StarterPlayerScripts` de Roblox Studio. No se requiere ningun script ni remoto del servidor para mostrar la UI o intentar las dos acciones locales. La UI aparece arriba a la derecha. Ignora toques sobre otras interfaces y arrastres.

## Alcance de esta version

El `.rbxl` de referencia muestra un plano visual X/Y y distintas profundidades Z, pero los scripts de movimiento guardados no son legibles. Por eso el teleport conserva la Z actual del personaje. Si el juego corrige la posicion o el movimiento desde el servidor, una accion local puede revertirse; hay que comprobarlo en el juego real. Recoger items no esta implementado: el snapshot no incluye los handlers del servidor ni permite verificar que un cambio de inventario hecho solo en cliente persista.
