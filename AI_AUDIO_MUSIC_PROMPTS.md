# 《边境守夜人》背景音乐与结算音效提示词

本文档只放背景音乐与胜负结算音效，不包含高频战斗音效、玩家武器音效、成长反馈音效或环境音。音乐最终导出为 OGG，结算音效可先生成 WAV 母版，剪辑后再按项目需求转换为 OGG。

## 一、背景音乐

### 1. 主菜单：村庄最后的防线

建议文件名：`music_menu_village.ogg`

- 时长：90–120秒。
- 速度：72–82 BPM，4/4拍。
- 情绪：宁静、朴素、略带忧虑与希望。
- 核心乐器：木吉他或鲁特琴、低音提琴、柔和手鼓、木笛、少量弦乐铺底。

```text
Create main-menu background music for a top-down rural survival game. The scene is a village at sunset, with its guard preparing to walk toward the outer defensive line. The music should feel quiet, humble, and warm, with a subtle undertone of unease and responsibility. 72-82 BPM in 4/4. Use a gentle acoustic guitar or lute as the repeating motif, restrained double bass, sparse hand drum for a slow pulse, a short memorable rural theme on wooden flute, and only a small amount of soft string support. Keep the structure stable without a strong climax so it can play while the player remains in the menu. Duration 90-120 seconds, seamless loop. The final harmony, beat, and ambience tail must connect naturally back to the opening.

Avoid vocals, lyrics, choir, modern electronic drums, pop-song structure, epic brass, horror screams, excessive sadness, long reverb, abrupt endings, obvious fade-in or fade-out, and complex virtuoso solos.
```

### 2. 普通战斗：村外巡守

建议文件名：`music_battle_patrol.ogg`

- 时长：120–150秒。
- 速度：118–126 BPM，4/4拍。
- 情绪：持续推进、敏捷、坚韧，不压过战斗反馈。
- 核心乐器：低音弦乐拨奏、框鼓、木质打击乐、短促弦乐、少量木笛或口风琴主题。

```text
Create a standard combat loop for a top-down survivor game. The player continuously moves and automatically fires at enemy swarms across village outskirts, a dark forest, and a bandit camp. The music should feel steadily driven, agile, and resilient, sustaining long combat sessions without becoming as oppressive as a boss theme. 118-126 BPM in 4/4. Build a continuous pulse with low string pizzicato and restrained frame drum, add wooden percussion and short string rhythms, and use a very brief wooden-flute or harmonica motif to retain the rural identity. Introduce subtle layer changes every 16 or 32 bars, with no abrupt pauses or huge climaxes. Duration 120-150 seconds, seamless loop. Leave mix space for gunshots, impacts, pickups, and level-up effects.

Avoid vocals, lyrics, dominant rock guitar, modern EDM, heavy sub-bass bombardment, complex jazz rhythms, epic trailer sound walls, excessive cheerfulness, excessive horror, sudden key changes, long quiet passages, and obvious fade-outs.
```

### 3. Boss战：防线告急

建议文件名：`music_boss_last_defense.ogg`

- 时长：90–120秒。
- 速度：138–150 BPM，4/4拍或稳定的6/8拍。
- 情绪：危险、压迫、最后抵抗，但仍保持乡村世界观。
- 核心乐器：战鼓、低音弦乐、持续弦乐、低音木管、少量粗糙铜管。

```text
Create a boss-battle loop for a rural survival game. The alpha wolf, forest beast, or bandit chief has appeared and the village defense is at its most dangerous stage. The music should be tense, oppressive, and urgent, expressing a final stand and the will to survive rather than pure horror. 138-150 BPM. Drive the rhythm with steady war drums and repeating low-string figures, use sustained strings for pressure, and introduce a short threatening motif with low woodwinds and a small amount of rough brass. Include a transformed fragment of the main-menu rural motif so all three tracks belong to the same world. Increase layers every 8-16 bars without stopping completely. Duration 90-120 seconds, seamless loop; the ending must return directly to the opening downbeat.

Avoid vocals, lyrics, choir, metal rock, EDM drops, oversized cinematic explosions, continuous high-frequency screeching, beatless ambience, triumphant major-key endings, sudden silence, and fade-out endings.
```

## 二、结算音效

### 1. 胜利

建议文件名：`sfx_victory.wav`

- 时长：2.5–4秒。

```text
Short victory stinger for a rural pixel survival game. A warm, confident ascending theme played by wooden flute, plucked strings, hand drum, and restrained brass, expressing relief and honor after successfully defending the village. Keep the melody concise and clear, resolving firmly to a bright chord. About 3 seconds, no loop, no voice.

Avoid exaggerated imperial triumph, choir, applause, fireworks, casino-jackpot sounds, modern electronic tones, and tails longer than 4 seconds.
```

### 2. 失败

建议文件名：`sfx_defeat.wav`

- 时长：2–3.5秒。

```text
Short defeat stinger for a rural pixel survival game. A brief descending theme on low wooden flute and plucked strings, supported by one soft low-drum landing. Express a broken defense and regret while leaving room to try again; neither horrifying nor hopeless. About 2.8 seconds, clean ending, no loop, no voice.

Avoid death screams, funeral marches, horror effects, mocking laughter, excessively tragic orchestration, and long reverb.
```

## 三、导出与验收

- 三首音乐实际首尾拼接试听至少3次，不应听到节拍跳动或空间断层。
- 音乐不要人声、歌词、对白和可识别的现成旋律。
- 音乐低频适度，避免压过枪声、受伤、拾取、升级和Boss警告音效。
- 结算音效可以有短音乐性，但不应变成长音乐段或覆盖结算界面反馈。
- 胜利和失败必须一听就能区分，且都要保留乡村防线的朴素世界观。
- 所有文件峰值留出余量，避免导入Godot后削波；最终响度在游戏内通过Music、SFX、UI总线统一调整。
