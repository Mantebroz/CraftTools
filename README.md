# BLOCKTOPIA client tests

Pruebas locales basadas en `BLOCKTOPIA.rbxl`, cargadas desde cliente. Esta copia tiene 189 fuentes descompiladas; los scripts servidor del anticheat, salud, inventario y mundo no estan disponibles. Cada respuesta del servidor debe verificarse dentro del juego.

El menu permite probar:

- Anticheat local: desactiva `MacroDetection` y `Anticheat_Local` cuando estan presentes. No modifica el anticheat servidor.
- Saltos infinitos: aplica un impulso en cada solicitud de salto, sin Magplant.
- Modo owner: cambia `WorldOwner`, `LockOwner` y funciones de `LockModule` solo en este cliente.
- Wrench libre: toca un objeto con tag `CreateWrench` o `PlayerWrench` para llamar a `RequestWrench`.
- No damage: desactiva el tacto de `HumanoidSecond` y restaura la salud visible localmente.
- Wall hack: desactiva colisiones de bloques cercanos manteniendo los que sostienen al personaje.
- 1 hit break: envia una secuencia limitada de `PunchBlock` al bloque tocado. El servidor puede rechazar golpes por distancia o cadencia.
- Solicitar objeto: valida nombre o ID contra `BlockModule.blocks` y envia `GetBlock` con el nombre del catalogo. El servidor decide si lo concede.

Los toggles son reversibles al cerrar el menu, excepto los remotes que ya hayan sido enviados. El resultado local no demuestra un cambio persistente: comprueba inventario, mundo y posicion desde otra cuenta o al reconectar.

## Carga

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mantebroz/CraftTools/main/StarterPlayer/StarterPlayerScripts/Blocktopia.client.luau"))()
```

Tambien puede colocarse como LocalScript en `StarterPlayerScripts`. El script no requiere acceso al servidor para abrir el menu.
