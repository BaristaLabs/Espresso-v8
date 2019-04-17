#!/usr/bin/env python

import glob
import os
import re
import string
import sys
import subprocess
import shutil

V8_URL = 'https://chromium.googlesource.com/v8/v8.git'
V8_VERSION = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('V8_VERSION', '')

# Use only Last Known Good Revision branches
if V8_VERSION == '':
	V8_VERSION = 'lkgr' 
elif V8_VERSION.count('.') < 2 and all(x.isdigit() for x in V8_VERSION.split('.')):
	V8_VERSION += '-lkgr' 


PLATFORM = sys.argv[2] if len(sys.argv) > 2 else os.environ.get('PLATFORM', '')
PLATFORMS = [PLATFORM] if PLATFORM else ['x64']

CONFIGURATION = sys.argv[3] if len(sys.argv) > 3 else os.environ.get('CONFIGURATION', '')
CONFIGURATIONS = [CONFIGURATION] if CONFIGURATION else ['Release']

PACKAGES = ['v8']

BIN_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'bin')
GN = os.path.join(BIN_DIR, 'gn.exe')
NINJA = os.path.join(BIN_DIR, 'ninja.exe')

GN_OPTIONS = [
	'is_component_build=false',
	'v8_static_library=true',
	'use_custom_libcxx=false',
	'use_custom_libcxx_for_host=false',
	'v8_use_external_startup_data=true',
	'is_clang=false',
	'treat_warnings_as_errors=false',
	'symbol_level=1',
	'v8_enable_fast_mksnapshot=true',
]

def git_fetch(url, target):
	if isinstance(url, dict):
		#url = url['url']
		#if url['condition'] == 'checkut_android':
		return
	parts = url.split('.git@')
	if len(parts) > 1:
		url = parts[0] + '.git'
		ref = parts[1]
	else:
		ref = 'HEAD'
	print 'Fetch {}@{} into {}'.format(url, ref, target)

	if not os.path.isdir(os.path.join(target, '.git')):
		subprocess.check_call(['git', 'init', target])
	fetch_args = ['git', 'fetch', '--depth=1', '--update-shallow', '--update-head-ok', '--quiet', url, ref]
	if subprocess.call(fetch_args, cwd=target) != 0:
		print 'RETRY:', target
		shutil.rmtree(target, ignore_errors=True)
		subprocess.check_call(['git', 'init', target])
		subprocess.check_call(fetch_args, cwd=target)
	subprocess.check_call(['git', 'checkout', '-f', '-B', 'Branch_'+ref, 'FETCH_HEAD'], cwd=target)

def rmtree(dir):
	if os.path.isdir(dir):
		shutil.rmtree(dir)

def copytree(src_dir, dest_dir):
	if not os.path.isdir(dest_dir):
		os.makedirs(dest_dir)
	for path in glob.iglob(src_dir):
		shutil.copy(path, dest_dir)


# __main__

## Fetch V8 sources
git_fetch(V8_URL+'@'+V8_VERSION, 'v8')

## Fetch V8 source dependencies besides tests
Var = lambda name: vars[name]
deps = open('v8/DEPS').read()
exec deps
for dep in deps:
	if not dep.startswith('v8/test/'):
		git_fetch(deps[dep], dep)

### Get v8 version from defines in v8-version.h
v8_version_h = open('v8/include/v8-version.h').read()
version = string.join(map(lambda name: re.search(r'^#define\s+'+name+r'\s+(\d+)$', v8_version_h, re.M).group(1), \
	['V8_MAJOR_VERSION', 'V8_MINOR_VERSION', 'V8_BUILD_NUMBER', 'V8_PATCH_LEVEL']), '.')

vs_versions = {
	'12.0': { 'version': '2013', 'toolset': 'v120' },
	'14.0': { 'version': '2015', 'toolset': 'v140' },
	'15.0': { 'version': '2017', 'toolset': 'v141' },
	'16.0': { 'version': '2019', 'toolset': 'v142' },
}
vs_version = vs_versions[os.environ.get('VisualStudioVersion', '16.0')]
toolset = vs_version['toolset']
vs_version = vs_version['version']
vs_install_dir = os.path.abspath(os.path.join(os.environ['VCINSTALLDIR'], os.pardir))

env = os.environ.copy()
env['SKIP_V8_GYP_ENV'] = '1'
env['DEPOT_TOOLS_WIN_TOOLCHAIN'] = '0'
env['GYP_MSVS_VERSION'] = vs_version
env['GYP_MSVS_OVERRIDE_PATH'] = vs_install_dir

print 'V8 version', version
print 'Visual Studio', vs_version, 'in', vs_install_dir
print 'C++ Toolset', toolset

# Copy GN to the V8 buildtools in order to work v8gen script
shutil.copy(GN, 'v8/buildtools/win')

# Generate LASTCHANGE file
# similiar to `lastchange` hook from DEPS
if os.path.isfile('v8/build/util/lastchange.py'):
	subprocess.check_call([sys.executable, 'lastchange.py', '-o', 'LASTCHANGE'], cwd='v8/build/util', env=env)

## Build V8
for arch in PLATFORMS:
	arch = arch.lower()
	for conf in CONFIGURATIONS:
		### Generate build.ninja files in out.gn/V8_VERSION/toolset/arch/conf directory
		out_dir = os.path.join(V8_VERSION, toolset, arch, conf)
		builder = ('ia32' if arch == 'x86' else arch) + '.' + conf.lower()
		subprocess.check_call([sys.executable, 'tools/dev/v8gen.py',
			'-b', builder, out_dir, '-vv', '--'] + GN_OPTIONS, cwd='v8', env=env)
		### Build V8 with ninja from the generated files
		out_dir = os.path.join('out.gn', out_dir)
		subprocess.check_call([NINJA, '-C', out_dir, 'v8'], cwd='v8', env=env)

	if arch == 'x86':
		platform = "('$(Platform)' == 'x86' Or '$(Platform)' == 'Win32')"
	else:
		platform = "'$(Platform)' == '{}'".format(arch)
	condition = "'$(PlatformToolset)' == '{}' And {}".format(toolset, platform)

	## Build NuGet packages
	for name in PACKAGES:
		## Generate property sheets with specific conditions
		props = open('nuget/{}.props'.format(name)).read()
		props = props.replace('$Condition$', condition)
		open('nuget/{}-{}-{}.props'.format(name, toolset, arch), 'w+').write(props)

		nuspec = name + '.nuspec'
		print 'NuGet pack {} for V8 {} {} {}'.format(nuspec, version, toolset, arch)
		nuget_args = [
			'-NoPackageAnalysis',
			'-Version', version,
			'-Properties', 'Platform='+arch+';PlatformToolset='+toolset+';BuildVersion='+V8_VERSION,
			'-OutputDirectory', '..'
		]
		subprocess.check_call(['nuget', 'pack', nuspec] + nuget_args, cwd='nuget')
		os.remove('nuget/{}-{}-{}.props'.format(name, toolset, arch))