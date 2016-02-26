#  Copyright 2012 Calvin Rien
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#  A pbxproj file is an OpenStep format plist
#  {} represents dictionary of key=value pairs delimited by ;
#  () represents list of values delimited by ,
#  file starts with a comment specifying the character type
#  // !$*UTF8*$!

#  when adding a file to a project, create the PBXFileReference
#  add the PBXFileReference's guid to a group
#  create a PBXBuildFile with the PBXFileReference's guid
#  add the PBXBuildFile to the appropriate build phase

#  when adding a header search path add
#  HEADER_SEARCH_PATHS = "path/**";
#  to each XCBuildConfiguration object

#  Xcode4 will read either a OpenStep or XML plist.
#  this script uses `plutil` to validate, read and write
#  the pbxproj file.  Plutil is available in OS X 10.2 and higher
#  Plutil can't write OpenStep plists, so I save as XML

import datetime
import json
import ntpath
import os
import plistlib
import re
import shutil
import subprocess
import uuid

from UserDict import IterableUserDict
from UserList import UserList

regex = '[a-zA-Z0-9\\._/-]*'


class PBXEncoder(json.JSONEncoder):
    def default(self, obj):
        """Tests the input object, obj, to encode as JSON."""

        if isinstance(obj, (PBXList, PBXDict)):
            return obj.data

        return json.JSONEncoder.default(self, obj)


class PBXDict(IterableUserDict):
    def __init__(self, d=None):
        if d:
            d = dict([(PBXType.Convert(k), PBXType.Convert(v)) for k, v in d.items()])

        IterableUserDict.__init__(self, d)

    def __setitem__(self, key, value):
        IterableUserDict.__setitem__(self, PBXType.Convert(key), PBXType.Convert(value))

    def remove(self, key):
        self.data.pop(PBXType.Convert(key), None)


class PBXList(UserList):
    def __init__(self, l=None):
        if isinstance(l, basestring):
            UserList.__init__(self)
            self.add(l)
            return
        elif l:
            l = [PBXType.Convert(v) for v in l]

        UserList.__init__(self, l)

    def add(self, value):
        value = PBXType.Convert(value)

        if value in self.data:
            return False

        self.data.append(value)
        return True

    def remove(self, value):
        value = PBXType.Convert(value)

        if value in self.data:
            self.data.remove(value)
            return True
        return False

    def __setitem__(self, key, value):
        UserList.__setitem__(self, PBXType.Convert(key), PBXType.Convert(value))


class PBXType(PBXDict):
    def __init__(self, d=None):
        PBXDict.__init__(self, d)

        if 'isa' not in self:
            self['isa'] = self.__class__.__name__
        self.id = None

    @staticmethod
    def Convert(o):
        if isinstance(o, list):
            return PBXList(o)
        elif isinstance(o, dict):
            isa = o.get('isa')

            if not isa:
                return PBXDict(o)

            cls = globals().get(isa)

            if cls and issubclass(cls, PBXType):
                return cls(o)

            print 'warning: unknown PBX type: %s' % isa
            return PBXDict(o)
        else:
            return o

    @staticmethod
    def IsGuid(o):
        return re.match('^[A-F0-9]{24}$', str(o))

    @classmethod
    def GenerateId(cls):
        return ''.join(str(uuid.uuid4()).upper().split('-')[1:])

    @classmethod
    def Create(cls, *args, **kwargs):
        return cls(*args, **kwargs)


class PBXFileReference(PBXType):
    def __init__(self, d=None):
        PBXType.__init__(self, d)
        self.build_phase = None

    types = {
        '.a': ('archive.ar', 'PBXFrameworksBuildPhase'),
        '.app': ('wrapper.application', None),
        '.s': ('sourcecode.asm', 'PBXSourcesBuildPhase'),
        '.c': ('sourcecode.c.c', 'PBXSourcesBuildPhase'),
        '.cpp': ('sourcecode.cpp.cpp', 'PBXSourcesBuildPhase'),
        '.framework': ('wrapper.framework', 'PBXFrameworksBuildPhase'),
        '.h': ('sourcecode.c.h', None),
        '.hpp': ('sourcecode.c.h', None),
        '.swift': ('sourcecode.swift', 'PBXSourcesBuildPhase'),
        '.icns': ('image.icns', 'PBXResourcesBuildPhase'),
        '.m': ('sourcecode.c.objc', 'PBXSourcesBuildPhase'),
        '.j': ('sourcecode.c.objc', 'PBXSourcesBuildPhase'),
        '.mm': ('sourcecode.cpp.objcpp', 'PBXSourcesBuildPhase'),
        '.nib': ('wrapper.nib', 'PBXResourcesBuildPhase'),
        '.plist': ('text.plist.xml', 'PBXResourcesBuildPhase'),
        '.json': ('text.json', 'PBXResourcesBuildPhase'),
        '.png': ('image.png', 'PBXResourcesBuildPhase'),
        '.rtf': ('text.rtf', 'PBXResourcesBuildPhase'),
        '.tiff': ('image.tiff', 'PBXResourcesBuildPhase'),
        '.txt': ('text', 'PBXResourcesBuildPhase'),
        '.xcodeproj': ('wrapper.pb-project', None),
        '.xib': ('file.xib', 'PBXResourcesBuildPhase'),
        '.strings': ('text.plist.strings', 'PBXResourcesBuildPhase'),
        '.bundle': ('wrapper.plug-in', 'PBXResourcesBuildPhase'),
        '.dylib': ('compiled.mach-o.dylib', 'PBXFrameworksBuildPhase')
    }

    trees = [
        '<absolute>',
        '<group>',
        'BUILT_PRODUCTS_DIR',
        'DEVELOPER_DIR',
        'SDKROOT',
        'SOURCE_ROOT',
        ]

    def guess_file_type(self, ignore_unknown_type=False):
        self.remove('explicitFileType')
        self.remove('lastKnownFileType')

        name = os.path.split(self.get('path'))[1]
        ext = os.path.splitext(name)[1]
        if os.path.isdir(self.get('path')) and ext != '.framework' and ext != '.bundle':
            f_type = 'folder'
            build_phase = None
            ext = ''
        else:
            f_type, build_phase = PBXFileReference.types.get(ext, ('?', 'PBXResourcesBuildPhase'))

        self['lastKnownFileType'] = f_type
        self.build_phase = build_phase

        if f_type == '?' and not ignore_unknown_type:
            print 'unknown file extension: %s' % ext
            print 'please add extension and Xcode type to PBXFileReference.types'

        return f_type

    def set_file_type(self, ft):
        self.remove('explicitFileType')
        self.remove('lastKnownFileType')

        self['explicitFileType'] = ft

    @classmethod
    def Create(cls, os_path, name=None, tree='SOURCE_ROOT', ignore_unknown_type=False):
        if tree not in cls.trees:
            print 'Not a valid sourceTree type: %s' % tree
            return None

        fr = cls()
        fr.id = cls.GenerateId()
        fr['path'] = os_path
        if name is None:
            fr['name'] = os.path.split(os_path)[1]
        else:
            fr['name'] = name
        fr['sourceTree'] = '<absolute>' if os.path.isabs(os_path) else tree
        fr.guess_file_type(ignore_unknown_type=ignore_unknown_type)

        return fr


