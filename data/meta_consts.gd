extends Node

# ============================================================
# Meta 配置中心（替代 MetaConsts.js - 1265行纯数据）
# 所有游戏配置数据集中管理
# ============================================================

# ---------- 元素克制 ----------
const elementWeakness: Dictionary = {
	1: 4,  # 火 克制 土
	2: 1,  # 水 克制 火
	3: 2,  # 风 克制 水
	4: 3,  # 土 克制 风
}

const elementDamageMultiplier: Dictionary = {
	1: { 1: 0.85, 2: 0.70, 3: 1.00, 4: 1.50 },
	2: { 1: 1.50, 2: 0.85, 3: 0.70, 4: 1.00 },
	3: { 1: 1.00, 2: 1.50, 3: 0.85, 4: 0.70 },
	4: { 1: 0.70, 2: 1.00, 3: 1.50, 4: 0.85 },
}

# ---------- 难度曲线 ----------
const difficultyCurves: Dictionary = {
	"normal": {
		"stepReduction": 0.94,
		"hpMultiplier": 1.12,
		"atkMultiplier": 1.06,
		"dropRate": 1.05,
		"minStep": 14,
		"maxHpMultiplier": 3.0,
		"maxAtkMultiplier": 2.2,
		"smoothingStart": 7,
		"smoothingFactor": 0.75,
	},
	"hard": {
		"stepReduction": 0.90,
		"hpMultiplier": 1.20,
		"atkMultiplier": 1.12,
		"dropRate": 1.08,
		"minStep": 10,
		"maxHpMultiplier": 4.0,
		"maxAtkMultiplier": 3.0,
		"smoothingStart": 5,
		"smoothingFactor": 0.65,
	},
	"expert": {
		"stepReduction": 0.86,
		"hpMultiplier": 1.32,
		"atkMultiplier": 1.20,
		"dropRate": 1.12,
		"minStep": 7,
		"maxHpMultiplier": 5.0,
		"maxAtkMultiplier": 4.2,
		"smoothingStart": 4,
		"smoothingFactor": 0.55,
	},
}

# ---------- 15级递进回合难度表 ----------
const roundDifficulty: Dictionary = {
	50001: { "difficulty": "normal", "baseStep": 32, "tier": 1, "name": "新手引导" },
	50002: { "difficulty": "normal", "baseStep": 28, "tier": 2, "name": "热身战斗" },
	50003: { "difficulty": "normal", "baseStep": 26, "tier": 3, "name": "基础敌人" },
	50004: { "difficulty": "normal", "baseStep": 24, "tier": 4, "name": "组合敌人" },
	50005: { "difficulty": "normal", "baseStep": 22, "tier": 5, "name": "首次精英" },
	50006: { "difficulty": "hard",   "baseStep": 20, "tier": 6, "name": "强度提升" },
	50007: { "difficulty": "hard",   "baseStep": 18, "tier": 7, "name": "多敌人场" },
	50008: { "difficulty": "hard",   "baseStep": 16, "tier": 8, "name": "精英组合" },
	50009: { "difficulty": "hard",   "baseStep": 15, "tier": 9, "name": "小Boss前" },
	50010: { "difficulty": "hard",   "baseStep": 18, "tier":10, "name": "一号Boss" },
	50011: { "difficulty": "expert", "baseStep": 14, "tier":11, "name": "中期高压" },
	50012: { "difficulty": "expert", "baseStep": 13, "tier":12, "name": "精英潮" },
	50013: { "difficulty": "expert", "baseStep": 12, "tier":13, "name": "最终前哨" },
	50014: { "difficulty": "expert", "baseStep": 16, "tier":14, "name": "二号Boss" },
	50015: { "difficulty": "expert", "baseStep": 20, "tier":15, "name": "最终Boss" },
}

# ---------- 步数软着陆算法配置 ----------
const stepSoftLanding: Dictionary = {
	"criticalThreshold": 10,
	"emergencyBonus": 3,
	"recoveryRate": 0.5,
	"minGuaranteedStep": 3,
}

