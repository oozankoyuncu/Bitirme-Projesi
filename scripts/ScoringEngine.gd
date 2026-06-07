extends RefCounted

# ============================================================================
#  ScoringEngine.gd — Static KPI calculator for the Festival Management Game
#  Usage:  var results = ScoringEngine.calculate_all()
# ============================================================================

# Hardcoded volunteer-club data (mirrors volunteer_club_panel.gd)
const CLUB_DATA := {
	"art_club": {
		"engagement_level": 10,
		"activity_type": "Artistic",
	},
	"esports_club": {
		"engagement_level": 20,
		"activity_type": "Interactive",
	},
	"dance_troupe": {
		"engagement_level": 15,
		"activity_type": "Performance",
	},
	"tech_club": {
		"engagement_level": 5,
		"activity_type": "Informational",
	},
	"sports_team": {
		"engagement_level": 15,
		"activity_type": "Competitive",
	},
}

# Required activity types for Scope Adherence check
const REQUIRED_ACTIVITY_TYPES := ["Competitive", "Artistic", "Informational", "Interactive"]


# ── Main entry point ────────────────────────────────────────────────────────
static func calculate_all() -> Dictionary:
	print("\n========== SCORING ENGINE RESULTS ==========")

	# Pre-compute shared values used by multiple KPIs
	var volunteer_attendance_contribution := _calc_volunteer_attendance_contribution()
	var total_attendance := _calc_total_attendance(volunteer_attendance_contribution)

	var ps := _calculate_ps()
	var eq := _calculate_eq(volunteer_attendance_contribution, total_attendance)
	var sa := _calculate_sa(total_attendance)
	var bc := _calculate_bc()
	var tm := _calculate_tm()
	var sp := _calculate_sp()

	# Overall Festival Success
	var ofs_score: float = 0.6 * ps["score"] + 0.4 * eq["score"]
	var ofs_status := _ofs_status(ofs_score)
	var ofs_feedback := _ofs_feedback(ofs_score)

	print("\n[OFS] = 0.6 × ", ps["score"], " + 0.4 × ", eq["score"], " = ", ofs_score)
	print("[OFS] Status: ", ofs_status)
	print("=========================================\n")

	return {
		"ofs": {"score": ofs_score, "status": ofs_status, "feedback": ofs_feedback},
		"ps": ps,
		"eq": eq,
		"sa": sa,
		"bc": bc,
		"tm": tm,
		"sp": sp,
	}


