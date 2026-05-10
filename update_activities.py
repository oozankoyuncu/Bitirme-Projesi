import json

with open('/Users/zeynepgokmen/Bitirme-Projesi/data/activities.json', 'r') as f:
    data = json.load(f)

data['activities'].append({
    "id": "festival_day",
    "name": "Festival Day",
    "type": "festival_day",
    "cost": 0,
    "duration": 0,
    "dependencies": [
        "final_festival_layout_mapping"
    ]
})

with open('/Users/zeynepgokmen/Bitirme-Projesi/data/activities.json', 'w') as f:
    json.dump(data, f, indent=4)