# ---------- 己方角色配置 ----------
const orderSelf: Dictionary = {
	20001: {
		"id": 20001,
		"name": "火焰术士",
		"elementType": 1,
		"hp": 100,
		"def": 5,
		"atk": 12,
		"step": 3,
		"role": 8,
		"maxBullet": 2,
		"buffId": 90051,
		"desc": "专精火焰魔法，爆发伤害极高",
	},
	20002: {
		"id": 20002,
		"name": "寒冰守护",
		"elementType": 2,
		"hp": 130,
		"def": 10,
		"atk": 8,
		"step": 4,
		"role": 8,
		"maxBullet": 2,
		"buffId": 90003,
		"desc": "坚不可摧的防御型角色",
	},
	20003: {
		"id": 20003,
		"name": "疾风行者",
		"elementType": 3,
		"hp": 80,
		"def": 3,
		"atk": 10,
		"step": 5,
		"role": 8,
		"maxBullet": 3,
		"buffId": 90101,
		"desc": "极限机动，擅长连击作战",
	},
	20004: {
		"id": 20004,
		"name": "大地守护者",
		"elementType": 4,
		"hp": 150,
		"def": 15,
		"atk": 7,
		"step": 3,
		"role": 8,
		"maxBullet": 1,
		"buffId": 90153,
		"desc": "极致生存，高防御高血量",
	},
	20005: {
		"id": 20005,
		"name": "虚空行者",
		"elementType": 0,
		"hp": 105,
		"def": 7,
		"atk": 10,
		"step": 4,
		"role": 8,
		"maxBullet": 2,
		"buffId": 90004,
		"desc": "游离于元素之外的神秘旅者，精通本源力量",
	},
}