# ══════════════════════════════════════════════════════════════════════════════
#  KPI 1 — Participant Satisfaction (PS)
# ══════════════════════════════════════════════════════════════════════════════
static func _calculate_ps() -> Dictionary:
	print("\n--- KPI 1: Participant Satisfaction (PS) ---")

	var details: Array = []
	var met_count := 0

	# 1. Entertainment avg popularity > 4
	var ent_avg: float = GameState.get_average_lineup_popularity()
	var ent_met: bool = ent_avg > 4.0
	if ent_met:
		met_count += 1
	print("[PS] Entertainment avg popularity: ", ent_avg, " (Required: > 4) → ", "MET" if ent_met else "NOT MET")
	var ent_feedback := ""
	if ent_met:
		ent_feedback = "Entertainment Line-up: The expected requirement was to have an average popularity level higher than 4. Your selected entertainment line-up had an average popularity level of %s, so this requirement was met." % str(snapped(ent_avg, 0.01))
	else:
		ent_feedback = "Entertainment Line-up: The expected requirement was to have an average popularity level higher than 4. Your selected entertainment line-up had an average popularity level of %s, which was below the required level, so this requirement was not met." % str(snapped(ent_avg, 0.01))
	details.append({"name": "Entertainment Line-up", "requirement": "avg popularity > 4", "value": snapped(ent_avg, 0.01), "met": ent_met, "feedback": ent_feedback})

	# 2. Volunteer avg engagement > 6
	var vol_avg := _calc_volunteer_avg_engagement()
	var vol_met: bool = vol_avg > 6.0
	if vol_met:
		met_count += 1
	print("[PS] Volunteer avg engagement: ", vol_avg, " (Required: > 6) → ", "MET" if vol_met else "NOT MET")
	var vol_feedback := ""
	if vol_met:
		vol_feedback = "Volunteer Engagement: The expected requirement was to have an average engagement level higher than 6. Your selected volunteer clubs had an average engagement level of %s, so this requirement was met." % str(snapped(vol_avg, 0.01))
	else:
		vol_feedback = "Volunteer Engagement: The expected requirement was to have an average engagement level higher than 6. Your selected volunteer clubs had an average engagement level of %s, which was below the required level, so this requirement was not met." % str(snapped(vol_avg, 0.01))
	details.append({"name": "Volunteer Engagement", "requirement": "avg engagement > 6", "value": snapped(vol_avg, 0.01), "met": vol_met, "feedback": vol_feedback})

	# 3. Sound system score > 5
	var snd_val: float = GameState.sound_system_score
	var snd_met: bool = snd_val > 5.0
	if snd_met:
		met_count += 1
	print("[PS] Sound system score: ", snd_val, " (Required: > 5) → ", "MET" if snd_met else "NOT MET")
	var snd_feedback := ""
	if snd_met:
		snd_feedback = "Sound System: The expected requirement was to have a sound system score higher than 5. Your sound system had a score of %s, so this requirement was met." % str(snapped(snd_val, 0.01))
	else:
		snd_feedback = "Sound System: The expected requirement was to have a sound system score higher than 5. Your sound system had a score of %s, which was below the required level, so this requirement was not met." % str(snapped(snd_val, 0.01))
	details.append({"name": "Sound System", "requirement": "score > 5", "value": snapped(snd_val, 0.01), "met": snd_met, "feedback": snd_feedback})

	# 4. Decoration theme score >= 0.5
	var dec_val: float = GameState.decoration_theme_score
	var dec_met: bool = dec_val >= 0.5
	if dec_met:
		met_count += 1
	print("[PS] Decoration theme score: ", dec_val, " (Required: >= 0.5) → ", "MET" if dec_met else "NOT MET")
	var dec_feedback := ""
	if dec_met:
		dec_feedback = "Decoration Theme: The expected requirement was to have a decoration theme score of at least 0.5. Your decoration theme had a score of %s, so this requirement was met." % str(snapped(dec_val, 0.01))
	else:
		dec_feedback = "Decoration Theme: The expected requirement was to have a decoration theme score of at least 0.5. Your decoration theme had a score of %s, which was below the required level, so this requirement was not met." % str(snapped(dec_val, 0.01))
	details.append({"name": "Decoration Theme", "requirement": "score >= 0.5", "value": snapped(dec_val, 0.01), "met": dec_met, "feedback": dec_feedback})

	var score: float = (met_count / 4.0) * 100.0
	var status := _ps_status(met_count)
	var feedback := _ps_feedback(met_count)

	print("[PS] Met: ", met_count, "/4  Score: ", score, "  Status: ", status)

	return {
		"score": score,
		"status": status,
		"feedback": feedback,
		"met_count": met_count,
		"total": 4,
		"details": details,
	}


static func _ps_status(met: int) -> String:
	match met:
		4: return "Excellent"
		3: return "Good"
		2: return "Moderate"
		1: return "Weak"
		_: return "Very Low"


static func _ps_feedback(met: int) -> String:
	match met:
		4: return "Your participant satisfaction performance was excellent. All main satisfaction requirements were met."
		3: return "Your participant satisfaction performance was good, but one area reduced the final score."
		2: return "Your participant satisfaction performance was moderate. Some elements of the festival experience were successful, but several requirements were not met."
		1: return "Your participant satisfaction performance was weak because most satisfaction requirements were not met."
		_: return "Participant satisfaction was very low because none of the main satisfaction requirements were satisfied."


