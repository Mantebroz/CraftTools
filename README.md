# CraftTools

Prototipo cliente para un juego Roblox con movimiento e inventario personalizados. La integracion con el juego original sigue pendiente: las comprobaciones realizadas son de sintaxis, no pruebas funcionales dentro del juego.

- **Teleport (experimental)**: proyecta el toque a X/Y y modifica el modelo del personaje. No esta conectado al estado de `PlayerMovement`.
- **Infinite jump (experimental)**: modifica `Humanoid` y velocidad fisica. No esta conectado al controlador propio ni a su boton de salto.
- **Noclip (experimental)**: cambia `CanCollide` dentro de `Workspace.Tiles`. No se ha verificado si el controlador usa esa propiedad para resolver colisiones.

Se retiro el boton que creaba Tools en Backpack: no correspondia al inventario personalizado de este juego. Agregar y recoger items sigue pendiente de integrar con su API real.

## Cargar desde GitHub

En un entorno que permita `loadstring` y `game:HttpGet`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mantebroz/CraftTools/main/StarterPlayer/StarterPlayerScripts/CraftTools.client.luau"))()
```

Tambien puedes colocar `StarterPlayer/StarterPlayerScripts/CraftTools.client.luau` como **LocalScript** en `StarterPlayerScripts` de Roblox Studio. El prototipo se ejecuta solo en cliente. El enlace carga la ultima version de main cuando se actualiza la cache de GitHub; los enlaces con un hash de commit siguen cargando aquella version antigua.

## Alcance de esta version

Consulta [la inspeccion del archivo](docs/game-integration.md). El archivo conserva la estructura y atributos de los objetos, pero los modulos relevantes contienen errores de descompilacion. Para completar la integracion hacen falta sus fuentes cliente originales o una sesion de Studio conectada con esos scripts disponibles.