# ---------- 敌方单位配置 ----------
const orderEnermy: Dictionary = {
	30001: {
		"id": 30001,
		"name": "火焰史莱姆",
		"type": "normal",
		"hp": 50,
		"def": 2,
		"atk": 10,
		"role": 7,
		"step": 5,
		"bullets": [1102, 1103],
		"level": 2,
		"elementType": 1,
		"tier": 1,
		"dropItems": [
			{"itemId": 60000001, "chance": 0.4},
			{"itemId": 60000002, "chance": 0.15},
		],
	},
	30002: {
		"id": 30002,
		"name": "水系精灵",
		"type": "normal",
		"hp": 45,
		"def": 4,
		"atk": 8,
		"role": 7,
		"step": 5,
		"bullets": [1202, 1203],
		"level": 3,
		"elementType": 2,
		"tier": 1,
		"dropItems": [
			{"itemId": 60000001, "chance": 0.35},
			{"itemId": 60000003, "chance": 0.2},
		],
	},
	30003: {
		"id": 30003,
		"name": "岩石傀儡",
		"type": "normal",
		"hp": 70,
		"def": 7,
		"atk": 7,
		"role": 7,
		"step": 6,
		"bullets": [1403, 1404],
		"level": 4,
		"elementType": 4,
		"tier": 2,
		"dropItems": [
			{"itemId": 60000002, "chance": 0.3},
			{"itemId": 60000004, "chance": 0.1},
		],
	},
	30004: {
		"id": 30004,
		"name": "风暴术士",
		"type": "elite",
		"hp": 100,
		"def": 6,
		"atk": 18,
		"role": 6,
		"step": 4,
		"bullets": [1305, 1306, 1307],
		"level": 6,
		"elementType": 3,
		"tier": 3,
		"buffId": 90151,
		"dropItems": [
			{"itemId": 60000005, "chance": 0.5},
			{"itemId": 60000006, "chance": 0.2},
			{"itemId": 60000007, "chance": 0.08},
		],
	},
	30005: {
		"id": 30005,
		"name": "熔岩守卫",
		"type": "elite",
		"hp": 140,
		"def": 12,
		"atk": 15,
		"role": 6,
		"step": 5,
		"bullets": [1106, 1107, 1108],
		"level": 8,
		"elementType": 1,
		"tier": 4,
		"buffId": 90152,
		"dropItems": [
			{"itemId": 60000005, "chance": 0.45},
			{"itemId": 60000007, "chance": 0.15},
			{"itemId": 60000008, "chance": 0.1},
		],
	},
	30006: {
		"id": 30006,
		"name": "深渊水母",
		"type": "elite",
		"hp": 110,
		"def": 10,
		"atk": 20,
		"role": 6,
		"step": 4,
		"bullets": [1207, 1208, 1209],
		"level": 7,
		"elementType": 2,
		"tier": 4,
		"buffId": 90153,
		"dropItems": [
			{"itemId": 60000006, "chance": 0.5},
			{"itemId": 60000008, "chance": 0.2},
		],
	},
	30007: {
		"id": 30007,
		"name": "山脉巨人",
		"type": "boss",
		"hp": 320,
		"def": 16,
		"atk": 26,
		"role": 6,
		"step": 3,
		"bullets": [1409, 1410, 1411],
		"level": 12,
		"elementType": 4,
		"tier": 5,
		"dropItems": [
			{"itemId": 60000007, "chance": 0.8},
			{"itemId": 60000009, "chance": 0.4},
			{"itemId": 60000010, "chance": 0.15},
		],
		"phases": [
			{"phaseId": "phase1", "hpThreshold": 1.0, "skills": [{"skillId": 95001, "priority": 1}]},
			{"phaseId": "phase2", "hpThreshold": 0.66, "skills": [{"skillId": 95002, "priority": 1}, {"skillId": 95003, "priority": 2}]},
			{"phaseId": "phase3", "hpThreshold": 0.33, "skills": [{"skillId": 95004, "priority": 1}, {"skillId": 95005, "priority": 2}]},
		],
		"currentPhase": "phase1",
	},
	30008: {
		"id": 30008,
		"name": "元素领主",
		"type": "boss",
		"hp": 480,
		"def": 20,
		"atk": 30,
		"role": 6,
		"step": 3,
		"bullets": [1112, 1212, 1312, 1412],
		"level": 15,
		"elementType": 0,
		"tier": 6,
		"dropItems": [
			{"itemId": 60000009, "chance": 1.0},
			{"itemId": 60000010, "chance": 0.6},
			{"itemId": 60000015, "chance": 0.25},
		],
		"phases": [
			{"phaseId": "fire", "hpThreshold": 1.0, "element": 1, "skills": [{"skillId": 95006, "priority": 1}]},
			{"phaseId": "water", "hpThreshold": 0.75, "element": 2, "skills": [{"skillId": 95007, "priority": 1}, {"skillId": 95008, "priority": 2}]},
			{"phaseId": "wind", "hpThreshold": 0.5, "element": 3, "skills": [{"skillId": 95009, "priority": 1}, {"skillId": 95010, "priority": 2}]},
			{"phaseId": "earth", "hpThreshold": 0.25, "element": 4, "skills": [{"skillId": 95011, "priority": 1}, {"skillId": 95012, "priority": 2}]},
		],
		"currentPhase": "fire",
	},
}

# ---------- 发射器配置 ----------
const launchers: Dictionary = {
	1001: { "id": 1001, "name": "火焰发射器", "elementType": [1, 2], "range": 3, "atk": 2, "type": 2 },
	1002: { "id": 1002, "name": "寒冰发射器", "elementType": [2, 3], "range": 4, "atk": 1, "type": 2 },
	1003: { "id": 1003, "name": "风暴发射器", "elementType": [3, 4], "range": 5, "atk": 1, "type": 2 },
	1004: { "id": 1004, "name": "大地发射器", "elementType": [4, 1], "range": 3, "atk": 3, "type": 2 },
	1005: { "id": 1005, "name": "虚空发射器", "elementType": [0], "range": 4, "atk": 2, "type": 2 },
}

