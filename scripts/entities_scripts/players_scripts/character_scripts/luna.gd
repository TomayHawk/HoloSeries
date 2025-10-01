extends PlayerStats

# Score: 4.285
# Healer

# ..............................................................................

#region CONSTANTS

# name, index
const CHARACTER_NAME: String = "Himemori Luna"
const CHARACTER_INDEX: int = 4

# animation, default unlocked
const CHARACTER_ANIMATION: SpriteFrames = preload("res://entities/character_animations/luna.tres")
const CHARACTER_DEFAULT_UNLOCKED: Array[int] = [100, 132, 147]

# health, mana, stamina
const CHARACTER_HEALTH: float = 377.0 # +177 (+0.885 T1)
const CHARACTER_MANA: float = 36.0 # +26 (+2.6 T1)
const CHARACTER_STAMINA: float = 100.0

# basic stats
const CHARACTER_DEFENSE: float = 3.0 # -7 (-1.6 T1)
const CHARACTER_WARD: float = 13.0 # +3 (+0.6 T1)
const CHARACTER_STRENGTH: float = 4.0 # -6 (-0.8 T1)
const CHARACTER_INTELLIGENCE: float = 18.0 # +8 (+1.6 T1)
const CHARACTER_SPEED: float = 1.0 # +1 (+1 T1)
const CHARACTER_AGILITY: float = 1.0 # +1 (+1 T1)
const CHARACTER_CRIT_CHANCE: float = 0.05
const CHARACTER_CRIT_DAMAGE: float = 0.50

# basic attack, ultimate
const CHARACTER_BASIC_ATTACK: PackedScene = preload("res://abilities/attack/sora_slash.tscn")
const CHARACTER_ULTIMATE: PackedScene = preload("res://abilities/attack/sora_slash.tscn")

#endregion

# ..............................................................................
