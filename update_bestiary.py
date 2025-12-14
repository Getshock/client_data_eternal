import re
import os
import xml.etree.ElementTree as ET

# Paths
BASE_MONSTER_PATH = r"\\wsl.localhost\Debian\home\Getshock\Get_OT\data\monster"
CONFIG_FILE = "bestiary_config_temp.lua"
MONSTERS_XML = "monsters_temp.xml"
OUTPUT_FILE = "bestiary_config_new.lua"

def get_monsters_map():
    """Maps monster name to file path from monsters.xml"""
    monster_files = {}
    try:
        tree = ET.parse(MONSTERS_XML)
        root = tree.getroot()
        for monster in root.findall('monster'):
            name = monster.get('name')
            file_path = monster.get('file')
            if name and file_path:
                monster_files[name.lower()] = file_path
    except Exception as e:
        print(f"Error parsing monsters.xml: {e}")
    return monster_files

def get_look_type(file_path):
    """Reads the monster XML and extracts look attributes"""
    full_path = os.path.join(BASE_MONSTER_PATH, file_path)
    try:
        # Check if file exists
        if not os.path.exists(full_path):
            print(f"Warning: File not found: {full_path}")
            return None

        tree = ET.parse(full_path)
        root = tree.getroot()
        look = root.find('look')
        if look is not None:
            return {
                'type': look.get('type'),
                'head': look.get('head'),
                'body': look.get('body'),
                'legs': look.get('legs'),
                'feet': look.get('feet'),
                'addons': look.get('addons'),
                'corpse': look.get('corpse') # Not used but good to know
            }
    except Exception as e:
        print(f"Error parsing {full_path}: {e}")
    return None

def update_config():
    monster_map = get_monsters_map()
    
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find monster entries in Lua table
    # Pattern looks for: monsterName = "Name",
    # We will insert lookType after that line
    
    # We iterate line by line to be safer
    lines = content.split('\n')
    new_lines = []
    
    current_monster_name = None
    
    for line in lines:
        new_lines.append(line)
        
        # Check if this line defines a monsterName
        match = re.search(r'monsterName\s*=\s*"(.*)"', line)
        if match:
            monster_name = match.group(1)
            lower_name = monster_name.lower()
            
            if lower_name in monster_map:
                file_path = monster_map[lower_name]
                look_data = get_look_type(file_path)
                
                if look_data and look_data.get('type'):
                    indent = line[:line.find('monsterName')]
                    look_str = f"{indent}lookType = {look_data['type']},"
                    new_lines.append(look_str)
                    
                    if look_data.get('head'): new_lines.append(f"{indent}lookHead = {look_data['head']},")
                    if look_data.get('body'): new_lines.append(f"{indent}lookBody = {look_data['body']},")
                    if look_data.get('legs'): new_lines.append(f"{indent}lookLegs = {look_data['legs']},")
                    if look_data.get('feet'): new_lines.append(f"{indent}lookFeet = {look_data['feet']},")
                    if look_data.get('addons'): new_lines.append(f"{indent}lookAddons = {look_data['addons']},")
                    
                    print(f"Updated {monster_name} with lookType {look_data['type']}")
                else:
                    print(f"Could not find look data for {monster_name}")
            else:
                print(f"Monster {monster_name} not found in monsters.xml map")

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lines))
    
    print("Done!")

if __name__ == "__main__":
    update_config()