# ---------- 子弹/元素配置 ----------
const elements: Dictionary = {
	1001: { "id": 1001, "type": 1, "atk": 5, "distance": 2, "cover": 0, "elementType": 1, "mergeId": 0 },
	1102: { "id": 1102, "type": 1, "atk": 8, "distance": 2, "cover": 0, "elementType": 1, "mergeId": 1103 },
	1103: { "id": 1103, "type": 1, "atk": 12, "distance": 3, "cover": 0, "elementType": 1, "mergeId": 0 },
	1106: { "id": 1106, "type": 1, "atk": 15, "distance": 3, "cover": 0, "elementType": 1, "mergeId": 1107 },
	1107: { "id": 1107, "type": 1, "atk": 20, "distance": 4, "cover": 0, "elementType": 1, "mergeId": 1108 },
	1108: { "id": 1108, "type": 1, "atk": 28, "distance": 4, "cover": 0, "elementType": 1, "mergeId": 0 },
	1112: { "id": 1112, "type": 1, "atk": 35, "distance": 5, "cover": 0, "elementType": 1, "mergeId": 0 },
	1202: { "id": 1202, "type": 1, "atk": 6, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 1203 },
	1203: { "id": 1203, "type": 1, "atk": 10, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 0 },
	1207: { "id": 1207, "type": 1, "atk": 14, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 1208 },
	1208: { "id": 1208, "type": 1, "atk": 20, "distance": 4, "cover": 0, "elementType": 2, "mergeId": 1209 },
	1209: { "id": 1209, "type": 1, "atk": 26, "distance": 4, "cover": 0, "elementType": 2, "mergeId": 0 },
	1212: { "id": 1212, "type": 1, "atk": 32, "distance": 5, "cover": 0, "elementType": 2, "mergeId": 0 },
	1305: { "id": 1305, "type": 1, "atk": 12, "distance": 4, "cover": 1, "elementType": 3, "mergeId": 1306 },
	1306: { "id": 1306, "type": 1, "atk": 18, "distance": 4, "cover": 1, "elementType": 3, "mergeId": 1307 },
	1307: { "id": 1307, "type": 1, "atk": 24, "distance": 5, "cover": 1, "elementType": 3, "mergeId": 0 },
	1312: { "id": 1312, "type": 1, "atk": 30, "distance": 5, "cover": 1, "elementType": 3, "mergeId": 0 },
	1403: { "id": 1403, "type": 1, "atk": 10, "distance": 2, "cover": 0, "elementType": 4, "mergeId": 1404 },
	1404: { "id": 1404, "type": 1, "atk": 14, "distance": 2, "cover": 0, "elementType": 4, "mergeId": 0 },
	1409: { "id": 1409, "type": 1, "atk": 22, "distance": 3, "cover": 0, "elementType": 4, "mergeId": 1410 },
	1410: { "id": 1410, "type": 1, "atk": 28, "distance": 3, "cover": 0, "elementType": 4, "mergeId": 1411 },
	1411: { "id": 1411, "type": 1, "atk": 35, "distance": 4, "cover": 0, "elementType": 4, "mergeId": 0 },
	1412: { "id": 1412, "type": 1, "atk": 40, "distance": 4, "cover": 0, "elementType": 4, "mergeId": 0 },
	2001: { "id": 2001, "type": 1, "atk": 5, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 0 },
	4001: { "id": 4001, "type": 1, "atk": 5, "distance": 4, "cover": 1, "elementType": 3, "mergeId": 0 },
	6001: { "id": 6001, "type": 1, "atk": 5, "distance": 2, "cover": 0, "elementType": 4, "mergeId": 0 },
	8001: { "id": 8001, "type": 1, "atk": 5, "distance": 3, "cover": 0, "elementType": 0, "mergeId": 0 },
}

