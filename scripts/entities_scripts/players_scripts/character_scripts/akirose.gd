extends PlayerStats

# Score: 4.18 + 2% Crit Rate + 10% Crit Damage
# Physical - Magic

# ..............................................................................

#region CONSTANTS

# name, index
const CHARACTER_NAME: String = "Aki Rosenthal"
const CHARACTER_INDEX: int = 3

# health, mana, stamina
const CHARACTER_HEALTH: float = 396.0 # +196 (+0.98 T1)
const CHARACTER_MANA: float = 26.0 # +16 (+1.6 T1)
const CHARACTER_STAMINA: float = 100.0

# basic stats
const CHARACTER_DEFENSE: float = 11.0 # +1 (+0.2 T1)
const CHARACTER_WARD: float = 11.0 # +1 (+0.2 T1)
const CHARACTER_STRENGTH: float = 14.0 # +4 (+0.8 T1)
const CHARACTER_INTELLIGENCE: float = 12.0 # +2 (+0.4 T1)
const CHARACTER_SPEED: float = 0.0
const CHARACTER_AGILITY: float = 0.0
const CHARACTER_CRIT_CHANCE: float = 0.07 # +0.02 Crit Rate
const CHARACTER_CRIT_DAMAGE: float = 0.60 # +0.10 Crit Damage

# animation, default unlocked
const CHARACTER_ANIMATION: SpriteFrames = preload("res://entities/character_animations/akirose.tres")
const CHARACTER_DEFAULT_UNLOCKED: Array[int] = [491, 522, 523]

# basic attack, ultimate
const CHARACTER_BASIC_ATTACK: PackedScene = preload("res://abilities/attack/sora_slash.tscn")
const CHARACTER_ULTIMATE: PackedScene = preload("res://abilities/attack/sora_slash.tscn")

#endregion

# ..............................................................................
