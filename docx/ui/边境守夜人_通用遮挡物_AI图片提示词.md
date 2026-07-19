# 《边境守夜人》通用遮挡物 AI 图片提示词

## 一、统一制作要求

- 文件命名规则：全部使用英文小写字母和下划线，避免中文、空格和特殊符号

- 使用范围：荒漠边境平原、草原边境平原、红土边境平原
- 游戏视角：固定 3/4 斜俯视
- 图片形式：单个独立物体、透明背景 PNG
- 光照方向：统一从左上方照射
- 风格：轻度写实、低多边形质感、荒漠边境、轻度废土
- 图片要求：物体完整显示，居中，不裁切，不带文字和水印
- 底部要求：接地区域清楚，方便在 Godot 中添加碰撞体
- 阴影要求：只保留轻微、紧贴物体底部的柔和阴影
- 不要生成地面、场景、人物、怪物或其他无关物体
- 推荐单图尺寸：1024 × 1024
- 正式使用时可以根据实际显示大小缩小到 256、512 或 1024

---

# 一、岩石

## 1. 小型圆润岩石

### 推荐图片文件名

```text
obstacle_rock_small_round.png
```

### 中文说明

用于地图边缘和零散点缀。底部接近圆形，碰撞体可以使用小型圆形。

### AI 图片提示词

```text
Create one isolated small desert rock obstacle for a top-down 2.5D mobile survivor game. The rock should have a compact rounded shape, a clearly visible stable base, slightly weathered surfaces, muted brown and dusty gray colors, and a simple silhouette that is easy to read at a small game scale. Use a fixed three-quarter top-down game view, showing the top and front side of the rock. Use consistent soft lighting from the upper left and a very subtle tight contact shadow directly beneath the rock. Keep the object centered, fully visible, and suitable for a simple circular collision shape. Transparent background, no ground plane, no sand patch, no grass, no other rocks, no debris, no text, no watermark, no frame, no dramatic perspective, no photorealistic environment.
```

---

## 2. 中型椭圆岩石

### 推荐图片文件名

```text
obstacle_rock_medium_oval.png
```

### 中文说明

作为普通绕行障碍。底部接近椭圆形，碰撞体可以使用椭圆或两个圆形组合。

### AI 图片提示词

```text
Create one isolated medium-sized oval desert boulder obstacle for a top-down 2.5D mobile survivor game. The boulder should be wider than it is tall, with a smooth weathered silhouette, a clearly defined oval ground footprint, a few broad natural cracks, and muted sandstone brown, dusty beige, and gray colors. Use a fixed three-quarter top-down game view, showing the upper surface and front side. Use soft lighting from the upper left and a small tight contact shadow under the base. The shape must remain simple and collision-friendly, without deep holes, sharp spikes, overhangs, or thin protrusions. Center the complete object on a transparent background. No terrain, no sand patch, no plants, no extra stones, no characters, no text, no watermark, no frame.
```

---

## 3. 长条岩石

### 推荐图片文件名

```text
obstacle_rock_long.png
```

### 中文说明

用于改变玩家走位路线。底部轮廓接近长椭圆，碰撞体可以使用胶囊形或长矩形。

### AI 图片提示词

```text
Create one isolated long low desert rock formation obstacle for a top-down 2.5D mobile survivor game. The rock should have a horizontal elongated shape, a low profile, a clear long oval ground footprint, broad weathered surfaces, and only a few simple cracks. Use muted brown, faded orange, dusty beige, and gray colors. Show the object from a fixed three-quarter top-down game view with soft light from the upper left and a subtle contact shadow directly under the base. Keep the silhouette simple, solid, and suitable for a capsule-shaped or long rectangular collision area. The complete rock must be centered and fully visible on a transparent background. No cliff, no mountain, no ground patch, no grass, no debris, no additional rocks, no text, no watermark, no frame.
```

---

# 二、沙袋

## 1. 短沙袋墙

### 推荐图片文件名

```text
obstacle_sandbag_short.png
```

### 中文说明

用于小型掩体。底部为规则短矩形，碰撞容易匹配。

### AI 图片提示词