# ══════════════════════════════════════════════════════════════════════════════
#  KPI 2 — Event Quality (EQ)
# ══════════════════════════════════════════════════════════════════════════════
static func _calculate_eq(volunteer_attendance_contribution: int, total_attendance: int) -> Dictionary:
	print("\n--- KPI 2: Event Quality (EQ) ---")

	var ticket_attendance: float = GameState.final_attendance
	var entertainment_attendance: int = GameState.get_total_expected_attendance()

	print("[EQ] Ticket attendance (includes promotion base): ", ticket_attendance)
	print("[EQ] Entertainment attendance: ", entertainment_attendance)
	print("[EQ] Volunteer attendance contribution: ", volunteer_attendance_contribution)
	print("[EQ] Total attendance: ", total_attendance)

	var score: float = min((total_attendance / 5000.0) * 100.0, 100.0)
	var status := _eq_status(total_attendance)
	var feedback := _eq_feedback(total_attendance)

	print("[EQ] Score: ", score, "  Status: ", status)

	return {
		"score": score,
		"status": status,
		"feedback": feedback,
		"total_attendance": total_attendance,
		"breakdown": {
			"ticket": int(ticket_attendance),
			"entertainment": entertainment_attendance,
			"volunteer": volunteer_attendance_contribution,
		},
	}


static func _eq_status(attendance: int) -> String:
	if attendance >= 5000:
		return "Excellent — Target Exceeded"
	elif attendance >= 4000:
		return "Good but Below Target"
	elif attendance >= 2500:
		return "Moderate"
	elif attendance >= 1000:
		return "Weak"
	else:
		return "Very Low"


static func _eq_feedback(attendance: int) -> String:
	if attendance >= 5000:
		return "Your festival exceeded the target attendance of 5000. The combination of ticket sales, entertainment appeal, and volunteer engagement created an outstanding turnout. This is a remarkable achievement."
	elif attendance >= 4000:
		return "Your festival attracted a good crowd but fell short of the 5000 target. With minor improvements to entertainment or promotion strategy, you could have reached the goal."
	elif attendance >= 2500:
		return "Your festival had a moderate turnout. While some elements drew attendees, the overall reach was limited. Stronger entertainment choices or more effective promotion could improve this."
	elif attendance >= 1000:
		return "Your festival had a weak turnout. Attendance was significantly below the target. Major improvements are needed across entertainment, promotion, and volunteer engagement."
	else:
		return "Your festival had a very low turnout. Almost no attendees were attracted. This indicates critical failures in entertainment selection, promotion, and overall festival appeal."


