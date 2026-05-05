with open('scripts/charter_panel.gd', 'r') as f:
    content = f.read()

content = content.replace(
    'margin_container.custom_minimum_size = Vector2(1100, 750)',
    'margin_container.custom_minimum_size = Vector2(1100, 950)'
)

with open('scripts/charter_panel.gd', 'w') as f:
    f.write(content)
