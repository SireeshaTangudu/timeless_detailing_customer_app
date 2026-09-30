import re

pbxproj = '/Users/linkfields/flutterProjects/timeless_detailing_customer_app/ios/Runner.xcodeproj/project.pbxproj'
with open(pbxproj, 'r') as f:
    content = f.read()

# Step 1: Remove the incorrectly-placed attributes block from PBXNativeTarget Runner entry.
# It currently looks like:
#   97C146ED1CF9000F007C117D /* Runner */ = {
#       attributes = {
#               LastSwiftMigration = 1100;
#               SystemCapabilities = {
#                       com.apple.Push = {
#                               enabled = 1;
#                       };
#               };
#       };
#       isa = PBXNativeTarget;
#       ...
# We need to REMOVE that attributes = {...}; block from the PBXNativeTarget.
native_attr_re = re.compile(
    r'attributes = \{\s*LastSwiftMigration = 1100;\s*SystemCapabilities = \{\s*com\.apple\.Push = \{\s*enabled = 1;\s*\};\s*\};\s*\};\s*\n',
    re.MULTILINE | re.DOTALL
)
new_content, removed = native_attr_re.subn('', content, count=1)
print(f"Removed misplaced PBXNativeTarget attributes: {removed}")

# Step 2: Find the PBXProject object's targetAttributes dict and inject the correct entry there.
# The Runner target UUID we know:
runner_uuid = '97C146ED1CF9000F007C117D'

# First find if targetAttributes already has an entry for runner_uuid with attributes.
# We look for: runner_uuid /* Runner */ = { buildConfigurationList = ... ; } ; inside targetAttributes.
runner_entry_in_targetattrs_re = re.compile(
    r'(' + re.escape(runner_uuid) + r' /\* Runner \*/ = \{)(\s*buildConfigurationList = [^;]+;)(\s*\};)',
    re.DOTALL
)
m = runner_entry_in_targetattrs_re.search(new_content)
if m:
    if 'SystemCapabilities' not in new_content:
        attrs_block = '''
			attributes = {
				LastSwiftMigration = 1100;
				SystemCapabilities = {
					com.apple.Push = {
						enabled = 1;
					};
				};
			};'''
        replacement = m.group(1) + attrs_block + m.group(2) + m.group(3)
        new_content = new_content[:m.start()] + replacement + new_content[m.end():]
        print("[OK] SystemCapabilities correctly injected into PBXProject.targetAttributes[Runner].attributes")
    else:
        print("[INFO] SystemCapabilities already present in targetAttributes.")
else:
    # Alternative: find targetAttributes dict and append the runner entry with attributes.
    tgt_attrs_re = re.compile(r'(targetAttributes\s*=\s*\{)(.*?)(\s*\};)', re.DOTALL)
    ta = tgt_attrs_re.search(new_content)
    if ta:
        entry = f'''
		{runner_uuid} /* Runner */ = {{
			attributes = {{
				LastSwiftMigration = 1100;
				SystemCapabilities = {{
					com.apple.Push = {{
						enabled = 1;
					}};
				}};
			}};
			buildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;
		}};
'''
        replacement = ta.group(1) + entry + ta.group(2) + ta.group(3)
        new_content = new_content[:ta.start()] + replacement + new_content[ta.end():]
        print("[OK-FALLBACK] SystemCapabilities injected into targetAttributes dict.")
    else:
        print("[ERROR] Could not find PBXProject.targetAttributes section. Please add Push Notifications capability manually in Xcode: Signing & Capabilities > + > Push Notifications")

with open(pbxproj, 'w') as f:
    f.write(new_content)
print("Done.")