# ══════════════════════════════════════════════════════════════════════════════
#  KPI 3 — Scope Adherence (SA)
# ══════════════════════════════════════════════════════════════════════════════
static func _calculate_sa(total_attendance: int) -> Dictionary:
	print("\n--- KPI 3: Scope Adherence (SA) ---")

	var details: Array = []
	var met_count := 0

	# 1. Team avg performance > 2.5
	var team_avg := _calc_team_avg_performance()
	var team_met: bool = team_avg > 2.5
	if team_met:
		met_count += 1
	print("[SA] Team avg performance: ", team_avg, " (Required: > 2.5) → ", "MET" if team_met else "NOT MET")
	details.append({"name": "Team Performance", "requirement": "avg skill > 2.5", "value": str(snapped(team_avg, 0.01)), "met": team_met, "feedback": "Team average performance was %s." % str(snapped(team_avg, 0.01))})

	# 2. >= 2 sponsors
	var sponsor_count: int = GameState.accepted_sponsors.size()
	var sponsor_count_met: bool = sponsor_count >= 2
	if sponsor_count_met:
		met_count += 1
	print("[SA] Accepted sponsors: ", sponsor_count, " (Required: >= 2) → ", "MET" if sponsor_count_met else "NOT MET")
	details.append({"name": "Sponsor Count", "requirement": ">= 2 sponsors", "value": str(sponsor_count), "met": sponsor_count_met, "feedback": "You accepted %d sponsor(s)." % sponsor_count})

	# 3. Avg sponsor score > 2.5
	var sponsor_avg := _calc_avg_sponsor_score()
	var sponsor_avg_met: bool = sponsor_avg > 2.5
	if sponsor_avg_met:
		met_count += 1
	print("[SA] Avg sponsor score: ", sponsor_avg, " (Required: > 2.5) → ", "MET" if sponsor_avg_met else "NOT MET")
	details.append({"name": "Sponsor Quality", "requirement": "avg score > 2.5", "value": str(snapped(sponsor_avg, 0.01)), "met": sponsor_avg_met, "feedback": "Average sponsor score was %s." % str(snapped(sponsor_avg, 0.01))})

	# 4. Sponsor budget contribution >= 200000
	var sponsor_income := _calc_total_sponsor_income()
	var sponsor_budget_met: bool = sponsor_income >= 200000
	if sponsor_budget_met:
		met_count += 1
	print("[SA] Sponsor income: ", sponsor_income, " (Required: >= 200000) → ", "MET" if sponsor_budget_met else "NOT MET")
	details.append({"name": "Sponsor Budget", "requirement": ">= 200,000 TL", "value": str(sponsor_income), "met": sponsor_budget_met, "feedback": "Total sponsor income was %d TL." % sponsor_income})

	# 5. Attendance >= 3000
	var att_met: bool = total_attendance >= 3000
	if att_met:
		met_count += 1
	print("[SA] Total attendance: ", total_attendance, " (Required: >= 3000) → ", "MET" if att_met else "NOT MET")
	details.append({"name": "Attendance Target", "requirement": ">= 3000", "value": str(total_attendance), "met": att_met, "feedback": "Total attendance was %d." % total_attendance})

	# 6. Entertainment avg popularity > 3
	var ent_avg: float = GameState.get_average_lineup_popularity()
	var ent_met: bool = ent_avg > 3.0
	if ent_met:
		met_count += 1
	print("[SA] Entertainment avg popularity: ", ent_avg, " (Required: > 3) → ", "MET" if ent_met else "NOT MET")
	details.append({"name": "Entertainment Popularity", "requirement": "avg popularity > 3", "value": str(snapped(ent_avg, 0.01)), "met": ent_met, "feedback": "Entertainment average popularity was %s." % str(snapped(ent_avg, 0.01))})

	# 7. At least 1 headliner + 2 supporting
	var hl: int = GameState.selected_headliners.size()
	var sa_count: int = GameState.selected_supporting_artists.size()
	var lineup_met: bool = hl >= 1 and sa_count >= 2
	if lineup_met:
		met_count += 1
	print("[SA] Headliners: ", hl, ", Supporting: ", sa_count, " (Required: >= 1 HL + >= 2 SA) → ", "MET" if lineup_met else "NOT MET")
	details.append({"name": "Lineup Composition", "requirement": ">= 1 headliner + >= 2 supporting", "value": "%d HL + %d SA" % [hl, sa_count], "met": lineup_met, "feedback": "Lineup has %d headliner(s) and %d supporting artist(s)." % [hl, sa_count]})

	# 8. Activity types covered (at least 3 of 4 required types)
	var covered_types := _get_covered_activity_types()
	var types_covered_count := 0
	for req_type in REQUIRED_ACTIVITY_TYPES:
		if req_type in covered_types:
			types_covered_count += 1
	var types_met: bool = types_covered_count >= 3
	if types_met:
		met_count += 1
	print("[SA] Activity types covered: ", types_covered_count, "/4 (Required: >= 3) → ", "MET" if types_met else "NOT MET")
	details.append({"name": "Activity Diversity", "requirement": ">= 3 of 4 activity types", "value": str(types_covered_count) + "/4", "met": types_met, "feedback": "Covered %d out of 4 required activity types." % types_covered_count})

	# 9. At least 3 clubs selected
	var club_count: int = GameState.selected_volunteer_clubs.size()
	var clubs_met: bool = club_count >= 3
	if clubs_met:
		met_count += 1
	print("[SA] Volunteer clubs: ", club_count, " (Required: >= 3) → ", "MET" if clubs_met else "NOT MET")
	details.append({"name": "Volunteer Clubs Count", "requirement": ">= 3 clubs", "value": str(club_count), "met": clubs_met, "feedback": "Selected %d volunteer club(s)." % club_count})

	# 10. Cuisine types >= 3
	var cuisine_types := _count_cuisine_types()
	var cuisine_met: bool = cuisine_types >= 3
	if cuisine_met:
		met_count += 1
	print("[SA] Cuisine types: ", cuisine_types, " (Required: >= 3) → ", "MET" if cuisine_met else "NOT MET")
	details.append({"name": "Cuisine Diversity", "requirement": ">= 3 cuisine types", "value": str(cuisine_types), "met": cuisine_met, "feedback": "Offered %d different cuisine type(s)." % cuisine_types})

	# 11. Avg hygiene > 2.5
	var hygiene: float = GameState.average_hygiene
	var hygiene_met: bool = hygiene > 2.5
	if hygiene_met:
		met_count += 1
	print("[SA] Avg hygiene: ", hygiene, " (Required: > 2.5) → ", "MET" if hygiene_met else "NOT MET")
	details.append({"name": "Hygiene Standards", "requirement": "avg hygiene > 2.5", "value": str(snapped(hygiene, 0.01)), "met": hygiene_met, "feedback": "Average hygiene score was %s." % str(snapped(hygiene, 0.01))})

	# 12. At least 1 cleaning + 1 security
	var cl_count: int = GameState.selected_cleaning_teams.size()
	var sec_count: int = GameState.selected_security_teams.size()
	var cs_met: bool = cl_count >= 1 and sec_count >= 1
	if cs_met:
		met_count += 1
	print("[SA] Cleaning teams: ", cl_count, ", Security teams: ", sec_count, " (Required: >= 1 each) → ", "MET" if cs_met else "NOT MET")
	details.append({"name": "Cleaning & Security", "requirement": ">= 1 cleaning + >= 1 security", "value": "%d cleaning + %d security" % [cl_count, sec_count], "met": cs_met, "feedback": "Selected %d cleaning team(s) and %d security team(s)." % [cl_count, sec_count]})

	var score: float = (met_count / 12.0) * 100.0
	var status := _sa_status(met_count)
	var feedback := _sa_feedback(met_count)

	print("[SA] Met: ", met_count, "/12  Score: ", score, "  Status: ", status)

	return {
		"score": score,
		"status": status,
		"feedback": feedback,
		"met_count": met_count,
		"total": 12,
		"details": details,
	}


