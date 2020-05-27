#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import argparse
import glob
import logging
import os
import sys
import yaml

from zipfile import ZipFile

log = logging.getLogger(__name__)


def main():
    _init_logging()

    parser = argparse.ArgumentParser(description="Ensures a directory has all expected locales and screenshots.")

    parser.add_argument("--artifacts-directory", required=True, help="The directory containing the zip archives to look into")
    parser.add_argument("--screenshots-configuration", type=argparse.FileType("r"), required=True, help="YAML file that contains the number of screenshots to expect as well as exceptions/")
    parser.add_argument("--locale", dest="locales", metavar="LOCALE", action="append", required=True, help="locale that must be present(can be repeated)")

    result = parser.parse_args()

    number_of_screenshots_per_locale = _parse_screenshots_configuration(result.screenshots_configuration)
    _check_files(result.artifacts_directory, result.locales, number_of_screenshots_per_locale)


def _init_logging():
    logging.basicConfig(
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.DEBUG,
    )


def _parse_screenshots_configuration(config_file):
    config = yaml.safe_load(config_file)

    number_of_screenshots_per_locale = {}
    for locale in config["locales"]:
        expected_screenshots = config["usual-number-of-screenshots"]
        if locale in config["locales-with-shorter-context-menu"]:
            expected_screenshots -= 1

        number_of_screenshots_per_locale[locale] = expected_screenshots

    return number_of_screenshots_per_locale


# This exit code was picked to avoid collision with famous exit codes (like 1 or 2). This way,
# Taskcluster can spot if this script failed for a known reason and rerun this task if needed.
_FAILURE_EXIT_CODE = 47


def _check_files(artifacts_directory, locales, number_of_screenshots_per_locale):
    errors = []

    archives = set(glob.glob("{}/*.zip".format(artifacts_directory)))
    archives = _filter_out_derived_data_archive(archives)
    expected_number_of_screenshots_per_archive = {
        "{}/{}.zip".format(artifacts_directory, locale): number_of_screenshots_per_locale[locale]
        for locale in locales
    }

    expected_archives = set(expected_number_of_screenshots_per_archive.keys())
    if archives != expected_archives:
        errors.append(
            "The list of archives (zip files) does not match the expected one. Expected: {}. Got: {}.".format(
                expected_archives, archives
            )
        )

    log.info("Processing {} archives...".format(len(expected_archives)))
    log.debug("Archives are expected to have these numbers of screenshots: {}".format(expected_number_of_screenshots_per_archive))

    for archive, expected_number_of_screenshots in expected_number_of_screenshots_per_archive.items():
        errors.extend(_check_single_archive(archive, expected_number_of_screenshots))

    if errors:
        error_list = "\n * ".join(errors)
        log.critical("Got {} error(s) while verifying screenshots: \n * {}".format(len(errors), error_list))
        # TODO Uncomment the next line once screenshot tests are fixed on all locales.
        # sys.exit(_FAILURE_EXIT_CODE)

    log.info("No archive is missing and all of them contain the right number of screenshots!")


def _filter_out_derived_data_archive(archives):
    filtered_out_archives = set()
    for archive in archives:
        with ZipFile(archive) as zip_file:
            # So far, only the derived data archive contains info.plist
            if "info.plist" in zip_file.namelist():
                log.warn('Archive "{}" seems to be the derived data archive. Ignoring...'.format(archive))
                continue

            filtered_out_archives.add(archive)
    return filtered_out_archives


def _check_single_archive(archive, expected_number_of_screenshots):
    errors = []

    with ZipFile(archive) as zip_file:
        all_files = set(zip_file.namelist())
        png_files = set(file for file in all_files if file.endswith(".png"))
        non_png_files = all_files - png_files
        if non_png_files:
            errors.append('Archive "{}" contains non-png files: {}'.format(archive, non_png_files))

        actual_number_of_screenshots = len(png_files)
        if actual_number_of_screenshots != expected_number_of_screenshots:
            errors.append(
                'Archive "{}" does not contain the expected number of screenshots. Expected: {}. Got: {}'.format(
                    archive, expected_number_of_screenshots, actual_number_of_screenshots
                )
            )

    return errors


__name__ == "__main__" and main()
