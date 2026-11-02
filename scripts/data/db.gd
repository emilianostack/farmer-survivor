## All game content lives here, so balance can be tuned without touching logic.
class_name DB
extends RefCounted

const STAGE_LENGTH := 480.0  # seconds until the stage boss arrives
const MID_BOSS_TIME := 240.0
const MAX_WEAPONS := 6
const MAX_PASSIVES := 6
const MAX_WEAPON_LEVEL := 8
const MAX_PASSIVE_LEVEL := 5

# hp/dmg/spd at minute zero. beh: chase, ranged, dash, explode, split, gas
const ENEMIES := {
	"pea": {"hp": 5.0, "dmg": 4.0, "spd": 52.0, "xp": 1, "r": 7.0, "beh": "chase", "w": 22, "h": 22, "col": Color("7fd04b")},
	"carrot": {"hp": 11.0, "dmg": 6.0, "spd": 44.0, "xp": 1, "r": 8.0, "beh": "chase", "w": 26, "h": 34, "col": Color("f79a2e")},
	"tomato": {"hp": 16.0, "dmg": 7.0, "spd": 36.0, "xp": 2, "r": 10.0, "beh": "ranged", "shot": "seed", "w": 30, "h": 30, "col": Color("cf2f3a")},
	"potato": {"hp": 40.0, "dmg": 9.0, "spd": 26.0, "xp": 3, "r": 12.0, "beh": "split", "w": 34, "h": 34, "col": Color("c89a62")},
	"onion": {"hp": 22.0, "dmg": 7.0, "spd": 34.0, "xp": 2, "r": 10.0, "beh": "ranged", "shot": "tear", "w": 30, "h": 34, "col": Color("e088ae")},
	"corn": {"hp": 26.0, "dmg": 8.0, "spd": 32.0, "xp": 3, "r": 9.0, "beh": "ranged", "shot": "kernel", "w": 28, "h": 38, "col": Color("fbdc55")},
	"chili": {"hp": 12.0, "dmg": 18.0, "spd": 72.0, "xp": 2, "r": 7.0, "beh": "explode", "w": 24, "h": 34, "col": Color("f15b47")},
	"eggplant": {"hp": 34.0, "dmg": 11.0, "spd": 40.0, "xp": 3, "r": 10.0, "beh": "dash", "w": 30, "h": 36, "col": Color("9c52c8")},
	"broccoli": {"hp": 120.0, "dmg": 14.0, "spd": 24.0, "xp": 8, "r": 16.0, "beh": "chase", "w": 44, "h": 46, "col": Color("3f9c4a")},
	"beet": {"hp": 42.0, "dmg": 12.0, "spd": 42.0, "xp": 4, "r": 10.0, "beh": "dash", "w": 32, "h": 36, "col": Color("c42a6a")},
	"garlic": {"hp": 30.0, "dmg": 8.0, "spd": 34.0, "xp": 3, "r": 10.0, "beh": "gas", "w": 28, "h": 30, "col": Color("f0e8d8")},
	"crate": {"hp": 1.0, "dmg": 0.0, "spd": 0.0, "xp": 0, "r": 9.0, "beh": "crate", "w": 20, "h": 20, "frames": 1, "col": Color("e6b84a")},
	"boss_gourd": {"hp": 26000.0, "dmg": 20.0, "spd": 34.0, "xp": 80, "r": 38.0, "beh": "boss", "w": 100, "h": 98, "name": "BOSS_GOURD", "col": Color("f79a2e")},
	"boss_corn": {"hp": 34000.0, "dmg": 28.0, "spd": 36.0, "xp": 140, "r": 32.0, "beh": "boss", "w": 108, "h": 118, "name": "BOSS_CORN", "col": Color("fbdc55")},
	"boss_root": {"hp": 48000.0, "dmg": 36.0, "spd": 30.0, "xp": 260, "r": 44.0, "beh": "boss", "w": 124, "h": 122, "name": "BOSS_ROOT", "col": Color("c42a6a")},
}