# ---------- Buff 配置 ----------
const buffs: Dictionary = {
	90001: { "id": 90001, "type": "atk_up", "value": 3, "duration": -1, "stackable": false, "desc": "攻击力+3" },
	90002: { "id": 90002, "type": "def_up", "value": 3, "duration": -1, "stackable": false, "desc": "防御力+3" },
	90003: { "id": 90003, "type": "def_up", "value": 5, "duration": -1, "stackable": false, "desc": "防御力+5" },
	90004: { "id": 90004, "type": "all_stats", "value": 2, "duration": -1, "stackable": false, "desc": "全属性+2" },
	90051: { "id": 90051, "type": "atk_up", "value": 5, "duration": -1, "stackable": false, "desc": "攻击力+5" },
	90101: { "id": 90101, "type": "step_per_round", "value": 1, "duration": -1, "stackable": false, "desc": "每回合额外+1步" },
	90151: { "id": 90151, "type": "atk_up", "value": 8, "duration": -1, "stackable": false, "desc": "攻击力+8" },
	90152: { "id": 90152, "type": "def_up", "value": 10, "duration": -1, "stackable": false, "desc": "防御力+10" },
	90153: { "id": 90153, "type": "heal", "value": 15, "duration": -1, "stackable": false, "desc": "每回合恢复15HP" },
	90201: { "id": 90201, "type": "atk_multi", "value": 0.15, "duration": -1, "stackable": false, "desc": "攻击倍率+15%" },
	90202: { "id": 90202, "type": "def_multi", "value": 0.15, "duration": -1, "stackable": false, "desc": "防御倍率+15%" },
	90203: { "id": 90203, "type": "crit_rate", "value": 0.10, "duration": -1, "stackable": false, "desc": "暴击率+10%" },
	90204: { "id": 90204, "type": "crit_dmg", "value": 0.25, "duration": -1, "stackable": false, "desc": "暴击伤害+25%" },
	90205: { "id": 90205, "type": "elem_dmg", "value": 0.10, "duration": -1, "stackable": false, "desc": "元素伤害+10%" },
	90206: { "id": 90206, "type": "dmg_reduce", "value": 0.10, "duration": -1, "stackable": false, "desc": "所受伤害-10%" },
	90207: { "id": 90207, "type": "shield", "value": 20, "duration": 3, "stackable": false, "desc": "获得20护盾持续3回合" },
	90208: { "id": 90208, "type": "weakness_bonus", "value": 0.25, "duration": -1, "stackable": false, "desc": "克制伤害+25%" },
	90209: { "id": 90209, "type": "bullet_count", "value": 1, "duration": -1, "stackable": false, "desc": "子弹数量+1" },
}

# ---------- 游戏关卡配置 ----------
const gameStartLevel: Dictionary = {
	1: 1001,
}

const gameLevels: Dictionary = {
	1001: {
		"id": 1001,
		"name": "初入元素世界",
		"rounds": [50001, 50002, 50003],
		"next": [1002],
	},
	1002: {
		"id": 1002,
		"name": "元素试炼",
		"rounds": [50004, 50005],
		"next": [],
	},
}

const gameRounds: Dictionary = {
	50001: {
		"id": 50001,
		"name": "最初之战",
		"step": 20,
		"baseStep": 32,
		"orderEnermyPool": [30001, 30002],
	},
	50002: {
		"id": 50002,
		"name": "元素初现",
		"step": 18,
		"baseStep": 28,
		"orderEnermyPool": [30001, 30002, 30003],
	},
	50003: {
		"id": 50003,
		"name": "组合挑战",
		"step": 16,
		"baseStep": 26,
		"orderEnermyPool": [30001, 30002, 30003],
	},
	50004: {
		"id": 50004,
		"name": "精英初现",
		"step": 14,
		"baseStep": 24,
		"orderEnermyPool": [30004, 30001, 30002],
	},
	50005: {
		"id": 50005,
		"name": "首次精英",
		"step": 12,
		"baseStep": 22,
		"orderEnermyPool": [30004, 30003],
	},
}

