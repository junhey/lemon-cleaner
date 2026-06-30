#!/usr/bin/env python3
import os
import uuid

ROOT = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.join(ROOT, "LemonCleaner")
TEST_DIR = os.path.join(ROOT, "LemonCleanerTests")
OUT = os.path.join(ROOT, "LemonCleaner.xcodeproj", "project.pbxproj")
APP_TARGET_NAME = "Airy"
APP_PRODUCT_NAME = "Airy.app"


def uid():
    return uuid.uuid4().hex[:24].upper()


def collect_swift(base):
    files = []
    for dirpath, _, filenames in os.walk(base):
        for name in sorted(filenames):
            if name.endswith(".swift"):
                files.append(os.path.relpath(os.path.join(dirpath, name), ROOT))
    return files


app_sources = collect_swift(APP_DIR)
test_sources = collect_swift(TEST_DIR)

ids = {name: uid() for name in [
    "project", "app_target", "test_target", "app_product", "test_product",
    "main_group", "app_group", "test_group", "products_group",
    "sources_app", "sources_test", "resources", "frameworks_app", "frameworks_test",
    "proj_cfg", "app_cfg", "test_cfg",
    "debug_proj", "release_proj", "debug_app", "release_app", "debug_test", "release_test",
    "assets", "assets_build", "info_plist", "test_dep",
]}

file_ref = {}
build_file = {}
for path in app_sources + test_sources:
    file_ref[path] = uid()
    build_file[path] = uid()

