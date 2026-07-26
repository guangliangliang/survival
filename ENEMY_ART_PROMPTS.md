# 敌人美术生成提示词

本文档用于使用 AI 图像工具重新生成敌人美术资源。

> 重要：在使用下面任意单个敌人的提示词之前，请先阅读
> **「动画质量 — 关键规则」** 一节。把那些规则（尤其是
> 禁止平移、腿部动作要大而明显、帧间干净分隔）附加到你发给
> 图像工具的走路/攻击提示词末尾。之前的美术之所以失败，主要是
> 因为各帧看起来像同一姿势横向平移、腿几乎没动 —— 这些规则就是
> 为了避免这种情况。

尽量为每个敌人使用一张参考图。为每个敌人生成两张精灵表：

- `*_single.png`：一张高分辨率透明单帧敌人图，用于锁定设计
- `*_walk_right_4.png`：4 列 × 1 行，向右走
- `*_attack_right_4.png`：4 列 × 1 行，向右攻击

朝左的动画可以之后通过水平翻转朝右的精灵表来制作。

## 入库前归一化

AI 生成的走路/攻击精灵表不能直接放进游戏使用，必须先运行归一化工具：

```powershell
& "C:\Users\ASUS\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" scripts\tools\normalize_enemy_sprites.py --overwrite
```

原因：`scripts/systems/Enemy.gd` 当前按 4 帧读取敌人动画，每帧宽度为 612px，帧与帧之间有 20px 透明间隔；最终整张表仍保持 `2508x627`。归一化工具会把 AI 常见的 4 等分输出重新裁切、统一缩放、底部基线对齐，并清空 20px gap，避免前后帧残影或串帧。

## 地图敌人清单

当前地图使用以下敌人角色：

| 地图 | 敌人 | Boss |
|---|---|---|
| 村庄外围 | 野狼、野猪、强盗 | 狼王 |
| 黑暗森林 | 野狼、野猪、强盗、强盗精英 | 森林巨兽 |
| 强盗营地 | 强盗、邪教巫师、强盗火铳手、强盗精英、野猪 | 强盗头目 |

说明：

- `gunner`（枪手）被有意替换为 `cult_wizard`（邪教巫师），因为人类阵营应避免使用枪械。
- 如果人类阵营需要一个物理远程敌人，可以使用 `musketeer_bandit`（强盗火铳手）。它应当像一个使用老式黑火药的强盗，而不是现代枪手。
- `thorn_porcupine`（荆棘豪猪）是一个规划中的动物远程敌人，之后可以加入森林/村庄的刷怪池。

## 共享要求

每条提示词都需遵循以下要求：

- 透明 PNG 精灵表。
- 严格的水平网格：4 列 1 行。
- 4 帧中的敌人设计完全相同。
- 每帧中都是一个完整的敌人，居中放置。
- 每帧使用相同的隐形单元格尺寸。
- 脚/爪对齐到同一条水平基线。
- 各帧身体中心大致一致，避免动画抖动。
- 无棋盘格背景、无地面、无阴影、无文字、无数字、无标签、无 UI、无多余物体。
- 高质量 2D 游戏精灵，剪影清晰易读，暗黑奇幻生存风格。
- 侧面 3/4 游戏精灵视角，仅带轻微俯视角度。

## 动画质量 — 关键规则（请先阅读，适用于每一张走路/攻击精灵表）

设立这些规则，是因为之前的生成结果中各帧看起来像同一姿势横向滑动（「平移」），腿几乎不动。使用时把下面这段英文规则附加到走路/攻击提示词的末尾：

