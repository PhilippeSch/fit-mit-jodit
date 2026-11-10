#!/usr/bin/env python3
"""Erzeugt FitMitJodit.xcodeproj/project.pbxproj.

Das Projekt nutzt synchronisierte Ordner (PBXFileSystemSynchronizedRootGroup):
neue Swift-Dateien in den Ordnern werden automatisch Teil des Targets.
Neue Targets oder Build-Einstellungen hier eintragen und das Skript erneut
laufen lassen:  python3 Tools/gen_project.py

Die IDs sind aus Namen abgeleitet und damit stabil.
Team-ID und Bundle-ID stehen zentral in Config/Base.xcconfig.
"""
import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "FitMitJodit.xcodeproj")


def oid(*parts):
    return hashlib.md5("/".join(parts).encode()).hexdigest()[:24].upper()


IOS_MIN = "17.0"
WATCH_MIN = "10.0"

# ---------------------------------------------------------------- Targets
# kind: app | watchapp | unit | uitest | appex
TARGETS = [
    dict(name="FitMitJodit", kind="app", product="Fit mit Jodit", folders=["FitMitJodit", "Shared"],
         settings={
             "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_BUNDLE_ID)",
             "PRODUCT_NAME": "FitMitJodit",
             "PRODUCT_MODULE_NAME": "FitMitJodit",
             "INFOPLIST_FILE": "FitMitJodit/Info.plist",
             "GENERATE_INFOPLIST_FILE": "YES",
             "INFOPLIST_KEY_CFBundleDisplayName": "\"Fit mit Jodit\"",
             "INFOPLIST_KEY_LSApplicationCategoryType": "\"public.app-category.healthcare-fitness\"",
             "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
             "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
             "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
             "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
             "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "\"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\"",
             "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "\"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\"",
             "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
             "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
             "CODE_SIGN_ENTITLEMENTS": "$(APP_ENTITLEMENTS)",
             "SDKROOT": "iphoneos",
             "SUPPORTED_PLATFORMS": "\"iphoneos iphonesimulator\"",
             "SUPPORTS_MACCATALYST": "NO",
             "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
             "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
             "TARGETED_DEVICE_FAMILY": "\"1,2\"",
             "IPHONEOS_DEPLOYMENT_TARGET": IOS_MIN,
             "LD_RUNPATH_SEARCH_PATHS": "\"@executable_path/Frameworks\"",
             "ENABLE_PREVIEWS": "YES",
             "SWIFT_EMIT_LOC_STRINGS": "YES",
         },
         release=dict(CODE_SIGN_STYLE="Manual", CODE_SIGN_IDENTITY="Apple Distribution",
                      PROVISIONING_PROFILE_SPECIFIER="$(APP_BUNDLE_ID) AppStore"),
         embed_watch="FitMitJoditWatch", embed_appex=[]),
    dict(name="FitMitJoditWatch", kind="watchapp", product="Fit mit Jodit Watch", folders=["FitMitJoditWatch", "Shared"],
         settings={
             "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_BUNDLE_ID).watchkitapp",
             "PRODUCT_NAME": "FitMitJoditWatch",
             "PRODUCT_MODULE_NAME": "FitMitJoditWatch",
             "GENERATE_INFOPLIST_FILE": "YES",
             "INFOPLIST_KEY_CFBundleDisplayName": "\"Fit mit Jodit\"",
             "INFOPLIST_KEY_WKCompanionAppBundleIdentifier": "$(APP_BUNDLE_ID)",
             "INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp": "NO",
             "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
             "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
             "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
             "SDKROOT": "watchos",
             "SUPPORTED_PLATFORMS": "\"watchos watchsimulator\"",
             "TARGETED_DEVICE_FAMILY": "4",
             "WATCHOS_DEPLOYMENT_TARGET": WATCH_MIN,
             "SKIP_INSTALL": "YES",
             "CODE_SIGN_ENTITLEMENTS": "FitMitJoditWatch/FitMitJoditWatch.entitlements",
             "LD_RUNPATH_SEARCH_PATHS": "\"@executable_path/Frameworks\"",
             "ENABLE_PREVIEWS": "YES",
             "SWIFT_EMIT_LOC_STRINGS": "YES",
         },
         release=dict(CODE_SIGN_STYLE="Manual", CODE_SIGN_IDENTITY="Apple Distribution",
                      PROVISIONING_PROFILE_SPECIFIER="$(APP_BUNDLE_ID).watchkitapp AppStore")),
    dict(name="FitMitJoditTests", kind="unit", product="FitMitJoditTests", folders=["FitMitJoditTests"], host="FitMitJodit",
         settings={
             "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_BUNDLE_ID).tests",
             "PRODUCT_NAME": "$(TARGET_NAME)",
             "GENERATE_INFOPLIST_FILE": "YES",
             "SDKROOT": "iphoneos",
             "SUPPORTED_PLATFORMS": "\"iphoneos iphonesimulator\"",
             "TARGETED_DEVICE_FAMILY": "\"1,2\"",
             "IPHONEOS_DEPLOYMENT_TARGET": IOS_MIN,
             "BUNDLE_LOADER": "\"$(TEST_HOST)\"",
             "TEST_HOST": "\"$(BUILT_PRODUCTS_DIR)/FitMitJodit.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/FitMitJodit\"",
             "SWIFT_EMIT_LOC_STRINGS": "NO",
         }),
    dict(name="FitMitJoditUITests", kind="uitest", product="FitMitJoditUITests", folders=["FitMitJoditUITests"], host="FitMitJodit",
         settings={
             "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_BUNDLE_ID).uitests",
             "PRODUCT_NAME": "$(TARGET_NAME)",
             "GENERATE_INFOPLIST_FILE": "YES",
             "SDKROOT": "iphoneos",
             "SUPPORTED_PLATFORMS": "\"iphoneos iphonesimulator\"",
             "TARGETED_DEVICE_FAMILY": "\"1,2\"",
             "IPHONEOS_DEPLOYMENT_TARGET": IOS_MIN,
             "TEST_TARGET_NAME": "FitMitJodit",
             "SWIFT_EMIT_LOC_STRINGS": "NO",
         }),
    dict(name="FitMitJoditWatchUITests", kind="uitest", product="FitMitJoditWatchUITests", folders=["FitMitJoditWatchUITests"], host="FitMitJoditWatch",
         settings={
             "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_BUNDLE_ID).watchkitapp.uitests",
             "PRODUCT_NAME": "$(TARGET_NAME)",
             "GENERATE_INFOPLIST_FILE": "YES",
             "SDKROOT": "watchos",
             "SUPPORTED_PLATFORMS": "\"watchos watchsimulator\"",
             "TARGETED_DEVICE_FAMILY": "4",
             "WATCHOS_DEPLOYMENT_TARGET": WATCH_MIN,
             "TEST_TARGET_NAME": "FitMitJoditWatch",
             "SWIFT_EMIT_LOC_STRINGS": "NO",
         }),
]