class PBXBuildFile(PBXType):
    def set_weak_link(self, weak=False):
        k_settings = 'settings'
        k_attributes = 'ATTRIBUTES'

        s = self.get(k_settings)

        if not s:
            if weak:
                self[k_settings] = PBXDict({k_attributes: PBXList(['Weak'])})

            return True

        atr = s.get(k_attributes)

        if not atr:
            if weak:
                atr = PBXList()
            else:
                return False

        if weak:
            atr.add('Weak')
        else:
            atr.remove('Weak')

        self[k_settings][k_attributes] = atr

        return True

    def add_compiler_flag(self, flag):
        k_settings = 'settings'
        k_attributes = 'COMPILER_FLAGS'

        if k_settings not in self:
            self[k_settings] = PBXDict()

        if k_attributes not in self[k_settings]:
            self[k_settings][k_attributes] = flag
            return True

        flags = self[k_settings][k_attributes].split(' ')

        if flag in flags:
            return False

        flags.append(flag)

        self[k_settings][k_attributes] = ' '.join(flags)

    @classmethod
    def Create(cls, file_ref, weak=False):
        if isinstance(file_ref, PBXFileReference) or isinstance(file_ref, PBXVariantGroup):
            file_ref = file_ref.id

        bf = cls()
        bf.id = cls.GenerateId()
        bf['fileRef'] = file_ref

        if weak:
            bf.set_weak_link(True)

        return bf


class PBXGroup(PBXType):
    def add_child(self, ref):
        if not isinstance(ref, PBXDict):
            return None

        isa = ref.get('isa')

        if isa != 'PBXFileReference' and isa != 'PBXGroup' and isa != 'PBXVariantGroup':
            return None

        if 'children' not in self:
            self['children'] = PBXList()

        self['children'].add(ref.id)

        return ref.id

    def remove_child(self, id):
        if 'children' not in self:
            self['children'] = PBXList()
            return

        if not PBXType.IsGuid(id):
            id = id.id

        self['children'].remove(id)

    def has_child(self, id):
        if 'children' not in self:
            self['children'] = PBXList()
            return False

        if not PBXType.IsGuid(id):
            id = id.id

        return id in self['children']

    def get_name(self):
        path_name = os.path.split(self.get('path', ''))[1]
        return self.get('name', path_name)

    @classmethod
    def Create(cls, name, path=None, tree='SOURCE_ROOT'):
        grp = cls()
        grp.id = cls.GenerateId()
        grp['name'] = name
        grp['children'] = PBXList()

        if path:
            grp['path'] = path
            grp['sourceTree'] = tree
        else:
            grp['sourceTree'] = '<group>'

        return grp


class PBXNativeTarget(PBXType):
    pass


class PBXProject(PBXType):
    pass


class PBXContainerItemProxy(PBXType):
    pass


class PBXReferenceProxy(PBXType):
    pass


class PBXVariantGroup(PBXType):
    def add_child(self, ref):
        if not isinstance(ref, PBXDict):
            return None

        isa = ref.get('isa')

        if isa != 'PBXFileReference':
            return None

        if 'children' not in self:
            self['children'] = PBXList()

        self['children'].add(ref.id)

        return ref.id

    def remove_child(self, id):
        if 'children' not in self:
            self['children'] = PBXList()
            return

        if not PBXType.IsGuid(id):
            id = id.id

        self['children'].remove(id)

    def has_child(self, id):
        if 'children' not in self:
            self['children'] = PBXList()
            return False

        if not PBXType.IsGuid(id):
            id = id.id

        return id in self['children']

    @classmethod
    def Create(cls, name, path=None, tree='SOURCE_ROOT'):
        grp = cls()
        grp.id = cls.GenerateId()
        grp['name'] = name
        grp['children'] = PBXList()

        if path:
            grp['path'] = path
            grp['sourceTree'] = tree
        else:
            grp['sourceTree'] = '<group>'

        return grp

class PBXTargetDependency(PBXType):
    pass


class PBXAggregateTarget(PBXType):
    pass


class PBXHeadersBuildPhase(PBXType):
    pass


