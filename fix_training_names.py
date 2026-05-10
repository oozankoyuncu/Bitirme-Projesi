with open('scripts/festival_day_panel.gd', 'r') as f:
    content = f.read()

content = content.replace('"training_type": "technical_training"', '"training_type": "electrical_failure_response"')
content = content.replace('"training_type": "crowd_control_training"', '"training_type": "crowd_control"')
content = content.replace('"training_type": "first_aid_training"', '"training_type": "medical_first_response"')
content = content.replace('"training_type": "crisis_communication_training"', '"training_type": "crisis_management"')

with open('scripts/festival_day_panel.gd', 'w') as f:
    f.write(content)

