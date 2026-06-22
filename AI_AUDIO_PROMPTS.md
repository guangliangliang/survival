# 《守卫村庄：幸存者》音乐与音效提示词

本文档不绑定具体音乐或音效生成工具。提示词描述游戏需要的情绪、结构、时长和声音边界。音乐最终导出为 OGG，音效可先生成 WAV 母版，剪辑后再按项目需求转换为 OGG。

## 一、统一音频规范

### 音乐规范

- 44.1kHz或48kHz，立体声。
- 必须可无缝循环，开头和结尾不能有突兀渐入、渐出或残响断点。
- 不要人声、歌词、对白和可识别的现成旋律。
- 避免电影预告片式巨大音墙，给枪声、受伤和升级音效留出频段。
- 低频适度，手机扬声器上仍能听清节奏与主题。
- 建议先生成90–150秒，再剪辑出稳定的循环段。

### 音效规范

- 44.1kHz或48kHz，单声道或窄立体声。
- 单次音效前端紧凑，删除无意义静音。
- 除胜负结算外，不要长混响、长尾音或背景环境声。
- 高频事件需要短促、克制，连续播放时不能刺耳或浑浊。
- 每个高频音效建议生成3–5个轻微变化版本，游戏内随机播放。

## 二、背景音乐

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

## 三、高频战斗音效

### 1. 玩家步枪开枪

建议文件名：`sfx_player_rifle_01.wav` 至 `sfx_player_rifle_05.wav`

- 时长：0.12–0.22秒。
- 生成5个轻微变化版本。

```text
A short single shot from an old wooden-stock rifle for a top-down pixel survival game. Clear, forceful mechanical crack with a dry powder impact and a very brief metallic action sound. Close-range but not painfully loud, no indoor echo, no long reverb, no background noise. About 0.16 seconds, immediate onset and fast decay, suitable for repeated playback several times per second. Generate 5 variants with slight differences in pitch and force.

Avoid modern automatic-rifle bursts, cannon fire, shotgun blasts, laser weapons, exaggerated bass explosions, long shell-casing tails, ambient wind, music, and voices.
```

### 2. 子弹命中敌人

建议文件名：`sfx_bullet_hit_01.wav` 至 `sfx_bullet_hit_04.wav`

- 时长：0.07–0.14秒。

```text
Bullet impact on an enemy in a pixel action game: a short dry impact combining a light cloth slap, a muted wooden hit, and a small amount of crisp pixel-fragment texture. Clear feedback without gore. About 0.10 seconds, no reverb, no background sound, suitable for frequent rapid repetition. Generate 4 subtle variants.

Avoid wet flesh sounds, breaking bones, huge metal impacts, explosions, a prominent gunshot, long tails, and piercing high frequencies.
```

### 3. 敌人死亡

建议文件名：`sfx_enemy_death_01.wav` 至 `sfx_enemy_death_04.wav`

- 时长：0.25–0.45秒。

```text
Defeat sound for a regular enemy dissolving into dust in a top-down pixel game. Begin with a short low impact, followed immediately by a light air puff and disappearing pixel debris. Clearly communicates that the enemy is dead, non-gory, with no human scream. About 0.35 seconds with a fast decay. Generate 4 slightly different variants.

Avoid dialogue, screams, groans, flesh tearing, huge body-fall impacts, long reverb, explosions, and comedic effects.
```

### 4. 玩家受伤

建议文件名：`sfx_player_hurt_01.wav` 至 `sfx_player_hurt_03.wav`

- 时长：0.18–0.32秒。

```text
Player-damage cue for a pixel survival game. A short low body impact layered with slight cloth movement and a restrained nonverbal exhale. Clearly signals danger without gore or exaggerated suffering. About 0.25 seconds, clear transient and very short tail. Generate 3 subtle variants.

Avoid spoken lines, screams, long groans, flesh sounds, metallic explosions, long reverb, and ambient background noise.
```

