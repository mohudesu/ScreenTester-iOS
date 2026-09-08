"""Maintainer utility: emit a dependency-free Xcode project. Not required on the user's Mac."""
from pathlib import Path
import json
import plistlib
import struct
import zlib

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'ScreenTester'
PROJECT = ROOT / 'ScreenTester.xcodeproj'
PROJECT.mkdir(exist_ok=True)
objects = {}

def obj(key, **values):
    ident = f'{key:024X}'
    objects[ident] = values
    return ident

files = [obj(100+i, isa='PBXFileReference', lastKnownFileType='sourcecode.swift', path=name, sourceTree='<group>')
         for i, name in enumerate(['App.swift', 'TestController.swift', 'TestCanvas.swift', 'Interface.swift'])]
info = obj(13, isa='PBXFileReference', lastKnownFileType='text.plist.xml', path='Info.plist', sourceTree='<group>')
assets = obj(14, isa='PBXFileReference', lastKnownFileType='folder.assetcatalog', path='Assets.xcassets', sourceTree='<group>')
product = obj(15, isa='PBXFileReference', explicitFileType='wrapper.application', includeInIndex=0, path='ScreenTester.app', sourceTree='BUILT_PRODUCTS_DIR')
build_files = [obj(200+i, isa='PBXBuildFile', fileRef=ref) for i, ref in enumerate(files)]
asset_build = obj(24, isa='PBXBuildFile', fileRef=assets)
sources = obj(30, isa='PBXSourcesBuildPhase', buildActionMask=2147483647, files=build_files, runOnlyForDeploymentPostprocessing=0)
resources = obj(31, isa='PBXResourcesBuildPhase', buildActionMask=2147483647, files=[asset_build], runOnlyForDeploymentPostprocessing=0)
frameworks = obj(32, isa='PBXFrameworksBuildPhase', buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)
app_group = obj(40, isa='PBXGroup', children=files+[info, assets], path='ScreenTester', sourceTree='<group>')
products = obj(41, isa='PBXGroup', children=[product], name='Products', sourceTree='<group>')
main = obj(42, isa='PBXGroup', children=[app_group, products], sourceTree='<group>')
project_settings = dict(CLANG_ENABLE_MODULES='YES', CLANG_ENABLE_OBJC_ARC='YES', SDKROOT='iphoneos', IPHONEOS_DEPLOYMENT_TARGET='17.0', SWIFT_VERSION='5.0')
target_settings = dict(PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='com.local.screentester', INFOPLIST_FILE='ScreenTester/Info.plist', GENERATE_INFOPLIST_FILE='NO', CODE_SIGN_STYLE='Automatic', TARGETED_DEVICE_FAMILY='1', SUPPORTED_PLATFORMS='iphoneos iphonesimulator', SUPPORTS_MACCATALYST='NO', SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD='NO', ASSETCATALOG_COMPILER_APPICON_NAME='AppIcon', LD_RUNPATH_SEARCH_PATHS=['$(inherited)', '@executable_path/Frameworks'], CURRENT_PROJECT_VERSION='3', MARKETING_VERSION='0.2.0')
p_debug = obj(50, isa='XCBuildConfiguration', name='Debug', buildSettings={**project_settings, 'SWIFT_OPTIMIZATION_LEVEL': '-Onone', 'DEBUG_INFORMATION_FORMAT': 'dwarf', 'ENABLE_TESTABILITY': 'YES', 'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG'})
p_release = obj(51, isa='XCBuildConfiguration', name='Release', buildSettings={**project_settings, 'SWIFT_OPTIMIZATION_LEVEL': '-O', 'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym', 'SWIFT_COMPILATION_MODE': 'wholemodule'})
t_debug = obj(52, isa='XCBuildConfiguration', name='Debug', buildSettings=target_settings.copy())
t_release = obj(53, isa='XCBuildConfiguration', name='Release', buildSettings=target_settings.copy())
p_configs = obj(54, isa='XCConfigurationList', buildConfigurations=[p_debug, p_release], defaultConfigurationIsVisible=0, defaultConfigurationName='Release')
t_configs = obj(55, isa='XCConfigurationList', buildConfigurations=[t_debug, t_release], defaultConfigurationIsVisible=0, defaultConfigurationName='Release')
target = obj(60, isa='PBXNativeTarget', buildConfigurationList=t_configs, buildPhases=[sources, frameworks, resources], buildRules=[], dependencies=[], name='ScreenTester', productName='ScreenTester', productReference=product, productType='com.apple.product-type.application')
root = obj(1, isa='PBXProject', attributes={'BuildIndependentTargetsInParallel': 'YES', 'LastUpgradeCheck': '1600', 'TargetAttributes': {target: {'CreatedOnToolsVersion': '16.0', 'ProvisioningStyle': 'Automatic'}}}, buildConfigurationList=p_configs, compatibilityVersion='Xcode 14.0', developmentRegion='zh-Hans', hasScannedForEncodings=0, knownRegions=['zh-Hans', 'en', 'Base'], mainGroup=main, productRefGroup=products, projectDirPath='', projectRoot='', targets=[target])

