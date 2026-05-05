import re

with open('/Users/zeynepgokmen/Bitirme-Projesi/Game.tscn', 'r') as f:
    content = f.read()

# Make descriptions multi-line and autowrap
import sys

def replace_desc(node_name, new_text):
    global content
    # Find the Desc node for the given KPI
    pattern = r'(\[node name="Desc" type="Label" parent="CharterPanel/MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/' + node_name + r'".*?\ntext = ).*?(?=\n\n\[node|\n\n)'
    
    # We need to correctly handle replacing the text property which might span multiple lines.
    # It's safer to just regex replace the text property string.
    # Let's find the block of the node:
    block_pattern = r'(\[node name="Desc" type="Label" parent="CharterPanel/MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/' + node_name + r'".*?\]\n(?:[^\n]*\n)*?)text = ".*?"'
    
    # Actually, the texts in Game.tscn are sometimes `text = "..."` and sometimes `text = "...\n..."`.
    pass

