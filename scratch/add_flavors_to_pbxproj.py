import re

pbxproj_path = '/Users/linkfields/flutterProjects/timeless_detailing_customer_app/ios/Runner.xcodeproj/project.pbxproj'

with open(pbxproj_path, 'r') as f:
    content = f.read()

# Add to Flutter PBXGroup children
flutter_children = """				E1F2A3B45C6D7E8F90123401 /* Debug-uat.xcconfig */,
				E1F2A3B45C6D7E8F90123402 /* Release-uat.xcconfig */,
				E1F2A3B45C6D7E8F90123403 /* Profile-uat.xcconfig */,
				E1F2A3B45C6D7E8F90123404 /* Debug-prod.xcconfig */,
				E1F2A3B45C6D7E8F90123405 /* Release-prod.xcconfig */,
				E1F2A3B45C6D7E8F90123406 /* Profile-prod.xcconfig */,
"""

flutter_group_match = re.search(r'(9740EEB11CF90186004384FC /\* Flutter \*/ = \{[\s\S]*?children = \(\n)', content)
if flutter_group_match and 'E1F2A3B45C6D7E8F90123401' not in flutter_group_match.group(0):
    content = content.replace(flutter_group_match.group(1), flutter_group_match.group(1) + flutter_children)

with open(pbxproj_path, 'w') as f:
    f.write(content)

print("Successfully added .xcconfig file references to Flutter PBXGroup children!")