```text
CRITICAL ANIMATION RULES (must follow strictly):
- NO TRANSLATION: Do NOT create the animation by moving or sliding the same drawing horizontally. Each frame must be a genuinely re-drawn pose. If the character were removed and the 4 frames overlaid, the torso and head must sit at the SAME horizontal position; only the limbs and body posture change.
- BIG, OBVIOUS LEG MOTION: The legs must swing through a LARGE range. In a walk cycle the two visible legs must clearly ALTERNATE — when one leg is stretched fully forward, the opposite leg must be stretched fully back, with a wide visible gap between them. Exaggerate the stride so it reads clearly at 64x64 pixels.
- EVERY FRAME DIFFERENT: All 4 frames must be distinctly different poses. Never duplicate or near-duplicate a frame. Frame-to-frame limb positions must change noticeably.
- FIXED FEET BASELINE, VERTICAL BOB ONLY: Feet touch the same horizontal ground line in every frame. The body may bob slightly UP and DOWN between steps, but must NOT drift left or right.
- CLEAN FRAME SEPARATION: Leave a fixed empty transparent margin of exactly 10% of the cell width on EACH side of every frame (so the gap between two adjacent characters is about 20% of a cell width), kept identical for all 4 frames. Neighboring frames must never touch or overlap. Nothing from one frame may bleed into the next cell.
- LEGS ALWAYS VISIBLE: Legs and feet must be fully drawn and clearly separated from the body silhouette in every frame — never hide the legs behind the body or crop them at the bottom edge.
- CONSISTENT SCALE & DESIGN: Same character size, colors, and proportions in all 4 frames.
```

## 1. 野狼 (Wolf)

游戏 ID：`wolf`

中文名：`野狼`

定位：快速近战动物敌人。

最终文件名：

- `enemy_wolf_single.png`
- `enemy_wolf_walk_right_4.png`
- `enemy_wolf_attack_right_4.png`

### 单帧透明图

```text
Use the reference wolf image only as design inspiration.

Create one high-resolution transparent PNG of a dark gray hostile wolf enemy for a 2D survival game. The wolf should be a full-body creature sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Lean wild wolf body, dark charcoal gray shaggy fur, sharp pointed ears, long narrow snout, glowing yellow-green eyes, visible teeth, sharp claws, tense shoulders, lowered head, aggressive hunting posture, threatening expression. The silhouette must be clear and readable for a small game sprite.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, slightly stylized but not cute, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire wolf must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference wolf image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same dark gray hostile wolf walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The wolf must be fully visible and centered inside each cell. The wolf's feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a natural four-legged wolf walking cycle. The leg positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near front leg reaches forward, far rear leg pushes backward, other two legs support the body.
Frame 2: near front leg is planted under the shoulder, far rear leg moves forward under the body, body slightly lower.
Frame 3: far front leg reaches forward, near rear leg pushes backward, opposite diagonal pair active.
Frame 4: far front leg is planted under the shoulder, near rear leg moves forward under the body, body slightly higher.

Make the paws visibly different in each frame. Keep clear gaps between the legs. Add subtle shoulder sway, hip sway, head bobbing, and tail movement. Exaggerate the leg motion enough to be readable at 64x64 pixels.

Character style:
Same dark charcoal gray hostile wolf in every frame, shaggy fur, lean wild body, sharp ears, glowing yellow-green eyes, visible teeth, aggressive expression. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference wolf image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same dark gray hostile wolf attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The wolf must be fully visible and centered inside each cell. The wolf's feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent across all frames so the animation does not jitter, while still allowing a small forward lunge during the attack.

Animation requirements:
Create a fast wolf bite attack animation. The 4 frames must be clearly different poses.

Frame 1: anticipation pose, the wolf crouches low, head lowered, legs bent, shoulders tense, jaws starting to open.
Frame 2: lunge pose, the wolf pushes forward slightly inside the cell, front claws extended, mouth wide open, body stretched toward the target.
Frame 3: bite impact pose, jaws fully open with visible teeth, head thrust forward, claws striking, body at maximum extension.
Frame 4: recovery pose, the wolf pulls back after biting, jaws partially closed, body recoiling, legs returning under the body.

The attack should feel like a bite animation, not a sliding copy of the same pose. Keep the paws and body posture visibly different in each frame.

Character style:
Same dark charcoal gray hostile wolf in every frame, shaggy fur, lean wild body, sharp ears, glowing yellow-green eyes, visible teeth, aggressive expression. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 2. 野猪 (Boar)

游戏 ID：`boar`

中文名：`野猪`

定位：坚实的近战动物敌人。

最终文件名：

- `enemy_boar_single.png`
- `enemy_boar_walk_right_4.png`
- `enemy_boar_attack_right_4.png`

### 单帧透明图

```text
Use the reference boar image only as design inspiration.