```text
Create one isolated short sandbag barrier for a top-down 2.5D mobile survivor game set in an arid frontier wasteland. The barrier should consist of two neat layers of worn military sandbags arranged in a short straight line. Use faded tan canvas, dusty brown stains, subtle seams, and a few restrained signs of wear. The overall footprint must be a clean short rectangle with no loose bags extending far outside the base. Show the object from a fixed three-quarter top-down game view, with soft lighting from the upper left and a small tight shadow beneath it. Keep the object centered, fully visible, and easy to match with a simple rectangular collision shape. Transparent background, no ground, no weapons, no soldiers, no fence, no crates, no text, no watermark, no frame.
```

---

## 2. 长沙袋墙

### 推荐图片文件名

```text
obstacle_sandbag_long.png
```

### 中文说明

用于形成防线和改变路线。底部为规则长矩形。

### AI 图片提示词

```text
Create one isolated long straight sandbag wall for a top-down 2.5D mobile survivor game set at a desert frontier. Build it from two orderly layers of weathered military sandbags, forming one clean horizontal defensive barrier. Use muted tan, dusty beige, and faded brown canvas colors with subtle stitching and limited dirt. Keep the ground footprint long, straight, and rectangular, with no irregular curves, gaps, loose sacks, poles, weapons, or decorations. Use a fixed three-quarter top-down game view, soft lighting from the upper left, and a subtle contact shadow directly beneath the wall. Center the complete object on a transparent background and make it suitable for one long rectangular collision shape. No scenery, no ground plane, no characters, no text, no watermark, no frame.
```

---

## 3. L形沙袋墙

### 推荐图片文件名

```text
obstacle_sandbag_l_shape.png
```

### 中文说明

用于转角掩体。碰撞体可以使用两个细长矩形组合。

### AI 图片提示词

```text
Create one isolated L-shaped sandbag defensive barrier for a top-down 2.5D mobile survivor game set in an arid border wasteland. Use two neat rows of worn military sandbags forming a clear ninety-degree corner. The two arms of the L shape should be straight, balanced, and easy to identify, with a clean ground footprint suitable for two simple rectangular collision shapes. Use faded tan canvas, dusty brown wear, subtle seams, and restrained damage. Show the complete object from a fixed three-quarter top-down game view with soft lighting from the upper left and a tight subtle shadow under the base. Transparent background, centered composition, no ground, no weapons, no soldiers, no signs, no crates, no text, no watermark, no frame.
```

---

# 三、围栏

## 1. 短金属围栏

### 推荐图片文件名

```text
obstacle_fence_metal_short.png
```

### 中文说明

用于分隔小区域。底部带清晰金属底座，碰撞体使用细长矩形。

### AI 图片提示词

```text
Create one isolated short metal frontier fence segment for a top-down 2.5D mobile survivor game. The fence should use a simple industrial wire mesh panel held by two sturdy metal posts, with one narrow solid base rail along the ground so the collision footprint is clearly visible. Use weathered dark steel, muted gray metal, light rust, and a practical border checkpoint design. Keep the fence straight, compact, and readable at a small game scale. Show it from a fixed three-quarter top-down game view with soft lighting from the upper left and a subtle contact shadow along the base. Center the entire fence on a transparent background. No ground, no barbed wire loops extending outside the silhouette, no gate, no buildings, no characters, no warning text, no watermark, no frame.
```

---

## 2. 长金属围栏

### 推荐图片文件名

```text
obstacle_fence_metal_long.png
```

### 中文说明

用于长距离分区和边缘限制。底部为规则长条形。

### AI 图片提示词

```text
Create one isolated long straight metal frontier fence segment for a top-down 2.5D mobile survivor game. Use a practical industrial wire mesh panel supported by evenly spaced strong metal posts and one clear continuous base rail. The fence must have a clean long rectangular ground footprint, moderate height, simple geometry, and a weathered border checkpoint appearance. Use muted gray steel, dark metal, and subtle rust without excessive detail. Show the complete object from a fixed three-quarter top-down game view, with soft light from the upper left and a narrow contact shadow along the bottom edge. Transparent background, centered composition, no terrain, no gate, no buildings, no characters, no signs, no text, no watermark, no frame.
```

---

## 3. 破损围栏

### 推荐图片文件名

```text
obstacle_fence_metal_damaged.png
```

### 中文说明

用于地图变化和视觉丰富。整体仍保持直线底座，不要让破损部分影响碰撞范围。

### AI 图片提示词