# Each stage is a timeline of waves: from `t` seconds, spawn from `pool` at `rate` per second.
const STAGES := [
	{
		"id": 0, "name": "STAGE_1", "desc": "STAGE_1_D", "ground": 0, "boss": "boss_gourd", "mid": "potato", "hp": 1.0, "dmg": 1.0, "reward": 300,
		"props": ["dirt", "dirt", "dirt", "fence", "hay", "tree", "sunflower", "rock", "wheelbarrow"], "tint": Color(1, 1, 1),
		"waves": [
			{"t": 0, "rate": 1.3, "pool": ["pea"]},
			{"t": 30, "rate": 2.0, "pool": ["pea", "pea", "carrot"]},
			{"t": 90, "rate": 3.0, "pool": ["carrot", "pea", "tomato"]},
			{"t": 150, "rate": 4.0, "pool": ["carrot", "tomato", "tomato", "potato"]},
			{"t": 240, "rate": 5.0, "pool": ["pea", "carrot", "potato", "onion"]},
			{"t": 330, "rate": 6.5, "pool": ["carrot", "tomato", "onion", "potato"]},
			{"t": 420, "rate": 8.0, "pool": ["carrot", "tomato", "onion", "potato", "potato"]},
		],
	},
	{
		"id": 1, "name": "STAGE_2", "desc": "STAGE_2_D", "ground": 1, "boss": "boss_corn", "mid": "corn", "hp": 1.8, "dmg": 1.25, "reward": 700,
		"props": ["deadtree", "reeds", "barrel", "tiltsign", "toxicpool", "rock"], "tint": Color(1, 1, 1),
		"waves": [
			{"t": 0, "rate": 2.0, "pool": ["pea", "carrot"]},
			{"t": 45, "rate": 3.0, "pool": ["carrot", "chili", "onion"]},
			{"t": 120, "rate": 4.5, "pool": ["corn", "chili", "onion"]},
			{"t": 210, "rate": 5.5, "pool": ["corn", "eggplant", "chili", "potato"]},
			{"t": 300, "rate": 7.0, "pool": ["eggplant", "corn", "garlic", "chili"]},
			{"t": 400, "rate": 9.0, "pool": ["eggplant", "garlic", "corn", "potato", "chili"]},
		],
	},
	{
		"id": 2, "name": "STAGE_3", "desc": "STAGE_3_D", "ground": 2, "boss": "boss_root", "mid": "broccoli", "hp": 3.2, "dmg": 1.55, "reward": 1600,
		"props": ["barrier", "pipe", "barrel", "tiltsign", "tower", "crate"], "tint": Color(1, 1, 1),
		"waves": [
			{"t": 0, "rate": 3.0, "pool": ["carrot", "chili", "garlic"]},
			{"t": 45, "rate": 4.0, "pool": ["beet", "chili", "garlic"]},
			{"t": 120, "rate": 5.5, "pool": ["beet", "eggplant", "corn", "broccoli"]},
			{"t": 210, "rate": 7.0, "pool": ["beet", "garlic", "broccoli", "corn"]},
			{"t": 300, "rate": 8.5, "pool": ["beet", "eggplant", "broccoli", "garlic", "chili"]},
			{"t": 400, "rate": 10.0, "pool": ["beet", "broccoli", "broccoli", "eggplant", "corn", "chili"]},
		],
	},
]

const CHARACTERS := [
	{"id": "hank", "name": "CHAR_HANK", "desc": "CHAR_HANK_D", "weapon": "scythe", "bonus": {"might": 0.1}, "cost": 0, "needs": -1},
	{"id": "mabel", "name": "CHAR_MABEL", "desc": "CHAR_MABEL_D", "weapon": "shotgun", "bonus": {"area": 0.1, "max_hp": 10.0}, "cost": 600, "needs": -1},
	{"id": "rosa", "name": "CHAR_ROSA", "desc": "CHAR_ROSA_D", "weapon": "bees", "bonus": {"luck": 0.2, "speed": 0.1}, "cost": 2500, "needs": 0},
	{"id": "tucker", "name": "CHAR_TUCKER", "desc": "CHAR_TUCKER_D", "weapon": "tractor", "bonus": {"armor": 2.0, "max_hp": 20.0}, "cost": 8000, "needs": 1},
]