Create one high-resolution transparent PNG of a hostile wild boar enemy for a 2D survival game. The boar should be a full-body creature sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Compact muscular body, dark brown coarse bristles, short sturdy legs, lowered head, sharp tusks, angry eyes, heavy shoulders, aggressive charging posture. The silhouette must clearly read as a dangerous boar, not a pig.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, slightly stylized but not cute, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire boar must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference boar image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same hostile wild boar walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The boar must be fully visible and centered inside each cell. The boar's hooves must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a heavy four-legged boar walking cycle. The leg positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near front leg steps forward, far rear leg pushes back, head slightly lowered.
Frame 2: legs gather under the heavy body, shoulders dip slightly.
Frame 3: far front leg steps forward, near rear leg pushes back, hips shift forward.
Frame 4: legs pass under the body, head and shoulders rise slightly.

Make the hooves visibly different in each frame. Add subtle shoulder sway, hip sway, head bobbing, and tail movement. The walk should feel heavy and grounded, readable at 64x64 pixels.

Character style:
Same hostile wild boar in every frame, dark brown coarse bristles, compact muscular body, short legs, sharp tusks, angry eyes, lowered head, aggressive charging posture. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference boar image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same hostile wild boar attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The boar must be fully visible and centered inside each cell. The hooves must align to the same horizontal baseline in every frame. The body center must stay mostly consistent, while allowing a small forward thrust during the attack.

Animation requirements:
Create a tusk charge attack animation with 4 clearly different poses.

Frame 1: anticipation pose, boar lowers its head, bends its legs, shoulders tense, tusks aimed forward.
Frame 2: charge start, boar pushes forward, front hooves digging in, head thrusting toward the target.
Frame 3: impact pose, tusks fully forward, body compressed and powerful, bristles raised, angry expression.
Frame 4: recovery pose, boar pulls its head back, legs return under the body, body rebounds after impact.

The attack should feel like a heavy tusk ram, not a sliding copy of the same pose.

Character style:
Same hostile wild boar in every frame, dark brown coarse bristles, compact muscular body, short legs, sharp tusks, angry eyes, lowered head. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 3. 荆棘豪猪 (Thorn Porcupine)

游戏 ID：`thorn_porcupine`

中文名：`荆棘豪猪`

定位：发射毒刺的远程动物敌人。

最终文件名：

- `enemy_thorn_porcupine_single.png`
- `enemy_thorn_porcupine_walk_right_4.png`
- `enemy_thorn_porcupine_attack_right_4.png`

### 单帧透明图

