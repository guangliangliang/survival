# 《边境守夜人》即梦美术提示词

本文档用于生成游戏正式美术资源。提示词以即梦生图为目标，采用“先生成角色设定图，再生成单方向动作条”的方式，避免一次生成复杂 Sprite Sheet 导致角色、帧数和方向失控。

> 注意：提示词中的 32×32、64×64、96×96 是最终游戏资源规格。即梦生成后仍需裁切、去背景、像素化缩放并对齐到对应画布，不能仅依赖生成图片的原始分辨率。

## 一、统一视觉规范

### 通用正向提示词

将下面内容放在每条美术提示词的开头：

```text
Top-down 2D rural survival game art, pixel art, orthographic game sprite, retro 16-bit game aesthetic, muted natural colors, crisp dark outlines, simple separated light and shadow shapes, consistent soft light from the upper left, no perspective distortion, clearly readable silhouettes on a small mobile screen, consistent pixel density, rural post-apocalyptic village militia theme, non-gory
```

### 通用负面提示词

将下面内容放在每条提示词的末尾：

```text
No photorealism, no 3D render, no painterly style, no watercolor, no anime illustration, no chibi proportions, no isometric view, no side view, no horizon, no complex background, no text, no watermark, no signature, no frame, no smooth anti-aliasing, no blur, no depth of field, no neon sci-fi elements, no modern city elements, no extra limbs, no duplicate characters, no cropped subject, no changes to clothing or color palette
```

### 输出和命名规范

- 普通角色最终单帧：64×64 PNG，透明背景。
- Boss最终单帧：96×96 PNG，透明背景。
- 地图瓦片：32×32 PNG，无透明缝隙。
- 普通物件：64×64、96×96、128×128或256×256 PNG，透明背景。
- 四方向顺序统一为：下、左、右、上。
- 每个方向单独生成一条横向动作条，不要求一次生成四方向总表。
- 行走动画：4帧等宽横排；Boss攻击动画：6帧等宽横排。
- 角色锚点统一在脚底中心；动物锚点统一在身体接地面的中心。
- 文件名使用英文小写与下划线，例如 `player_walk_down.png`。

## 二、角色生成流程

每个角色按以下顺序生成：

1. 先生成四方向角色设定图，锁定服装、比例和色板。
2. 选择最符合要求的设定图作为即梦参考图。
3. 使用对应的动作条提示词，分别生成下、左、右、上四条。
4. 裁切、去背景、逐帧校正脚底位置，并缩放到最终画布。

### 通用角色设定图后缀

```text
Four-direction game character turnaround sheet showing the same character. Keep clothing, body proportions, weapon, and colors strictly consistent. Show four complete views in this exact order: facing down, facing left, facing right, facing up. Leave ample empty space between views. Standing idle pose, solid chroma-key background, full uncropped character
```

### 通用行走动作条后缀

将 `{方向}` 替换为朝下、朝左、朝右或朝上，并附上已经确认的角色设定图作为参考图。

```text
Strictly preserve the same character, clothing, weapon, proportions, and colors from the reference image. A seamless walking cycle facing {down/left/right/up}, exactly 4 frames arranged left to right in one evenly spaced horizontal strip: contact, down, passing, up. Moderate motion, clearly readable footsteps, stable body center and bottom-center foot anchor. Each frame must show the complete character without overlap. Solid chroma-key background, sprite animation strip, 4 frames horizontal
```

## 三、玩家角色

### 1. 村庄守卫设定图

最终规格：64×64；四方向待机各1帧。

```text
Top-down 2D rural survival game art, pixel art, orthographic game sprite, retro 16-bit game aesthetic, muted natural colors, crisp dark outlines, consistent soft light from the upper left. A young village guard wearing a practical dark blue-gray short jacket, beige shirt, brown work pants, rugged ankle boots, and a small cross-body ammunition pouch, holding a simple wooden-stock rifle with both hands. Calm and alert, no helmet. Four-direction turnaround sheet of the same character in this exact order: facing down, facing left, facing right, facing up. The rifle points in the same direction as the body. Standing idle pose, solid chroma-key background, full uncropped character.

No photorealism, no 3D render, no painterly style, no watermark, no text, no complex background, no modern assault rifle, no scope, no sci-fi equipment, no clothing or color changes, no cropped character
```