# Optionale Erweiterungen (z. B. Widget für die Live Activity) kommen hier dazu.
EXTRA_TARGETS_FILE = os.path.join(ROOT, "Tools", "extra_targets.py")
if os.path.exists(EXTRA_TARGETS_FILE):
    ns = {"IOS_MIN": IOS_MIN, "WATCH_MIN": WATCH_MIN}
    exec(open(EXTRA_TARGETS_FILE).read(), ns)
    for t in ns.get("EXTRA", []):
        TARGETS.append(t)
        if t["kind"] == "appex":
            TARGETS[0]["embed_appex"].append(t["name"])
    for folder in ns.get("APP_EXTRA_FOLDERS", []):
        TARGETS[0]["folders"].append(folder)

COMMON_PROJECT = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
    "CODE_SIGN_STYLE": "Automatic",
    "COPY_PHASE_STRIP": "NO",
    "DEVELOPMENT_TEAM": "\"$(APPLE_TEAM_ID)\"",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MARKETING_VERSION": "\"$(APP_MARKETING_VERSION)\"",
    "CURRENT_PROJECT_VERSION": "\"$(APP_BUILD_NUMBER)\"",
    "STRING_CATALOG_GENERATE_SYMBOLS": "NO",
    "SWIFT_VERSION": "5.0",
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_TREAT_WARNINGS_AS_ERRORS": "NO",
    "IPHONEOS_DEPLOYMENT_TARGET": IOS_MIN,
    "WATCHOS_DEPLOYMENT_TARGET": WATCH_MIN,
}
DEBUG_PROJECT = {
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_TESTABILITY": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": "(\n\t\t\t\t\t\"DEBUG=1\",\n\t\t\t\t\t\"$(inherited)\",\n\t\t\t\t)",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "\"DEBUG $(inherited)\"",
    "SWIFT_OPTIMIZATION_LEVEL": "\"-Onone\"",
}
RELEASE_PROJECT = {
    "DEBUG_INFORMATION_FORMAT": "\"dwarf-with-dsym\"",
    "ENABLE_NS_ASSERTIONS": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "VALIDATE_PRODUCT": "YES",
}