```text
Create one high-resolution transparent PNG of a hostile thorn porcupine enemy for a 2D survival game. The porcupine should be a full-body creature sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Low stocky body, dark brown and black fur, many long sharp green-tinted poison quills covering its back, small glowing yellow-green eyes, short legs, tense crouched posture, threatening expression, not cute. The quills must be the main readable silhouette feature.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire porcupine must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same hostile thorn porcupine walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The porcupine must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a low, cautious four-legged walking cycle. The leg positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near front foot reaches forward, far rear foot pushes back, body low.
Frame 2: feet gather under the body, shoulders dip slightly.
Frame 3: far front foot reaches forward, near rear foot pushes back, quill-covered back shifts subtly.
Frame 4: feet pass under the body, body rises slightly.

Make the small paws visibly different in each frame. Add subtle head bobbing, shoulder movement, hip movement, and quill movement. The walk should feel low and tense, readable at 64x64 pixels.

Character style:
Same hostile thorn porcupine in every frame, low stocky body, dark brown and black fur, many long sharp green-tinted poison quills on its back, small glowing yellow-green eyes, threatening expression, not cute. Side-facing 3/4 game sprite view with only a slight top-down angle, legs and quills clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same hostile thorn porcupine attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The porcupine must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent across all frames.

Animation requirements:
Create a poison quill shooting attack animation with 4 clearly different poses.

Frame 1: anticipation pose, porcupine crouches low, quills begin to rise, eyes glowing.
Frame 2: charge pose, back arches, poison quills stand upright, green venom glow appears on quill tips.
Frame 3: release pose, several sharp poison quills shoot forward to the right, body recoils slightly.
Frame 4: recovery pose, quills settle back down, body relaxes, paws return under the body.

The attack should clearly read as firing poison spikes from its back, not biting or charging.

Character style:
Same hostile thorn porcupine in every frame, low stocky body, dark brown and black fur, many long green-tinted poison quills, glowing yellow-green eyes, threatening expression, not cute. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 4. 狼王 (Alpha Wolf)

游戏 ID：`alpha_wolf`

中文名：`狼王`

定位：动物 Boss / 精英狼。

最终文件名：

- `enemy_alpha_wolf_single.png`
- `enemy_alpha_wolf_walk_right_4.png`
- `enemy_alpha_wolf_attack_right_4.png`

### 单帧透明图

```text
Use the reference alpha wolf image only as design inspiration.

Create one high-resolution transparent PNG of a large alpha wolf boss enemy for a 2D survival game. The alpha wolf should be a full-body creature sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Larger and more dominant than a normal wolf, dark gray and black shaggy fur, raised mane, sharp ears, glowing yellow-green eyes, visible teeth, long claws, scarred face or body, tense shoulders, lowered head, violent boss-like hunting posture. The silhouette must feel powerful and readable at small size.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, slightly stylized but not cute, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire alpha wolf must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference alpha wolf image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same large alpha wolf walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The alpha wolf must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a powerful four-legged wolf walking cycle. The leg positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near front leg reaches forward, far rear leg pushes backward, other two legs support the body.
Frame 2: near front leg is planted under the shoulder, far rear leg moves forward under the body, body slightly lower.
Frame 3: far front leg reaches forward, near rear leg pushes backward, opposite diagonal pair active.
Frame 4: far front leg is planted under the shoulder, near rear leg moves forward under the body, body slightly higher.

Make the paws visibly different in each frame. Add strong shoulder sway, hip sway, head bobbing, tail movement, and subtle mane movement. The walk should feel heavier and more dominant than a normal wolf.

Character style:
Same large alpha wolf in every frame, larger body than a normal wolf, dark gray and black shaggy fur, raised mane, sharp ears, glowing yellow-green eyes, visible teeth, long claws, scarred and dominant boss-like expression. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference alpha wolf image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same large alpha wolf attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The alpha wolf must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent, while allowing a strong forward lunge during the attack.

Animation requirements:
Create a powerful boss wolf bite and claw attack animation with 4 clearly different poses.

Frame 1: anticipation pose, alpha wolf crouches low, mane raised, head lowered, legs bent, shoulders tense.
Frame 2: lunge pose, alpha wolf surges forward, front claws extended, mouth wide open, body stretched toward the target.
Frame 3: impact pose, jaws fully open with visible teeth, claws slashing forward, mane flaring, body at maximum extension.
Frame 4: recovery pose, alpha wolf pulls back, jaws partially closed, body recoiling, legs returning under the body.

The attack should feel stronger and more violent than a normal wolf bite.

Character style:
Same large alpha wolf in every frame, dark gray and black shaggy fur, raised mane, glowing yellow-green eyes, visible teeth, long claws, scarred boss-like expression. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 5. 森林巨兽 (Forest Beast)

游戏 ID：`forest_beast`

中文名：`森林巨兽`

定位：大型森林 Boss。

最终文件名：

- `enemy_forest_beast_single.png`
- `enemy_forest_beast_walk_right_4.png`
- `enemy_forest_beast_attack_right_4.png`