test_file = obj(300, isa='PBXFileReference', lastKnownFileType='sourcecode.swift', path='InterfaceTests.swift', sourceTree='<group>')
test_product = obj(301, isa='PBXFileReference', explicitFileType='wrapper.cfbundle', includeInIndex=0, path='ScreenTesterUITests.xctest', sourceTree='BUILT_PRODUCTS_DIR')
test_group = obj(302, isa='PBXGroup', children=[test_file], path='UITests', sourceTree='<group>')
objects[main]['children'].append(test_group)
objects[products]['children'].append(test_product)
test_build_file = obj(303, isa='PBXBuildFile', fileRef=test_file)
test_sources = obj(304, isa='PBXSourcesBuildPhase', buildActionMask=2147483647, files=[test_build_file], runOnlyForDeploymentPostprocessing=0)
test_settings = dict(PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='com.local.screentester.UITests', GENERATE_INFOPLIST_FILE='YES', CODE_SIGN_STYLE='Automatic', TARGETED_DEVICE_FAMILY='1', SUPPORTED_PLATFORMS='iphoneos iphonesimulator', TEST_TARGET_NAME='ScreenTester', SWIFT_VERSION='5.0', IPHONEOS_DEPLOYMENT_TARGET='17.0', LD_RUNPATH_SEARCH_PATHS=['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks'])
test_debug = obj(305, isa='XCBuildConfiguration', name='Debug', buildSettings=test_settings.copy())
test_release = obj(306, isa='XCBuildConfiguration', name='Release', buildSettings=test_settings.copy())
test_configs = obj(307, isa='XCConfigurationList', buildConfigurations=[test_debug, test_release], defaultConfigurationIsVisible=0, defaultConfigurationName='Debug')
proxy = obj(308, isa='PBXContainerItemProxy', containerPortal=root, proxyType=1, remoteGlobalIDString=target, remoteInfo='ScreenTester')
dependency = obj(309, isa='PBXTargetDependency', target=target, targetProxy=proxy)
test_target = obj(310, isa='PBXNativeTarget', buildConfigurationList=test_configs, buildPhases=[test_sources], buildRules=[], dependencies=[dependency], name='ScreenTesterUITests', productName='ScreenTesterUITests', productReference=test_product, productType='com.apple.product-type.bundle.ui-testing')
objects[root]['targets'].append(test_target)
objects[root]['attributes']['TargetAttributes'][test_target] = {'CreatedOnToolsVersion': '16.0', 'TestTargetID': target}

def encode(value, depth=0):
    tab = '\t' * depth
    if isinstance(value, dict):
        return '{\n' + ''.join('\t'*(depth+1) + json.dumps(k) + ' = ' + encode(v, depth+1) + ';\n' for k,v in value.items()) + tab + '}'
    if isinstance(value, list):
        return '(\n' + ''.join('\t'*(depth+1) + encode(v, depth+1) + ',\n' for v in value) + tab + ')'
    if isinstance(value, int):
        return str(value)
    return json.dumps(value, ensure_ascii=False)

(PROJECT / 'project.pbxproj').write_text('// !$*UTF8*$!\n' + encode({'archiveVersion': 1, 'classes': {}, 'objectVersion': 56, 'objects': objects, 'rootObject': root}) + '\n', encoding='utf-8')
plist = dict(CFBundleDevelopmentRegion='zh_CN', CFBundleDisplayName='ScreenTester', CFBundleExecutable='$(EXECUTABLE_NAME)', CFBundleIdentifier='$(PRODUCT_BUNDLE_IDENTIFIER)', CFBundleInfoDictionaryVersion='6.0', CFBundleName='$(PRODUCT_NAME)', CFBundlePackageType='APPL', CFBundleShortVersionString='$(MARKETING_VERSION)', CFBundleVersion='$(CURRENT_PROJECT_VERSION)', LSRequiresIPhoneOS=True, UILaunchScreen={}, UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait'], UIRequiredDeviceCapabilities=['arm64'], UIViewControllerBasedStatusBarAppearance=True, CADisableMinimumFrameDurationOnPhone=True)
plist['UIApplicationSceneManifest'] = {'UIApplicationSupportsMultipleScenes': False, 'UISceneConfigurations': {'UIWindowSceneSessionRoleApplication': [{'UISceneConfigurationName': 'Default', 'UISceneDelegateClassName': '$(PRODUCT_MODULE_NAME).SceneDelegate'}]}}
(SOURCE / 'Info.plist').write_bytes(plistlib.dumps(plist))
scheme_dir = PROJECT / 'xcshareddata' / 'xcschemes'
scheme_dir.mkdir(parents=True, exist_ok=True)
ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="ScreenTester.app" BlueprintName="ScreenTester" ReferencedContainer="container:ScreenTester.xcodeproj"/>'
test_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{test_target}" BuildableName="ScreenTesterUITests.xctest" BlueprintName="ScreenTesterUITests" ReferencedContainer="container:ScreenTester.xcodeproj"/>'
(scheme_dir/'ScreenTester.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry><BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">{test_ref}</BuildActionEntry></BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''', encoding='utf-8')

# Simple geometric test-frame icon, generated as a code-native app asset.
asset_dir = SOURCE / 'Assets.xcassets' / 'AppIcon.appiconset'
asset_dir.mkdir(parents=True, exist_ok=True)
(asset_dir.parent / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}), encoding='utf-8')
(asset_dir / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2), encoding='utf-8')
def chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
pixels = bytearray()
for y in range(1024):
    pixels.append(0)
    for x in range(1024):
        color = (13, 20, 31)
        outer = 190 <= x < 834 and 120 <= y < 904
        inner = 218 <= x < 806 and 148 <= y < 876
        if outer and not inner:
            color = (68, 226, 179)
        if 292 <= x < 732 and 350 <= y < 674:
            color = [(247, 94, 99), (80, 215, 153), (80, 153, 245)][min(2, (x-292)//147)]
        pixels.extend(color)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1024, 1024, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(pixels, 9)) + chunk(b'IEND', b'')
(asset_dir / 'AppIcon.png').write_bytes(png)
print('Generated Xcode project, Info.plist, scheme and icon; Xcode compilation still required.')