class PBXBuildPhase(PBXType):
    def add_build_file(self, bf):
        if bf.get('isa') != 'PBXBuildFile':
            return False

        if 'files' not in self:
            self['files'] = PBXList()

        self['files'].add(bf.id)

        return True

    def remove_build_file(self, id):
        if 'files' not in self:
            self['files'] = PBXList()
            return

        self['files'].remove(id)

    def has_build_file(self, id):
        if 'files' not in self:
            self['files'] = PBXList()
            return False

        if not PBXType.IsGuid(id):
            id = id.id

        return id in self['files']


class PBXFrameworksBuildPhase(PBXBuildPhase):
    pass


class PBXResourcesBuildPhase(PBXBuildPhase):
    pass


class PBXShellScriptBuildPhase(PBXBuildPhase):
    @classmethod
    def Create(cls, script, shell="/bin/sh", files=[], input_paths=[], output_paths=[], show_in_log = '0'):
        bf = cls()
        bf.id = cls.GenerateId()
        bf['files'] = files
        bf['inputPaths'] = input_paths
        bf['outputPaths'] = output_paths
        bf['runOnlyForDeploymentPostprocessing'] = '0';
        bf['shellPath'] = shell
        bf['shellScript'] = script
        bf['showEnvVarsInLog'] = show_in_log

        return bf


class PBXSourcesBuildPhase(PBXBuildPhase):
    pass


class PBXCopyFilesBuildPhase(PBXBuildPhase):
    pass


class XCBuildConfiguration(PBXType):
    def add_search_paths(self, paths, base, key, recursive=True, escape=True):
        modified = False

        if not isinstance(paths, list):
            paths = [paths]

        if base not in self:
            self[base] = PBXDict()

        for path in paths:
            if recursive and not path.endswith('/**'):
                path = os.path.join(path, '**')

            if key not in self[base]:
                self[base][key] = PBXList()
            elif isinstance(self[base][key], basestring):
                self[base][key] = PBXList(self[base][key])

            if escape:
                if self[base][key].add('"%s"' % path):  # '\\"%s\\"' % path
                    modified = True
            else:
                if self[base][key].add(path):  # '\\"%s\\"' % path
                    modified = True

        return modified

    def add_header_search_paths(self, paths, recursive=True):
        return self.add_search_paths(paths, 'buildSettings', 'HEADER_SEARCH_PATHS', recursive=recursive)

    def add_library_search_paths(self, paths, recursive=True):
        return self.add_search_paths(paths, 'buildSettings', 'LIBRARY_SEARCH_PATHS', recursive=recursive)

    def add_framework_search_paths(self, paths, recursive=True):
        return self.add_search_paths(paths, 'buildSettings', 'FRAMEWORK_SEARCH_PATHS', recursive=recursive)

    def add_other_cflags(self, flags):
        return self.add_flag('OTHER_CFLAGS', flags)

    def add_other_ldflags(self, flags):
        return self.add_flag('OTHER_LDFLAGS', flags)

    def add_flag(self, key, flags):
        modified = False
        base = 'buildSettings'

        if isinstance(flags, basestring):
            flags = PBXList(flags)

        if base not in self:
            self[base] = PBXDict()

        for flag in flags:
            if key not in self[base]:
                self[base][key] = PBXList()
            elif isinstance(self[base][key], basestring):
                self[base][key] = PBXList(self[base][key])

            if self[base][key].add(flag):
                self[base][key] = [e for e in self[base][key] if e]
                modified = True

        return modified

    def remove_flag(self, key, flags):
        modified = False
        base = 'buildSettings'

        if isinstance(flags, basestring):
            flags = PBXList(flags)

        if base in self:  # there are flags, so we can "remove" something
            for flag in flags:
                if key not in self[base]:
                    return False
                elif isinstance(self[base][key], basestring):
                    self[base][key] = PBXList(self[base][key])

                if self[base][key].remove(flag):
                    self[base][key] = [e for e in self[base][key] if e]
                    modified = True

                if len(self[base][key]) == 0:
                    self[base].pop(key, None)

        return modified

    def remove_other_ldflags(self, flags):
        return self.remove_flag('OTHER_LD_FLAGS', flags)

class XCConfigurationList(PBXType):
    pass


