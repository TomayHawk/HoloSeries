extends PlayerStats

# Score: 4.265 + 5% Crit Rate
# Buffer - Skills

# ..............................................................................

#region CONSTANTS

# name, index
const CHARACTER_NAME: String = "AZKi"
const CHARACTER_INDEX: int = 1

# animation, default unlocked
const CHARACTER_ANIMATION: SpriteFrames = preload("res://entities/character_animations/azki.tres")
const CHARACTER_DEFAULT_UNLOCKED: Array[int] = [139, 154, 170]

# health, mana, stamina
const CHARACTER_HEALTH: float = 373.0 # +173 (+0.865 T1)
const CHARACTER_MANA: float = 40.0 # +30 (+3 T1)
const CHARACTER_STAMINA: float = 100.0

# basic stats
const CHARACTER_DEFENSE: float = 8.0 # -2 (-0.2 T1)
const CHARACTER_WARD: float = 6.0 # -4 (-0.8 T1)
const CHARACTER_STRENGTH: float = 9.0 # -1 (-0.2 T1)
const CHARACTER_INTELLIGENCE: float = 12.0 # +2 (+0.4 T1)
const CHARACTER_SPEED: float = 2.0 # +2 (+2 T1)
const CHARACTER_AGILITY: float = 2.0 # +2 (+2 T1)
const CHARACTER_CRIT_CHANCE: float = 0.10 # +0.05 Crit Rate
const CHARACTER_CRIT_DAMAGE: float = 0.50

# basic attack, ultimate
const CHARACTER_BASIC_ATTACK: PackedScene = preload("res://abilities/attack/sora_slash.tscn")
const CHARACTER_ULTIMATE: PackedScene = preload("res://abilities/attack/sora_slash.tscn")

#endregion

# ..............................................................................