### 单帧透明图

```text
Use the reference forest beast image only as design inspiration.

Create one high-resolution transparent PNG of a massive forest beast boss enemy for a 2D survival game. The forest beast should be a full-body monster sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Huge hulking body, dark green and brown fur, mossy back, bark-like armor plates, branch-like horns or antlers, glowing eyes, large claws, ancient forest monster silhouette, heavy shoulders, powerful limbs, threatening boss posture, not cute. The silhouette must feel large, slow, and dangerous.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire forest beast must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference forest beast image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same massive forest beast walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The forest beast must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a slow heavy monster walking cycle. The leg positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: one massive front limb plants forward, opposite rear limb pushes back, shoulders leaning forward.
Frame 2: heavy weight shifts onto planted limbs, body dips lower, head lowers.
Frame 3: opposite front limb plants forward, opposite rear limb pushes back, hips shift.
Frame 4: body rises slightly, limbs gather under the body before the next step.

Make the feet visibly different in each frame. Add heavy shoulder sway, hip sway, head bobbing, and subtle movement in fur, moss, branches, or growths. The walk should feel huge, slow, and heavy.

Character style:
Same massive forest beast in every frame, huge hulking body, dark green and brown fur, mossy back, bark-like armor plates, branch-like horns or antlers, glowing eyes, large claws, ancient forest monster silhouette, not cute. Side-facing 3/4 game sprite view with only a slight top-down angle, limbs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference forest beast image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same massive forest beast attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The forest beast must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent, while allowing a heavy forward strike.

Animation requirements:
Create a heavy claw slam attack animation with 4 clearly different poses.

Frame 1: anticipation pose, forest beast raises one huge claw, shoulders twist, head lowers, body gathers power.
Frame 2: wind-up pose, claw lifted high and forward, torso stretched, moss and branches moving.
Frame 3: impact pose, claw slams downward and forward, body compressed, mouth open, eyes glowing brighter.
Frame 4: recovery pose, claw pulls back, body rises from the slam, limbs return under the body.

The attack should feel like a huge crushing boss strike, not a fast bite.

Character style:
Same massive forest beast in every frame, huge hulking body, dark green and brown fur, mossy back, bark-like armor plates, branch-like horns or antlers, glowing eyes, large claws, ancient forest monster silhouette. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 6. 强盗 (Bandit)

游戏 ID：`bandit`

中文名：`强盗`

定位：基础近战人类敌人。

最终文件名：

- `enemy_bandit_single.png`
- `enemy_bandit_walk_right_4.png`
- `enemy_bandit_attack_right_4.png`

### 单帧透明图

```text
Use the reference bandit image only as design inspiration.

Create one high-resolution transparent PNG of a rough bandit enemy for a 2D survival game. The bandit should be a full-body human sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Ragged dark clothing, leather straps, hood or head wrap, dirty face, small axe or short blade, aggressive posture, hostile expression, worn survival gear, no gun, no modern weapon. The silhouette must clearly read as a basic melee bandit.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire bandit must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference bandit image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same bandit walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The bandit must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a natural human walking cycle. The leg and arm positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near leg steps forward, far arm swings forward, weapon hand held ready.
Frame 2: feet pass under the body, body slightly lower, arms crossing through neutral.
Frame 3: far leg steps forward, near arm swings forward, shoulders shift.
Frame 4: feet pass under the body again, body slightly higher, ready for the next step.

Make the feet visibly different in each frame. Add subtle shoulder sway, hip sway, head bobbing, cloth movement, and weapon movement. The walk should feel like a cautious hostile bandit.

Character style:
Same rough bandit in every frame, ragged dark clothing, leather straps, hood or head wrap, dirty face, small axe or short blade, aggressive expression, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference bandit image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same bandit attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The bandit must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent, while allowing a small forward step during the attack.

Animation requirements:
Create a short melee slash attack animation with 4 clearly different poses.