# ---------- 道具配置 ----------
const items: Dictionary = {
	60000001: { "id": 60000001, "name": "小回复药水", "type": "consumable", "effect": {"type": "heal", "value": 15}, "desc": "恢复15点HP" },
	60000002: { "id": 60000002, "name": "小攻击药水", "type": "consumable", "effect": {"type": "atk_up", "value": 3, "duration": 5}, "desc": "攻击力+3持续5回合" },
	60000003: { "id": 60000003, "name": "小防御药水", "type": "consumable", "effect": {"type": "def_up", "value": 3, "duration": 5}, "desc": "防御力+3持续5回合" },
	60000004: { "id": 60000004, "name": "大回复药水", "type": "consumable", "effect": {"type": "heal", "value": 40}, "desc": "恢复40点HP" },
	60000005: { "id": 60000005, "name": "元素碎片", "type": "material", "effect": {}, "desc": "蕴含元素之力的碎片" },
	60000006: { "id": 60000006, "name": "精炼核心", "type": "material", "effect": {}, "desc": "用于装备强化的核心材料" },
	60000007: { "id": 60000007, "name": "大攻击药水", "type": "consumable", "effect": {"type": "atk_up", "value": 8, "duration": 3}, "desc": "攻击力+8持续3回合" },
	60000008: { "id": 60000008, "name": "大防御药水", "type": "consumable", "effect": {"type": "def_up", "value": 8, "duration": 3}, "desc": "防御力+8持续3回合" },
	60000009: { "id": 60000009, "name": "复活石", "type": "special", "effect": {"type": "revive", "value": 1}, "desc": "死亡时自动复活一次" },
	60000010: { "id": 60000010, "name": "元素祝福", "type": "consumable", "effect": {"type": "full_elem", "duration": 3}, "desc": "全元素加成持续3回合" },
	60000015: { "id": 60000015, "name": "最终秘药", "type": "special", "effect": {"type": "all_stats", "value": 5, "duration": -1}, "desc": "永久全属性+5" },
}

# ---------- 技能配置 ----------
const skills: Dictionary = {
	95001: { "id": 95001, "name": "山崩", "type": "area_attack", "value": 25, "cooldown": 2, "desc": "全体攻击造成25点伤害" },
	95002: { "id": 95002, "name": "硬化皮肤", "type": "shield", "value": 30, "cooldown": 3, "desc": "获得30点护盾" },
	95003: { "id": 95003, "name": "地震波", "type": "area_attack", "value": 18, "cooldown": 2, "desc": "全体攻击造成18点伤害" },
	95004: { "id": 95004, "name": "暴怒", "type": "area_attack", "value": 40, "cooldown": 3, "desc": "全体攻击造成40点伤害" },
	95005: { "id": 95005, "name": "回复", "type": "heal", "value": 50, "cooldown": 4, "desc": "恢复50点HP" },
	95006: { "id": 95006, "name": "火焰风暴", "type": "area_attack", "value": 20, "cooldown": 2, "desc": "火焰全体攻击20点伤害" },
	95007: { "id": 95007, "name": "冰霜新星", "type": "area_attack", "value": 25, "cooldown": 2, "desc": "冰霜全体攻击25点伤害" },
	95008: { "id": 95008, "name": "水之护盾", "type": "shield", "value": 35, "cooldown": 3, "desc": "获得35点护盾" },
	95009: { "id": 95009, "name": "暴风切割", "type": "area_attack", "value": 30, "cooldown": 2, "desc": "风系全体攻击30点伤害" },
	95010: { "id": 95010, "name": "风之祝福", "type": "heal", "value": 40, "cooldown": 3, "desc": "恢复40点HP" },
	95011: { "id": 95011, "name": "大地之怒", "type": "area_attack", "value": 35, "cooldown": 2, "desc": "土系全体攻击35点伤害" },
	95012: { "id": 95012, "name": "元素转换", "type": "element_change", "value": 0, "cooldown": 1, "desc": "切换元素形态" },
}

# ---------- 辅助方法 ----------
static func get_difficulty_profile(difficulty: int) -> Dictionary:
	if difficulty <= 3:
		return difficultyCurves.get("normal", {})
	elif difficulty <= 6:
		return difficultyCurves.get("hard", {})
	else:
		return difficultyCurves.get("expert", {})

static func get_weakness_multiplier(atk_elem: int, def_elem: int) -> float:
	var elem_mult = elementDamageMultiplier.get(atk_elem, {})
	return elem_mult.get(def_elem, 1.0) if elem_mult else 1.0

static func is_weakness(atk_elem: int, def_elem: int) -> bool:
	return elementWeakness.get(atk_elem, -1) == def_elem

static func is_resistance(atk_elem: int, def_elem: int) -> bool:
	return elementWeakness.get(def_elem, -1) == atk_elem

static func get_element_damage_multiplier(atk_elem: int, def_elem: int) -> float:
	return get_weakness_multiplier(atk_elem, def_elem)