class XcodeProject(PBXDict):
    plutil_path = 'plutil'
    special_folders = ['.bundle', '.framework', '.xcodeproj']

    def __init__(self, d=None, path=None):
        if not path:
            path = os.path.join(os.getcwd(), 'project.pbxproj')

        self.pbxproj_path = os.path.abspath(path)
        self.source_root = os.path.abspath(os.path.join(os.path.split(path)[0], '..'))

        IterableUserDict.__init__(self, d)

        self.data = PBXDict(self.data)
        self.objects = self.get('objects')
        self.modified = False

        root_id = self.get('rootObject')

        if root_id:
            self.root_object = self.objects[root_id]
            root_group_id = self.root_object.get('mainGroup')
            self.root_group = self.objects[root_group_id]
        else:
            print "error: project has no root object"
            self.root_object = None
            self.root_group = None

        for k, v in self.objects.iteritems():
            v.id = k

    def add_other_cflags(self, flags):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        for b in build_configs:
            if b.add_other_cflags(flags):
                self.modified = True

    def add_other_ldflags(self, flags):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        for b in build_configs:
            if b.add_other_ldflags(flags):
                self.modified = True

    def remove_other_ldflags(self, flags):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        for b in build_configs:
            if b.remove_other_ldflags(flags):
                self.modified = True

    def add_header_search_paths(self, paths, recursive=True):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        for b in build_configs:
            if b.add_header_search_paths(paths, recursive):
                self.modified = True

    def add_framework_search_paths(self, paths, recursive=True):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        for b in build_configs:
            if b.add_framework_search_paths(paths, recursive):
                self.modified = True

    def add_library_search_paths(self, paths, recursive=True):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        for b in build_configs:
            if b.add_library_search_paths(paths, recursive):
                self.modified = True

    def add_flags(self, pairs, configuration='All'):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        # iterate over all the pairs of configurations
        for b in build_configs:
            if configuration != "All" and b.get('name') != configuration :
                continue

            for k in pairs:
                if b.add_flag(k, pairs[k]):
                    self.modified = True

    def remove_flags(self, pairs, configuration='All'):
        build_configs = [b for b in self.objects.values() if b.get('isa') == 'XCBuildConfiguration']

        # iterate over all the pairs of configurations
        for b in build_configs:
            if configuration != "All" and b.get('name') != configuration :
                continue
            for k in pairs:
                if b.remove_flag(k, pairs[k]):
                    self.modified = True

    def get_obj(self, id):
        return self.objects.get(id)

    def get_ids(self):
        return self.objects.keys()

    def get_files_by_os_path(self, os_path, tree='SOURCE_ROOT'):
        files = [f for f in self.objects.values() if f.get('isa') == 'PBXFileReference'
                                                     and f.get('path') == os_path
                                                     and f.get('sourceTree') == tree]

        return files

    def get_files_by_name(self, name, parent=None):
        if parent:
            files = [f for f in self.objects.values() if f.get('isa') == 'PBXFileReference'
                                                         and f.get('name') == name
                                                         and parent.has_child(f)]
        else:
            files = [f for f in self.objects.values() if f.get('isa') == 'PBXFileReference'
                                                         and f.get('name') == name]

        return files

    def get_build_files(self, id):
        files = [f for f in self.objects.values() if f.get('isa') == 'PBXBuildFile'
                                                     and f.get('fileRef') == id]

        return files

    def get_groups_by_name(self, name, parent=None):
        if parent:
            groups = [g for g in self.objects.values() if g.get('isa') == 'PBXGroup'
                                                          and g.get_name() == name
                                                          and parent.has_child(g)]
        else:
            groups = [g for g in self.objects.values() if g.get('isa') == 'PBXGroup'
                                                          and g.get_name() == name]

        return groups

    def get_or_create_group(self, name, path=None, parent=None):
        if not name:
            return None

        if not parent:
            parent = self.root_group
        elif not isinstance(parent, PBXGroup):
            # assume it's an id
            parent = self.objects.get(parent, self.root_group)

        groups = self.get_groups_by_name(name)

        for grp in groups:
            if parent.has_child(grp.id):
                return grp

        grp = PBXGroup.Create(name, path)
        parent.add_child(grp)

        self.objects[grp.id] = grp

        self.modified = True

        return grp

    def get_groups_by_os_path(self, path):
        path = os.path.abspath(path)

        groups = [g for g in self.objects.values() if g.get('isa') == 'PBXGroup'
                                                      and os.path.abspath(g.get('path', '/dev/null')) == path]

        return groups

    def get_build_phases(self, phase_name):
        phases = [p for p in self.objects.values() if p.get('isa') == phase_name]

        return phases

    def get_relative_path(self, os_path):
        return os.path.relpath(os_path, self.source_root)

    def verify_files(self, file_list, parent=None):
        # returns list of files not in the current project.
        if not file_list:
            return []

        if parent:
            exists_list = [f.get('name') for f in self.objects.values() if f.get('isa') == 'PBXFileReference' and f.get('name') in file_list and parent.has_child(f)]
        else:
            exists_list = [f.get('name') for f in self.objects.values() if f.get('isa') == 'PBXFileReference' and f.get('name') in file_list]

        return set(file_list).difference(exists_list)

    def add_run_script(self, target, script=None):
        result = []
        targets = [t for t in self.get_build_phases('PBXNativeTarget') + self.get_build_phases('PBXAggregateTarget') if t.get('name') == target]
        if len(targets) != 0 :
            script_phase = PBXShellScriptBuildPhase.Create(script)
            for t in targets:
                skip = False
                for buildPhase in t['buildPhases']:
                    if self.objects[buildPhase].get('isa') == 'PBXShellScriptBuildPhase' and self.objects[buildPhase].get('shellScript') == script:
                        skip = True

                if not skip:
                    t['buildPhases'].add(script_phase.id)
                    self.objects[script_phase.id] = script_phase
                    result.append(script_phase)

        return result

    def add_run_script_all_targets(self, script=None):
        result = []
        targets = self.get_build_phases('PBXNativeTarget') + self.get_build_phases('PBXAggregateTarget')
        if len(targets) != 0 :
            script_phase = PBXShellScriptBuildPhase.Create(script)
            for t in targets:
                skip = False
                for buildPhase in t['buildPhases']:
                    if self.objects[buildPhase].get('isa') == 'PBXShellScriptBuildPhase' and self.objects[buildPhase].get('shellScript') == script:
                        skip = True

                if not skip:
                    t['buildPhases'].add(script_phase.id)
                    self.objects[script_phase.id] = script_phase
                    result.append(script_phase)

        return result

    def add_folder(self, os_path, parent=None, excludes=None, recursive=True, create_build_files=True):
        if not os.path.isdir(os_path):
            return []

        if not excludes:
            excludes = []

        results = []

        if not parent:
            parent = self.root_group
        elif not isinstance(parent, PBXGroup):
            # assume it's an id
            parent = self.objects.get(parent, self.root_group)

        path_dict = {os.path.split(os_path)[0]: parent}
        special_list = []

        for (grp_path, subdirs, files) in os.walk(os_path):
            parent_folder, folder_name = os.path.split(grp_path)
            parent = path_dict.get(parent_folder, parent)

            if [sp for sp in special_list if parent_folder.startswith(sp)]:
                continue

            if folder_name.startswith('.'):
                special_list.append(grp_path)
                continue

            if os.path.splitext(grp_path)[1] in XcodeProject.special_folders:
                # if this file has a special extension (bundle or framework mainly) treat it as a file
                special_list.append(grp_path)
                new_files = self.verify_files([folder_name], parent=parent)

                # Ignore this file if it is in excludes
                if new_files and not [m for m in excludes if re.match(m, grp_path)]:
                    results.extend(self.add_file(grp_path, parent, create_build_files=create_build_files))

                continue

            # create group
            grp = self.get_or_create_group(folder_name, path=self.get_relative_path(grp_path), parent=parent)
            path_dict[grp_path] = grp

            results.append(grp)

            file_dict = {}

            for f in files:
                if f[0] == '.' or [m for m in excludes if re.match(m, f)]:
                    continue

                kwds = {
                    'create_build_files': create_build_files,
                    'parent': grp,
                    'name': f
                }

                f_path = os.path.join(grp_path, f)
                file_dict[f_path] = kwds

            new_files = self.verify_files([n.get('name') for n in file_dict.values()], parent=grp)
            add_files = [(k, v) for k, v in file_dict.items() if v.get('name') in new_files]

            for path, kwds in add_files:
                kwds.pop('name', None)
                self.add_file(path, **kwds)

            if not recursive:
                break

        for r in results:
            self.objects[r.id] = r

        return results

    def path_leaf(self, path):
        head, tail = ntpath.split(path)
        return tail or ntpath.basename(head)

    def add_file_if_doesnt_exist(self, f_path, parent=None, tree='SOURCE_ROOT', create_build_files=True, weak=False, ignore_unknown_type=False):
        for obj in self.objects.values():
            if 'path' in obj:
                if self.path_leaf(f_path) == self.path_leaf(obj.get('path')):
                    return []

        return self.add_file(f_path, parent, tree, create_build_files, weak, ignore_unknown_type=ignore_unknown_type)



    def my_add_file_reference(self, f_path, parent=None, tree='SOURCE_ROOT', create_build_files=True, weak=False, ignore_unknown_type=False):
        results = []
        abs_path = ''

        if os.path.isabs(f_path):
            abs_path = f_path

            if not os.path.exists(f_path):
                return results
            elif tree == 'SOURCE_ROOT':
                f_path = os.path.relpath(f_path, self.source_root)
            else:
                tree = '<absolute>'

        if not parent:
            parent = self.root_group
        elif not isinstance(parent, PBXGroup):
            # assume it's an id
            parent = self.objects.get(parent, self.root_group)

        file_ref = PBXFileReference.Create(f_path, tree, ignore_unknown_type=ignore_unknown_type)
        parent.add_child(file_ref)
        results.append(file_ref)
        self.objects[file_ref.id] = file_ref

        build_file = PBXBuildFile.Create(file_ref, weak=weak)
        results.append(build_file)
        self.objects[build_file.id] = build_file

        self.modified = True

        return (file_ref, build_file)



    def add_file(self, f_path, parent=None, tree='SOURCE_ROOT', create_build_files=True, weak=False, ignore_unknown_type=False):
        results = []
        abs_path = ''

        if os.path.isabs(f_path):
            abs_path = f_path

            if not os.path.exists(f_path):
                return results
            elif tree == 'SOURCE_ROOT':
                f_path = os.path.relpath(f_path, self.source_root)
            else:
                tree = '<absolute>'

        if not parent:
            parent = self.root_group
        elif not isinstance(parent, PBXGroup):
            # assume it's an id
            parent = self.objects.get(parent, self.root_group)

        file_ref = PBXFileReference.Create(f_path, tree, ignore_unknown_type=ignore_unknown_type)
        parent.add_child(file_ref)
        results.append(file_ref)

        # create a build file for the file ref
        if file_ref.build_phase and create_build_files:
            phases = self.get_build_phases(file_ref.build_phase)

            for phase in phases:
                build_file = PBXBuildFile.Create(file_ref, weak=weak)

                phase.add_build_file(build_file)
                results.append(build_file)

            if abs_path and tree == 'SOURCE_ROOT' \
                        and os.path.isfile(abs_path) \
                        and file_ref.build_phase == 'PBXFrameworksBuildPhase':
                library_path = os.path.join('$(SRCROOT)', os.path.split(f_path)[0])
                self.add_library_search_paths([library_path], recursive=False)

            if abs_path and tree == 'SOURCE_ROOT' \
                        and not os.path.isfile(abs_path) \
                        and file_ref.build_phase == 'PBXFrameworksBuildPhase':
                framework_path = os.path.join('$(SRCROOT)', os.path.split(f_path)[0])
                self.add_framework_search_paths([framework_path, '$(inherited)'], recursive=False)

        for r in results:
            self.objects[r.id] = r

        if results:
            self.modified = True

        return results

    def check_and_repair_framework(self, base):
        name = os.path.basename(base)

        if ".framework" in name:
            basename = name[:-len(".framework")]

            finalHeaders = os.path.join(base, "Headers")
            finalCurrent = os.path.join(base, "Versions/Current")
            finalLib = os.path.join(base, basename)
            srcHeaders = "Versions/A/Headers"
            srcCurrent = "A"
            srcLib = "Versions/A/" + basename

            if not os.path.exists(finalHeaders):
                os.symlink(srcHeaders, finalHeaders)
            if not os.path.exists(finalCurrent):
                os.symlink(srcCurrent, finalCurrent)
            if not os.path.exists(finalLib):
                os.symlink(srcLib, finalLib)


    def remove_file(self, id, recursive=True):
        if not PBXType.IsGuid(id):
            id = id.id

        if id in self.objects:
            self.objects.remove(id)
            # Remove from PBXResourcesBuildPhase and PBXSourcesBuildPhase if necessary
            buildFiles = [f for f in self.objects.values() if f.get('isa') == 'PBXBuildFile']
            for buildFile in buildFiles:
                if id == buildFile.get('fileRef'):
                    key = buildFile.id
                    PBXRBP = [f for f in self.objects.values() if f.get('isa') == 'PBXResourcesBuildPhase']
                    PBXSBP = [f for f in self.objects.values() if f.get('isa') == 'PBXSourcesBuildPhase']
                    self.objects.remove(key)
                    if PBXSBP[0].has_build_file(key):
                        PBXSBP[0].remove_build_file(key)
                    if PBXRBP[0].has_build_file(key):
                        PBXRBP[0].remove_build_file(key)
            if recursive:
                groups = [g for g in self.objects.values() if g.get('isa') == 'PBXGroup']

                for group in groups:
                    if id in group['children']:
                        group.remove_child(id)

            self.modified = True

    def remove_group(self, id, recursive = False):
        if not PBXType.IsGuid(id):
            id = id.id
        name = self.objects.get(id).get('path')
        children = self.objects.get(id).get('children')
        if name is None:
            name = id
        if id in self.objects:
            if recursive:
                for childKey in children:
                    childValue = self.objects.get(childKey)
                    if childValue.get('isa') == 'PBXGroup':
                        self.remove_group(childKey, True)
                    else:
                        self.remove_file(childKey, False)
            else:
                return
        else:
            return
        self.objects.remove(id);

    def remove_group_by_name(self, name, recursive = False):
        groups = self.get_groups_by_name(name)
        if len(groups):
            for group in groups:
                self.remove_group(group, recursive)
        else:
            return

    def move_file(self, id, dest_grp=None):
        pass

    def apply_patch(self, patch_path, xcode_path):
        if not os.path.isfile(patch_path) or not os.path.isdir(xcode_path):
            print 'ERROR: couldn\'t apply "%s" to "%s"' % (patch_path, xcode_path)
            return

        print 'applying "%s" to "%s"' % (patch_path, xcode_path)

        return subprocess.call(['patch', '-p1', '--forward', '--directory=%s' % xcode_path, '--input=%s' % patch_path])

    def apply_mods(self, mod_dict, default_path=None):
        if not default_path:
            default_path = os.getcwd()

        keys = mod_dict.keys()

        for k in keys:
            v = mod_dict.pop(k)
            mod_dict[k.lower()] = v

        parent = mod_dict.pop('group', None)

        if parent:
            parent = self.get_or_create_group(parent)

        excludes = mod_dict.pop('excludes', [])

        if excludes:
            excludes = [re.compile(e) for e in excludes]

        compiler_flags = mod_dict.pop('compiler_flags', {})

        for k, v in mod_dict.items():
            if k == 'patches':
                for p in v:
                    if not os.path.isabs(p):
                        p = os.path.join(default_path, p)

                    self.apply_patch(p, self.source_root)
            elif k == 'folders':
                # get and compile excludes list
                # do each folder individually
                for folder in v:
                    kwds = {}

                    # if path contains ':' remove it and set recursive to False
                    if ':' in folder:
                        args = folder.split(':')
                        kwds['recursive'] = False
                        folder = args.pop(0)

                    if os.path.isabs(folder) and os.path.isdir(folder):
                        pass
                    else:
                        folder = os.path.join(default_path, folder)
                        if not os.path.isdir(folder):
                            continue

                    if parent:
                        kwds['parent'] = parent

                    if excludes:
                        kwds['excludes'] = excludes

                    self.add_folder(folder, **kwds)
            elif k == 'headerpaths' or k == 'librarypaths':
                paths = []

                for p in v:
                    if p.endswith('/**'):
                        p = os.path.split(p)[0]

                    if not os.path.isabs(p):
                        p = os.path.join(default_path, p)

                    if not os.path.exists(p):
                        continue

                    p = self.get_relative_path(p)
                    paths.append(os.path.join('$(SRCROOT)', p, "**"))

                if k == 'headerpaths':
                    self.add_header_search_paths(paths)
                else:
                    self.add_library_search_paths(paths)
            elif k == 'other_cflags':
                self.add_other_cflags(v)
            elif k == 'other_ldflags':
                self.add_other_ldflags(v)
            elif k == 'libs' or k == 'frameworks' or k == 'files':
                paths = {}

                for p in v:
                    kwds = {}

                    if ':' in p:
                        args = p.split(':')
                        p = args.pop(0)

                        if 'weak' in args:
                            kwds['weak'] = True

                    file_path = os.path.join(default_path, p)
                    search_path, file_name = os.path.split(file_path)

                    if [m for m in excludes if re.match(m, file_name)]:
                        continue

                    try:
                        expr = re.compile(file_name)
                    except re.error:
                        expr = None

                    if expr and os.path.isdir(search_path):
                        file_list = os.listdir(search_path)

                        for f in file_list:
                            if [m for m in excludes if re.match(m, f)]:
                                continue

                            if re.search(expr, f):
                                kwds['name'] = f
                                paths[os.path.join(search_path, f)] = kwds
                                p = None

                    if k == 'libs':
                        kwds['parent'] = self.get_or_create_group('Libraries', parent=parent)
                    elif k == 'frameworks':
                        kwds['parent'] = self.get_or_create_group('Frameworks', parent=parent)

                    if p:
                        kwds['name'] = file_name

                        if k == 'libs':
                            p = os.path.join('usr', 'lib', p)
                            kwds['tree'] = 'SDKROOT'
                        elif k == 'frameworks':
                            p = os.path.join('System', 'Library', 'Frameworks', p)
                            kwds['tree'] = 'SDKROOT'
                        elif k == 'files' and not os.path.exists(file_path):
                            # don't add non-existent files to the project.
                            continue

                        paths[p] = kwds

                new_files = self.verify_files([n.get('name') for n in paths.values()])
                add_files = [(k, v) for k, v in paths.items() if v.get('name') in new_files]

                for path, kwds in add_files:
                    kwds.pop('name', None)

                    if 'parent' not in kwds and parent:
                        kwds['parent'] = parent

                    self.add_file(path, **kwds)

        if compiler_flags:
            for k, v in compiler_flags.items():
                filerefs = []

                for f in v:
                    filerefs.extend([fr.id for fr in self.objects.values() if fr.get('isa') == 'PBXFileReference'
                                                                              and fr.get('name') == f])

                buildfiles = [bf for bf in self.objects.values() if bf.get('isa') == 'PBXBuildFile'
                                                                    and bf.get('fileRef') in filerefs]

                for bf in buildfiles:
                    if bf.add_compiler_flag(k):
                        self.modified = True

    def backup(self, file_name=None, backup_name=None):
        if not file_name:
            file_name = self.pbxproj_path

        if not backup_name:
            backup_name = "%s.%s.backup" % (file_name, datetime.datetime.now().strftime('%d%m%y-%H%M%S'))

        shutil.copy2(file_name, backup_name)
        return backup_name

    def save(self, file_name=None, old_format=False):
        if old_format :
            self.saveFormatXML(file_name)
        else:
            self.saveFormat3_2(file_name)

    def saveFormat3_2(self, file_name=None):
        """Alias for backward compatibility"""
        self.save_new_format(file_name)

    def save_format_xml(self, file_name=None):
        """Saves in old (xml) format"""
        if not file_name:
            file_name = self.pbxproj_path

        # This code is adapted from plistlib.writePlist
        with open(file_name, "w") as f:
            writer = PBXWriter(f)
            writer.writeln("<plist version=\"1.0\">")
            writer.writeValue(self.data)
            writer.writeln("</plist>")

    def save_new_format(self, file_name=None):
        """Save in Xcode 3.2 compatible (new) format"""
        if not file_name:
            file_name = self.pbxproj_path

        # process to get the section's info and names
        objs = self.data.get('objects')
        sections = dict()
        uuids = dict()

        for key in objs:
            l = list()

            if objs.get(key).get('isa') in sections:
                l = sections.get(objs.get(key).get('isa'))

            l.append(tuple([key, objs.get(key)]))
            sections[objs.get(key).get('isa')] = l

            if 'name' in objs.get(key):
                uuids[key] = objs.get(key).get('name')
            elif 'path' in objs.get(key):
                uuids[key] = objs.get(key).get('path')
            else:
                if objs.get(key).get('isa') == 'PBXProject':
                    uuids[objs.get(key).get('buildConfigurationList')] = 'Build configuration list for PBXProject "Unity-iPhone"'
                elif objs.get(key).get('isa')[0:3] == 'PBX':
                    uuids[key] = objs.get(key).get('isa')[3:-10]
                else:
                    uuids[key] = 'Build configuration list for PBXNativeTarget "TARGET_NAME"'

        ro = self.data.get('rootObject')
        uuids[ro] = 'Project Object'

        for key in objs:
            # transitive references (used in the BuildFile section)
            if 'fileRef' in objs.get(key) and objs.get(key).get('fileRef') in uuids:
                uuids[key] = uuids[objs.get(key).get('fileRef')]

            # transitive reference to the target name (used in the Native target section)
            if objs.get(key).get('isa') == 'PBXNativeTarget':
                uuids[objs.get(key).get('buildConfigurationList')] = uuids[objs.get(key).get('buildConfigurationList')].replace('TARGET_NAME', uuids[key])

        self.uuids = uuids
        self.sections = sections

        out = open(file_name, 'w')
        out.write('// !$*UTF8*$!\n')
        self._printNewXCodeFormat(out, self.data, '', enters=True)
        out.close()

    @classmethod
    def addslashes(cls, s):
        d = {'"': '\\"', "'": "\\'", "\0": "\\\0", "\\": "\\\\", "\n":"\\n"}
        return ''.join(d.get(c, c) for c in s)

    def _printNewXCodeFormat(self, out, root, deep, enters=True):
        if isinstance(root, IterableUserDict):
            out.write('{')

            if enters:
                out.write('\n')

            isa = root.pop('isa', '')

            if isa != '':  # keep the isa in the first spot
                if enters:
                    out.write('\t' + deep)

                out.write('isa = ')
                self._printNewXCodeFormat(out, isa, '\t' + deep, enters=enters)
                out.write(';')

                if enters:
                    out.write('\n')
                else:
                    out.write(' ')

            for key in sorted(root.iterkeys()):  # keep the same order as Apple.
                if enters:
                    out.write('\t' + deep)

                if re.match(regex, key).group(0) == key:
                    out.write(key.encode("utf-8") + ' = ')
                else:
                    out.write('"' + key.encode("utf-8") + '" = ')

                if key == 'objects':
                    out.write('{')  # open the objects section

                    if enters:
                        out.write('\n')
                        #root.remove('objects')  # remove it to avoid problems

                    sections = [
                        ('PBXBuildFile', False),
                        ('PBXCopyFilesBuildPhase', True),
                        ('PBXFileReference', False),
                        ('PBXFrameworksBuildPhase', True),
                        ('PBXGroup', True),
                        ('PBXAggregateTarget', True),
                        ('PBXNativeTarget', True),
                        ('PBXProject', True),
                        ('PBXResourcesBuildPhase', True),
                        ('PBXShellScriptBuildPhase', True),
                        ('PBXSourcesBuildPhase', True),
                        ('XCBuildConfiguration', True),
                        ('XCConfigurationList', True),
                        ('PBXTargetDependency', True),
                        ('PBXVariantGroup', True),
                        ('PBXReferenceProxy', True),
                        ('PBXContainerItemProxy', True),
                        ('XCVersionGroup', True)]

                    for section in sections:  # iterate over the sections
                        if self.sections.get(section[0]) is None:
                            continue

                        out.write('\n/* Begin %s section */' % section[0].encode("utf-8"))
                        self.sections.get(section[0]).sort(cmp=lambda x, y: cmp(x[0], y[0]))

                        for pair in self.sections.get(section[0]):
                            key = pair[0]
                            value = pair[1]
                            out.write('\n')

                            if enters:
                                out.write('\t\t' + deep)

                            out.write(key.encode("utf-8"))

                            if key in self.uuids:
                                out.write(" /* " + self.uuids[key].encode("utf-8") + " */")

                            out.write(" = ")
                            self._printNewXCodeFormat(out, value, '\t\t' + deep, enters=section[1])
                            out.write(';')

                        out.write('\n/* End %s section */\n' % section[0].encode("utf-8"))

                    out.write(deep + '\t}')  # close of the objects section
                else:
                    self._printNewXCodeFormat(out, root[key], '\t' + deep, enters=enters)

                out.write(';')

                if enters:
                    out.write('\n')
                else:
                    out.write(' ')

            root['isa'] = isa  # restore the isa for further calls

            if enters:
                out.write(deep)

            out.write('}')

        elif isinstance(root, UserList):
            out.write('(')

            if enters:
                out.write('\n')

            for value in root:
                if enters:
                    out.write('\t' + deep)

                self._printNewXCodeFormat(out, value, '\t' + deep, enters=enters)
                out.write(',')

                if enters:
                    out.write('\n')

            if enters:
                out.write(deep)

            out.write(')')

        else:
            if len(root) > 0 and re.match(regex, root).group(0) == root:
                out.write(root.encode("utf-8"))
            else:
                out.write('"' + XcodeProject.addslashes(root.encode("utf-8")) + '"')

            if root in self.uuids:
                out.write(" /* " + self.uuids[root].encode("utf-8") + " */")

    @classmethod
    def Load(cls, path):
        cls.plutil_path = os.path.join(os.path.split(__file__)[0], 'plutil')

        if not os.path.isfile(XcodeProject.plutil_path):
            cls.plutil_path = 'plutil'

        # load project by converting to xml and then convert that using plistlib
        p = subprocess.Popen([XcodeProject.plutil_path, '-convert', 'xml1', '-o', '-', path], stdout=subprocess.PIPE)
        stdout, stderr = p.communicate()

        # If the plist was malformed, returncode will be non-zero
        if p.returncode != 0:
            print stdout
            return None

        tree = plistlib.readPlistFromString(stdout)
        return XcodeProject(tree, path)

    @classmethod
    def LoadFromXML(cls, path):
        tree = plistlib.readPlist(path)
        return XcodeProject(tree, path)


