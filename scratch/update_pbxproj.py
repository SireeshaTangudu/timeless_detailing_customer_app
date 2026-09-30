import re

pbxproj_path = '/Users/linkfields/flutterProjects/timeless_detailing_customer_app/ios/Runner.xcodeproj/project.pbxproj'

with open(pbxproj_path, 'r') as f:
    content = f.read()

# 1. PBXBuildFile section
build_file_entry = '		A1B2C3D42E5F678900112233 /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = A1B2C3D42E5F678900112234 /* GoogleService-Info.plist */; };\n'
if 'A1B2C3D42E5F678900112233' not in content:
    content = content.replace('/* Begin PBXBuildFile section */\n', '/* Begin PBXBuildFile section */\n' + build_file_entry)

# 2. PBXFileReference section
file_ref_entries = (
    '		A1B2C3D42E5F678900112234 /* GoogleService-Info.plist */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; path = "GoogleService-Info.plist"; sourceTree = "<group>"; };\n'
    '		B1C2D3E45F67890102132435 /* Runner.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Runner.entitlements; sourceTree = "<group>"; };\n'
)
if 'A1B2C3D42E5F678900112234' not in content:
    content = content.replace('/* Begin PBXFileReference section */\n', '/* Begin PBXFileReference section */\n' + file_ref_entries)

# 3. Runner group children
group_children_entries = (
    '				A1B2C3D42E5F678900112234 /* GoogleService-Info.plist */,\n'
    '				B1C2D3E45F67890102132435 /* Runner.entitlements */,\n'
)
runner_group_match = re.search(r'(97C146F01CF9000F007C117D /\* Runner \*/ = \{[\s\S]*?children = \(\n)', content)
if runner_group_match and 'A1B2C3D42E5F678900112234' not in runner_group_match.group(0):
    content = content.replace(runner_group_match.group(1), runner_group_match.group(1) + group_children_entries)

# 4. Resources build phase
res_phase_entry = '				A1B2C3D42E5F678900112233 /* GoogleService-Info.plist in Resources */,\n'
res_phase_match = re.search(r'(97C146EC1CF9000F007C117D /\* Resources \*/ = \{[\s\S]*?files = \(\n)', content)
if res_phase_match and 'A1B2C3D42E5F678900112233' not in res_phase_match.group(0):
    content = content.replace(res_phase_match.group(1), res_phase_match.group(1) + res_phase_entry)

# 5. Add CODE_SIGN_ENTITLEMENTS to target build configurations
for config_id in ['97C147061CF9000F007C117D', '97C147071CF9000F007C117D', '249021D4217E4FDB00AE95B9']:
    target_str = config_id + ' /*'
    idx = content.find(target_str)
    if idx != -1:
        bs_idx = content.find('buildSettings = {\n', idx)
        if bs_idx != -1 and bs_idx - idx < 200:
            insert_pos = bs_idx + len('buildSettings = {\n')
            # Check if already added
            if 'CODE_SIGN_ENTITLEMENTS' not in content[idx:idx+500]:
                content = content[:insert_pos] + '				CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n' + content[insert_pos:]

with open(pbxproj_path, 'w') as f:
    f.write(content)

print("Successfully updated project.pbxproj!")