行走动作：使用“通用行走动作条后缀”，分别生成4个方向，每方向4帧，最终文件：

- `player_walk_down.png`
- `player_walk_left.png`
- `player_walk_right.png`
- `player_walk_up.png`

### 2. 玩家受伤闪白轮廓

最终规格：64×64；1帧，可作为受伤叠加层。

```text
Top-down pixel game effect on a 64x64 canvas. A bright white silhouette of the player at the instant of taking damage, with a few red-orange pixel impact lines around the outer edge. Centered subject, simple outline, transparent background, single-frame hit flash overlay, full uncropped character.

No detailed facial or clothing features, no scenery, no text, no blood, no realistic wounds, no large smoke cloud
```

## 四、普通敌人与精英

以下角色先用“设定图提示词”生成四方向参考，再用通用行走动作条生成四方向、每方向4帧。

### 1. 野狼 `wolf`

最终规格：64×64。

```text
Top-down 2D pixel game enemy, a lean and athletic wild wolf with rough gray-brown fur, a dark gray back, muted beige underside, upright ears, and small yellow eyes. Low stalking posture with a strong sense of speed, but without an excessively sharp silhouette. Four-direction turnaround of the same wolf in this exact order: facing down, left, right, up. Keep body proportions and fur colors strictly consistent. Solid chroma-key background, top-down wolf game sprite
```

### 2. 野猪 `boar`

最终规格：64×64。

```text
Top-down 2D pixel game enemy, a sturdy adult wild boar with coarse dark-brown bristles, broad shoulders, lowered head, short legs, small pale tusks, and a darker mane along its back. Heavy, clearly readable silhouette that suggests charging power. Four-direction turnaround of the same boar in this exact order: facing down, left, right, up. Keep body proportions and colors strictly consistent. Solid chroma-key background, top-down boar game sprite
```

### 3. 普通强盗 `bandit`

最终规格：64×64。

```text
Top-down 2D pixel game enemy, a rural bandit wearing a worn dark red-brown coat, gray trousers, leather boots, and an old cloth mask covering the lower face, holding a short machete. Improvised equipment; dangerous but not a heavily armored warrior. Four-direction turnaround of the same bandit in this exact order: facing down, left, right, up. Keep clothing, machete, proportions, and colors strictly consistent. Solid chroma-key background, top-down bandit game sprite
```

### 4. 强盗枪手 `gunner`

最终规格：64×64。

```text
Top-down 2D pixel game enemy, a lean bandit gunner wearing a worn dark purple-red jacket, charcoal trousers, a cloth shoulder guard, and an old cap, holding a short-barreled antique rifle with both hands. Match the regular bandit's style while making the ranged role immediately clear. Four-direction turnaround of the same gunner in this exact order: facing down, left, right, up. Rifle barrel follows the body direction. Keep clothing, weapon, proportions, and colors strictly consistent. Solid chroma-key background, top-down bandit gunner game sprite
```

### 5. 强盗精英 `elite_bandit`

最终规格：64×64。

```text
Top-down 2D pixel game enemy, an elite bandit taller and broader than a regular bandit, wearing dark orange-brown leather armor, a metal shoulder guard and forearm armor, a dark headscarf, and carrying a long machete. Heavy silhouette but clearly not a boss; improvised rural raider equipment. Four-direction turnaround of the same elite bandit in this exact order: facing down, left, right, up. Keep clothing, blade, proportions, and colors strictly consistent. Solid chroma-key background, top-down elite bandit game sprite
```

## 五、Boss敌人

Boss最终单帧96×96。除四方向待机与每方向4帧行走外，再生成主要攻击动作。