# The code below was adapted from plistlib.py.

class PBXWriter(plistlib.PlistWriter):
    def writeValue(self, value):
        if isinstance(value, (PBXList, PBXDict)):
            plistlib.PlistWriter.writeValue(self, value.data)
        else:
            plistlib.PlistWriter.writeValue(self, value)

    def simpleElement(self, element, value=None):
        """
        We have to override this method to deal with Unicode text correctly.
        Non-ascii characters have to get encoded as character references.
        """
        if value is not None:
            value = _escapeAndEncode(value)
            self.writeln("<%s>%s</%s>" % (element, value, element))
        else:
            self.writeln("<%s/>" % element)


# Regex to find any control chars, except for \t \n and \r
_controlCharPat = re.compile(
    r"[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x0b\x0c\x0e\x0f"
    r"\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f]")


def _escapeAndEncode(text):
    m = _controlCharPat.search(text)
    if m is not None:
        raise ValueError("strings can't contains control characters; "
                         "use plistlib.Data instead")
    text = text.replace("\r\n", "\n")       # convert DOS line endings
    text = text.replace("\r", "\n")         # convert Mac line endings
    text = text.replace("&", "&amp;")       # escape '&'
    text = text.replace("<", "&lt;")        # escape '<'
    text = text.replace(">", "&gt;")        # escape '>'
    return text.encode("ascii", "xmlcharrefreplace")  # encode as ascii with xml character references