### 5. 敌人枪手射击

建议文件名：`sfx_enemy_rifle_01.wav` 至 `sfx_enemy_rifle_03.wav`

- 时长：0.14–0.24秒。

```text
A distant bandit gunner firing a worn short-barreled rifle. More muffled, lighter, and rougher than the player's rifle, with a slight loose-mechanism quality. Clear onset and fast decay to signal an enemy ranged attack. About 0.19 seconds, no long reverb, no falling shell casing. Generate 3 slightly different variants.

Avoid sounding identical to the player's rifle, modern automatic weapons, lasers, artillery, huge low end, environmental echo, and music.
```

### 6. 敌方弹丸掠过或落空

建议文件名：`sfx_enemy_projectile_pass.wav`

- 时长：0.12–0.22秒。

```text
A short sound of a dangerous projectile passing quickly beside the player in a pixel game. Narrow, fast air-slicing motion with a very subtle dark-red energy texture, clear directional feel, restrained loudness. About 0.16 seconds, no explosion, no long tail, no background sound.

Avoid sci-fi laser cannons, aircraft flybys, piercing tinnitus, huge bass, and long reverb.
```

## 四、成长与反馈音效

### 1. 经验宝石拾取

建议文件名：`sfx_exp_pickup_01.wav` 至 `sfx_exp_pickup_04.wav`

- 时长：0.08–0.16秒。

```text
Short pickup sound for collecting a green experience gem in a pixel game. Combine a crisp but soft wooden click with a tiny glass-like tone particle. Bright pitch without harshness, immediate decay, suitable for many triggers within one second. About 0.12 seconds, no reverb. Generate 4 neighboring-pitch variants for random or ascending playback during consecutive pickups.

Avoid coin sounds, cash registers, long bells, magical explosions, piercing high frequencies, and background music.
```

### 2. 升级

建议文件名：`sfx_level_up.wav`

- 时长：0.8–1.2秒。

```text
Character level-up sound for a rural pixel survival game. Four simple ascending notes using xylophone and a soft metal bell, ending with a very short warm string resolution. Communicate increased power and a new choice, positive but not overly cartoonish. About 1 second, clean ending, no long reverb, no voice.

Avoid casino jackpots, phone notifications, harsh 8-bit square waves, grand victory fanfares, applause, dialogue, and tails longer than 1.5 seconds.
```

### 3. 选择升级卡

建议文件名：`sfx_upgrade_select.wav`

- 时长：0.18–0.3秒。

```text
Short confirmation sound for selecting a skill upgrade in a pixel game. A solid wooden button click layered with a warm, crisp upward tone particle, clearly communicating that the choice has taken effect. About 0.24 seconds, clean and definite, no reverb, no background sound.

Avoid ordinary mouse clicks, coins, error alerts, long melodies, and speech.
```

### 4. Boss出现警告

建议文件名：`sfx_boss_warning.wav`

- 时长：1.5–2.2秒。

```text
Boss-arrival warning for a pixel survival game. Two deep war-drum strikes with clear spacing, layered with a short rough rising brass tone and a distant wooden alarm bell. Communicate that the defensive line is in immediate danger. About 1.8 seconds, powerful without clipping, tail ends within 2 seconds, no voice.

Avoid modern air-raid sirens, electronic alarms, horror screams, cinematic trailer booms, long reverb, and full musical passages.
```

### 5. Boss受击

建议文件名：`sfx_boss_hit_01.wav` 至 `sfx_boss_hit_03.wav`

- 时长：0.12–0.22秒。

```text
Bullet impact on a large boss in a pixel action game. Deeper and heavier than a regular hit, combining a short leather thud, wooden armor or thick-hide contact, and a small low-frequency impact. Keep it short enough for continuous fire. About 0.18 seconds, no long reverb. Generate 3 variants.

Avoid huge explosions, wet flesh sounds, ringing metal, repeated gunshot transients, and long low-frequency tails.
```

