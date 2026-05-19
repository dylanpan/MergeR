extends Node

# ============================================================
# Meta 配置中心（替代 MetaConsts.js - 1265行纯数据）
# 所有游戏配置数据集中管理
# ============================================================

# ==============================================
# 四元素完整相克循环系统 v1.0
# 元素ID: 1=火, 2=水, 3=风, 4=土
# 克制关系: 火→土→风→水→火
# 伤害系数规则:
#  ✅ 攻击克制目标: 伤害 * 1.50
#  ❌ 攻击被克制目标: 伤害 * 0.70
#  ⚪ 攻击同属性目标: 伤害 * 0.85
#  ⚫ 无属性相关: 伤害 * 1.00
# ==============================================
const elementWeakness: Dictionary = {
	1: 4,  # 火 克制 土
	2: 1,  # 水 克制 火
	3: 2,  # 风 克制 水
	4: 3,  # 土 克制 风
}

const elementDamageMultiplier: Dictionary = {
	# 攻击方 火(1)
	1: { 1: 0.85, 2: 0.70, 3: 1.00, 4: 1.50 },
	# 攻击方 水(2)
	2: { 1: 1.50, 2: 0.85, 3: 0.70, 4: 1.00 },
	# 攻击方 风(3)
	3: { 1: 1.00, 2: 1.50, 3: 0.85, 4: 0.70 },
	# 攻击方 土(4)
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

# ==============================================
# 四元素子弹链系统 v1.0
# 4套独立子弹体系, 每套12级梯度成长
# ID分段: 火11xx | 水12xx | 风13xx | 土14xx
# 成长曲线: 1-10级每级+2, 11级+5, 12级+5
# ==============================================
# ---------- 🔥 火元素子弹 (1101-1112) ----------
const elements: Dictionary = {
	1001: {"id": 1001, "atk": 2, "distance": 1, "cover": 1, "mergeId": 1002, "elementType": 1},
	1002: {"id": 1002, "atk": 4, "distance": 1, "cover": 1, "mergeId": 1003, "elementType": 1},
	1003: {"id": 1003, "atk": 6, "distance": 1, "cover": 1, "mergeId": 1004, "elementType": 1},
	1004: {"id": 1004, "atk": 8, "distance": 1, "cover": 1, "mergeId": 1005, "elementType": 1},
	1005: {"id": 1005, "atk":10, "distance": 1, "cover": 1, "mergeId": 1006, "elementType": 1},
	1006: {"id": 1006, "atk":12, "distance": 1, "cover": 1, "mergeId": 1007, "elementType": 1},
	1007: {"id": 1007, "atk":14, "distance": 1, "cover": 1, "mergeId": 1008, "elementType": 1},
	1008: {"id": 1008, "atk":16, "distance": 1, "cover": 1, "mergeId": 1009, "elementType": 1},
	1009: {"id": 1009, "atk":18, "distance": 1, "cover": 1, "mergeId": 1010, "elementType": 1},
	1010: {"id": 1010, "atk":20, "distance": 1, "cover": 1, "mergeId": 1011, "elementType": 1},
	1011: {"id": 1011, "atk":25, "distance": 1, "cover": 1, "mergeId": 1012, "elementType": 1},
	1012: {"id": 1012, "atk":30, "distance": 1, "cover": 1, "elementType": 1},
	# ---------- 💧 水元素子弹 (1201-1212) ----------
	2001: {"id": 2001, "atk": 2, "distance": 1, "cover": 1, "mergeId": 2002, "elementType": 2},
	2002: {"id": 2002, "atk": 4, "distance": 1, "cover": 1, "mergeId": 2003, "elementType": 2},
	2003: {"id": 2003, "atk": 6, "distance": 1, "cover": 1, "mergeId": 2004, "elementType": 2},
	2004: {"id": 2004, "atk": 8, "distance": 1, "cover": 1, "mergeId": 2005, "elementType": 2},
	2005: {"id": 2005, "atk":10, "distance": 1, "cover": 1, "mergeId": 2006, "elementType": 2},
	2006: {"id": 2006, "atk":12, "distance": 1, "cover": 1, "mergeId": 2007, "elementType": 2},
	2007: {"id": 2007, "atk":14, "distance": 1, "cover": 1, "mergeId": 2008, "elementType": 2},
	2008: {"id": 2008, "atk":16, "distance": 1, "cover": 1, "mergeId": 2009, "elementType": 2},
	2009: {"id": 2009, "atk":18, "distance": 1, "cover": 1, "mergeId": 2010, "elementType": 2},
	2010: {"id": 2010, "atk":20, "distance": 1, "cover": 1, "mergeId": 2011, "elementType": 2},
	2011: {"id": 2011, "atk":25, "distance": 1, "cover": 1, "mergeId": 2012, "elementType": 2},
	2012: {"id": 2012, "atk":30, "distance": 1, "cover": 1, "elementType": 2},
	# ---------- 🌪️ 风元素子弹 (1301-1312) ----------
	4001: {"id": 4001, "atk": 2, "distance": 1, "cover": 1, "mergeId": 4002, "elementType": 3},
	4002: {"id": 4002, "atk": 4, "distance": 1, "cover": 1, "mergeId": 4003, "elementType": 3},
	4003: {"id": 4003, "atk": 6, "distance": 1, "cover": 1, "mergeId": 4004, "elementType": 3},
	4004: {"id": 4004, "atk": 8, "distance": 1, "cover": 1, "mergeId": 4005, "elementType": 3},
	4005: {"id": 4005, "atk":10, "distance": 1, "cover": 1, "mergeId": 4006, "elementType": 3},
	4006: {"id": 4006, "atk":12, "distance": 1, "cover": 1, "mergeId": 4007, "elementType": 3},
	4007: {"id": 4007, "atk":14, "distance": 1, "cover": 1, "mergeId": 4008, "elementType": 3},
	4008: {"id": 4008, "atk":16, "distance": 1, "cover": 1, "mergeId": 4009, "elementType": 3},
	4009: {"id": 4009, "atk":18, "distance": 1, "cover": 1, "mergeId": 4010, "elementType": 3},
	4010: {"id": 4010, "atk":20, "distance": 1, "cover": 1, "mergeId": 4011, "elementType": 3},
	4011: {"id": 4011, "atk":25, "distance": 1, "cover": 1, "mergeId": 4012, "elementType": 3},
	4012: {"id": 4012, "atk":30, "distance": 1, "cover": 1, "elementType": 3},
	# ---------- 🪨 土元素子弹 (1401-1412) ----------
	6001: {"id": 6001, "atk": 2, "distance": 1, "cover": 1, "mergeId": 6002, "elementType": 4},
	6002: {"id": 6002, "atk": 4, "distance": 1, "cover": 1, "mergeId": 6003, "elementType": 4},
	6003: {"id": 6003, "atk": 6, "distance": 1, "cover": 1, "mergeId": 6004, "elementType": 4},
	6004: {"id": 6004, "atk": 8, "distance": 1, "cover": 1, "mergeId": 6005, "elementType": 4},
	6005: {"id": 6005, "atk":10, "distance": 1, "cover": 1, "mergeId": 6006, "elementType": 4},
	6006: {"id": 6006, "atk":12, "distance": 1, "cover": 1, "mergeId": 6007, "elementType": 4},
	6007: {"id": 6007, "atk":14, "distance": 1, "cover": 1, "mergeId": 6008, "elementType": 4},
	6008: {"id": 6008, "atk":16, "distance": 1, "cover": 1, "mergeId": 6009, "elementType": 4},
	6009: {"id": 6009, "atk":18, "distance": 1, "cover": 1, "mergeId": 6010, "elementType": 4},
	6010: {"id": 6010, "atk":20, "distance": 1, "cover": 1, "mergeId": 6011, "elementType": 4},
	6011: {"id": 6011, "atk":25, "distance": 1, "cover": 1, "mergeId": 6012, "elementType": 4},
	6012: {"id": 6012, "atk":30, "distance": 1, "cover": 1, "elementType": 4},
	# ---------- ⚪ 无属性子弹 (8001-8012) ----------
	8001: {"id": 8001, "atk": 2, "distance": 1, "cover": 1, "mergeId": 8002, "elementType": 0},
	8002: {"id": 8002, "atk": 4, "distance": 1, "cover": 1, "mergeId": 8003, "elementType": 0},
	8003: {"id": 8003, "atk": 6, "distance": 1, "cover": 1, "mergeId": 8004, "elementType": 0},
	8004: {"id": 8004, "atk": 8, "distance": 1, "cover": 1, "mergeId": 8005, "elementType": 0},
	8005: {"id": 8005, "atk":10, "distance": 1, "cover": 1, "mergeId": 8006, "elementType": 0},
	8006: {"id": 8006, "atk":12, "distance": 1, "cover": 1, "mergeId": 8007, "elementType": 0},
	8007: {"id": 8007, "atk":14, "distance": 1, "cover": 1, "mergeId": 8008, "elementType": 0},
	8008: {"id": 8008, "atk":16, "distance": 1, "cover": 1, "mergeId": 8009, "elementType": 0},
	8009: {"id": 8009, "atk":18, "distance": 1, "cover": 1, "mergeId": 8010, "elementType": 0},
	8010: {"id": 8010, "atk":20, "distance": 1, "cover": 1, "mergeId": 8011, "elementType": 0},
	8011: {"id": 8011, "atk":25, "distance": 1, "cover": 1, "mergeId": 8012, "elementType": 0},
	8012: {"id": 8012, "atk":30, "distance": 1, "cover": 1, "elementType": 0},
	# ---------- 旧ID兼容（被敌人直接引用） ----------
	1102: {"id": 1102, "type": 1, "atk": 8, "distance": 2, "cover": 0, "elementType": 1, "mergeId": 1002},
	1103: {"id": 1103, "type": 1, "atk": 12, "distance": 3, "cover": 0, "elementType": 1, "mergeId": 0},
	1106: {"id": 1106, "type": 1, "atk": 15, "distance": 3, "cover": 0, "elementType": 1, "mergeId": 1006},
	1107: {"id": 1107, "type": 1, "atk": 20, "distance": 4, "cover": 0, "elementType": 1, "mergeId": 1007},
	1108: {"id": 1108, "type": 1, "atk": 28, "distance": 4, "cover": 0, "elementType": 1, "mergeId": 0},
	1112: {"id": 1112, "type": 1, "atk": 35, "distance": 5, "cover": 0, "elementType": 1, "mergeId": 0},
	1202: {"id": 1202, "type": 1, "atk": 6, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 2002},
	1203: {"id": 1203, "type": 1, "atk": 10, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 0},
	1207: {"id": 1207, "type": 1, "atk": 14, "distance": 3, "cover": 0, "elementType": 2, "mergeId": 2007},
	1208: {"id": 1208, "type": 1, "atk": 20, "distance": 4, "cover": 0, "elementType": 2, "mergeId": 2008},
	1209: {"id": 1209, "type": 1, "atk": 26, "distance": 4, "cover": 0, "elementType": 2, "mergeId": 0},
	1212: {"id": 1212, "type": 1, "atk": 32, "distance": 5, "cover": 0, "elementType": 2, "mergeId": 0},
	1305: {"id": 1305, "type": 1, "atk": 12, "distance": 4, "cover": 1, "elementType": 3, "mergeId": 4005},
	1306: {"id": 1306, "type": 1, "atk": 18, "distance": 4, "cover": 1, "elementType": 3, "mergeId": 4006},
	1307: {"id": 1307, "type": 1, "atk": 24, "distance": 5, "cover": 1, "elementType": 3, "mergeId": 0},
	1312: {"id": 1312, "type": 1, "atk": 30, "distance": 5, "cover": 1, "elementType": 3, "mergeId": 0},
	1403: {"id": 1403, "type": 1, "atk": 10, "distance": 2, "cover": 0, "elementType": 4, "mergeId": 6003},
	1404: {"id": 1404, "type": 1, "atk": 14, "distance": 2, "cover": 0, "elementType": 4, "mergeId": 0},
	1409: {"id": 1409, "type": 1, "atk": 22, "distance": 3, "cover": 0, "elementType": 4, "mergeId": 6009},
	1410: {"id": 1410, "type": 1, "atk": 28, "distance": 3, "cover": 0, "elementType": 4, "mergeId": 6010},
	1411: {"id": 1411, "type": 1, "atk": 35, "distance": 4, "cover": 0, "elementType": 4, "mergeId": 0},
	1412: {"id": 1412, "type": 1, "atk": 40, "distance": 4, "cover": 0, "elementType": 4, "mergeId": 0},
}

# ==============================================
# 发射器系统 v2.0
# 15个发射器，5个品质等级
# ==============================================
const launchers: Dictionary = {
	1101: {"id": 1101, "quality": 1, "name": "基础发射器", "atkBonus": 0.00, "magCapacity": 1, "fireRate": 1.0, "elementType": [{"type":0,"weight":1}], "desc": "标准制式发射器，性能均衡"},
	1102: {"id": 1102, "quality": 1, "name": "训练发射器", "atkBonus": 0.03, "magCapacity": 1, "fireRate": 1.0, "elementType": [{"type":0,"weight":1}], "desc": "新手训练用发射器，小幅提升攻击力"},
	1103: {"id": 1103, "quality": 1, "name": "通用发射器", "atkBonus": 0.05, "magCapacity": 1, "fireRate": 1.0, "elementType": [{"type":0,"weight":1}], "desc": "通用型发射器，基础攻击加成"},
	1104: {"id": 1104, "quality": 2, "name": "火焰发射器", "atkBonus": 0.08, "magCapacity": 1, "fireRate": 1.0, "elementType": [{"type":0,"weight":70},{"type":1,"weight":30}], "buffId": 90057, "desc": "火焰属性专用发射器"},
	1105: {"id": 1105, "quality": 2, "name": "寒冰发射器", "atkBonus": 0.08, "magCapacity": 1, "fireRate": 1.0, "elementType": [{"type":0,"weight":70},{"type":2,"weight":30}], "buffId": 90057, "desc": "寒冰属性专用发射器"},
	1106: {"id": 1106, "quality": 2, "name": "疾风发射器", "atkBonus": 0.07, "magCapacity": 2, "fireRate": 1.1, "elementType": [{"type":0,"weight":65},{"type":3,"weight":35}], "buffId": 90058, "desc": "疾风属性专用发射器"},
	1107: {"id": 1107, "quality": 2, "name": "重岩发射器", "atkBonus": 0.10, "magCapacity": 1, "fireRate": 1.0, "elementType": [{"type":0,"weight":70},{"type":4,"weight":30}], "buffId": 90059, "desc": "重岩属性专用发射器"},
	1108: {"id": 1108, "quality": 3, "name": "烈焰炮", "atkBonus": 0.15, "magCapacity": 2, "fireRate": 1.1, "elementType": [{"type":0,"weight":80},{"type":1,"weight":20}], "buffId": 90104, "desc": "强化型火焰发射器，暴击加成"},
	1109: {"id": 1109, "quality": 3, "name": "冰霜炮", "atkBonus": 0.14, "magCapacity": 2, "fireRate": 1.1, "elementType": [{"type":0,"weight":80},{"type":2,"weight":20}], "buffId": 90106, "desc": "强化型寒冰发射器，附带减速"},
	1110: {"id": 1110, "quality": 3, "name": "风暴炮", "atkBonus": 0.13, "magCapacity": 3, "fireRate": 1.2, "elementType": [{"type":0,"weight":85},{"type":3,"weight":15}], "buffId": 90105, "desc": "强化型疾风发射器，连击加成"},
	1111: {"id": 1111, "quality": 3, "name": "地震炮", "atkBonus": 0.18, "magCapacity": 2, "fireRate": 1.0, "elementType": [{"type":0,"weight":80},{"type":4,"weight":20}], "buffId": 90107, "desc": "强化型重岩发射器，范围攻击"},
	1112: {"id": 1112, "quality": 4, "name": "元素融合器", "atkBonus": 0.22, "magCapacity": 3, "fireRate": 1.2, "elementType": [{"type":0,"weight":40},{"type":1,"weight":15},{"type":2,"weight":15},{"type":3,"weight":15},{"type":4,"weight":15}], "buffId": 90108, "desc": "史诗级发射器，支持全部元素"},
	1113: {"id": 1113, "quality": 4, "name": "奇点发射器", "atkBonus": 0.28, "magCapacity": 3, "fireRate": 1.2, "elementType": [{"type":0,"weight":40},{"type":1,"weight":15},{"type":2,"weight":15},{"type":3,"weight":15},{"type":4,"weight":15}], "buffId": 90109, "desc": "史诗级发射器，穿透防御"},
	1114: {"id": 1114, "quality": 5, "name": "毁灭核心", "atkBonus": 0.35, "magCapacity": 4, "fireRate": 1.3, "elementType": [{"type":0,"weight":40},{"type":1,"weight":15},{"type":2,"weight":15},{"type":3,"weight":15},{"type":4,"weight":15}], "buffId": 90110, "desc": "传说级发射器，极致输出"},
	1115: {"id": 1115, "quality": 5, "name": "混沌发射器", "atkBonus": 0.42, "magCapacity": 5, "fireRate": 1.4, "elementType": [{"type":0,"weight":40},{"type":1,"weight":15},{"type":2,"weight":15},{"type":3,"weight":15},{"type":4,"weight":15}], "buffId": 90111, "desc": "传说级发射器，随机增益"},
}

# ==============================================
# 全局Buff统一配置表 v1.0
# 所有游戏内Buff统一定义于此，全局唯一ID
# 角色、道具、事件、敌人全部通过buffId引用
# ==============================================
const buffs: Dictionary = {
	# 90001-90050 基础属性Buff
	90001: { "id": 90001, "name": "攻击力提升", "type": "atk_up", "buff_desc": "攻击力+3", "bonus": { "value": 3 } },
	90002: { "id": 90002, "name": "防御力提升", "type": "def_up", "buff_desc": "防御力+2", "bonus": { "value": 2 } },
	90003: { "id": 90003, "name": "伤害减免", "type": "dmg_reduce", "buff_desc": "受到伤害-10%", "bonus": { "value": 0.1 } },
	90004: { "id": 90004, "name": "攻击倍率", "type": "atk_multi", "buff_desc": "所有伤害+12%", "bonus": { "value": 0.12 } },
	90005: { "id": 90005, "name": "防御倍率", "type": "def_multi", "buff_desc": "受到的所有伤害降低30%", "bonus": { "value": 1.3 } },
	# 90051-90100 元素Buff
	90051: { "id": 90051, "name": "火属性伤害", "type": "elem_dmg", "buff_desc": "火属性伤害+15%", "bonus": { "value": 0.15, "elementType": 1 } },
	90052: { "id": 90052, "name": "全元素抗性", "type": "elem_resist", "buff_desc": "所有元素伤害减免20%", "bonus": { "value": 0.2 } },
	90053: { "id": 90053, "name": "克制伤害加成", "type": "weakness_bonus", "buff_desc": "克制伤害额外提升20%", "bonus": { "value": 0.2 } },
	90054: { "id": 90054, "name": "火焰诅咒护符", "type": "dual_element_adjust", "buff_desc": "火属性伤害+10%，受到水属性伤害-10%", "bonus": { "elem_dmg": { "1": 0.10 }, "elem_dmg_reduce": { "2": 0.10 } } },
	90055: { "id": 90055, "name": "无属性子弹伤害", "type": "neutral_dmg_bonus", "buff_desc": "本局无属性子弹伤害+10%", "bonus": { "value": 0.10 } },
	90056: { "id": 90056, "name": "全属性子弹伤害", "type": "all_elem_bonus", "buff_desc": "所有属性子弹伤害+7%", "bonus": { "value": 0.07 } },
	90057: { "id": 90057, "name": "元素子弹伤害", "type": "elem_bullet_dmg", "buff_desc": "属性子弹伤害+5%", "bonus": { "value": 0.05 } },
	90058: { "id": 90058, "name": "元素子弹速度", "type": "elem_bullet_speed", "buff_desc": "属性子弹速度+10%", "bonus": { "value": 0.1 } },
	90059: { "id": 90059, "name": "元素子弹穿透", "type": "elem_bullet_pierce", "buff_desc": "属性子弹穿透+1", "bonus": { "value": 1 } },
	# 90101-90150 回合/步数Buff
	90101: { "id": 90101, "name": "每回合步数", "type": "step_per_round", "buff_desc": "每回合额外+1步", "bonus": { "value": 1 } },
	90102: { "id": 90102, "name": "额外步数", "type": "step_bonus", "buff_desc": "立即获得2点额外步数", "bonus": { "value": 2 } },
	90103: { "id": 90103, "name": "子弹数量", "type": "bullet_count", "buff_desc": "每回合额外发射1颗子弹", "bonus": { "value": 1 } },
	90104: { "id": 90104, "name": "暴击率", "type": "crit_rate", "buff_desc": "暴击率+10%", "bonus": { "value": 0.1 } },
	90105: { "id": 90105, "name": "连击概率", "type": "combo_rate", "buff_desc": "连击概率+15%", "bonus": { "value": 0.15 } },
	90106: { "id": 90106, "name": "减速", "type": "slow", "buff_desc": "减速效果", "bonus": {} },
	90107: { "id": 90107, "name": "范围伤害", "type": "area_dmg", "buff_desc": "范围伤害", "bonus": {} },
	90108: { "id": 90108, "name": "全属性适应", "type": "full_elem", "buff_desc": "全属性适应", "bonus": {} },
	90109: { "id": 90109, "name": "无视防御", "type": "def_ignore", "buff_desc": "无视防御5%", "bonus": { "value": 0.05 } },
	90110: { "id": 90110, "name": "暴击伤害", "type": "crit_dmg", "buff_desc": "暴击伤害+50%", "bonus": { "value": 0.5 } },
	90111: { "id": 90111, "name": "随机元素共鸣", "type": "random_elem", "buff_desc": "每回合随机元素共鸣", "bonus": {} },
	90112: { "id": 90112, "name": "属性槽位", "type": "add_elem_slot", "buff_desc": "发射器支持额外1种属性子弹", "bonus": { "value": 1 } },
	90113: { "id": 90113, "name": "全属性兼容", "type": "full_elem_support", "buff_desc": "激活发射器全属性兼容模式", "bonus": { "value": 1 } },
	# 90151-90200 特殊状态Buff
	90151: { "id": 90151, "name": "双动", "type": "double_act", "buff_desc": "每回合行动两次", "bonus": {} },
	90152: { "id": 90152, "name": "护盾", "type": "shield", "buff_desc": "获得护盾效果", "bonus": {} },
	90153: { "id": 90153, "name": "治愈", "type": "heal", "buff_desc": "每回合恢复5点生命", "bonus": { "value": 5, "isInstant": false } },
	# 90201-90250 道具专属Buff
	90201: { "id": 90201, "name": "复活", "type": "revive", "buff_desc": "死亡时自动复活并恢复50%生命值", "bonus": { "value": 50 } },
	90202: { "id": 90202, "name": "全属性提升", "type": "all_stats", "buff_desc": "所有属性提升15%", "bonus": { "value": 1.15 } },
	# 90251-90300 治疗类Buff
	90251: { "id": 90251, "name": "治疗小型", "type": "heal", "buff_desc": "恢复30点生命值", "bonus": { "value": 30, "isInstant": true } },
	90252: { "id": 90252, "name": "治疗中型", "type": "heal", "buff_desc": "恢复60点生命值", "bonus": { "value": 60, "isInstant": true } },
	90253: { "id": 90253, "name": "治疗大型", "type": "heal", "buff_desc": "恢复120点生命值", "bonus": { "value": 120, "isInstant": true } },
	# 90301-90350 数值变种Buff
	90301: { "id": 90301, "name": "额外步数+5", "type": "step_bonus", "buff_desc": "立即获得5点额外步数", "bonus": { "value": 5 } },
	90302: { "id": 90302, "name": "伤害提升25%", "type": "atk_multi", "buff_desc": "造成的所有伤害提升25%", "bonus": { "value": 0.25 } },
	90303: { "id": 90303, "name": "每回合步数+2", "type": "step_per_round", "buff_desc": "每回合开始时额外获得2步", "bonus": { "value": 2 } },
	# 90401-90450 事件临时Buff
	90401: { "id": 90401, "name": "攻击提升(事件)", "type": "atk_up", "buff_desc": "攻击力+5，持续3回合", "bonus": { "value": 5, "duration": 3 } },
	90402: { "id": 90402, "name": "防御提升(事件)", "type": "def_up", "buff_desc": "防御力+3，持续3回合", "bonus": { "value": 3, "duration": 3 } },
	90403: { "id": 90403, "name": "步伐轻盈(事件)", "type": "step_per_round", "buff_desc": "每回合额外+1步，持续2回合", "bonus": { "value": 1, "duration": 2 } },
	90404: { "id": 90404, "name": "暴击祝福(事件)", "type": "crit_rate", "buff_desc": "暴击率+15%，持续3回合", "bonus": { "value": 0.15, "duration": 3 } },
	90405: { "id": 90405, "name": "伤害减免(事件)", "type": "dmg_reduce", "buff_desc": "受到伤害-10%，持续3回合", "bonus": { "value": 0.1, "duration": 3 } },
}

# ==============================================
# 全局Skill统一配置表 v1.0
# 所有游戏内技能统一定义于此，全局唯一ID
# 敌人、Boss、角色全部通过skillId引用
# ==============================================
const skills: Dictionary = {
	95001: { "id": 95001, "name": "大地重击", "skillId": "groundSlam", "type": "aoe", "damage": 1.2, "target": "all", "desc": "对全场造成120%攻击力伤害" },
	95002: { "id": 95002, "name": "召唤小怪", "skillId": "summonMinions", "type": "summon", "count": 2, "desc": "召唤2个小怪协助战斗" },
	95003: { "id": 95003, "name": "护甲强化", "skillId": "armorUp", "type": "buff", "buffId": 90002, "value": 10, "desc": "防御力提升10点" },
	95004: { "id": 95004, "name": "狂暴", "skillId": "enrage", "type": "buff", "buffId": 90001, "value": 15, "desc": "攻击力提升15点" },
	95005: { "id": 95005, "name": "毁灭重击", "skillId": "massiveSlam", "type": "single", "damage": 2.5, "target": "player", "desc": "对玩家造成250%攻击力伤害" },
	95006: { "id": 95006, "name": "火焰风暴", "skillId": "fireStorm", "type": "aoe", "elementType": 1, "damage": 1.5, "desc": "全场火焰风暴攻击" },
	95007: { "id": 95007, "name": "冰冻", "skillId": "freeze", "type": "debuff", "buffId": 90106, "duration": 2, "desc": "冻结玩家2回合" },
	95008: { "id": 95008, "name": "治疗", "skillId": "heal", "type": "heal", "value": 0.2, "desc": "恢复20%最大生命值" },
	95009: { "id": 95009, "name": "龙卷风", "skillId": "tornado", "type": "aoe", "elementType": 3, "damage": 1.8, "desc": "风属性范围攻击" },
	95010: { "id": 95010, "name": "加速", "skillId": "speedUp", "type": "buff", "buffId": 90101, "value": 2, "desc": "每回合额外获得2步" },
	95011: { "id": 95011, "name": "无敌", "skillId": "invincible", "type": "buff", "duration": 1, "desc": "本回合免疫所有伤害" },
	95012: { "id": 95012, "name": "终极大招", "skillId": "ultimate", "type": "aoe", "damage": 3.0, "target": "all", "desc": "全屏最终毁灭攻击" },
}

# ==============================================
# 15种道具系统 v1.0
# 4个品质等级: 普通/稀有/史诗/传说
# ID从60000001开始独立分配
# ==============================================
const shopItems: Dictionary = {
	60000001: {"id": 60000001, "quality": 1, "name": "小型治疗药剂", "buffId": 90251, "price": 15, "desc": ""},
	60000002: {"id": 60000002, "quality": 1, "name": "攻击强化卷轴", "buffId": 90001, "price": 20, "desc": ""},
	60000003: {"id": 60000003, "quality": 1, "name": "护盾碎片", "buffId": 90002, "price": 18, "desc": ""},
	60000004: {"id": 60000004, "quality": 1, "name": "能量水晶", "buffId": 90102, "price": 25, "desc": ""},
	60000005: {"id": 60000005, "quality": 2, "name": "中型治疗药剂", "buffId": 90252, "price": 35, "desc": ""},
	60000006: {"id": 60000006, "quality": 2, "name": "元素护符", "buffId": 90052, "price": 40, "desc": ""},
	60000007: {"id": 60000007, "quality": 2, "name": "连击手册", "buffId": 90103, "price": 50, "desc": ""},
	60000008: {"id": 60000008, "quality": 2, "name": "时光沙漏", "buffId": 90301, "price": 45, "desc": ""},
	60000009: {"id": 60000009, "quality": 3, "name": "大型治疗药剂", "buffId": 90253, "price": 75, "desc": ""},
	60000010: {"id": 60000010, "quality": 3, "name": "狂暴之心", "buffId": 90302, "price": 90, "desc": ""},
	60000011: {"id": 60000011, "quality": 3, "name": "钢铁壁垒", "buffId": 90005, "price": 85, "desc": ""},
	60000012: {"id": 60000012, "quality": 3, "name": "元素精通", "buffId": 90053, "price": 100, "desc": ""},
	60000013: {"id": 60000013, "quality": 4, "name": "凤凰之羽", "buffId": 90201, "price": 200, "desc": ""},
	60000014: {"id": 60000014, "quality": 4, "name": "时间掌控者", "buffId": 90303, "price": 180, "desc": ""},
	60000015: {"id": 60000015, "quality": 4, "name": "混沌核心", "buffId": 90202, "price": 250, "desc": ""},
	60000016: {"id": 60000016, "quality": 1, "name": "中性弹药包", "buffId": 90055, "price": 20, "desc": ""},
	60000017: {"id": 60000017, "quality": 2, "name": "通用弹药校准器", "buffId": 90056, "price": 45, "desc": ""},
	60000018: {"id": 60000018, "quality": 3, "name": "元素适配器", "buffId": 90112, "price": 95, "desc": ""},
	60000019: {"id": 60000019, "quality": 4, "name": "全属性核心", "buffId": 90113, "price": 220, "desc": ""},
}

# 旧items配置（兼容）
const items: Dictionary = shopItems.duplicate(true)

# ==============================================
# 商店系统 v1.0
# 对应 GameConsts.MapNodeType.SHOP 节点类型
# ==============================================
const gameShops: Dictionary = {
	60001: {
		"id": 60001, "name": "新手商人", "type": "normal", "tier": 1,
		"itemPool": [60000001, 60000002, 60000003, 60000004, 60000005, 60000016],
		"slotCount": 4, "refreshPrice": 10, "priceMultiplier": 1.0, "refreshCount": 3, "unlockLevel": 1,
	},
	60002: {
		"id": 60002, "name": "神秘商人", "type": "rare", "tier": 2,
		"itemPool": [60000005, 60000006, 60000007, 60000008, 60000009, 60000010, 60000011, 60000012, 60000017],
		"slotCount": 5, "refreshPrice": 25, "priceMultiplier": 1.2, "refreshCount": 2, "unlockLevel": 5,
	},
	60003: {
		"id": 60003, "name": "传奇商人", "type": "legendary", "tier": 3,
		"itemPool": [60000009, 60000010, 60000011, 60000012, 60000013, 60000014, 60000015, 60000018, 60000019],
		"slotCount": 3, "refreshPrice": 50, "priceMultiplier": 1.5, "refreshCount": 1, "unlockLevel": 10,
	},
}

# ---------- 游戏事件配置 ----------
const gameEvents: Dictionary = {
	70001: {
		"id": 70001, "name": "神秘宝箱", "type": "treasure", "tier": 1, "desc": "发现一个神秘的宝箱",
		"rewardPool": [
			{"itemId": 60000001, "chance": 0.4},
			{"itemId": 60000002, "chance": 0.3},
			{"itemId": 60000005, "chance": 0.2},
			{"itemId": 60000006, "chance": 0.1},
		],
	},
	70002: {
		"id": 70002, "name": "治疗泉水", "type": "heal", "tier": 1, "desc": "清澈的泉水可以恢复生命", "healPercent": 0.3,
	},
	70003: {
		"id": 70003, "name": "随机祝福", "type": "buff", "tier": 2, "desc": "获得临时增益效果",
		"buffPool": [
			{"buffId": 90401, "chance": 0.25},
			{"buffId": 90402, "chance": 0.25},
			{"buffId": 90403, "chance": 0.20},
			{"buffId": 90404, "chance": 0.15},
			{"buffId": 90405, "chance": 0.15},
		],
	},
}

# ---------- 休息系统配置 ----------
const gameRests: Dictionary = {
	80001: { "id": 80001, "name": "营火休息点", "type": "heal", "tier": 1, "desc": "可以在这里休息恢复体力，恢复50%生命值", "healPercent": 0.5 },
	80002: { "id": 80002, "name": "武器工匠", "type": "upgrade", "tier": 2, "desc": "可以在这里升级你的发射器等级，发射器等级+1" },
	80003: { "id": 80003, "name": "隐藏宝箱", "type": "reward", "tier": 2, "desc": "发现了一个隐藏的奖励宝箱，随机获得道具" },
}

# ---------- 关卡固定配置（备用，当动态生成失败时使用）----------
const gameLevels: Dictionary = {
	40001: { "id": 40001, "level": 1, "rounds": [50001, 50002], "shops": [], "events": [], "rests": [], "next": [40002], },
	40002: { "id": 40002, "level": 2, "rounds": [], "shops": [60001], "events": [], "rests": [], "next": [40005], },
	40003: { "id": 40003, "level": 1, "rounds": [], "shops": [], "events": [70001], "rests": [], "next": [40004], },
	40004: { "id": 40004, "level": 2, "rounds": [50001, 50002, 50003, 50004], "shops": [], "events": [], "rests": [], "next": [], },
	40005: { "id": 40005, "level": 1, "rounds": [], "shops": [], "events": [70002], "rests": [], "next": [40003], },
}

const gameRounds: Dictionary = {
	50001: { "id": 50001, "step": 30, "orderEnermyPool": [30001], },
	50002: { "id": 50002, "step": 20, "orderEnermyPool": [30002], },
	50003: { "id": 50003, "step": 10, "orderEnermyPool": [30001, 30002], },
	50004: { "id": 50004, "step": 5, "orderEnermyPool": [30001, 30002, 30001, 30002], },
}

const gameStartLevel: Dictionary = {
	1: 40001,
}

# ==============================================
# 10级难度档位系统 v2.0
# 基于normal/hard/expert三条曲线线性插值平滑过渡
# ==============================================
const difficultyProfiles: Dictionary = {
	1:  { "name": "休闲", "curve": "normal", "curveFactor": 0.70, "layerCount": 10, "shopRate": 0.30, "eliteRate": 0.10, "eventRate": 0.25, "restRate": 0.20, "bossFrequency": 8 },
	2:  { "name": "简单", "curve": "normal", "curveFactor": 0.85, "layerCount": 12, "shopRate": 0.28, "eliteRate": 0.15, "eventRate": 0.23, "restRate": 0.18, "bossFrequency": 7 },
	3:  { "name": "普通", "curve": "normal", "curveFactor": 1.00, "layerCount": 14, "shopRate": 0.26, "eliteRate": 0.20, "eventRate": 0.20, "restRate": 0.16, "bossFrequency": 6 },
	4:  { "name": "进阶", "curve": "normal", "curveFactor": 1.15, "layerCount": 15, "shopRate": 0.24, "eliteRate": 0.25, "eventRate": 0.18, "restRate": 0.15, "bossFrequency": 6 },
	5:  { "name": "困难", "curve": "hard",   "curveFactor": 0.85, "layerCount": 16, "shopRate": 0.22, "eliteRate": 0.30, "eventRate": 0.17, "restRate": 0.14, "bossFrequency": 5 },
	6:  { "name": "挑战", "curve": "hard",   "curveFactor": 1.00, "layerCount": 17, "shopRate": 0.20, "eliteRate": 0.35, "eventRate": 0.16, "restRate": 0.13, "bossFrequency": 5 },
	7:  { "name": "高手", "curve": "hard",   "curveFactor": 1.15, "layerCount": 18, "shopRate": 0.18, "eliteRate": 0.40, "eventRate": 0.15, "restRate": 0.12, "bossFrequency": 4 },
	8:  { "name": "专家", "curve": "expert", "curveFactor": 0.85, "layerCount": 19, "shopRate": 0.16, "eliteRate": 0.45, "eventRate": 0.14, "restRate": 0.11, "bossFrequency": 4 },
	9:  { "name": "大师", "curve": "expert", "curveFactor": 1.00, "layerCount": 20, "shopRate": 0.14, "eliteRate": 0.50, "eventRate": 0.13, "restRate": 0.10, "bossFrequency": 3 },
	10: { "name": "地狱", "curve": "expert", "curveFactor": 1.20, "layerCount": 22, "shopRate": 0.12, "eliteRate": 0.60, "eventRate": 0.12, "restRate": 0.08, "bossFrequency": 3 },
}

# ==============================================
# 数值平衡校准完成 v1.1
# ==============================================
