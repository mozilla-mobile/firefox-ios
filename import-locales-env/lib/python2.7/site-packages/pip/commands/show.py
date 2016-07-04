from __future__ import absolute_import

from email.parser import FeedParser
import logging
import os

from pip.basecommand import Command
from pip.status_codes import SUCCESS, ERROR
from pip._vendor import pkg_resources


logger = logging.getLogger(__name__)


class ShowCommand(Command):
    """Show information about one or more installed packages."""
    name = 'show'
    usage = """
      %prog [options] <package> ..."""
    summary = 'Show information about installed packages.'

    def __init__(self, *args, **kw):
        super(ShowCommand, self).__init__(*args, **kw)
        self.cmd_opts.add_option(
            '-f', '--files',
            dest='files',
            action='store_true',
            default=False,
            help='Show the full list of installed files for each package.')

        self.parser.insert_option_group(0, self.cmd_opts)

    def run(self, options, args):
        if not args:
            logger.warning('ERROR: Please provide a package name or names.')
            return ERROR
        query = args

        results = search_packages_info(query)
        if not print_results(results, options.files):
            return ERROR
        return SUCCESS


def search_packages_info(query):
    """
    Gather details from installed distributions. Print distribution name,
    version, location, and installed files. Installed files requires a
    pip generated 'installed-files.txt' in the distributions '.egg-info'
    directory.
    """
    installed = dict(
        [(p.project_name.lower(), p) for p in pkg_resources.working_set])
    query_names = [name.lower() for name in query]
    for dist in [installed[pkg] for pkg in query_names if pkg in installed]:
        package = {
            'name': dist.project_name,
            'version': dist.version,
            'location': dist.location,
            'requires': [dep.project_name for dep in dist.requires()],
        }
        file_list = None
        metadata = None
        if isinstance(dist, pkg_resources.DistInfoDistribution):
            # RECORDs should be part of .dist-info metadatas
            if dist.has_metadata('RECORD'):
                lines = dist.get_metadata_lines('RECORD')
                paths = [l.split(',')[0] for l in lines]
                paths = [os.path.join(dist.location, p) for p in paths]
                file_list = [os.path.relpath(p, dist.location) for p in paths]

            if dist.has_metadata('METADATA'):
                metadata = dist.get_metadata('METADATA')
        else:
            # Otherwise use pip's log for .egg-info's
            if dist.has_metadata('installed-files.txt'):
                paths = dist.get_metadata_lines('installed-files.txt')
                paths = [os.path.join(dist.egg_info, p) for p in paths]
                file_list = [os.path.relpath(p, dist.location) for p in paths]

            if dist.has_metadata('PKG-INFO'):
                metadata = dist.get_metadata('PKG-INFO')

        if dist.has_metadata('entry_points.txt'):
            entry_points = dist.get_metadata_lines('entry_points.txt')
            package['entry_points'] = entry_points

        installer = None
        if dist.has_metadata('INSTALLER'):
            for line in dist.get_metadata_lines('INSTALLER'):
                if line.strip():
                    installer = line.strip()
                    break
        package['installer'] = installer

        # @todo: Should pkg_resources.Distribution have a
        # `get_pkg_info` method?
        feed_parser = FeedParser()
        feed_parser.feed(metadata)
        pkg_info_dict = feed_parser.close()
        for key in ('metadata-version', 'summary',
                    'home-page', 'author', 'author-email', 'license'):
            package[key] = pkg_info_dict.get(key)

        # It looks like FeedParser can not deal with repeated headers
        classifiers = []
        for line in metadata.splitlines():
            if not line:
                break
            # Classifier: License :: OSI Approved :: MIT License
            if line.startswith('Classifier: '):
                classifiers.append(line[len('Classifier: '):])
        package['classifiers'] = classifiers

        if file_list:
            package['files'] = sorted(file_list)
        yield package


def print_results(distributions, list_all_files):
    """
    Print the informations from installed distributions found.
    """
    results_printed = False
    for dist in distributions:
        results_printed = True
        logger.info("---")
        logger.info("Metadata-Version: %s", dist.get('metadata-version'))
        logger.info("Name: %s", dist['name'])
        logger.info("Version: %s", dist['version'])
        logger.info("Summary: %s", dist.get('summary'))
        logger.info("Home-page: %s", dist.get('home-page'))
        logger.info("Author: %s", dist.get('author'))
        logger.info("Author-email: %s", dist.get('author-email'))
        if dist['installer'] is not None:
            logger.info("Installer: %s", dist['installer'])
        logger.info("License: %s", dist.get('license'))
        logger.info("Location: %s", dist['location'])
        logger.info("Requires: %s", ', '.join(dist['requires']))
        logger.info("Classifiers:")
        for classifier in dist['classifiers']:
            logger.info("  %s", classifier)
        if list_all_files:
            logger.info("Files:")
            if 'files' in dist:
                for line in dist['files']:
                    logger.info("  %s", line.strip())
            else:
                logger.info("Cannot locate installed-files.txt")
        if 'entry_points' in dist:
            logger.info("Entry-points:")
            for line in dist['entry_points']:
                logger.info("  %s", line.strip())
    return results_printed
