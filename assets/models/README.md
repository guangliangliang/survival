# 3D Model Import Layout

Place source model files here before wrapping them in Godot scenes.

- `characters/`: character `GLB` or `glTF` files.
- `weapons/`: weapon `GLB` or `glTF` files.
- `res://scenes/models/CharacterModelTemplate.tscn`: wrapper template for character models.
- `res://scenes/models/WeaponModelTemplate.tscn`: wrapper template for weapon models.
- `res://scenes/models/Player3DPreview.tscn`: preview scene for `idle`, `run`, and `shoot`.

Character wrappers should expose a `WeaponSocket3D` node. Weapon wrappers should expose a `MuzzleSocket3D` node.