### 1. 狼王 `alpha_wolf`

```text
Top-down 2D pixel game boss, a giant alpha wolf about twice the size of a regular wolf, with dark gray fur, an earthy gold mane across the shoulders and back, battle scars on one ear, amber eyes, and powerful limbs. Majestic and fierce while retaining a believable animal silhouette. Four-direction boss turnaround of the same alpha wolf in this exact order: facing down, left, right, up. Keep proportions and fur colors strictly consistent. Solid chroma-key background, top-down alpha wolf boss sprite
```

攻击动作条，最终6帧：

```text
Strictly preserve the alpha wolf from the reference image. A downward-facing pounce-and-bite attack animation, exactly 6 frames arranged horizontally: lower body, load hind legs, leap forward, open-mouth bite, land, return to idle. Clear speed and power, stable ground anchor, transparent background, pixel art boss attack sprite strip, 6 frames horizontal
```

### 2. 森林巨兽 `forest_beast`

```text
Top-down 2D pixel game boss, a forest beast with a massive bear-like body, deep green mossy fur, bark-like natural armor, and a few vines. Huge body, broad shoulders, powerful forepaws, and dim yellow glowing eyes. It should feel like an ancient forest guardian beast, not a humanoid tree creature. Four-direction boss turnaround of the same creature in this exact order: facing down, left, right, up. Keep anatomy, proportions, and colors strictly consistent. Solid chroma-key background, top-down forest beast boss sprite
```

攻击动作条，最终6帧：

```text
Strictly preserve the forest beast from the reference image. A downward-facing heavy claw ground-slam animation, exactly 6 frames arranged horizontally: raise forepaw, lean back, charge, slam the ground, impact hold, return to idle. Strong sense of weight, stable body center, transparent background, pixel art boss attack sprite strip, 6 frames horizontal
```

### 3. 强盗头目 `bandit_chief`

```text
Top-down 2D pixel game boss, a tall and heavily built bandit chief wearing a dark red long coat, worn metal chest armor, a single shoulder plate, a black headscarf, and an ammunition belt. He carries a heavy machete in one hand and a short-barreled firearm in the other. An intimidating rural raider leader with no fantasy crown. Four-direction boss turnaround of the same chief in this exact order: facing down, left, right, up. Keep weapons, clothing, proportions, and colors strictly consistent. Solid chroma-key background, top-down bandit chief boss sprite
```

近战攻击动作条，最终6帧：

```text
Strictly preserve the bandit chief from the reference image. A downward-facing heavy horizontal slash animation, exactly 6 frames arranged horizontally: raise blade, pull back to charge, begin swing, full horizontal slash, recover blade, return to idle. Clear blade path without obscuring the body, stable bottom-center foot anchor, transparent background, pixel art boss slash sprite strip, 6 frames horizontal
```

## 六、武器、弹丸与战斗特效

### 1. 玩家木托步枪

最终规格：64×32；透明背景。

```text
Top-down pixel game weapon sprite, a simple old wooden-stock rifle with a dark brown stock and dark gray metal barrel, no scope and no modern attachments. Barrel pointing right, complete readable game-view silhouette, 64x32 canvas, transparent background, pixel art rifle game sprite
```

### 2. 玩家子弹

最终规格：16×8；透明背景。

```text
Pixel game projectile, a small short golden rifle bullet flying right, bright core with only two or three orange speed pixels behind it, crisp silhouette, 16x8 canvas, transparent background, pixel art bullet projectile
```

### 3. 敌人子弹

最终规格：16×16；透明背景。

```text
Pixel game enemy projectile, a dark red-orange arrow-shaped energy shot flying right, clearly dangerous, bright center with dark red edges, crisp silhouette, 16x16 canvas, transparent background, pixel art enemy projectile
```

### 4. 枪口火焰

最终规格：每帧32×32，3帧横排。

