# 游戏新增技能资源需求清单

> **文档说明：** 这是为《边境守夜人》游戏新增两个技能所需的资源清单。所有资源均可以通过AI生成，提示词已准备好。

---

## 资源目录结构

```
assets/
├── images/
│   └── ui/
│       └── icons/
│           ├── sword.svg       (新增: 剑雨风暴按钮图标)
│           └── heal.svg        (新增: 治疗技能按钮图标)
├── audio/
│   └── sfx/
│       ├── sfx_sword_rain.wav  (新增: 剑雨施放音效)
│       └── sfx_heal_cast.wav   (新增: 治疗施放音效)
```

---

## 图片资源 (2个)

### 1. sword.svg - 剑雨风暴图标

**用途：** 虚拟按钮上的技能图标

**设计要求：**
- 风格：简约、扁平化
- 颜色：金色/银色金属质感
- 形状：单把剑或交叉双剑
- 尺寸：64x64 适配缩放
- 背景：透明

**AI生成提示词 (SVG/PNG):**
```
minimalist icon of a medieval sword, flat design style, metallic silver and gold color palette, sharp clean lines, transparent background, game UI icon, 64x64 pixels, high contrast, no shadows, vector style, suitable for action RPG skill button
```

---

### 2. heal.svg - 治疗技能图标

**用途：** 虚拟按钮上的技能图标

**设计要求：**
- 风格：简约、扁平化
- 颜色：绿色/白色治愈系
- 形状：十字形或心形加光芒
- 尺寸：64x64 适配缩放
- 背景：透明

**AI生成提示词 (SVG/PNG):**
```
minimalist healing icon, flat design style, bright green and white color palette, medical cross shape with subtle glow effect, clean geometric lines, transparent background, game UI icon, 64x64 pixels, high contrast, vector style, suitable for RPG healing skill button
```

---

## 音频资源 (2个)

### 1. sfx_sword_rain.wav - 剑雨施放音效

**用途：** 施放剑雨风暴技能时播放

**音效要求：**
- 时长：0.5-0.8秒
- 感觉：锐利、密集、有气势
- 元素：多把剑破空的声音 + 魔法施法感
- 格式：WAV 44.1kHz 16bit

**AI生成提示词 (Audio):**
```
short fantasy spell sound effect, sword rain ability cast, multiple blades slicing through air, magical whooshing sound, bright and sharp tones, 0.6 seconds duration, RPG game audio, clean sound, no background noise, suitable for top-down survivor game
```

---

### 2. sfx_heal_cast.wav - 治疗施放音效

**用途：** 施放治疗技能时播放

**音效要求：**
- 时长：0.4-0.6秒
- 感觉：温暖、治愈、明亮
- 元素：柔和的光环声 + 清脆的"叮"声
- 格式：WAV 44.1kHz 16bit

**AI生成提示词 (Audio):**
```
short healing spell sound effect, warm bright chime with magical undertones, gentle aura sound, uplifting and soothing tones, 0.5 seconds duration, fantasy RPG game audio, clean sound, no background noise, suitable for player healing ability in top-down survivor game
```

---

## 临时替代方案 (实施阶段使用)

在AI生成资源到位前，使用以下现有资源代替，不影响功能：

| 新增资源 | 临时替代资源 |
|----------|-------------|
| `sword.svg` | `skill.svg` (现有) |
| `heal.svg` | `health.svg` (现有) |
| `sfx_sword_rain.wav` | `sfx_wizard_orb_cast.wav` (现有) |
| `sfx_heal_cast.wav` | `sfx_level_up.wav` (现有) |

---

## 实施状态

- [ ] 生成 sword.svg
- [ ] 生成 heal.svg
- [ ] 生成 sfx_sword_rain.wav
- [ ] 生成 sfx_heal_cast.wav

> **说明：** 代码功能将先使用临时替代资源实现，资源生成后无缝替换即可。
