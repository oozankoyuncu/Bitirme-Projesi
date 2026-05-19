import re

with open("scripts/GameState.gd", "r") as f:
    content = f.read()

# Add variables
vars_str = """var selected_team: Array = []
var all_team_members: Array = []
var team_motivation: float = 80.0
var skip_onboarding: bool = false

# Work Assignment
var work_assignment_completed: bool = false
var work_assignments: Dictionary = {}  # activity_id -> member_id
var hired_extra_members: Array = []     # 9th+ person hires (scope penalty)
var outsourced_activities: Array = []   # activity IDs outsourced to external
var capacity_boosts: Dictionary = {}    # member_id -> extra capacity added
var work_assignment_scope_penalty: float = 0.0  # score penalty for going out of scope
const HIRE_EXTRA_COST: int = 15000
const OUTSOURCE_COST: int = 10000
const CAPACITY_BOOST_COST: int = 8000
const SCOPE_PENALTY_PER_EXTRA: float = 5.0"""

content = re.sub(r'var selected_team: Array = \[\]\nvar all_team_members: Array = \[\]\nvar team_motivation: float = 80\.0\nvar skip_onboarding: bool = false', vars_str, content)

# Add functions
funcs_str = """func complete_activity(activity_id: String):
	if not completed_activities.has(activity_id):
		completed_activities.append(activity_id)

func finalize_work_assignment(assignments: Dictionary, extra_hires: Array, outsourced: Array, boosts: Dictionary, total_extra_cost: int) -> void:
	work_assignments = assignments.duplicate(true)
	hired_extra_members = extra_hires.duplicate(true)
	outsourced_activities = outsourced.duplicate(true)
	capacity_boosts = boosts.duplicate(true)
	money -= total_extra_cost
	# Scope penalty: each extra hired member costs score points
	work_assignment_scope_penalty = extra_hires.size() * SCOPE_PENALTY_PER_EXTRA
	event_quality_score -= work_assignment_scope_penalty
	work_assignment_completed = true
	complete_activity("work_assignment")

func get_member_assigned_count(member_id: String) -> int:
	var count := 0
	for activity_id in work_assignments:
		if work_assignments[activity_id] == member_id:
			count += 1
	for activity_id in outsourced_activities:
		pass  # outsourced don't count toward member capacity
	return count

func get_effective_capacity(member: Dictionary) -> int:
	var base = int(member.get("workload_capacity", 1))
	var boost = capacity_boosts.get(member["id"], 0)
	return base + boost
"""

content = re.sub(r'func complete_activity\(activity_id: String\):\n\tif not completed_activities\.has\(activity_id\):\n\t\tcompleted_activities\.append\(activity_id\)\n\t\t\n\t\t\n\t\t', funcs_str, content)

with open("scripts/GameState.gd", "w") as f:
    f.write(content)

print("Patched GameState.gd successfully")