```text
Top-down pixel game muzzle-flash animation, exactly 3 frames arranged horizontally: small yellow flash, bright orange-yellow starburst, rapidly fading dark-orange sparks. Muzzle origin at the center-left of every frame, no overlapping frames, transparent background, pixel art muzzle flash sprite strip, 3 frames horizontal
```

### 5. 子弹命中

最终规格：每帧32×32，4帧横排。

```text
Pixel game bullet-impact effect, exactly 4 frames arranged horizontally: white-yellow contact point, orange star-shaped impact, a few spreading pixel fragments, rapid fade. Short and readable, no blood, transparent background, pixel art bullet impact sprite strip, 4 frames horizontal
```

### 6. 敌人死亡烟尘

最终规格：每帧64×64，6帧横排。

```text
Top-down pixel game enemy disappearance effect, exactly 6 frames arranged horizontally: small gray-brown dust puff appears, expands, reaches maximum size, separates, fades, disappears. Include a few dark pixel fragments, non-gory, no body parts, transparent background, pixel art death puff sprite strip, 6 frames horizontal
```

### 7. 经验宝石

最终规格：每帧24×24，4帧横排。

```text
Top-down pixel game experience gem, a small green-cyan diamond crystal, exactly 4 frames in a horizontal seamless loop: dim glow, normal, bright sparkle, normal. Keep silhouette and position identical across frames, suitable for many simultaneous drops, transparent background, pixel art experience gem sprite strip, 4 frames horizontal
```

### 8. Boss登场警告标志

最终规格：128×128；透明背景。

```text
Pixel game boss warning icon, a dark red triangular warning sign containing a simple combination of beast claw marks and an exclamation symbol, thick dark outline, a few orange highlights, tense and highly visible, no words, transparent background, pixel art boss warning icon
```

## 七、地图瓦片与场景物件

### 地图通用要求

```text
Strict top-down view, no horizon, orthographic projection, 32x32 seamless pixel tile, all four edges must connect continuously, consistent light from the upper left, pixel density matching 64x64 characters, no characters, no text, no UI, no perspective-facing walls
```

每套地面建议分别生成单张瓦片，再人工整理为图集。不要让即梦一次生成带文字标签的完整瓦片表。

### 1. 村庄外围

#### 地面瓦片

分别生成：普通草地、稀疏草地、泥土路、草地到泥路的边缘、浅色村口硬土地、金黄农田。

```text
Top-down rural pixel map tile showing {regular grass / sparse grass / dirt road / grass-to-dirt transition edge / pale packed earth / mature golden farmland}. Muted green and earthy brown palette, a few natural pixel details, 32x32 seamless texture, continuous on all four edges, no objects, no broken shadow seams, seamless top-down pixel art terrain tile
```

#### 独立物件

为木屋、木栅栏、草垛、木箱、阔叶树、灌木分别生成独立透明PNG：

```text
Top-down rural pixel map prop: {small wooden house / straight wooden fence section / round haystack / old wooden crate / dense broadleaf tree / low bush}. Simple village style, muted brown-green palette, consistent light from the upper left, subtle grounding shadow beneath the object, centered complete subject, transparent background, top-down pixel art village prop
```

### 2. 幽暗森林

#### 地面瓦片

分别生成：深色林地、苔藓地面、潮湿泥路、落叶地面、林地道路边缘。

```text
Top-down dark forest pixel map tile showing {dark forest floor / mossy ground / wet dirt path / brown leaf-covered ground / forest-to-path transition edge}. Muted deep green and gray-brown palette, mysterious but clearly readable, a few fallen leaves and small stones, 32x32 seamless texture, continuous on all four edges, seamless top-down pixel art forest tile
```

#### 独立物件

```text
Top-down dark forest pixel map prop: {huge ancient tree / dead tree stump / gray rock / fallen log / thorny bramble / cluster of dark red mushrooms}. Deep green and gray-brown palette, crisp silhouette, consistent light from the upper left, subtle grounding shadow, centered complete subject, transparent background, top-down pixel art forest prop
```

### 3. 强盗营地

#### 地面瓦片

