# Zusätzliche Targets für Tools/gen_project.py
EXTRA = [
    dict(name="FitMitJoditWidgets", kind="appex", product="FitMitJoditWidgets", folders=["FitMitJoditWidgets", "Shared"],
         settings={
             "PRODUCT_BUNDLE_IDENTIFIER": "$(APP_BUNDLE_ID).widgets",
             "PRODUCT_NAME": "FitMitJoditWidgets",
             "GENERATE_INFOPLIST_FILE": "YES",
             "INFOPLIST_KEY_CFBundleDisplayName": "Fit mit Jodit",
             "INFOPLIST_FILE": "FitMitJoditWidgets/Info.plist",
             "SDKROOT": "iphoneos",
             "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
             "TARGETED_DEVICE_FAMILY": "1,2",
             "IPHONEOS_DEPLOYMENT_TARGET": IOS_MIN,
             "SKIP_INSTALL": "YES",
             "LD_RUNPATH_SEARCH_PATHS": "@executable_path/Frameworks @executable_path/../../Frameworks",
             "SWIFT_EMIT_LOC_STRINGS": "YES",
             "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "",
         },
         release=dict(CODE_SIGN_STYLE="Manual", CODE_SIGN_IDENTITY="Apple Distribution",
                      PROVISIONING_PROFILE_SPECIFIER="$(APP_BUNDLE_ID).widgets AppStore")),
]