### 6. Boss死亡

建议文件名：`sfx_boss_death.wav`

- 时长：1.2–1.8秒。

```text
Defeat sound for a large boss in a pixel survival game. Start with a heavy body impact and low-frequency landing, followed by brief wood-and-stone fragments, an outward air burst, and a restrained low victorious interval. Communicate that a major threat has ended, without gore. About 1.5 seconds, natural tail no longer than 1.8 seconds, no voice.

Avoid screams, flesh tearing, massive building-collapse sounds, extended victory music, applause, dialogue, and excessive reverb.
```

## 五、UI音效

### 1. 普通按钮点击

建议文件名：`ui_button_click.wav`

- 时长：0.06–0.12秒。

```text
UI button click for a rural pixel game. A short clean wooden tap with a slight soft-leather texture, immediate decay, gentle and clear. About 0.09 seconds, no reverb, no background sound.

Avoid modern mouse clicks, mechanical keyboards, phone notifications, coins, and sharp electronic tones.
```

### 2. 返回或取消

建议文件名：`ui_back.wav`

- 时长：0.1–0.18秒。

```text
UI back-navigation sound for a pixel game. A soft wooden click followed by a very short descending tone particle, communicating exit from the current panel rather than an error. About 0.14 seconds, clean and restrained, no reverb.

Avoid error beeps, failure stingers, heavy door slams, speech, and long melodies.
```

### 3. 暂停

建议文件名：`ui_pause.wav`

- 时长：0.15–0.25秒。

```text
Pause sound for a pixel game. Two extremely short, closely spaced woodblock taps, with the second slightly lower in pitch, communicating that motion has frozen. About 0.20 seconds, clean, no reverb, no background sound.

Avoid long clock chimes, modern electronic alerts, speech, and music-stop effects.
```

### 4. 继续游戏

建议文件名：`ui_resume.wav`

- 时长：0.15–0.25秒。

```text
Resume sound for a pixel game. Two extremely short woodblock taps, with the second slightly higher in pitch and a subtle forward air movement, communicating that the game continues. About 0.20 seconds, clean, no reverb.

Avoid level-up sounds, phone notifications, long melodies, and speech.
```

## 六、结算音效

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

## 七、可选环境音

环境音不是首版必需。若添加，音量应明显低于音乐与战斗反馈。

### 1. 村庄外围环境

建议文件名：`amb_village_outskirts.ogg`

```text
Seamless ambient loop for quiet village outskirts: light wind through grass, an occasional distant wooden-fence creak, and very sparse bird calls. No voices, no nearby livestock, no music. Duration 30-60 seconds, stable dynamics, seamless loop, leaving space for combat effects.
```

### 2. 幽暗森林环境

建议文件名：`amb_dark_forest.ogg`

```text
Seamless ambient loop for a dark forest: low leaf rustle, occasional distant twig snaps, sparse night birds and insects. Mysterious without becoming overtly frightening. No monster calls, no music. Duration 30-60 seconds, stable dynamics, seamless loop.
```

### 3. 强盗营地环境

建议文件名：`amb_bandit_camp.ogg`

```text
Seamless ambient loop for an abandoned bandit camp: dry wind, a faint distant campfire crackle, and occasional movement from loose canvas and wooden structures. No voices, no combat sounds, no music. Duration 30-60 seconds, stable dynamics, seamless loop.
```

## 八、导出与验收

- 三首音乐实际首尾拼接试听至少3次，不应听到节拍跳动或空间断层。
- 高频音效连续快速播放10秒，不应刺耳、叠成巨大低频或明显削波。
- 玩家和敌人枪声必须一听就能区分。
- 经验拾取音效连续播放时不能像报警器；优先使用轻微变化版本。
- UI音效应比战斗音效更轻，暂停、升级和Boss警告必须明显不同。
- 所有文件峰值留出余量，避免导入Godot后削波；最终响度在游戏内通过Music、SFX、UI总线统一调整。