分别生成：干燥荒地、踩实营地地面、车辙道路、灰烬地面、营地道路边缘。

```text
Top-down bandit camp pixel map tile showing {dry wasteland / packed camp soil / rutted dirt road / ash-covered ground around a campfire / wasteland-to-road transition edge}. Muted earth brown, gray, and dark red palette, rough but clearly readable, 32x32 seamless texture, continuous on all four edges, seamless top-down pixel art bandit camp tile
```

#### 独立物件

```text
Top-down bandit camp pixel map prop: {worn triangular tent / straight sharpened wooden palisade / wooden barricade / crude watchtower / burning campfire / wooden crates and barrels}. Handmade by rural raiders, using dark red canvas, old timber, and rusty iron. Consistent light from the upper left, subtle grounding shadow, centered complete subject, transparent background, top-down pixel art bandit camp prop
```

篝火动画额外生成4帧横排：

```text
Top-down pixel game campfire, exactly 4 frames arranged horizontally as a seamless loop. A ring of stones with gently moving orange-yellow flames, stable brightness, no large glow halo, transparent background, pixel art campfire sprite strip, 4 frames horizontal
```

## 八、菜单、关卡预览与Logo

### 1. 主菜单背景

目标比例：16:9，建议生成1920×1080后裁切适配1280×720。画面中央需为标题和按钮留出干净区域。

```text
16:9 landscape pixel game main-menu background. Rural village outskirts at sunset, several distant wooden houses with chimney smoke, a wooden palisade forming the final defensive line, and a foreground road leading into the village. Faint silhouettes of beasts and bandits at the forest edge. Earthy golden sunset against deep green shadows, peaceful but tense before battle. Top-down view with a slight high-angle presentation. Leave large clean areas in the center and upper portion for the game title and buttons. No character close-up, no text, pixel art game menu background
```

### 2. 三张关卡预览图

目标比例：16:9，每张建议640×360。

村庄外围：

```text
16:9 pixel game level preview, top-down village outskirts with green grass, intersecting dirt roads, golden farmland, wooden houses, fences, and sparse trees. Clearly readable central area, muted rural palette, no characters, no text, top-down pixel art level preview
```

幽暗森林：

```text
16:9 pixel game level preview, top-down dark forest with a narrow path running through dense deep-green woodland. Large trees, fallen logs, rocks, and dark red mushrooms form obstacles. Mysterious and oppressive while keeping the path clearly readable. No characters, no text, top-down pixel art level preview
```

强盗营地：

```text
16:9 pixel game level preview, top-down bandit camp with earthy brown wasteland, a horizontal road, dark red tents, wooden palisades, a watchtower, crates, barrels, and a central campfire. Clearly readable camp layout, no characters, no text, top-down pixel art level preview
```

### 3. 游戏标题Logo底图

AI不生成中文文字，只生成可承载后期排字的徽章底图。正式标题“边境守夜人”应在Godot或图像编辑软件中使用授权中文字体排版。

```text
Pixel game title-emblem base, a horizontal weathered wooden sign with simple metal trim, a wooden-stock rifle and a farming tool crossed behind it, decorated with a few wheat stalks and torn banner cloth. Earthy gold, dark brown, and muted dark red palette. Leave a wide clean center area for adding the Chinese title later. No words, no letters, no watermark, transparent background, pixel art game title emblem
```

## 九、UI素材

### 1. 九宫格面板

最终建议：96×96，中心区域可拉伸。

```text
Pixel game nine-slice UI panel, dark gray-green semi-transparent fabric texture, thin weathered wood and dark copper border, simple fasteners in all four corners, flat clean stretchable center, no text, no icon, square, transparent background, pixel art nine-slice UI panel
```

### 2. 按钮四状态

最终建议：每个状态256×64，分别生成，后期统一裁切。

```text
Pixel game horizontal button base in the {normal / highlighted / pressed / disabled} state, weathered wooden board with a thin dark copper border, flat center reserved for adding Chinese text later, crisp silhouette, left-right symmetry, no text, no icon, transparent background, pixel art game button
```