lines = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {")
lines.append("\t};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")
lines.append("")
lines.append("/* Begin PBXBuildFile section */")
for path in app_sources + test_sources:
    base = os.path.basename(path)
    lines.append(
        f"\t\t{build_file[path]} /* {base} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref[path]} /* {base} */; }};"
    )
lines.append(
    f"\t\t{ids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['assets']} /* Assets.xcassets */; }};"
)
lines.append("/* End PBXBuildFile section */")
lines.append("")
lines.append("/* Begin PBXContainerItemProxy section */")
proxy = uid()
lines.append(f"\t\t{proxy} /* PBXContainerItemProxy */ = {{")
lines.append("\t\t\tisa = PBXContainerItemProxy;")
lines.append(f"\t\t\tcontainerPortal = {ids['project']} /* Project object */;")
lines.append("\t\t\tproxyType = 1;")
lines.append(f"\t\t\tremoteGlobalIDString = {ids['app_target']};")
lines.append(f"\t\t\tremoteInfo = {APP_TARGET_NAME};")
lines.append("\t\t};")
lines.append("/* End PBXContainerItemProxy section */")
lines.append("")
lines.append("/* Begin PBXFileReference section */")
lines.append(
    f"\t\t{ids['app_product']} /* {APP_PRODUCT_NAME} */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP_PRODUCT_NAME}; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
lines.append(
    f"\t\t{ids['test_product']} /* LemonCleanerTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LemonCleanerTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
lines.append(
    f"\t\t{ids['assets']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};"
)
lines.append(
    f"\t\t{ids['info_plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};"
)
for path in app_sources + test_sources:
    base = os.path.basename(path)
    rel_path = path
    if path.startswith("LemonCleaner/"):
        rel_path = path[len("LemonCleaner/"):]
    elif path.startswith("LemonCleanerTests/"):
        rel_path = path[len("LemonCleanerTests/"):]
    lines.append(
        f"\t\t{file_ref[path]} /* {base} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {rel_path}; sourceTree = \"<group>\"; }};"
    )
lines.append("/* End PBXFileReference section */")
lines.append("")
lines.append("/* Begin PBXFrameworksBuildPhase section */")
for key, label in [("frameworks_app", "app"), ("frameworks_test", "test")]:
    lines.append(f"\t\t{ids[key]} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
lines.append("/* End PBXFrameworksBuildPhase section */")
lines.append("")
lines.append("/* Begin PBXGroup section */")

# Build nested groups for app
subgroups = {}
for path in app_sources:
    rel = os.path.relpath(path, "LemonCleaner")
    folder = os.path.dirname(rel)
    if folder == ".":
        folder = ""
    subgroups.setdefault(folder, []).append(path)

def make_group(group_id, name, path, children_lines):
    lines.append(f"\t\t{group_id} = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for child in children_lines:
        lines.append(child)
    lines.append("\t\t\t);")
    if path:
        lines.append(f"\t\t\tpath = {path};")
    if name:
        lines.append(f"\t\t\tname = {name};")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

group_ids = {}
for folder in sorted(set(subgroups) | {""}):
    group_ids[folder] = uid()

# leaf groups
for folder, paths in subgroups.items():
    children = [f"\t\t\t\t{file_ref[p]} /* {os.path.basename(p)} */," for p in sorted(paths)]
    if folder:
        parent = os.path.dirname(folder)
        if parent == ".":
            parent = ""
        group_ids.setdefault(parent, uid())
    else:
        pass

# simpler flat app group
app_children = [f"\t\t\t\t{ids['assets']} /* Assets.xcassets */,"]
app_children.append(f"\t\t\t\t{ids['info_plist']} /* Info.plist */,")
for path in sorted(app_sources):
    app_children.append(f"\t\t\t\t{file_ref[path]} /* {os.path.basename(path)} */,")

make_group(ids["app_group"], "LemonCleaner", "LemonCleaner", app_children)

test_children = [f"\t\t\t\t{file_ref[p]} /* {os.path.basename(p)} */," for p in sorted(test_sources)]
make_group(ids["test_group"], "LemonCleanerTests", "LemonCleanerTests", test_children)

products_children = [
    f"\t\t\t\t{ids['app_product']} /* {APP_PRODUCT_NAME} */,",
    f"\t\t\t\t{ids['test_product']} /* LemonCleanerTests.xctest */,",
]
make_group(ids["products_group"], "Products", "", products_children)

main_children = [
    f"\t\t\t\t{ids['app_group']} /* LemonCleaner */,",
    f"\t\t\t\t{ids['test_group']} /* LemonCleanerTests */,",
    f"\t\t\t\t{ids['products_group']} /* Products */,",
]
make_group(ids["main_group"], "", "", main_children)

# Write xcscheme
scheme_dir = os.path.join(ROOT, "LemonCleaner.xcodeproj", "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
old_scheme = os.path.join(scheme_dir, "LemonCleaner.xcscheme")
if os.path.exists(old_scheme):
    os.remove(old_scheme)
scheme_path = os.path.join(scheme_dir, f"{APP_TARGET_NAME}.xcscheme")
with open(scheme_path, "w", encoding="utf-8") as f:
    f.write(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="{APP_PRODUCT_NAME}" BlueprintName="{APP_TARGET_NAME}" ReferencedContainer="container:LemonCleaner.xcodeproj"/>
      </BuildActionEntry>
      <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['test_target']}" BuildableName="LemonCleanerTests.xctest" BlueprintName="LemonCleanerTests" ReferencedContainer="container:LemonCleaner.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB">
    <Testables>
      <TestableReference skipped="NO">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['test_target']}" BuildableName="LemonCleanerTests.xctest" BlueprintName="LemonCleanerTests" ReferencedContainer="container:LemonCleaner.xcodeproj"/>
      </TestableReference>
    </Testables>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="{APP_PRODUCT_NAME}" BlueprintName="{APP_TARGET_NAME}" ReferencedContainer="container:LemonCleaner.xcodeproj"/>
    </BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="{APP_PRODUCT_NAME}" BlueprintName="{APP_TARGET_NAME}" ReferencedContainer="container:LemonCleaner.xcodeproj"/>
    </BuildableProductRunnable>
  </ProfileAction>
</Scheme>
''')

lines.append("/* End PBXGroup section */")
lines.append("")
lines.append("/* Begin PBXNativeTarget section */")
lines.append(f"\t\t{ids['app_target']} /* {APP_TARGET_NAME} */ = {{")
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {ids['app_cfg']} /* Build configuration list for PBXNativeTarget \"{APP_TARGET_NAME}\" */;")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{ids['sources_app']} /* Sources */,")
lines.append(f"\t\t\t\t{ids['frameworks_app']} /* Frameworks */,")
lines.append(f"\t\t\t\t{ids['resources']} /* Resources */,")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = (")
lines.append("\t\t\t);")
lines.append("\t\t\tdependencies = (")
lines.append("\t\t\t);")
lines.append(f'\t\t\tname = {APP_TARGET_NAME};')
lines.append(f"\t\t\tproductName = {APP_TARGET_NAME};")
lines.append(f"\t\t\tproductReference = {ids['app_product']} /* {APP_PRODUCT_NAME} */;")
lines.append('\t\t\tproductType = "com.apple.product-type.application";')
lines.append("\t\t};")

lines.append(f"\t\t{ids['test_target']} /* LemonCleanerTests */ = {{")
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {ids['test_cfg']} /* Build configuration list for PBXNativeTarget \"LemonCleanerTests\" */;")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{ids['sources_test']} /* Sources */,")
lines.append(f"\t\t\t\t{ids['frameworks_test']} /* Frameworks */,")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = (")
lines.append("\t\t\t);")
lines.append("\t\t\tdependencies = (")
lines.append(f"\t\t\t\t{ids['test_dep']} /* PBXTargetDependency */,")
lines.append("\t\t\t);")
lines.append('\t\t\tname = LemonCleanerTests;')
lines.append(f"\t\t\tproductName = LemonCleanerTests;")
lines.append(f"\t\t\tproductReference = {ids['test_product']} /* LemonCleanerTests.xctest */;")
lines.append('\t\t\tproductType = "com.apple.product-type.bundle.unit-test";')
lines.append("\t\t};")
lines.append("/* End PBXNativeTarget section */")
lines.append("")
lines.append("/* Begin PBXProject section */")
lines.append(f"\t\t{ids['project']} /* Project object */ = {{")
lines.append("\t\t\tisa = PBXProject;")
lines.append("\t\t\tattributes = {")
lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
lines.append("\t\t\t\tLastSwiftUpdateCheck = 1640;")
lines.append("\t\t\t\tLastUpgradeCheck = 1640;")
lines.append("\t\t\t\tTargetAttributes = {")
lines.append(f"\t\t\t\t\t{ids['app_target']} = {{")
lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 16.4;")
lines.append("\t\t\t\t\t};")
lines.append(f"\t\t\t\t\t{ids['test_target']} = {{")
lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 16.4;")
lines.append(f"\t\t\t\t\t\tTestTargetID = {ids['app_target']};")
lines.append("\t\t\t\t\t};")
lines.append("\t\t\t\t};")
lines.append("\t\t\t};")
lines.append(f"\t\t\tbuildConfigurationList = {ids['proj_cfg']} /* Build configuration list for PBXProject \"LemonCleaner\" */;")
lines.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
lines.append("\t\t\tdevelopmentRegion = \"zh-Hans\";")
lines.append("\t\t\thasScannedForEncodings = 0;")
lines.append("\t\t\tknownRegions = (")
lines.append("\t\t\t\ten,")
lines.append("\t\t\t\t\"zh-Hans\",")
lines.append("\t\t\t\tBase,")
lines.append("\t\t\t);")
lines.append(f"\t\t\tmainGroup = {ids['main_group']};")
lines.append(f"\t\t\tproductRefGroup = {ids['products_group']} /* Products */;")
lines.append('\t\t\tprojectDirPath = "";')
lines.append('\t\t\tprojectRoot = "";')
lines.append("\t\t\ttargets = (")
lines.append(f"\t\t\t\t{ids['app_target']} /* {APP_TARGET_NAME} */,")
lines.append(f"\t\t\t\t{ids['test_target']} /* LemonCleanerTests */,")
lines.append("\t\t\t);")
lines.append("\t\t};")
lines.append("/* End PBXProject section */")
lines.append("")
lines.append("/* Begin PBXResourcesBuildPhase section */")
lines.append(f"\t\t{ids['resources']} /* Resources */ = {{")
lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append(f"\t\t\t\t{ids['assets_build']} /* Assets.xcassets in Resources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXResourcesBuildPhase section */")
lines.append("")
lines.append("/* Begin PBXSourcesBuildPhase section */")
lines.append(f"\t\t{ids['sources_app']} /* Sources */ = {{")
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for path in app_sources:
    lines.append(f"\t\t\t\t{build_file[path]} /* {os.path.basename(path)} in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append(f"\t\t{ids['sources_test']} /* Sources */ = {{")
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for path in test_sources:
    lines.append(f"\t\t\t\t{build_file[path]} /* {os.path.basename(path)} in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXSourcesBuildPhase section */")
lines.append("")
lines.append("/* Begin PBXTargetDependency section */")
dep = uid()
lines.append(f"\t\t{ids['test_dep']} /* PBXTargetDependency */ = {{")
lines.append("\t\t\tisa = PBXTargetDependency;")
lines.append(f"\t\t\ttarget = {ids['app_target']} /* {APP_TARGET_NAME} */;")
lines.append(f"\t\t\ttargetProxy = {proxy} /* PBXContainerItemProxy */;")
lines.append("\t\t};")
lines.append("/* End PBXTargetDependency section */")
lines.append("")
lines.append("/* Begin XCBuildConfiguration section */")

common_swift = [
    "SWIFT_VERSION = 5.9;",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
] if False else []

def cfg(cid, name, settings):
    lines.append(f"\t\t{cid} /* {name} */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    for k, v in settings.items():
        escaped = v.replace('"', '\\"')
        lines.append(f'\t\t\t\t{k} = "{escaped}";')
    lines.append("\t\t\t};")
    lines.append(f'\t\t\tname = {name};')
    lines.append("\t\t};")

cfg(ids["debug_proj"], "Debug", {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "MACOSX_DEPLOYMENT_TARGET": "13.0",
    "ONLY_ACTIVE_ARCH": "YES",
    "SDKROOT": "macosx",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
})
cfg(ids["release_proj"], "Release", {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "MACOSX_DEPLOYMENT_TARGET": "13.0",
    "SDKROOT": "macosx",
    "SWIFT_COMPILATION_MODE": "wholemodule",
})

app_common = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_STYLE": "Automatic",
    "COMBINE_HIDPI_IMAGES": "YES",
    "CURRENT_PROJECT_VERSION": "3",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "LemonCleaner/Info.plist",
    "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/../Frameworks",
    "MARKETING_VERSION": "0.0.3",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.junhey.Airy",
    "PRODUCT_NAME": APP_TARGET_NAME,
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.9",
}
cfg(ids["debug_app"], "Debug", {**app_common, "CODE_SIGN_IDENTITY": "-"})
cfg(ids["release_app"], "Release", app_common)

test_common = {
    "BUNDLE_LOADER": "$(TEST_HOST)",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "3",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MACOSX_DEPLOYMENT_TARGET": "13.0",
    "MARKETING_VERSION": "0.0.3",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.junhey.AiryTests",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_VERSION": "5.9",
    "TEST_HOST": f"$(BUILT_PRODUCTS_DIR)/{APP_PRODUCT_NAME}/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{APP_TARGET_NAME}",
}
cfg(ids["debug_test"], "Debug", test_common)
cfg(ids["release_test"], "Release", test_common)

lines.append("/* End XCBuildConfiguration section */")
lines.append("")
lines.append("/* Begin XCConfigurationList section */")
for list_id, name, cfgs in [
    (ids["proj_cfg"], "Project", [(ids["debug_proj"], "Debug"), (ids["release_proj"], "Release")]),
    (ids["app_cfg"], APP_TARGET_NAME, [(ids["debug_app"], "Debug"), (ids["release_app"], "Release")]),
    (ids["test_cfg"], "LemonCleanerTests", [(ids["debug_test"], "Debug"), (ids["release_test"], "Release")]),
]:
    lines.append(f"\t\t{list_id} /* Build configuration list for PBXProject \"{name}\" */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    for cid, cname in cfgs:
        lines.append(f"\t\t\t\t{cid} /* {cname} */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
lines.append("/* End XCConfigurationList section */")
lines.append("\t};")
lines.append(f"\trootObject = {ids['project']} /* Project object */;")
lines.append("}")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print(f"Wrote {OUT}")
