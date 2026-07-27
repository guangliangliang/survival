# 武器动画指南

## ⚔️ 大刀动画（重点）

### AI出图提示词

#### 大刀挥砍动画（8帧）
```
pixel art, 32x32, melee weapon slash animation, 8 frames of sword swinging from right to left, attacking arc, white background, retro game sprite --style raw
```

#### 大刀向下攻击（4帧，简化版）
```
pixel art, 32x32, sword slash animation facing down, 4 frames, from idle position to full swing and back, white background --style raw
```

### 大刀动画帧序列
```
帧0：准备姿势（刀在身后）
帧1：开始挥下
帧2：挥到中间位置
帧3：最大挥砍位置（伤害判定）
帧4：挥回一半
帧5：回到准备位置
```

---

## 🔫 机枪动画（简单）

### AI出图提示词
```
pixel art, 32x32, gun muzzle flash animation, 2-3 frames, simple, white background --style raw
```

### 机枪动画帧序列
```
帧0：待机
帧1：发射（枪口闪光）
帧2：弹壳飞出
```

---

## 💡 实现建议

### 大刀：用动画Sprite
```gdscript
# 4帧挥砍动画，按下攻击时播放
```

### 机枪：用简单的Timer
```gdscript
# 每一帧显示不同的Sprite（待机/射击）
```
