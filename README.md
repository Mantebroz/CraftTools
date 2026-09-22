# CraftTools

Development controls for a Roblox side-view game. This first version provides two mobile-friendly toggles:

- **Teleport**: tap or click the scene to move to that X/Y position while keeping the character's current Z depth.
- **Infinite jump**: use the game's normal jump control repeatedly while airborne.

## Install

1. Put `ServerScriptService/CraftTools.server.luau` in your game's `ServerScriptService` as a **Script**.
2. Put `StarterPlayer/StarterPlayerScripts/CraftTools.client.luau` in `StarterPlayerScripts` as a **LocalScript**.
3. Add each collaborator's Roblox UserId to `allowedUserIds` in the server script. Studio playtests and the owner of a user-owned experience are allowed automatically. For group-owned experiences, add every developer explicitly.

The server script creates `ReplicatedStorage.CraftToolsRemote`. The UI appears at the upper-right and works with touch or mouse. Taps that begin over existing UI or become a drag are ignored. Keep these tools restricted to developers; do not grant the remote to every player.

## Place snapshot notes

The supplied `.rbxl` shows a thin `ParallaxPlane` aligned with X/Y and several character/world elements at different Z depths. Its saved client scripts, including `PlayerMovement`, `PlayerMovementControl`, `PlayerMovementHandler`, and `CameraHandler`, contain only decompilation errors. Server scripts are absent from that snapshot. This implementation therefore preserves each character's current Z instead of assuming one fixed depth. The existing movement code may still override the jump or teleport behavior; verify both in a Studio playtest of the actual project.

Item collection is **not implemented yet**. The snapshot has inventory-related remotes and an `ItemsManager`, but no readable server handlers. A client-only “take” cannot be assumed to update the authoritative inventory. Add that feature only after inspecting the actual server item pickup API and its validation rules.
