import re

with open('/Users/zeynepgokmen/Bitirme-Projesi/scripts/festival_day_panel.gd', 'r') as f:
    content = f.read()

# Add a festival_score variable in GameState via festival_day_panel
# Actually, I should just print the score for now and add it to GameState.event_quality_score or a new variable.

content = content.replace('sc["active"] = true', 'sc["active"] = true\n\t\tsc["start_time"] = GameState.game_seconds')

resolve_func = """func _resolve_assignment(sc: Dictionary) -> void:
	sc["completed"] = true
	detail_panel.hide()
	
	var time_taken = max(1.0, GameState.game_seconds - sc.get("start_time", GameState.game_seconds))
	var time_score = clamp(1.0 / time_taken, 0.0, 1.0)
	
	var training_match = 0.0
	var assigned_count = sc["assigned"].size()
	if assigned_count > 0:
		var trained_members = 0
		for member_id in sc["assigned"]:
			for m in GameState.selected_team:
				if m["id"] == member_id:
					if m.get(sc["training_type"], 0) > 0:
						trained_members += 1
		training_match = float(trained_members) / float(assigned_count)
	
	var ratio = float(assigned_count) / float(sc["required_members"]) if sc["required_members"] > 0 else 1.0
	var score = (training_match * 0.5) + (time_score * 0.3) + (clamp(ratio, 0.0, 1.0) * 0.2)
	
	GameState.event_quality_score += score * 10.0 # scale up for overall score
	print("Scenario resolved: ", sc["id"], " Score: ", score)
	
	refresh_scenarios_list()"""

content = re.sub(r'func _resolve_assignment.*?refresh_scenarios_list\(\)', resolve_func, content, flags=re.DOTALL)


decision_func = """func _make_decision(sc: Dictionary, opt: Dictionary) -> void:
	if GameState.money >= opt["cost"]:
		GameState.money -= opt["cost"]
		sc["completed"] = true
		detail_panel.hide()
		
		var score = 0.0
		if sc["id"] == "stage_delivery_accident":
			var decision_quality = 1.0 if opt["cost"] > 0 else 0.5
			var delay_impact = 1.0 if opt["cost"] > 0 else 5.0
			score = (decision_quality * 0.6) + ((1.0 / delay_impact) * 0.4)
		elif sc["id"] == "team_motivation_drop":
			var decision_quality = 0.8
			if opt["cost"] > 0: decision_quality = 1.0
			var team_mot = GameState.team_motivation / 100.0
			var op_eff = 0.8
			score = (decision_quality * 0.5) + (team_mot * 0.3) + (op_eff * 0.2)
			
		GameState.event_quality_score += score * 10.0
		print("Decision made: ", sc["id"], " Score: ", score)
		
		refresh_scenarios_list()
	else:
		print("Not enough money!")"""

content = re.sub(r'func _make_decision.*?print\("Not enough money!"\)', decision_func, content, flags=re.DOTALL)

with open('/Users/zeynepgokmen/Bitirme-Projesi/scripts/festival_day_panel.gd', 'w') as f:
    f.write(content)