```text
Create one isolated damaged metal frontier fence segment for a top-down 2.5D mobile survivor game. The fence should remain mostly straight with a clear rectangular base footprint, while one small upper section of the wire mesh is bent or torn to show abandonment. Keep both support posts and the lower base rail intact so the obstacle remains easy to match with a simple long rectangular collision shape. Use weathered gray steel, dark metal, restrained rust, and dusty frontier wear. Show the complete object from a fixed three-quarter top-down game view with soft lighting from the upper left and a subtle contact shadow along the base. Transparent background, centered object, no ground, no large hanging wires, no barbed wire coils, no characters, no text, no watermark, no frame.
```

---

# 四、木箱

## 1. 单个木箱

### 推荐图片文件名

```text
obstacle_crate_single.png
```

### 中文说明

最基础的通用障碍物。底部为规则正方形，碰撞体可以使用稍小的矩形。

### AI 图片提示词

```text
Create one isolated frontier supply wooden crate obstacle for a top-down 2.5D mobile survivor game. The crate should have a compact square footprint, sturdy weathered wooden boards, simple dark metal corner brackets, and restrained dusty wear. Use muted brown wood, faded gray metal, and a slightly post-apocalyptic border supply style. Show the top, front, and one side from a fixed three-quarter top-down game view. Use soft lighting from the upper left and a small tight contact shadow beneath the base. Keep the silhouette clean, square, centered, fully visible, and suitable for a simple rectangular collision shape. Transparent background, no ground, no rope, no loose boards, no open lid, no other crates, no text, no logo, no watermark, no frame.
```

---

## 2. 双层木箱

### 推荐图片文件名

```text
obstacle_crate_double_stack.png
```

### 中文说明

两个木箱垂直堆叠，但底部占地与单箱接近，用于增加视觉高度。

### AI 图片提示词

```text
Create one isolated stack of two frontier supply wooden crates for a top-down 2.5D mobile survivor game. Stack one square wooden crate directly and securely on top of another, keeping the bottom footprint compact and regular. Use weathered wooden boards, simple dark metal corner brackets, muted brown colors, dusty wear, and a light post-apocalyptic border supply style. Show the complete stack from a fixed three-quarter top-down game view, with soft lighting from the upper left and a subtle tight shadow beneath the bottom crate. Keep the stack stable, centered, fully visible, and easy to match with one simple square collision area at the base. Transparent background, no ground, no tilted boxes, no loose boards, no rope, no open lids, no text, no logo, no watermark, no frame.
```

---

## 3. 横向木箱堆

### 推荐图片文件名

```text
obstacle_crate_horizontal_row.png
```

### 中文说明

两个或三个木箱横向组合，用于形成较长的路线遮挡。碰撞体使用长矩形。

### AI 图片提示词

```text
Create one isolated horizontal stack of three frontier supply wooden crates for a top-down 2.5D mobile survivor game. Arrange the crates tightly side by side in one straight row, forming a clean long rectangular footprint. Use sturdy weathered wooden boards, simple dark metal corner brackets, muted brown wood, faded gray metal, and restrained dusty wear. Show the top, front, and side surfaces from a fixed three-quarter top-down game view. Use soft lighting from the upper left and a narrow contact shadow directly beneath the complete row. Keep all crates aligned, centered, fully visible, and suitable for one long rectangular collision shape. Transparent background, no ground, no uneven stacking, no loose boards, no rope, no additional objects, no text, no logo, no watermark, no frame.
```

---

# 五、统一生成检查

生成每张图片后，需要检查以下内容：

1. 是否只有一个独立障碍物。
2. 背景是否真正透明。
3. 视角是否统一为 3/4 斜俯视。
4. 光照是否统一来自左上方。
5. 物体是否完整，没有被裁切。
6. 底部接地区域是否清楚。
7. 底部轮廓是否适合简单碰撞体。
8. 是否存在过大的空白区域。
9. 是否误生成文字、标志或场景背景。
10. 是否能够与另外三类障碍物保持一致的比例和风格。

---

# 六、第一版推荐实际生成数量

建议第一版先生成以下 8 张即可：

1. 中型椭圆岩石
2. 长条岩石
3. 短沙袋墙
4. 长沙袋墙
5. 短金属围栏
6. 长金属围栏
7. 单个木箱
8. 横向木箱堆

确认风格统一后，再补充其他变体。
