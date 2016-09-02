from __future__ import absolute_import

import logging
import warnings

from pip.basecommand import Command
from pip.exceptions import CommandError
from pip.index import PackageFinder
from pip.utils import (
    get_installed_distributions, dist_is_editable)
from pip.utils.deprecation import RemovedInPip10Warning
from pip.cmdoptions import make_option_group, index_group


logger = logging.getLogger(__name__)


class ListCommand(Command):
    """
    List installed packages, including editables.

    Packages are listed in a case-insensitive sorted order.
    """
    name = 'list'
    usage = """
      %prog [options]"""
    summary = 'List installed packages.'

    def __init__(self, *args, **kw):
        super(ListCommand, self).__init__(*args, **kw)

        cmd_opts = self.cmd_opts

        cmd_opts.add_option(
            '-o', '--outdated',
            action='store_true',
            default=False,
            help='List outdated packages')
        cmd_opts.add_option(
            '-u', '--uptodate',
            action='store_true',
            default=False,
            help='List uptodate packages')
        cmd_opts.add_option(
            '-e', '--editable',
            action='store_true',
            default=False,
            help='List editable projects.')
        cmd_opts.add_option(
            '-l', '--local',
            action='store_true',
            default=False,
            help=('If in a virtualenv that has global access, do not list '
                  'globally-installed packages.'),
        )
        self.cmd_opts.add_option(
            '--user',
            dest='user',
            action='store_true',
            default=False,
            help='Only output packages installed in user-site.')

        cmd_opts.add_option(
            '--pre',
            action='store_true',
            default=False,
            help=("Include pre-release and development versions. By default, "
                  "pip only finds stable versions."),
        )

        index_opts = make_option_group(index_group, self.parser)

        self.parser.insert_option_group(0, index_opts)
        self.parser.insert_option_group(0, cmd_opts)

    def _build_package_finder(self, options, index_urls, session):
        """
        Create a package finder appropriate to this list command.
        """
        return PackageFinder(
            find_links=options.find_links,
            index_urls=index_urls,
            allow_all_prereleases=options.pre,
            trusted_hosts=options.trusted_hosts,
            process_dependency_links=options.process_dependency_links,
            session=session,
        )

    def run(self, options, args):
        if options.allow_external:
            warnings.warn(
                "--allow-external has been deprecated and will be removed in "
                "the future. Due to changes in the repository protocol, it no "
                "longer has any effect.",
                RemovedInPip10Warning,
            )

        if options.allow_all_external:
            warnings.warn(
                "--allow-all-external has been deprecated and will be removed "
                "in the future. Due to changes in the repository protocol, it "
                "no longer has any effect.",
                RemovedInPip10Warning,
            )

        if options.allow_unverified:
            warnings.warn(
                "--allow-unverified has been deprecated and will be removed "
                "in the future. Due to changes in the repository protocol, it "
                "no longer has any effect.",
                RemovedInPip10Warning,
            )
        if options.outdated and options.uptodate:
            raise CommandError(
                "Options --outdated and --uptodate cannot be combined.")

        if options.outdated:
            self.run_outdated(options)
        elif options.uptodate:
            self.run_uptodate(options)
        else:
            self.run_listing(options)

    def run_outdated(self, options):
        for dist, latest_version, typ in sorted(
                self.find_packages_latest_versions(options),
                key=lambda p: p[0].project_name.lower()):
            if latest_version > dist.parsed_version:
                logger.info(
                    '%s - Latest: %s [%s]',
                    self.output_package(dist), latest_version, typ,
                )

    def find_packages_latest_versions(self, options):
        index_urls = [options.index_url] + options.extra_index_urls
        if options.no_index:
            logger.info('Ignoring indexes: %s', ','.join(index_urls))
            index_urls = []

        dependency_links = []
        for dist in get_installed_distributions(
                local_only=options.local,
                user_only=options.user,
                editables_only=options.editable):
            if dist.has_metadata('dependency_links.txt'):
                dependency_links.extend(
                    dist.get_metadata_lines('dependency_links.txt'),
                )

        with self._build_session(options) as session:
            finder = self._build_package_finder(options, index_urls, session)
            finder.add_dependency_links(dependency_links)

            installed_packages = get_installed_distributions(
                local_only=options.local,
                user_only=options.user,
                editables_only=options.editable,
            )
            for dist in installed_packages:
                typ = 'unknown'
                all_candidates = finder.find_all_candidates(dist.key)
                if not options.pre:
                    # Remove prereleases
                    all_candidates = [candidate for candidate in all_candidates
                                      if not candidate.version.is_prerelease]

                if not all_candidates:
                    continue
                best_candidate = max(all_candidates,
                                     key=finder._candidate_sort_key)
                remote_version = best_candidate.version
                if best_candidate.location.is_wheel:
                    typ = 'wheel'
                else:
                    typ = 'sdist'
                yield dist, remote_version, typ

    def run_listing(self, options):
        installed_packages = get_installed_distributions(
            local_only=options.local,
            user_only=options.user,
            editables_only=options.editable,
        )
        self.output_package_listing(installed_packages)

    def output_package(self, dist):
        if dist_is_editable(dist):
            return '%s (%s, %s)' % (
                dist.project_name,
                dist.version,
                dist.location,
            )
        else:
            return '%s (%s)' % (dist.project_name, dist.version)

    def output_package_listing(self, installed_packages):
        installed_packages = sorted(
            installed_packages,
            key=lambda dist: dist.project_name.lower(),
        )
        for dist in installed_packages:
            logger.info(self.output_package(dist))

    def run_uptodate(self, options):
        uptodate = []
        for dist, version, typ in self.find_packages_latest_versions(options):
            if dist.parsed_version == version:
                uptodate.append(dist)
        self.output_package_listing(uptodate)