PRODUCT_TYPES = {
    "app": ("com.apple.product-type.application", "wrapper.application", ".app"),
    "watchapp": ("com.apple.product-type.application", "wrapper.application", ".app"),
    "unit": ("com.apple.product-type.bundle.unit-test", "wrapper.cfbundle", ".xctest"),
    "uitest": ("com.apple.product-type.bundle.ui-testing", "wrapper.cfbundle", ".xctest"),
    "appex": ("com.apple.product-type.app-extension", "wrapper.app-extension", ".appex"),
}


def product_file(t):
    base = t["settings"].get("PRODUCT_NAME", t["name"])
    if base == "$(TARGET_NAME)":
        base = t["name"]
    return base + PRODUCT_TYPES[t["kind"]][2]


SAFE = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_./")


def val(v):
    v = str(v)
    if v.startswith('"') or v.startswith("("):
        return v
    if v and all(c in SAFE for c in v):
        return v
    return '"' + v.replace('"', '\\"') + '"'


def fmt_settings(d, indent="\t\t\t\t"):
    out = []
    for k in sorted(d):
        key = k if all(c in SAFE for c in k) else '"' + k + '"'
        out.append(f"{indent}{key} = {val(d[k])};")
    return "\n".join(out)


def q(s):
    return f'"{s}"' if any(c in s for c in " -+.") else s


