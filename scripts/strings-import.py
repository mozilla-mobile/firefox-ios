#!/usr/bin/env python

#
# strings-import.py project.xcodeproj strings-directory
#

import glob
import os
import sys

from mod_pbxproj import XcodeProject, PBXFileReference, PBXBuildFile, PBXVariantGroup

TARGETS = {
    "Client":    {"path": "Client"},
    "ShareTo":   {"path": "Extensions/ShareTo"},
    "SendTo":    {"path": "Extensions/SendTo"},
    "Today":     {"path": "Extensions/Today"},
    "ViewLater": {"path": "Extensions/ViewLater"},
    "Shared":    {"path": "Shared"},
}

LOCALES_TO_SKIP = []

def get_groups(project):
    return [group for group in project.objects.values() if group.get('isa') == 'PBXGroup']

def find_group(project, path):
    for group in project.objects.values():
        if group.get('isa') == 'PBXGroup':
            if group.get('path') == path:
                return group

def find_target(project, name):
    for target in project.get_build_phases('PBXNativeTarget'):
        if target['name'] == name:
            return target

def find_resources_phase(project, target):
    if not target:
        return None
    build_phases = target['buildPhases']
    for build_phase_id in target['buildPhases']:
        phase = project.objects.get(build_phase_id)
        if not phase:
            continue
        if phase.get('isa') == 'PBXResourcesBuildPhase':
            return phase

# TODO This should come from the transformed XLIFF files
def paths_for_localized_resources(path):
    return [path for path in glob.glob(path + "/*.lproj/*.strings")]

# TODO Rewrite to make more robust
def locale_name_from_path(path):
    directory_path = os.path.dirname(path)
    lproj_name = directory_path.split(os.sep)[-1]
    return lproj_name.split(".")[0]

def add_file_reference(project, path, variant_group):
    file_reference = PBXFileReference.Create(path, name=locale_name_from_path(path), tree="<group>")
    project.objects[file_reference.id] = file_reference
    variant_group.add_child(file_reference)

    project.modified = True

    return file_reference

def get_or_add_variant_group(project, name, parent_group, phase):
    for variant_group in project.objects.values():
        if variant_group.get('isa') == 'PBXVariantGroup':
            if variant_group.get('name') == name and parent_group.has_child(variant_group.id):
                # If the variantgroup with the name exists and it is part of
                # our parent group then we assume it has been setup correctly.
                return variant_group

    variant_group = PBXVariantGroup.Create(name)
    project.objects[variant_group.id] = variant_group
    parent_group.add_child(variant_group)

    build_file = PBXBuildFile.Create(variant_group)
    project.objects[build_file.id] = build_file
    phase.add_build_file(build_file)

    project.modified = True

    return variant_group

if __name__ == "__main__":
    project = XcodeProject.Load("Client.xcodeproj/project.pbxproj")
    if not project:
        print "Can't open ", "Client.xcodeproj/project.pbxproj"
        sys.exit(1)

    for target_name in TARGETS.keys():
        target = find_target(project, target_name)
        if not target:
            print "Can't find target ", target_name
            sys.exit(1)

        parent_group = find_group(project, target_name)
        if not parent_group:
            print "Can't find group ", target_name
            sys.exit(1)

        phase = find_resources_phase(project, target)
        if not phase:
            print "Can't find 'PBXResourcesBuildPhase' phase for target ", target_name
            sys.exit(1)

        if target and parent_group and phase:
            for path in paths_for_localized_resources(TARGETS[target_name]["path"]):
                locale_name = locale_name_from_path(path)
                if locale_name in LOCALES_TO_SKIP:
                    continue

                print "%s (%s): %s" % (target_name, locale_name, path)
                file_name = os.path.basename(path)

                variant_group = get_or_add_variant_group(project, file_name, parent_group, phase)

                # This is hacky - Trying to add these files as group relative to see if we can
                # get rid of the xx.lproj part in the exported filenames. (Does not work)
                c = path.split(os.sep)
                group_relative_path = c[-2] + "/" + c[-1]

                file_reference = add_file_reference(project, group_relative_path, variant_group)

    project.save()
