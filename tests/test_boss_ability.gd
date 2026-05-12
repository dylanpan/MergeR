extends GutTest

# ============================================================
# Boss 能力测试
# ============================================================

func test_boss_phase_manager():
	var entity = BaseEntity.new()
	var phase_mgr = PhaseManagerComponent.new()
	entity.add_component(phase_mgr)
	
	var phase_configs = [
		{"phaseId": "phase1", "hpThreshold": 1.0, "skills": [{"skillId": 95001, "priority": 1}]},
		{"phaseId": "phase2", "hpThreshold": 0.5, "skills": [{"skillId": 95002, "priority": 1}]},
	]
	phase_mgr.init(phase_configs, entity.get_id())
	
	assert_eq(phase_mgr.get_current_phase_id(), "phase1", "初始应为 phase1")
	
	phase_mgr.update_phase(0.1, 0.4)
	
	assert_eq(phase_mgr.current_phase_index, 1, "血量低于50%后应切换到 phase2")

func test_boss_skill_cooldown():
	var skill = BossSkillComponent.new(95001, 1)
	assert_true(skill.is_ready(), "初始技能应可用")
	skill.use()
	assert_false(skill.is_ready(), "使用后技能应进入冷却")
	skill.tick()
	skill.tick()
	assert_true(skill.is_ready(), "冷却结束后技能应可用")