def main():
    P = oid("project")
    main_group = oid("group", "main")
    products_group = oid("group", "products")
    config_group = oid("group", "config")
    base_xcconfig = oid("file", "Base.xcconfig")
    version_xcconfig = oid("file", "Version.xcconfig")

    folders = []
    for t in TARGETS:
        for f in t["folders"]:
            if f not in folders:
                folders.append(f)

    s = []
    s.append("// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n")

    # BuildFiles for embedding
    s.append("/* Begin PBXBuildFile section */")
    for t in TARGETS:
        if t.get("embed_watch"):
            w = t["embed_watch"]
            s.append(f"\t\t{oid('embedbf', w)} /* {w} in Embed Watch Content */ = {{isa = PBXBuildFile; fileRef = {oid('product', w)}; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};")
        for ex in t.get("embed_appex", []):
            s.append(f"\t\t{oid('embedbf', ex)} /* {ex} in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {oid('product', ex)}; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};")
    s.append("/* End PBXBuildFile section */\n")

    # Container proxies + dependencies
    deps = {}  # target -> list of dep names
    for t in TARGETS:
        d = []
        if t.get("host"):
            d.append(t["host"])
        if t.get("embed_watch"):
            d.append(t["embed_watch"])
        d += t.get("embed_appex", [])
        deps[t["name"]] = d
    s.append("/* Begin PBXContainerItemProxy section */")
    for tn, dl in deps.items():
        for dn in dl:
            s.append(f"\t\t{oid('proxy', tn, dn)} = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {P};\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {oid('target', dn)};\n\t\t\tremoteInfo = {q(dn)};\n\t\t}};")
    s.append("/* End PBXContainerItemProxy section */\n")

    # Copy phases
    s.append("/* Begin PBXCopyFilesBuildPhase section */")
    for t in TARGETS:
        if t.get("embed_watch"):
            w = t["embed_watch"]
            s.append(f"\t\t{oid('copywatch', t['name'])} /* Embed Watch Content */ = {{\n\t\t\tisa = PBXCopyFilesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tdstPath = \"$(CONTENTS_FOLDER_PATH)/Watch\";\n\t\t\tdstSubfolderSpec = 16;\n\t\t\tfiles = (\n\t\t\t\t{oid('embedbf', w)},\n\t\t\t);\n\t\t\tname = \"Embed Watch Content\";\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
        if t.get("embed_appex"):
            files = "".join(f"\t\t\t\t{oid('embedbf', ex)},\n" for ex in t["embed_appex"])
            s.append(f"\t\t{oid('copyappex', t['name'])} /* Embed Foundation Extensions */ = {{\n\t\t\tisa = PBXCopyFilesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tdstPath = \"\";\n\t\t\tdstSubfolderSpec = 13;\n\t\t\tfiles = (\n{files}\t\t\t);\n\t\t\tname = \"Embed Foundation Extensions\";\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    s.append("/* End PBXCopyFilesBuildPhase section */\n")

    # File references
    s.append("/* Begin PBXFileReference section */")
    for t in TARGETS:
        ptype, ftype, _ = PRODUCT_TYPES[t["kind"]]
        s.append(f"\t\t{oid('product', t['name'])} = {{isa = PBXFileReference; explicitFileType = {ftype}; includeInIndex = 0; path = {q(product_file(t))}; sourceTree = BUILT_PRODUCTS_DIR; }};")
    s.append(f"\t\t{base_xcconfig} /* Base.xcconfig */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Base.xcconfig; sourceTree = \"<group>\"; }};")
    s.append(f"\t\t{version_xcconfig} /* Version.xcconfig */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Version.xcconfig; sourceTree = \"<group>\"; }};")
    s.append("/* End PBXFileReference section */\n")

    # Exceptions: Info.plist / entitlements must not be copied as resources
    exc = {}
    s.append("/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */")
    for t in TARGETS:
        for f in t["folders"]:
            path = os.path.join(ROOT, f)
            members = []
            if os.path.isdir(path):
                for fn in sorted(os.listdir(path)):
                    if fn == "Info.plist":
                        members.append(fn)
            if members:
                eid = oid("exc", t["name"], f)
                exc.setdefault(f, []).append(eid)
                m = "".join(f"\t\t\t\t{x},\n" for x in members)
                s.append(f"\t\t{eid} = {{\n\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;\n\t\t\tmembershipExceptions = (\n{m}\t\t\t);\n\t\t\ttarget = {oid('target', t['name'])};\n\t\t}};")
    s.append("/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */\n")

    s.append("/* Begin PBXFileSystemSynchronizedRootGroup section */")
    for f in folders:
        e = ""
        if f in exc:
            e = "\t\t\texceptions = (\n" + "".join(f"\t\t\t\t{x},\n" for x in exc[f]) + "\t\t\t);\n"
        s.append(f"\t\t{oid('folder', f)} /* {f} */ = {{\n\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n{e}\t\t\tpath = {q(f)};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    s.append("/* End PBXFileSystemSynchronizedRootGroup section */\n")

    s.append("/* Begin PBXFrameworksBuildPhase section */")
    for t in TARGETS:
        s.append(f"\t\t{oid('fw', t['name'])} = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
    s.append("/* End PBXFrameworksBuildPhase section */\n")

    s.append("/* Begin PBXGroup section */")
    children = "".join(f"\t\t\t\t{oid('folder', f)},\n" for f in folders)
    s.append(f"\t\t{main_group} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{children}\t\t\t\t{config_group},\n\t\t\t\t{products_group},\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    prods = "".join(f"\t\t\t\t{oid('product', t['name'])},\n" for t in TARGETS)
    s.append(f"\t\t{products_group} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{prods}\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    s.append(f"\t\t{config_group} /* Config */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{base_xcconfig},\n\t\t\t\t{version_xcconfig},\n\t\t\t);\n\t\t\tpath = Config;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};")
    s.append("/* End PBXGroup section */\n")

    s.append("/* Begin PBXNativeTarget section */")
    for t in TARGETS:
        n = t["name"]
        phases = [oid("src", n), oid("fw", n), oid("res", n)]
        if t.get("embed_watch"):
            phases.append(oid("copywatch", n))
        if t.get("embed_appex"):
            phases.append(oid("copyappex", n))
        ph = "".join(f"\t\t\t\t{p},\n" for p in phases)
        dp = "".join(f"\t\t\t\t{oid('dep', n, d)},\n" for d in deps[n])
        fg = "".join(f"\t\t\t\t{oid('folder', f)},\n" for f in t["folders"])
        s.append(f"\t\t{oid('target', n)} /* {n} */ = {{\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = {oid('cfglist', n)};\n\t\t\tbuildPhases = (\n{ph}\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n{dp}\t\t\t);\n\t\t\tfileSystemSynchronizedGroups = (\n{fg}\t\t\t);\n\t\t\tname = {q(n)};\n\t\t\tproductName = {q(n)};\n\t\t\tproductReference = {oid('product', n)};\n\t\t\tproductType = \"{PRODUCT_TYPES[t['kind']][0]}\";\n\t\t}};")
    s.append("/* End PBXNativeTarget section */\n")

    ta = ""
    for t in TARGETS:
        ta += f"\t\t\t\t\t{oid('target', t['name'])} = {{\n\t\t\t\t\t\tCreatedOnToolsVersion = 27.2;\n"
        if t.get("host"):
            ta += f"\t\t\t\t\t\tTestTargetID = {oid('target', t['host'])};\n"
        ta += "\t\t\t\t\t};\n"
    tl = "".join(f"\t\t\t\t{oid('target', t['name'])},\n" for t in TARGETS)
    s.append("/* Begin PBXProject section */")
    s.append(f"\t\t{P} /* Project object */ = {{\n\t\t\tisa = PBXProject;\n\t\t\tattributes = {{\n\t\t\t\tBuildIndependentTargetsInParallel = 1;\n\t\t\t\tLastSwiftUpdateCheck = 2720;\n\t\t\t\tLastUpgradeCheck = 2720;\n\t\t\t\tTargetAttributes = {{\n{ta}\t\t\t\t}};\n\t\t\t}};\n\t\t\tbuildConfigurationList = {oid('cfglist', 'project')};\n\t\t\tdevelopmentRegion = de;\n\t\t\thasScannedForEncodings = 0;\n\t\t\tknownRegions = (\n\t\t\t\tde,\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t);\n\t\t\tmainGroup = {main_group};\n\t\t\tminimizedProjectReferenceProxies = 1;\n\t\t\tpreferredProjectObjectVersion = 77;\n\t\t\tproductRefGroup = {products_group};\n\t\t\tprojectDirPath = \"\";\n\t\t\tprojectRoot = \"\";\n\t\t\ttargets = (\n{tl}\t\t\t);\n\t\t}};")
    s.append("/* End PBXProject section */\n")

    for sec, key in (("PBXResourcesBuildPhase", "res"), ("PBXSourcesBuildPhase", "src")):
        s.append(f"/* Begin {sec} section */")
        for t in TARGETS:
            s.append(f"\t\t{oid(key, t['name'])} = {{\n\t\t\tisa = {sec};\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};")
        s.append(f"/* End {sec} section */\n")

    s.append("/* Begin PBXTargetDependency section */")
    for tn, dl in deps.items():
        for dn in dl:
            s.append(f"\t\t{oid('dep', tn, dn)} = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {oid('target', dn)};\n\t\t\ttargetProxy = {oid('proxy', tn, dn)};\n\t\t}};")
    s.append("/* End PBXTargetDependency section */\n")

    s.append("/* Begin XCBuildConfiguration section */")
    for cfg, extra in (("Debug", DEBUG_PROJECT), ("Release", RELEASE_PROJECT)):
        d = dict(COMMON_PROJECT)
        d.update(extra)
        s.append(f"\t\t{oid('cfg', 'project', cfg)} /* {cfg} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbaseConfigurationReference = {base_xcconfig};\n\t\t\tbuildSettings = {{\n{fmt_settings(d)}\n\t\t\t}};\n\t\t\tname = {cfg};\n\t\t}};")
    for t in TARGETS:
        for cfg in ("Debug", "Release"):
            d = dict(t["settings"])
            d.update(t.get(cfg.lower(), {}))
            s.append(f"\t\t{oid('cfg', t['name'], cfg)} /* {cfg} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{fmt_settings(d)}\n\t\t\t}};\n\t\t\tname = {cfg};\n\t\t}};")
    s.append("/* End XCBuildConfiguration section */\n")

    s.append("/* Begin XCConfigurationList section */")
    for n in ["project"] + [t["name"] for t in TARGETS]:
        key = "project" if n == "project" else n
        s.append(f"\t\t{oid('cfglist', n)} = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{oid('cfg', key, 'Debug')},\n\t\t\t\t{oid('cfg', key, 'Release')},\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};")
    s.append("/* End XCConfigurationList section */")

    s.append(f"\t}};\n\trootObject = {P} /* Project object */;\n}}\n")

    os.makedirs(PROJ, exist_ok=True)
    with open(os.path.join(PROJ, "project.pbxproj"), "w") as fh:
        fh.write("\n".join(s))
    print("geschrieben:", os.path.join(PROJ, "project.pbxproj"))


if __name__ == "__main__":
    main()


# ---------------------------------------------------------------- Schemes
def buildable(t):
    return (f'<BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{oid("target", t)}" '
            f'BuildableName = "{product_file(next(x for x in TARGETS if x["name"] == t))}" '
            f'BlueprintName = "{t}" ReferencedContainer = "container:FitMitJodit.xcodeproj"></BuildableReference>')


def scheme(name, main, tests, test_plan_lang=None):
    tests_xml = "".join(
        f'<TestableReference skipped = "NO" parallelizable = "NO">{buildable(t)}</TestableReference>' for t in tests)
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2720" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            {buildable(main)}
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         {tests_xml}
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         {buildable(main)}
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''


def write_schemes():
    d = os.path.join(PROJ, "xcshareddata", "xcschemes")
    os.makedirs(d, exist_ok=True)
    schemes = {
        "FitMitJodit": scheme("FitMitJodit", "FitMitJodit", ["FitMitJoditTests", "FitMitJoditUITests"]),
        "FitMitJoditUnit": scheme("FitMitJoditUnit", "FitMitJodit", ["FitMitJoditTests"]),
        "FitMitJoditWatch": scheme("FitMitJoditWatch", "FitMitJoditWatch", ["FitMitJoditWatchUITests"]),
    }
    for n, x in schemes.items():
        with open(os.path.join(d, n + ".xcscheme"), "w") as fh:
            fh.write(x)
    print("Schemes:", ", ".join(schemes))


write_schemes()