static func _sa_status(met: int) -> String:
	if met == 12:
		return "Excellent — Full Scope Completed"
	elif met >= 10:
		return "Good — Minor Scope Gaps"
	elif met >= 6:
		return "Moderate — Partial Scope Completion"
	elif met >= 3:
		return "Weak — Major Scope Gaps"
	else:
		return "Very Low — Scope Not Completed"


static func _sa_feedback(met: int) -> String:
	if met == 12:
		return "All scope requirements were fully met. Your festival planning covered every expected area comprehensively. This is an outstanding achievement."
	elif met >= 10:
		return "Your scope adherence was good with only minor gaps. Most planning areas were completed successfully, but a few requirements were missed."
	elif met >= 6:
		return "Your scope adherence was moderate. While several planning areas were addressed, a significant number of requirements remain unmet, limiting the festival's completeness."
	elif met >= 3:
		return "Your scope adherence was weak with major gaps. Most planning requirements were not fulfilled, leaving large portions of the festival inadequately prepared."
	else:
		return "Scope adherence was very low. Nearly all planning requirements were missed, indicating the festival was not adequately planned."


# ══════════════════════════════════════════════════════════════════════════════
#  KPI 4 — Budget Control (BC)
# ══════════════════════════════════════════════════════════════════════════════
static func _calculate_bc() -> Dictionary:
	print("\n--- KPI 4: Budget Control (BC) ---")

	var final_budget: int = GameState.money
	print("[BC] Final budget: ", final_budget, " TL")

	# Score calculation
	var score: float
	if final_budget >= 400000:
		score = 100.0
	elif final_budget <= -300000:
		score = 0.0
	else:
		score = (final_budget + 300000.0) / 700000.0 * 100.0

	var status := _bc_status(final_budget)
	var feedback := _bc_feedback(final_budget)

	# Income breakdown
	var incomes: Array = []
	var sponsor_income := _calc_total_sponsor_income()
	incomes.append({"name": "Sponsor Income", "amount": sponsor_income})
	var ticket_revenue: int = int(GameState.total_revenue)
	incomes.append({"name": "Ticket Revenue", "amount": ticket_revenue})
	var food_vendor_income: int = GameState.total_food_cost
	incomes.append({"name": "Food Vendor Income", "amount": food_vendor_income})

	print("[BC] Sponsor Income: ", sponsor_income)
	print("[BC] Ticket Revenue: ", ticket_revenue)
	print("[BC] Food Vendor Income: ", food_vendor_income)

	# Cost breakdown
	var costs: Array = []
	var entertainment_cost: int = GameState.get_total_lineup_cost()
	costs.append({"name": "Entertainment Cost", "amount": entertainment_cost})
	var stage_cost: int = GameState.selected_stage_setup.get("cost", 0)
	costs.append({"name": "Stage Cost", "amount": stage_cost})
	var sound_cost: int = GameState.selected_sound_system.get("cost", 0)
	costs.append({"name": "Sound System Cost", "amount": sound_cost})
	var decoration_cost: int = GameState.selected_decoration_theme.get("cost", 0)
	costs.append({"name": "Decoration Cost", "amount": decoration_cost})
	var cs_cost := _calc_cleaning_security_cost()
	costs.append({"name": "Cleaning & Security Cost", "amount": cs_cost})

	print("[BC] Entertainment Cost: ", entertainment_cost)
	print("[BC] Stage Cost: ", stage_cost)
	print("[BC] Sound System Cost: ", sound_cost)
	print("[BC] Decoration Cost: ", decoration_cost)
	print("[BC] Cleaning & Security Cost: ", cs_cost)
	print("[BC] Score: ", score, "  Status: ", status)

	return {
		"score": score,
		"status": status,
		"feedback": feedback,
		"final_budget": final_budget,
		"incomes": incomes,
		"costs": costs,
	}


