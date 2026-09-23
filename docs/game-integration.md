# Integracion con Craft2

Inspeccion estatica de `Craft2_Luna.rbxl`. En este archivo, LunaUX recupero 90 fuentes cliente sin errores `decompilation panicked` ni HTTP 429.

`StarterPlayerScripts.PlayerMovement.PlayerMovementHandler` resuelve colisiones de tiles con `ReplicatedStorage.Modules.AABB.SweepAABB`. Cada tile consultado usa una caja de 4.5 por 4.5 unidades. El barrido devuelve una normal; una normal Y de `1` es contacto con el suelo. El manejador tambien restringe la posicion a los atributos `WorldMin` y `WorldMax` del mundo.

El toggle de CraftTools filtra los contactos laterales y de techo en ese barrido del jugador. Los contactos de suelo quedan intactos. El cambio es local, reversible y no afecta los objetos de inventario ni sus remotos.

`PlayerMovementHandler` envia la posicion con el remote individual en `PlayerMovementPackets` y aplica las correcciones recibidas por `PlayerSetPosition.OnClientEvent`. CraftTools no interrumpe el envio. Cuando `getconnections` esta disponible, identifica por su entorno de script el listener de `PlayerMovementHandler` y lo suspende mientras el toggle esta activo. No suspende listeners de otros scripts.

La inspeccion del archivo no sustituye una prueba funcional dentro del juego. En particular, una zona sin tiles de suelo no se vuelve transitable por este filtro; el limite inferior del mundo sigue dependiendo de `WorldMin`.
