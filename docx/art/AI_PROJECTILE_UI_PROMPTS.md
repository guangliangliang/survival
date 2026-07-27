# 弹体与 UI 图标 AI 生成提示词

这份文档用于生成敌人弹体和游戏 UI 图标。每个资源下面的代码块都是完整提示词，可以直接整段复制使用，不需要再额外拼接统一前缀或负面提示词。

通用要求：

- 生成尺寸建议：128x128 或 256x256。
- 最终导出：PNG，透明背景。
- 弹体方向：默认朝右，方便代码旋转或翻转。
- UI 图标：主体居中，四周留少量透明边距。
- 原始大图或合集图可以先放到 `assets/images/generated_sources/`。

## 1. 巫师攻击弹

最终文件建议：

`assets/images/projectiles/projectile_wizard_orb.png`

直接复制：

```text
semi-realistic dark fantasy game projectile asset, transparent background, isolated magical attack orb, centered compact projectile, three-quarter top-down view, eerie cyan and violet arcane energy, bright glowing core, thin circular outer glow aura around the orb, contained energy surface, sharp readable silhouette, dramatic rim light, hand-painted realistic texture, detailed but readable at small size, suitable for a survival game enemy wizard attack, no text, no UI frame, no background, no watermark, no border, no smoke trail, no motion trail, no sparks trailing backward, no flame tail, not pixel art, not cartoon, not anime, not chibi, not flat vector, not 3D render, not photorealistic photo, not blurry, not a full scene
```

## 2. 豪猪发射刺

最终文件建议：

`assets/images/projectiles/projectile_porcupine_thorn.png`

直接复制：

```text
semi-realistic dark fantasy game projectile asset, transparent background, isolated flying porcupine thorn, horizontal projectile direction pointing to the right, three-quarter top-down view, long sharp natural quill spike, dark bark-brown base, bone-colored needle tip, rough organic texture, slight motion blur trail behind it, dangerous pointed silhouette, dramatic rim light, hand-painted realistic texture, detailed but readable at small size, suitable for a thorn porcupine enemy attack in a survival game, no text, no UI frame, no background, no watermark, no border, not pixel art, not cartoon, not anime, not chibi, not flat vector, not 3D render, not photorealistic photo, not blurry, not a full scene
```

## 3. 敌人枪手子弹

最终文件建议：

`assets/images/projectiles/projectile_musket_shot.png`

直接复制：

```text
semi-realistic dark fantasy game projectile asset, transparent background, isolated simple enemy bullet, horizontal projectile direction pointing to the right, three-quarter top-down view, small dark round lead ball or short simple bullet shape, clean compact form, gritty metal texture, sharp readable silhouette, subtle rim light, hand-painted realistic texture, detailed but readable at small size, suitable for a musketeer bandit enemy attack in a survival game, no text, no UI frame, no background, no watermark, no border, no muzzle flash, no smoke trail, no motion trail, no fire trail, no glow trail, not a modern brass cartridge with casing, not pixel art, not cartoon, not anime, not chibi, not flat vector, not 3D render, not photorealistic photo, not blurry, not a full scene
```

如果后面代码只想继续使用旧敌人子弹文件，也可以把生成好的图另存为：

`assets/images/projectiles/bullet_enemy.png`

## 4. 血量图标

最终文件建议：

`assets/images/ui/icon_health.png`

直接复制：

```text
semi-realistic dark fantasy game UI icon, transparent background, isolated red health heart emblem, centered composition, square icon proportions, organic but clean heart shape, deep crimson surface, glossy wet highlight, subtle dark outline, dramatic rim light, hand-painted realistic texture, sharp readable silhouette, detailed but readable at small size, suitable for a survival game HUD health indicator, no text, no numbers, no UI frame, no background, no watermark, no border, not pixel art, not cartoon, not anime, not chibi, not flat vector, not 3D render, not photorealistic photo, not blurry, not a full scene
```

## 5. 等级图标

最终文件建议：

`assets/images/ui/icon_level.png`

直接复制：

```text
semi-realistic dark fantasy game UI icon, transparent background, isolated glowing golden rune badge, centered composition, square icon proportions, upward arrow carved into ancient metal, faint green experience glow, aged gold and bronze texture, bright warm highlight, subtle dark outline, dramatic rim light, hand-painted realistic texture, sharp readable silhouette, detailed but readable at small size, suitable for a survival game HUD level indicator, no text, no numbers, no UI frame, no background, no watermark, no border, not pixel art, not cartoon, not anime, not chibi, not flat vector, not 3D render, not photorealistic photo, not blurry, not a full scene
```

## 6. 时间图标

最终文件建议：

`assets/images/ui/icon_time.png`

直接复制：

```text
semi-realistic dark fantasy game UI icon, transparent background, isolated antique hourglass, centered composition, square icon proportions, bronze frame, blue-gray glass, glowing golden sand, three-quarter view, dramatic rim light, subtle dark outline, hand-painted realistic texture, sharp readable silhouette, detailed but readable at small size, suitable for a survival game HUD timer indicator, no text, no numbers, no UI frame, no background, no watermark, no border, not pixel art, not cartoon, not anime, not chibi, not flat vector, not 3D render, not photorealistic photo, not blurry, not a full scene
```

## 推荐放置位置汇总

生成并裁剪完成后，建议按下面路径保存：

```text
assets/images/projectiles/projectile_wizard_orb.png
assets/images/projectiles/projectile_porcupine_thorn.png
assets/images/projectiles/projectile_musket_shot.png

assets/images/ui/icon_health.png
assets/images/ui/icon_level.png
assets/images/ui/icon_time.png
```

如果保留 AI 原始生成图，建议放这里：

```text
assets/images/generated_sources/projectiles_new_raw.png
assets/images/generated_sources/ui_icons_new_raw.png
```