Frame 1: anticipation pose, bandit bends knees, pulls short blade or axe back, shoulders tense.
Frame 2: swing start, bandit steps forward slightly, weapon begins slashing toward the right.
Frame 3: impact pose, weapon fully extended in a clear slash arc, torso twisted, aggressive expression.
Frame 4: recovery pose, weapon follows through, body pulls back, feet return under the body.

The attack should read as a close-range melee strike. Do not use guns.

Character style:
Same rough bandit in every frame, ragged dark clothing, leather straps, hood or head wrap, dirty face, small axe or short blade, aggressive expression, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 7. 邪教巫师 (Cult Wizard)

游戏 ID：`cult_wizard`

中文名：`邪教巫师`

定位：替代旧枪手的远程人类敌人。

最终文件名：

- `enemy_cult_wizard_single.png`
- `enemy_cult_wizard_walk_right_4.png`
- `enemy_cult_wizard_attack_right_4.png`

### 单帧透明图

```text
Create one high-resolution transparent PNG of a dark cult wizard enemy for a 2D survival game. The cult wizard should be a full-body human sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Hooded robe, tattered cloak, bone charms or occult ornaments, glowing purple or green eyes hidden under the hood, wooden staff or ritual dagger, sinister posture, dark magic atmosphere, no gun, no modern weapon. The silhouette must clearly read as a ranged spellcaster enemy.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire cult wizard must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same cult wizard walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The cult wizard must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a slow human walking cycle under a robe. The foot, robe, arm, and staff positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near foot steps forward under the robe, staff hand slightly forward.
Frame 2: feet pass under the robe, body slightly lower, robe folds sway.
Frame 3: far foot steps forward, opposite arm moves, staff shifts backward.
Frame 4: feet pass under the robe again, body slightly higher, robe settles.

Make the movement readable even with a robe. Add subtle hood bobbing, sleeve movement, robe sway, and staff movement.

Character style:
Same dark cult wizard in every frame, hooded robe, tattered cloak, bone charms or occult ornaments, glowing purple or green eyes under the hood, wooden staff or ritual dagger, sinister expression, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle, feet and robe motion clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same cult wizard attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The cult wizard must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent across all frames.

Animation requirements:
Create a dark magic projectile casting animation with 4 clearly different poses.

Frame 1: anticipation pose, wizard raises one hand or staff, hood lowered, robe tense.
Frame 2: charging pose, glowing dark magic gathers near the hand or staff tip, sleeves and robe lift slightly.
Frame 3: release pose, wizard thrusts hand or staff forward to the right, a dark purple or green magic bolt begins firing.
Frame 4: recovery pose, magic glow fades, arm lowers slightly, robe settles.

The attack should clearly read as casting a ranged spell. Do not use guns or modern weapons.

Character style:
Same dark cult wizard in every frame, hooded robe, tattered cloak, bone charms or occult ornaments, glowing purple or green eyes under the hood, wooden staff or ritual dagger, sinister expression, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 8. 强盗火铳手 (Musketeer Bandit)

游戏 ID：`musketeer_bandit`

中文名：`强盗火铳手`

定位：使用老式黑火药枪械的物理远程人类敌人。

最终文件名：

- `enemy_musketeer_bandit_single.png`
- `enemy_musketeer_bandit_walk_right_4.png`
- `enemy_musketeer_bandit_attack_right_4.png`

### 单帧透明图

```text
Create one high-resolution transparent PNG of a musketeer bandit enemy for a 2D survival game. The musketeer bandit should be a full-body human sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Rough outlaw clothing, worn leather armor, torn cloak or scarf, powder horn, ammunition pouch, old black-powder musket or hand cannon, dirty face, hostile expression, survival bandit style. The weapon must look like an old primitive firearm, not a modern rifle or pistol. The silhouette must clearly read as a physical ranged bandit enemy.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style, no modern military style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire musketeer bandit must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference musketeer bandit image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same musketeer bandit walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The musketeer bandit must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a cautious human walking cycle while carrying an old musket. The leg, arm, shoulder, cloak, and weapon positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near leg steps forward, musket held low and ready, far arm balancing the weapon.
Frame 2: feet pass under the body, body slightly lower, cloak and weapon shift.
Frame 3: far leg steps forward, musket sways subtly to the opposite side, shoulders shift.
Frame 4: feet pass under the body again, body slightly higher, weapon returns to ready position.