static func _bc_status(budget: int) -> String:
	if budget >= 400000:
		return "Excellent — Budget Surplus"
	elif budget >= 200000:
		return "Strong Budget Control"
	elif budget >= 0:
		return "Acceptable but Limited Budget"
	elif budget >= -150000:
		return "Risky Budget Performance"
	elif budget >= -300000:
		return "Critical Budget Performance"
	else:
		return "Budget Failure"


static func _bc_feedback(budget: int) -> String:
	if budget >= 400000:
		return "Your budget management was excellent. You maintained a healthy surplus while delivering a full festival experience. This demonstrates strong financial planning."
	elif budget >= 200000:
		return "Your budget control was strong. You managed to keep a positive balance with reasonable spending. There is room for more investment in future editions."
	elif budget >= 0:
		return "Your budget was acceptable but limited. While you avoided debt, the remaining balance is thin and leaves little room for unexpected costs."
	elif budget >= -150000:
		return "Your budget performance was risky. You ended in debt, which may create financial difficulties. Cost optimization is needed in several areas."
	elif budget >= -300000:
		return "Your budget performance was critical. The festival ended with significant debt that approaches the university's tolerance limit. Immediate corrective action is required."
	else:
		return "Budget failure. The festival exceeded the university's maximum debt limit of -300,000 TL. This level of financial loss is unacceptable and would result in serious consequences."


# ══════════════════════════════════════════════════════════════════════════════
#  KPI 5 — Time Management (TM)
# ══════════════════════════════════════════════════════════════════════════════
static func _calculate_tm() -> Dictionary:
	print("\n--- KPI 5: Time Management (TM) ---")

	var completed := 0
	for act in GameState.activities:
		if GameState.completed_activities.has(act["id"]):
			completed += 1
	var total_activities: int = GameState.activities.size()

	var score: float = 0.0
	if total_activities > 0:
		score = (completed / float(total_activities)) * 100.0

	var status := _tm_status(score)
	var feedback := _tm_feedback(score)

	print("[TM] Completed: ", completed, "/", total_activities, "  Score: ", score, "  Status: ", status)

	return {
		"score": score,
		"status": status,
		"feedback": feedback,
	}


static func _tm_status(score: float) -> String:
	if score >= 90.0:
		return "Excellent"
	elif score >= 70.0:
		return "Good"
	elif score >= 50.0:
		return "Moderate"
	else:
		return "Weak"


static func _tm_feedback(score: float) -> String:
	if score >= 90.0:
		return "Your time management was excellent. Nearly all activities were completed on time, showing strong organizational skills and effective prioritization."
	elif score >= 70.0:
		return "Your time management was good. Most activities were completed, but some were left unfinished. Better prioritization could improve results."
	elif score >= 50.0:
		return "Your time management was moderate. A significant portion of activities were not completed, indicating issues with planning or time allocation."
	else:
		return "Your time management was weak. Most activities were not completed, suggesting serious difficulties with organization and time allocation."


