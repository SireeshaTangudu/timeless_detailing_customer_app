import re

pbxproj_path = '/Users/linkfields/flutterProjects/timeless_detailing_customer_app/ios/Runner.xcodeproj/project.pbxproj'

with open(pbxproj_path, 'r') as f:
    content = f.read()

config_list_entries = """				E1F2A3B45C6D7E8F90123411 /* Debug-uat */,
				E1F2A3B45C6D7E8F90123412 /* Release-uat */,
				E1F2A3B45C6D7E8F90123413 /* Profile-uat */,
				E1F2A3B45C6D7E8F90123414 /* Debug-prod */,
				E1F2A3B45C6D7E8F90123415 /* Release-prod */,
				E1F2A3B45C6D7E8F90123416 /* Profile-prod */,
"""

target_cfg_match = re.search(r'(97C147051CF9000F007C117D /\* Build configuration list for PBXNativeTarget "Runner" \*/ = \{[\s\S]*?buildConfigurations = \(\n)', content)
if target_cfg_match and 'E1F2A3B45C6D7E8F90123411' not in target_cfg_match.group(0):
    content = content.replace(target_cfg_match.group(1), target_cfg_match.group(1) + config_list_entries)

with open(pbxproj_path, 'w') as f:
    f.write(content)

print("Successfully updated PBXNativeTarget Runner build configuration list!")
