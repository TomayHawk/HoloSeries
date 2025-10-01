extends PlayerStats

# Score: 4.55
# Buffer - Healer

# ..............................................................................

#region CONSTANTS

# name, index
const CHARACTER_NAME: String = "Tokino Sora"
const CHARACTER_INDEX: int = 0

# animation, default unlocked
const CHARACTER_ANIMATION: SpriteFrames = preload("res://entities/character_animations/sora.tres")
const CHARACTER_DEFAULT_UNLOCKED: Array[int] = [135, 167, 182]

# health, mana, stamina (debug values)
const CHARACTER_HEALTH: float = 99999.0 # +190 (+0.95 T1)
const CHARACTER_MANA: float = 9999.0 # +18 (+1.8 T1)
const CHARACTER_STAMINA: float = 500.0

# basic stats (debug values)
const CHARACTER_DEFENSE: float = 1000.0
const CHARACTER_WARD: float = 1000.0
const CHARACTER_STRENGTH: float = 1000.0
const CHARACTER_INTELLIGENCE: float = 1000.0 # +4 (+0.8 T1)
const CHARACTER_SPEED: float = 255.0 # +1 (+1 T1)
const CHARACTER_AGILITY: float = 255.0 # +1 (+1 T1)
const CHARACTER_CRIT_CHANCE: float = 0.50
const CHARACTER_CRIT_DAMAGE: float = 1.50

# basic attack, ultimate
const CHARACTER_BASIC_ATTACK: PackedScene = preload("res://abilities/attack/sora_slash.tscn")
const CHARACTER_ULTIMATE: PackedScene = preload("res://abilities/attack/sora_slash.tscn")

#endregion

# ..............................................................................