状态配色：普通为深棕；高亮增加土金边缘；按下整体下沉变暗；禁用为低对比灰褐。

### 3. HUD图标

最终规格：32×32，逐个生成。

```text
Pixel game HUD icon showing {red heart for health / green experience gem / old pocket watch for time / simple white skull for kill count / double vertical bars for pause}. 32x32 canvas, thick dark outline, muted rural palette, clearly readable on a small mobile screen, no text, transparent background, pixel art HUD icon
```

### 4. 虚拟摇杆

底盘最终192×192：

```text
Pixel game virtual joystick base, circular dark gray-green semi-transparent leather with a wooden rim, minimal notches indicating four directions, empty center, no text, transparent background, pixel art virtual joystick base
```

摇杆头最终72×72：

```text
Pixel game virtual joystick knob, circular worn-leather cap with pale gray-green highlights, dark outline, slightly recessed center, no text, no arrow, transparent background, pixel art virtual joystick knob
```

### 5. 七个升级图标

最终规格：64×64，统一深色圆角底板和土金色边框，逐个生成。

```text
Pixel game skill-upgrade icon on a 64x64 canvas, dark gray-green rounded-square backing with a thin earthy-gold border. Center symbol: {rifle bullet with sparks for increased damage / rifle with three speed lines for increased fire rate / bullet passing through two wooden boards for piercing / three bullets flying side by side for projectile count / crosshair with long-distance range marks for range / leather boot with wind streaks for movement speed / red heart inside a shield outline for maximum health}. Simple graphic, thick outline, clearly readable on a small mobile screen, no text, transparent background, pixel art upgrade icon
```

建议文件名：

- `upgrade_damage.png`
- `upgrade_fire_rate.png`
- `upgrade_pierce.png`
- `upgrade_projectiles.png`
- `upgrade_range.png`
- `upgrade_move_speed.png`
- `upgrade_max_health.png`

### 6. 结算徽章

胜利：

```text
Pixel game victory emblem, a village wooden shield with golden wheat and a rising sun in the center, a wooden-stock rifle and hoe crossed behind it, warm earthy-gold highlights, crisp silhouette, no text, transparent background, pixel art victory emblem
```

失败：

```text
Pixel game defeat emblem, a damaged dark village wooden shield with an extinguished torch crossed over a broken fence section, muted gray-blue and dark red palette, somber but non-gory, no text, transparent background, pixel art defeat emblem
```

## 十、应用图标与启动图

### 应用图标

建议生成1024×1024母版，再导出平台所需尺寸。

```text
Square pixel game app icon, side-profile silhouette of a village guard and wooden-stock rifle in the foreground, a warmly lit small wooden house and deep green forest behind, dark red sky, bold pixel outline, high contrast, tightly focused composition, readable when reduced to a small size, no text, no frame, no watermark, pixel art mobile game app icon
```

### 启动图

目标比例16:9，中央下部预留加载提示区域。

```text
16:9 landscape pixel game splash screen, village wooden palisade before dawn, a lone guard seen from behind holding a rifle at the village entrance, a few faint dangerous eyes glowing in the distant forest. Deep blue-green shadows contrast with warm yellow village lights. Quiet and protective mood. Leave a clean area in the lower center, no text, no logo, no watermark, pixel art game splash screen
```

## 十一、最终验收检查

- 同一角色四方向的服装、武器、体型和颜色一致。
- 所有动作条帧数准确，帧宽一致，角色互不重叠。
- 角色和物件背景已真正透明，不保留白边或棋盘格图案。
- 普通敌人、精英和Boss在缩放至游戏尺寸后仍能一眼区分。
- 地图瓦片四边无接缝，障碍物轮廓与实际碰撞区域大致一致。
- UI图标缩放到32×32或64×64后仍能识别。
- 图片不含AI生成的伪文字、水印、签名或未经要求的边框。