# ══════════════════════════════════════════════════════════════════════════════
#  KPI 6 — Scenario Preparedness (SP)
# ══════════════════════════════════════════════════════════════════════════════
static func _calculate_sp() -> Dictionary:
	print("\n--- KPI 6: Scenario Preparedness (SP) ---")

	var trained_count := 0
	var team_size: int = GameState.selected_team.size()

	for member in GameState.selected_team:
		var has_training := false
		if member.get("fire_safety", 0) == 1:
			has_training = true
		if member.get("first_aid", 0) == 1:
			has_training = true
		if member.get("crowd_control", 0) == 1:
			has_training = true
		if has_training:
			trained_count += 1

	var score: float = min((trained_count / float(max(team_size, 1))) * 100.0, 100.0)
	var status := _sp_status(score)
	var feedback := _sp_feedback(score)

	print("[SP] Trained members: ", trained_count, "/", team_size, "  Score: ", score, "  Status: ", status)

	return {
		"score": score,
		"status": status,
		"feedback": feedback,
	}


static func _sp_status(score: float) -> String:
	if score >= 90.0:
		return "Excellent"
	elif score >= 70.0:
		return "Good"
	elif score >= 50.0:
		return "Moderate"
	else:
		return "Weak"


static func _sp_feedback(score: float) -> String:
	if score >= 90.0:
		return "Your scenario preparedness was excellent. Nearly all team members received emergency training, ensuring the festival is well-prepared for any incident."
	elif score >= 70.0:
		return "Your scenario preparedness was good. Most team members are trained, but some gaps remain that could be problematic in an emergency."
	elif score >= 50.0:
		return "Your scenario preparedness was moderate. Only about half of the team is trained for emergencies, which could lead to slow or inadequate response."
	else:
		return "Your scenario preparedness was weak. Very few team members have emergency training, putting attendees and staff at risk during incidents."


# ══════════════════════════════════════════════════════════════════════════════
#  Overall Festival Success helpers
# ══════════════════════════════════════════════════════════════════════════════
static func _ofs_status(score: float) -> String:
	if score >= 90.0:
		return "Outstanding Festival"
	elif score >= 75.0:
		return "Successful Festival"
	elif score >= 50.0:
		return "Moderate Festival"
	elif score >= 25.0:
		return "Weak Festival"
	else:
		return "Failed Festival"


static func _ofs_feedback(score: float) -> String:
	if score >= 90.0:
		return "Your festival was outstanding! Both participant satisfaction and event quality were exceptional, creating a memorable experience for everyone."
	elif score >= 75.0:
		return "Your festival was successful. Participants were generally satisfied and the event quality was good, though there is room for improvement."
	elif score >= 50.0:
		return "Your festival had moderate success. Some areas performed well while others need significant improvement for future editions."
	elif score >= 25.0:
		return "Your festival was weak overall. Both participant satisfaction and event quality fell below expectations, requiring major changes."
	else:
		return "Your festival failed to meet minimum standards. Critical improvements are needed across all areas of planning and execution."


# ══════════════════════════════════════════════════════════════════════════════
#  Shared helper functions
# ══════════════════════════════════════════════════════════════════════════════

# Volunteer average engagement (used by PS and elsewhere)
static func _calc_volunteer_avg_engagement() -> float:
	var clubs: Array = GameState.selected_volunteer_clubs
	if clubs.is_empty():
		return 0.0
	var total := 0.0
	for club_id in clubs:
		if CLUB_DATA.has(club_id):
			total += CLUB_DATA[club_id]["engagement_level"]
	return total / clubs.size()


# Volunteer attendance contribution (engagement_level * 10 per selected club)
static func _calc_volunteer_attendance_contribution() -> int:
	var total := 0
	for club_id in GameState.selected_volunteer_clubs:
		if CLUB_DATA.has(club_id):
			total += CLUB_DATA[club_id]["engagement_level"] * 10
	return total


# Total attendance used by EQ and SA
static func _calc_total_attendance(volunteer_contribution: int) -> int:
	var ticket: float = GameState.final_attendance
	var entertainment: int = GameState.get_total_expected_attendance()
	return int(ticket) + entertainment + volunteer_contribution