# base stats + one delta per level after the first
const WEAPONS := {
	"scythe": {"base": {"dmg": 13.0, "cd": 1.25, "area": 1.0, "amount": 1, "knock": 70.0},
		"levels": [{"dmg": 4.0}, {"amount": 1}, {"area": 0.15}, {"dmg": 5.0}, {"cd": -0.12}, {"area": 0.15}, {"dmg": 9.0}],
		"evo": {"passive": "whetstone", "name": "EVO_SCYTHE", "dmg": 1.7, "area": 1.25, "amount": 2}},
	"pitchfork": {"base": {"dmg": 10.0, "cd": 1.0, "area": 1.0, "amount": 1, "pierce": 2, "speed": 270.0, "knock": 40.0},
		"levels": [{"amount": 1}, {"dmg": 4.0}, {"pierce": 1}, {"amount": 1}, {"dmg": 5.0}, {"cd": -0.12}, {"amount": 1}],
		"evo": {"passive": "gloves", "name": "EVO_PITCHFORK", "dmg": 1.5, "amount": 3, "pierce": 20}},
	"shotgun": {"base": {"dmg": 7.0, "cd": 1.5, "area": 1.0, "amount": 5, "pierce": 1, "speed": 330.0, "life": 0.42, "knock": 55.0},
		"levels": [{"amount": 1}, {"dmg": 2.0}, {"cd": -0.15}, {"amount": 2}, {"pierce": 1}, {"dmg": 3.0}, {"amount": 2}],
		"evo": {"passive": "horseshoe", "name": "EVO_SHOTGUN", "dmg": 1.6, "amount": 6, "pierce": 2}},
	"sickles": {"base": {"dmg": 7.0, "area": 1.0, "amount": 2, "orbit": 48.0, "spin": 3.2, "knock": 30.0},
		"levels": [{"dmg": 3.0}, {"amount": 1}, {"area": 0.2}, {"spin": 0.6}, {"amount": 1}, {"dmg": 4.0}, {"amount": 1}],
		"evo": {"passive": "boots", "name": "EVO_SICKLES", "dmg": 1.8, "amount": 2, "area": 1.3, "spin": 1.5}},
	"bees": {"base": {"dmg": 6.0, "cd": 2.1, "area": 1.0, "amount": 3, "pierce": 1, "speed": 150.0, "life": 3.0, "knock": 5.0},
		"levels": [{"amount": 1}, {"dmg": 2.0}, {"life": 1.0}, {"amount": 2}, {"dmg": 3.0}, {"cd": -0.3}, {"amount": 2}],
		"evo": {"passive": "thermos", "name": "EVO_BEES", "dmg": 1.6, "amount": 5, "pierce": 3}},
	"weedkiller": {"base": {"dmg": 5.0, "cd": 3.0, "area": 1.0, "amount": 1, "life": 3.0, "knock": 0.0},
		"levels": [{"area": 0.2}, {"dmg": 2.0}, {"amount": 1}, {"life": 0.8}, {"dmg": 3.0}, {"amount": 1}, {"area": 0.25}],
		"evo": {"passive": "lunchbox", "name": "EVO_WEEDKILLER", "dmg": 1.9, "amount": 2, "area": 1.35}},
	"tractor": {"base": {"dmg": 34.0, "cd": 8.0, "area": 1.0, "amount": 1, "speed": 400.0, "knock": 200.0},
		"levels": [{"dmg": 12.0}, {"cd": -0.8}, {"area": 0.2}, {"dmg": 16.0}, {"amount": 1}, {"cd": -0.8}, {"dmg": 24.0}],
		"evo": {"passive": "overalls", "name": "EVO_TRACTOR", "dmg": 1.8, "amount": 2, "area": 1.3, "cd": 0.7}},
	"lightning": {"base": {"dmg": 18.0, "cd": 2.4, "area": 1.0, "amount": 2, "knock": 20.0},
		"levels": [{"amount": 1}, {"dmg": 6.0}, {"cd": -0.3}, {"amount": 1}, {"area": 0.25}, {"dmg": 8.0}, {"amount": 2}],
		"evo": {"passive": "almanac", "name": "EVO_LIGHTNING", "dmg": 1.7, "amount": 4, "cd": 0.75}},
	"scarecrow": {"base": {"dmg": 8.0, "cd": 7.0, "area": 1.0, "amount": 1, "life": 6.0, "rate": 0.5, "speed": 260.0, "knock": 25.0},
		"levels": [{"dmg": 3.0}, {"life": 1.5}, {"rate": -0.08}, {"amount": 1}, {"dmg": 4.0}, {"rate": -0.08}, {"amount": 1}],
		"evo": {"passive": "hat", "name": "EVO_SCARECROW", "dmg": 1.7, "amount": 1, "rate": 0.6}},
}