Make the feet visibly different in each frame. The walk should feel like a cautious ranged bandit keeping distance from the player.

Character style:
Same musketeer bandit in every frame, rough outlaw clothing, worn leather armor, torn cloak or scarf, powder horn, ammunition pouch, old black-powder musket or hand cannon, hostile expression. The weapon must look primitive and old, not modern. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference musketeer bandit image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same musketeer bandit attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The musketeer bandit must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent across all frames, while allowing recoil during the shot.

Animation requirements:
Create an old black-powder musket firing animation with 4 clearly different poses.

Frame 1: anticipation pose, musketeer bandit raises the musket, feet planted, shoulders tense.
Frame 2: aiming pose, musket aimed to the right, one eye focused down the barrel, body steady.
Frame 3: firing pose, bright muzzle flash and smoke burst from the old musket, body recoils backward, cloak moves.
Frame 4: recovery pose, smoke fading, musket lowers slightly, body returns to balance as if preparing to reload.

The attack should clearly read as a slow powerful black-powder shot. Do not use a modern rifle, pistol, assault weapon, scope, laser sight, or military gear.

Character style:
Same musketeer bandit in every frame, rough outlaw clothing, worn leather armor, torn cloak or scarf, powder horn, ammunition pouch, old black-powder musket or hand cannon, hostile expression. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```
## 9. 强盗精英 (Elite Bandit)

游戏 ID：`elite_bandit`

中文名：`强盗精英`

定位：披甲近战精英。

最终文件名：

- `enemy_elite_bandit_single.png`
- `enemy_elite_bandit_walk_right_4.png`
- `enemy_elite_bandit_attack_right_4.png`

### 单帧透明图

```text
Use the reference elite bandit image only as design inspiration.

Create one high-resolution transparent PNG of an elite bandit enemy for a 2D survival game. The elite bandit should be a full-body human sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Rugged armor pieces, reinforced leather and metal plates, intimidating mask or helmet, large axe or heavy blade, veteran posture, heavier and more dangerous than a normal bandit, no gun, no modern weapon. The silhouette must clearly read as an armored melee elite.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire elite bandit must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference elite bandit image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same elite bandit walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The elite bandit must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a heavy human walking cycle. The leg, arm, shoulder, armor, and weapon positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near leg steps forward, heavy weapon held ready, shoulder armor shifts.
Frame 2: feet pass under the body, body dips lower under armor weight.
Frame 3: far leg steps forward, weapon and shoulders sway to the opposite side.
Frame 4: feet pass under the body again, body rises slightly.

Make the feet visibly different in each frame. The walk should feel heavier and more confident than a normal bandit.

Character style:
Same elite bandit in every frame, rugged armor pieces, reinforced leather and metal plates, intimidating mask or helmet, large axe or heavy blade, aggressive veteran posture, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference elite bandit image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same elite bandit attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The elite bandit must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent, while allowing a small forward step during the attack.

Animation requirements:
Create a heavy weapon slash attack animation with 4 clearly different poses.

Frame 1: anticipation pose, elite bandit plants feet, pulls heavy axe or blade back, shoulders tense.
Frame 2: wind-up pose, weapon rises or draws back farther, torso twists, armor shifts.
Frame 3: impact pose, weapon swings powerfully toward the right, body leans into the strike, clear slash silhouette.
Frame 4: recovery pose, weapon follows through, body returns to guard, feet stabilize.

The attack should feel like a strong elite melee strike. Do not use guns.

Character style:
Same elite bandit in every frame, rugged armor pieces, reinforced leather and metal plates, intimidating mask or helmet, large axe or heavy blade, aggressive veteran posture, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