# Team average performance across all skills
static func _calc_team_avg_performance() -> float:
	var team: Array = GameState.selected_team
	if team.is_empty():
		return 0.0

	var skill_keys := ["planning", "communication", "leadership", "technical", "creativity"]
	var total := 0.0
	var count := 0

	for member in team:
		for key in skill_keys:
			if member.has(key):
				total += float(member[key])
				count += 1

	if count == 0:
		return 0.0
	return total / count


# Average sponsor score from sponsors.json for accepted sponsors
static func _calc_avg_sponsor_score() -> float:
	var accepted: Array = GameState.accepted_sponsors
	if accepted.is_empty():
		return 0.0

	var sponsor_data := _load_sponsor_data()
	if sponsor_data.is_empty():
		return 0.0

	var total := 0.0
	var count := 0
	for sponsor_id in accepted:
		if sponsor_data.has(sponsor_id):
			total += float(sponsor_data[sponsor_id]["sponsor_score"])
			count += 1

	if count == 0:
		return 0.0
	return total / count


# Total sponsor income from sponsors.json for accepted sponsors
static func _calc_total_sponsor_income() -> int:
	var accepted: Array = GameState.accepted_sponsors
	if accepted.is_empty():
		return 0

	var sponsor_data := _load_sponsor_data()
	if sponsor_data.is_empty():
		return 0

	var total := 0
	for sponsor_id in accepted:
		if sponsor_data.has(sponsor_id):
			total += int(sponsor_data[sponsor_id]["price"])
	return total


# Load sponsor definitions from JSON
static func _load_sponsor_data() -> Dictionary:
	var file = FileAccess.open("res://data/sponsors.json", FileAccess.READ)
	if file == null:
		print("[ScoringEngine] WARNING: Could not open sponsors.json")
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if data == null or not data.has("sponsors"):
		print("[ScoringEngine] WARNING: Could not parse sponsors.json")
		return {}
	return data["sponsors"]


# Load cleaning & security definitions from JSON
static func _load_cleaning_security_data() -> Dictionary:
	var file = FileAccess.open("res://data/cleaning_security.json", FileAccess.READ)
	if file == null:
		print("[ScoringEngine] WARNING: Could not open cleaning_security.json")
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		print("[ScoringEngine] WARNING: Could not parse cleaning_security.json")
		return {}
	return data


# Cleaning & security total cost for selected teams
static func _calc_cleaning_security_cost() -> int:
	var cs_data := _load_cleaning_security_data()
	if cs_data.is_empty():
		return 0

	var total := 0
	var cleaning_defs: Dictionary = cs_data.get("cleaning_crews", {})
	var security_defs: Dictionary = cs_data.get("security_teams", {})

	for team_id in GameState.selected_cleaning_teams:
		if cleaning_defs.has(team_id):
			total += int(cleaning_defs[team_id]["cost"])

	for team_id in GameState.selected_security_teams:
		if security_defs.has(team_id):
			total += int(security_defs[team_id]["cost"])

	return total


# Get covered activity types from selected volunteer clubs
static func _get_covered_activity_types() -> Array:
	var types: Array = []
	for club_id in GameState.selected_volunteer_clubs:
		if CLUB_DATA.has(club_id):
			var activity_type: String = CLUB_DATA[club_id]["activity_type"]
			if not types.has(activity_type):
				types.append(activity_type)
	return types


# Count distinct cuisine types from selected food vendors
static func _count_cuisine_types() -> int:
	var vendor_data := _load_food_vendor_data()
	var types: Array = []
	for vendor_id in GameState.selected_food_vendors:
		if vendor_data.has(vendor_id):
			var cuisine: String = vendor_data[vendor_id].get("cuisine_type", "")
			if cuisine != "" and not types.has(cuisine):
				types.append(cuisine)
	return types.size()


# Load food vendor definitions from JSON
static func _load_food_vendor_data() -> Dictionary:
	var file = FileAccess.open("res://data/food_vendors.json", FileAccess.READ)
	if file == null:
		print("[ScoringEngine] WARNING: Could not open food_vendors.json")
		return {}
	var data = JSON.parse_string(file.get_as_text())
	if data == null or not data.has("food_vendors"):
		print("[ScoringEngine] WARNING: Could not parse food_vendors.json")
		return {}
	return data["food_vendors"]