const PASSIVES := {
	"hat": {"stat": "area", "v": 0.1},
	"boots": {"stat": "speed", "v": 0.08},
	"gloves": {"stat": "cooldown", "v": -0.08},
	"almanac": {"stat": "growth", "v": 0.12},
	"whetstone": {"stat": "might", "v": 0.1},
	"lunchbox": {"stat": "max_hp", "v": 20.0},
	"horseshoe": {"stat": "magnet", "v": 0.4},
	"thermos": {"stat": "regen", "v": 0.5},
	"overalls": {"stat": "armor", "v": 1.0},
	"clover": {"stat": "luck", "v": 0.15},
}

# Workshop: permanent upgrades. Costs grow geometrically: the incremental long game.
const META := [
	{"id": "might", "icon": "whetstone", "stat": "might", "v": 0.05, "max": 20, "cost": 60.0, "grow": 1.42},
	{"id": "vitality", "icon": "heart", "stat": "max_hp", "v": 8.0, "max": 20, "cost": 50.0, "grow": 1.4},
	{"id": "armor", "icon": "overalls", "stat": "armor", "v": 1.0, "max": 8, "cost": 180.0, "grow": 2.0},
	{"id": "regen", "icon": "thermos", "stat": "regen", "v": 0.15, "max": 10, "cost": 120.0, "grow": 1.6},
	{"id": "swift", "icon": "boots", "stat": "speed", "v": 0.03, "max": 10, "cost": 90.0, "grow": 1.55},
	{"id": "haste", "icon": "gloves", "stat": "cooldown", "v": -0.02, "max": 15, "cost": 120.0, "grow": 1.5},
	{"id": "reach", "icon": "hat", "stat": "area", "v": 0.03, "max": 15, "cost": 100.0, "grow": 1.48},
	{"id": "amount", "icon": "pitchfork", "stat": "amount", "v": 1.0, "max": 3, "cost": 4000.0, "grow": 8.0},
	{"id": "growth", "icon": "almanac", "stat": "growth", "v": 0.05, "max": 15, "cost": 80.0, "grow": 1.48},
	{"id": "greed", "icon": "coin", "stat": "greed", "v": 0.1, "max": 25, "cost": 100.0, "grow": 1.42},
	{"id": "magnet", "icon": "horseshoe", "stat": "magnet", "v": 0.1, "max": 10, "cost": 70.0, "grow": 1.5},
	{"id": "luck", "icon": "clover", "stat": "luck", "v": 0.05, "max": 15, "cost": 110.0, "grow": 1.5},
	{"id": "revive", "icon": "revive", "stat": "revive", "v": 1.0, "max": 3, "cost": 1500.0, "grow": 6.0},
	{"id": "reroll", "icon": "reroll", "stat": "reroll", "v": 1.0, "max": 6, "cost": 150.0, "grow": 2.0},
	{"id": "skip", "icon": "skip", "stat": "skip", "v": 1.0, "max": 5, "cost": 120.0, "grow": 2.0},
	{"id": "banish", "icon": "banish", "stat": "banish", "v": 1.0, "max": 5, "cost": 200.0, "grow": 2.0},
]

# Farm: idle buildings that earn coins while you are fighting or away.
const BUILDINGS := [
	{"id": "coop", "cost": 40.0, "cps": 0.2},
	{"id": "barn", "cost": 350.0, "cps": 1.2},
	{"id": "silo", "cost": 3000.0, "cps": 6.0},
	{"id": "windmill", "cost": 24000.0, "cps": 30.0},
	{"id": "greenhouse", "cost": 200000.0, "cps": 160.0},
	{"id": "lab", "cost": 1800000.0, "cps": 900.0},
]
const BUILDING_GROWTH := 1.15
const BUILDING_MILESTONE := 25  # every 25 of a building doubles its output
const OFFLINE_CAP_HOURS := 8.0
const SOIL_DIVISOR := 25000.0  # replant reward = sqrt(lifetime coins / divisor)
const SOIL_COIN_BONUS := 0.05
const SOIL_MIGHT_BONUS := 0.01

# Radiation Levels: replay a cleared stage for harder enemies and richer payouts.
const RAD_HP := 1.4
const RAD_DMG := 1.12
const RAD_COINS := 1.3

const JOURNAL := ["JOURNAL_0", "JOURNAL_1", "JOURNAL_2", "JOURNAL_3"]