## 10. 强盗头目 (Bandit Chief)

游戏 ID：`bandit_chief`

中文名：`强盗头目`

定位：人类阵营 Boss。

最终文件名：

- `enemy_bandit_chief_single.png`
- `enemy_bandit_chief_walk_right_4.png`
- `enemy_bandit_chief_attack_right_4.png`

### 单帧透明图

```text
Use the reference bandit chief image only as design inspiration.

Create one high-resolution transparent PNG of a bandit chief boss enemy for a 2D survival game. The bandit chief should be a full-body human boss sprite, facing RIGHT, viewed from a side-facing 3/4 game sprite view with only a slight top-down angle.

Design details:
Large imposing human boss, heavy patched armor, fur mantle or torn cloak, skull or bone trophies, scarred face or brutal mask, huge axe or cleaver, dominant stance, dangerous boss posture, no gun, no modern weapon. The silhouette must clearly read as a powerful human faction boss.

Style:
High-quality 2D game art, hand-painted sprite style, crisp edges, clean readable shape, dark fantasy survival atmosphere. No realistic photo style, no cartoon mascot style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No UI. No extra objects. The entire bandit chief must be visible, centered, with enough empty space around it for cropping.
```

### 向右走 4 帧

```text
Use the reference bandit chief image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same bandit chief walking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The bandit chief must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay consistent across all frames so the animation does not jitter.

Animation requirements:
Create a slow powerful boss walking cycle. The leg, arm, shoulder, cloak, armor, and weapon positions must change clearly in every frame. Do not duplicate the same pose.

Frame 1: near leg steps forward, huge weapon held ready, cloak trails behind.
Frame 2: feet pass under the body, body dips lower, armor and cloak sway.
Frame 3: far leg steps forward, shoulders shift, weapon weight swings slightly.
Frame 4: feet pass under the body again, body rises slightly, cloak settles.

Make the feet visibly different in each frame. The walk should feel dominant, heavy, and boss-like.

Character style:
Same bandit chief in every frame, large imposing human boss, heavy patched armor, fur mantle or torn cloak, skull or bone trophies, scarred face or brutal mask, huge axe or cleaver, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle, legs clearly visible. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```

### 向右攻击 4 帧

```text
Use the reference bandit chief image as the exact character design.

Create ONE transparent PNG sprite sheet for a 2D game. The image must be a strict horizontal sprite sheet with 4 columns and 1 row, 4 frames total.

All 4 frames must show the same bandit chief attacking to the RIGHT. Do not include left-facing poses.

Layout requirements:
Each frame must be placed inside an invisible identical-size cell. All 4 cells must have the same width and height. Keep equal spacing between cells. The bandit chief must be fully visible and centered inside each cell. The feet must align to the same horizontal baseline in every frame. The body center must stay mostly consistent, while allowing a strong forward boss strike.

Animation requirements:
Create a brutal boss heavy weapon attack animation with 4 clearly different poses.

Frame 1: anticipation pose, bandit chief plants feet wide, raises huge axe or cleaver, shoulders tense.
Frame 2: wind-up pose, weapon lifted high or pulled far back, cloak and fur mantle moving, torso twisted.
Frame 3: impact pose, weapon crashes forward to the right in a powerful slash or chop, body leaning into the strike.
Frame 4: recovery pose, weapon follows through, body recoils, feet return to a stable stance.

The attack should feel like a dangerous boss melee attack. Do not use guns.

Character style:
Same bandit chief in every frame, large imposing human boss, heavy patched armor, fur mantle or torn cloak, skull or bone trophies, scarred face or brutal mask, huge axe or cleaver, no gun. Side-facing 3/4 game sprite view with only a slight top-down angle. High-quality 2D game sprite, crisp silhouette, dark fantasy survival style.

Transparent background only. No checkerboard background. No ground. No shadow. No text. No numbers. No labels. No UI. No extra objects. Do not create a character concept sheet. Do not make identical frames.
```
