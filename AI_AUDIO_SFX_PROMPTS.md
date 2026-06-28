# 《边境守夜人》战斗与成长音效提示词

本文档只保留高频战斗音效、玩家武器与解锁音效、成长与反馈音效。音效可先生成 WAV 母版，剪辑后再按项目需求转换为 OGG。

## 一、高频战斗音效

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

### 7. 近战敌人攻击挥击

建议文件名：`sfx_enemy_melee_swing_01.wav` 至 `sfx_enemy_melee_swing_03.wav`

- 时长：0.10–0.18秒。

```text
Short melee attack whoosh for wolves, boars, and bandits in a top-down rural survival game. A quick cloth-and-air swipe with a small rough organic edge, readable but lighter than a player-damage cue. About 0.14 seconds, immediate onset, very fast decay, no impact baked in. Generate 3 subtle variants for repeated enemy attacks.

Avoid sword clangs, heavy monster roars, human shouts, wet gore, large impacts, long tails, and sharp high-frequency whistles.
```

### 8. 豪猪尖刺发射

建议文件名：`sfx_porcupine_thorn_shot_01.wav` 至 `sfx_porcupine_thorn_shot_03.wav`

- 时长：0.12–0.22秒。

```text
Thorn porcupine projectile launch for a dark forest enemy in a pixel survival game. A short dry quill snap followed by a narrow air flick, organic and woody rather than metallic. Clear enough to warn the player, but softer than a rifle shot. About 0.17 seconds, no long reverb. Generate 3 slight pitch variants.

Avoid gunshots, bowstring twangs that sound heroic, sci-fi lasers, wet flesh sounds, loud animal cries, huge bass, and long projectile trails.
```

### 9. 巫师法球发射

建议文件名：`sfx_wizard_orb_cast_01.wav` 至 `sfx_wizard_orb_cast_03.wav`

- 时长：0.22–0.38秒。

```text
Cult wizard magic-orb launch for a rural dark-fantasy survival game. A compact low wooden knock, a brief dusty inhale, and a restrained cyan-violet arcane pulse, suggesting forbidden magic without becoming flashy. About 0.30 seconds, clean transient, short tail, readable at mid distance. Generate 3 subtle variants.

Avoid spoken spells, choir, long magical charging, bright fairy sparkles, modern synth lasers, horror screams, huge cinematic whooshes, and tails longer than 0.5 seconds.
```

### 10. 敌方弹丸命中地面

建议文件名：`sfx_enemy_projectile_land_01.wav` 至 `sfx_enemy_projectile_land_03.wav`

- 时长：0.10–0.20秒。

```text
Enemy projectile landing or missing on dirt in a top-down pixel survival game. A short dry dirt tick with tiny dust grains, slightly dangerous but not explosive. Works for missed bullets, thorns, or small magic orbs with only very subtle tonal variation. About 0.15 seconds, no background sound. Generate 3 variants.

Avoid large explosions, metal ricochets, wet impacts, long dust clouds, loud magic blasts, and reverb.
```

## 二、玩家武器与解锁音效

### 1. 环绕飞轮旋转

建议文件名：`sfx_flywheel_loop.ogg`

- 时长：0.8–1.4秒。
- 低音量循环，只有飞轮存在时播放。

```text
Seamless low-volume loop for an orbiting wooden-and-metal flywheel spinning around the player in a rural survival game. A restrained circular air movement with faint rough wood and dull metal texture, rhythmic but not musical. It should imply continuous rotation without masking gunshots or hit sounds. Duration 0.8-1.4 seconds, seamless loop, narrow stereo or mono-compatible, very stable dynamics.

Avoid loud buzzsaws, modern engines, electric drones, high-pitched tinnitus, scraping that sounds broken, strong rhythm clicks, music, and obvious loop points.
```

### 2. 飞轮切中敌人

建议文件名：`sfx_flywheel_hit_01.wav` 至 `sfx_flywheel_hit_04.wav`

- 时长：0.08–0.16秒。

