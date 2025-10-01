extends PlayerStats

# Score: 4.025 + 20 Stamina + 15% Crit Damage
# Physical - Tank

# ..............................................................................

#region CONSTANTS

# name, index
const CHARACTER_NAME: String = "Roboco"
const CHARACTER_INDEX: int = 2

# animation, default unlocked
const CHARACTER_ANIMATION: SpriteFrames = preload("res://entities/character_animations/roboco.tres")
const CHARACTER_DEFAULT_UNLOCKED: Array[int] = [284, 333, 364]

# health, mana, stamina
const CHARACTER_HEALTH: float = 465.0 # +265 (+1.325 T1)
const CHARACTER_MANA: float = 10.0
const CHARACTER_STAMINA: float = 120.0 # +20 Stamina

# basic stats
const CHARACTER_DEFENSE: float = 18.0 # +8 (+1.6 T1)
const CHARACTER_WARD: float = 13.0 # +3 (+0.6 T1)
const CHARACTER_STRENGTH: float = 16.0 # +6 (+1.2 T1)
const CHARACTER_INTELLIGENCE: float = 4.0 # -6 (-1.2 T1)
const CHARACTER_SPEED: float = 0.0
const CHARACTER_AGILITY: float = 1.0 # +1 (+1.0 T1)
const CHARACTER_CRIT_CHANCE: float = 0.05
const CHARACTER_CRIT_DAMAGE: float = 0.65 # +0.15 Crit Damage

# basic attack, ultimate
const CHARACTER_BASIC_ATTACK: PackedScene = preload("res://abilities/attack/sora_slash.tscn")
const CHARACTER_ULTIMATE: PackedScene = preload("res://abilities/attack/sora_slash.tscn")

#endregion

# ..............................................................................