def main():
    import json
    import argparse
    import subprocess
    import shutil
    import os

    parser = argparse.ArgumentParser("Modify an xcode project file using a single command at a time.")
    parser.add_argument('project', help="Project path")
    parser.add_argument('configuration', help="Modify the flags of the given configuration", choices=['Debug', 'Release', 'All'])
    parser.add_argument('-af', help='Add a flag value, in the format key=value', action='append')
    parser.add_argument('-rf', help='Remove a flag value, in the format key=value', action='append')
    parser.add_argument('-b', '--backup', help='Create a temporary backup before modify', action='store_true')
    args = parser.parse_args();


    # open the project file
    if os.path.isdir(args.project) :
        args.project = args.project + "/project.pbxproj"

    if not os.path.isfile(args.project) :
        raise Exception("Project File not found")

    project = XcodeProject.Load(args.project)
    backup_file = None
    if args.backup :
        backup_file = project.backup()

    # apply the commands
    # add flags
    if args.af :
        pairs = {}
        for flag in args.af:
            tokens = flag.split("=")
            pairs[tokens[0]] = tokens[1]
        project.add_flags(pairs, args.configuration)

    # remove flags
    if args.rf :
        pairs = {}
        for flag in args.rf:
            tokens = flag.split("=")
            pairs[tokens[0]] = tokens[1]
        project.remove_flags(pairs, args.configuration)

    # save the file
    project.save()

    # remove backup if everything was ok.
    if args.backup :
        os.remove(backup_file)

if __name__ == "__main__":
    main()