```text
Short hit sound for an orbiting flywheel striking an enemy in a pixel survival game. A quick dull wooden chop with a small dry scrape and a compact impact, non-gory and lighter than a boss hit. About 0.12 seconds, fast decay, suitable for repeated contact hits. Generate 4 subtle variants.

Avoid wet slicing, sword clangs, chainsaws, huge impacts, long scraping tails, and piercing high frequencies.
```

### 3. 支援无人机开火

建议文件名：`sfx_drone_shot_01.wav` 至 `sfx_drone_shot_04.wav`

- 时长：0.08–0.14秒。

```text
Small support-drone shot for a top-down survival game. A short light pneumatic pop with a tiny mechanical click, clearly weaker and smaller than the player's old rifle. The tone should feel handmade and utilitarian, not futuristic. About 0.11 seconds, immediate onset, no reverb. Generate 4 subtle variants.

Avoid sci-fi lasers, modern machine guns, large rifle cracks, heavy bass, shell casings, electronic beeps, music, and voices.
```

### 4. 新武器解锁

建议文件名：`sfx_weapon_unlock.wav`

- 时长：0.7–1.1秒。

```text
New weapon unlock sound for a rural pixel survival game. A confident wooden latch click followed by two short warm ascending notes on plucked strings and a soft metal bell accent. Communicate that a new combat tool has joined the player, more substantial than selecting a normal upgrade but smaller than level-up fanfare. About 0.9 seconds, clean ending, no voice.

Avoid casino rewards, grand victory music, phone notifications, harsh chiptune, long magical sparkles, applause, and reverb tails longer than 1.2 seconds.
```

## 三、成长与反馈音效

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

### 4. 升级卡出现

建议文件名：`sfx_upgrade_panel_open.wav`

- 时长：0.35–0.6秒。

```text
Upgrade-choice panel opening sound for a rural pixel survival game. A soft parchment flick, a small wooden frame tap, and a brief warm rising tone that prepares the player to choose a new upgrade. About 0.45 seconds, clean and gentle, less celebratory than level-up and less final than upgrade selection.

Avoid menu whooshes that sound modern, loud paper tearing, magical explosions, casino sounds, speech, and long melodies.
```

### 5. 无法选择或操作无效

建议文件名：`ui_invalid.wav`

- 时长：0.10–0.18秒。

```text
Subtle invalid-action UI sound for a rural pixel game. A very soft low wooden tick with a tiny downward muted tone, communicating that the action cannot be performed without feeling punishing. About 0.14 seconds, quiet, dry, and clean.

Avoid harsh error buzzers, phone alerts, angry tones, speech, comedic failure sounds, and long tails.
```

### 6. Boss出现警告

建议文件名：`sfx_boss_warning.wav`

- 时长：1.5–2.2秒。

```text
Boss-arrival warning for a pixel survival game. Two deep war-drum strikes with clear spacing, layered with a short rough rising brass tone and a distant wooden alarm bell. Communicate that the defensive line is in immediate danger. About 1.8 seconds, powerful without clipping, tail ends within 2 seconds, no voice.

Avoid modern air-raid sirens, electronic alarms, horror screams, cinematic trailer booms, long reverb, and full musical passages.
```

### 7. Boss受击

建议文件名：`sfx_boss_hit_01.wav` 至 `sfx_boss_hit_03.wav`

- 时长：0.12–0.22秒。

```text
Bullet impact on a large boss in a pixel action game. Deeper and heavier than a regular hit, combining a short leather thud, wooden armor or thick-hide contact, and a small low-frequency impact. Keep it short enough for continuous fire. About 0.18 seconds, no long reverb. Generate 3 variants.

Avoid huge explosions, wet flesh sounds, ringing metal, repeated gunshot transients, and long low-frequency tails.
```

### 8. Boss死亡

建议文件名：`sfx_boss_death.wav`

- 时长：1.2–1.8秒。

```text
Defeat sound for a large boss in a pixel survival game. Start with a heavy body impact and low-frequency landing, followed by brief wood-and-stone fragments, an outward air burst, and a restrained low victorious interval. Communicate that a major threat has ended, without gore. About 1.5 seconds, natural tail no longer than 1.8 seconds, no voice.

Avoid screams, flesh tearing, massive building-collapse sounds, extended victory music, applause, dialogue, and excessive reverb.
```

