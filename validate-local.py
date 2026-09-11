"""Validate project structure offline; this does not replace an Xcode build."""
from pathlib import Path
import argparse
import datetime
import hashlib
import importlib
import json
import plistlib
import re
import shutil
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--swift-parser-path', type=Path)
    parser.add_argument('--write-report', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    raw = (root / 'ScreenTester.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
    tokens = re.findall(r'"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+', '\n'.join(raw.splitlines()[1:]))
    position = 0

    def take(expected=None):
        nonlocal position
        token = tokens[position]
        position += 1
        if expected is not None:
            assert token == expected, (token, expected)
        return token

    def value():
        token = take()
        if token == '{':
            result = {}
            while tokens[position] != '}':
                key = value()
                assert key not in result, f'Duplicate project key: {key}'
                take('=')
                result[key] = value()
                take(';')
            take('}')
            return result
        if token == '(':
            result = []
            while tokens[position] != ')':
                result.append(value())
                take(',')
            take(')')
            return result
        return json.loads(token) if token.startswith('"') else token

    project = value()
    assert position == len(tokens)
    objects = project['objects']
    project_object = objects[project['rootObject']]
    reference_keys = {'fileRef', 'buildConfigurationList', 'productReference', 'mainGroup', 'productRefGroup', 'target', 'targetProxy', 'containerPortal', 'remoteGlobalIDString'}
    list_keys = {'children', 'files', 'buildPhases', 'buildConfigurations', 'targets', 'dependencies'}
    for key, entry in objects.items():
        assert re.fullmatch(r'[0-9A-F]{24}', key), key
        for name, item in entry.items():
            if name in reference_keys:
                assert item in objects, (name, item)
            if name in list_keys:
                assert all(ref in objects for ref in item), (name, item)

    source_paths = {}

    def check_group(identifier, parent):
        entry = objects[identifier]
        if entry.get('sourceTree') == 'BUILT_PRODUCTS_DIR':
            return
        path = parent / entry.get('path', '')
        if entry['isa'] == 'PBXGroup':
            assert path.is_dir(), path
            for child in entry['children']:
                check_group(child, path)
        elif entry['isa'] == 'PBXFileReference':
            assert path.exists(), path
            source_paths[identifier] = path

    check_group(project_object['mainGroup'], root)
    compiled_sources = set()
    for entry in objects.values():
        if entry['isa'] == 'PBXSourcesBuildPhase':
            for build_id in entry['files']:
                compiled_sources.add(source_paths[objects[build_id]['fileRef']].resolve())
    all_swift = set(path.resolve() for folder in ['ScreenTester', 'UITests'] for path in (root / folder).glob('*.swift'))
    assert compiled_sources == all_swift, 'Swift files missing from compile phases'

    for entry in objects.values():
        settings = entry.get('buildSettings', {})
        if settings.get('PRODUCT_BUNDLE_IDENTIFIER') == 'com.local.screentester':
            assert settings['MARKETING_VERSION'] == '0.3.1'
            assert settings['CURRENT_PROJECT_VERSION'] == '5'
    info = plistlib.loads((root / 'ScreenTester/Info.plist').read_bytes())
    assert info['CFBundlePackageType'] == 'APPL'
    assert info['UIApplicationSceneManifest']['UIApplicationSupportsMultipleScenes'] is False
    scheme = ET.parse(root / 'ScreenTester.xcodeproj/xcshareddata/xcschemes/ScreenTester.xcscheme')
    for element in scheme.findall('.//BuildableReference'):
        assert objects[element.attrib['BlueprintIdentifier']]['isa'] == 'PBXNativeTarget'
    for path in (root / 'ScreenTester/Assets.xcassets').rglob('*.json'):
        json.loads(path.read_text(encoding='utf-8'))
    icon = (root / 'ScreenTester/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
    assert icon[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>IIBB', icon[16:26]) == (1024, 1024, 8, 2), 'Expected a 1024 x 1024 opaque RGB app icon'

    bash = shutil.which('bash')
    git_bash = Path(r'C:\Program Files\Git\bin\bash.exe')
    if sys.platform == 'win32' and git_bash.exists():
        bash = str(git_bash)
    if bash:
        for path in root.glob('*.command'):
            subprocess.run([bash, '-n', str(path)], check=True)

    syntax_status = 'NOT RUN: optional tree-sitter and tree-sitter-swift unavailable'
    if args.swift_parser_path:
        sys.path.insert(0, str(args.swift_parser_path.resolve()))
    try:
        tree_sitter = importlib.import_module('tree_sitter')
        swift_grammar = importlib.import_module('tree_sitter_swift')
    except ImportError:
        if args.swift_parser_path:
            raise
    else:
        swift_parser = tree_sitter.Parser(tree_sitter.Language(swift_grammar.language()))
        for path in sorted(all_swift):
            tree = swift_parser.parse(path.read_bytes())
            assert not tree.root_node.has_error, f'Swift grammar errors: {path}'
        syntax_status = f'PASS: grammar parsed for {len(all_swift)} Swift files; not SDK type checking'

    report = {
        'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'app_version': '0.3.1',
        'app_build': '5',
        'report_scope': 'Offline source checks; see CLOUD-BUILD.json for native build results',
        'project_object_references': 'PASS',
        'source_paths_and_compile_phases': 'PASS',
        'info_plist_and_scene_configuration': 'PASS',
        'shared_scheme_targets': 'PASS',
        'asset_catalog_json': 'PASS',
        'app_icon': 'PASS: 1024 x 1024, 8-bit RGB PNG',
        'app_icon_sha256': hashlib.sha256(icon).hexdigest(),
        'bash_syntax': 'PASS' if bash else 'NOT RUN: bash unavailable',
        'swift_syntax': syntax_status,
        'swift_compilation': 'NOT RUN: requires macOS/Xcode',
        'native_simulator_execution': 'NOT RUN: requires macOS/Xcode',
        'iphone_device_validation': 'NOT RUN',
        'ipa_generated': False,
        'source_sha256': {str(path.relative_to(root)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(all_swift)},
    }
    if args.write_report:
        (root / 'VALIDATION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
