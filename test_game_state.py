with open('/Users/zeynepgokmen/Bitirme-Projesi/scripts/GameState.gd', 'r') as f:
    content = f.read()

# Add promotion_intelligence_bought to GameState
if 'var promotion_intelligence_bought' not in content:
    content = content.replace(
        'var promotion_phase_completed: bool = false',
        'var promotion_phase_completed: bool = false\nvar promotion_intelligence_bought: bool = false'
    )
    with open('/Users/zeynepgokmen/Bitirme-Projesi/scripts/GameState.gd', 'w') as f:
        f.write(content)

