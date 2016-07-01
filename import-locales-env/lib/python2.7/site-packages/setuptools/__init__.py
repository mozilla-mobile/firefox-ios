"""Extensions to the 'distutils' for large or complex distributions"""

import os
import functools
import distutils.core
import distutils.filelist
from distutils.core import Command as _Command
from distutils.util import convert_path
from fnmatch import fnmatchcase

from setuptools.extern.six.moves import filterfalse, map

import setuptools.version
from setuptools.extension import Extension
from setuptools.dist import Distribution, Feature, _get_unpatched
from setuptools.depends import Require

__all__ = [
    'setup', 'Distribution', 'Feature', 'Command', 'Extension', 'Require',
    'find_packages'
]

__version__ = setuptools.version.__version__

bootstrap_install_from = None

# If we run 2to3 on .py files, should we also convert docstrings?
# Default: yes; assume that we can detect doctests reliably
run_2to3_on_doctests = True
# Standard package names for fixer packages
lib2to3_fixer_packages = ['lib2to3.fixes']


class PackageFinder(object):
    @classmethod
    def find(cls, where='.', exclude=(), include=('*',)):
        """Return a list all Python packages found within directory 'where'

        'where' should be supplied as a "cross-platform" (i.e. URL-style)
        path; it will be converted to the appropriate local path syntax.
        'exclude' is a sequence of package names to exclude; '*' can be used
        as a wildcard in the names, such that 'foo.*' will exclude all
        subpackages of 'foo' (but not 'foo' itself).

        'include' is a sequence of package names to include.  If it's
        specified, only the named packages will be included.  If it's not
        specified, all found packages will be included.  'include' can contain
        shell style wildcard patterns just like 'exclude'.

        The list of included packages is built up first and then any
        explicitly excluded packages are removed from it.
        """
        out = cls._find_packages_iter(convert_path(where))
        out = cls.require_parents(out)
        includes = cls._build_filter(*include)
        excludes = cls._build_filter('ez_setup', '*__pycache__', *exclude)
        out = filter(includes, out)
        out = filterfalse(excludes, out)
        return list(out)

    @staticmethod
    def require_parents(packages):
        """
        Exclude any apparent package that apparently doesn't include its
        parent.

        For example, exclude 'foo.bar' if 'foo' is not present.
        """
        found = []
        for pkg in packages:
            base, sep, child = pkg.rpartition('.')
            if base and base not in found:
                continue
            found.append(pkg)
            yield pkg

    @staticmethod
    def _candidate_dirs(base_path):
        """
        Return all dirs in base_path that might be packages.
        """
        has_dot = lambda name: '.' in name
        for root, dirs, files in os.walk(base_path, followlinks=True):
            # Exclude directories that contain a period, as they cannot be
            #  packages. Mutate the list to avoid traversal.
            dirs[:] = filterfalse(has_dot, dirs)
            for dir in dirs:
                yield os.path.relpath(os.path.join(root, dir), base_path)

    @classmethod
    def _find_packages_iter(cls, base_path):
        candidates = cls._candidate_dirs(base_path)
        return (
            path.replace(os.path.sep, '.')
            for path in candidates
            if cls._looks_like_package(os.path.join(base_path, path))
        )

    @staticmethod
    def _looks_like_package(path):
        return os.path.isfile(os.path.join(path, '__init__.py'))

    @staticmethod
    def _build_filter(*patterns):
        """
        Given a list of patterns, return a callable that will be true only if
        the input matches one of the patterns.
        """
        return lambda name: any(fnmatchcase(name, pat=pat) for pat in patterns)

class PEP420PackageFinder(PackageFinder):
    @staticmethod
    def _looks_like_package(path):
        return True

find_packages = PackageFinder.find

setup = distutils.core.setup

_Command = _get_unpatched(_Command)

class Command(_Command):
    __doc__ = _Command.__doc__

    command_consumes_arguments = False

    def __init__(self, dist, **kw):
        """
        Construct the command for dist, updating
        vars(self) with any keyword parameters.
        """
        _Command.__init__(self, dist)
        vars(self).update(kw)

    def reinitialize_command(self, command, reinit_subcommands=0, **kw):
        cmd = _Command.reinitialize_command(self, command, reinit_subcommands)
        vars(cmd).update(kw)
        return cmd

# we can't patch distutils.cmd, alas
distutils.core.Command = Command


def _find_all_simple(path):
    """
    Find all files under 'path'
    """
    results = (
        os.path.join(base, file)
        for base, dirs, files in os.walk(path, followlinks=True)
        for file in files
    )
    return filter(os.path.isfile, results)


def findall(dir=os.curdir):
    """
    Find all files under 'dir' and return the list of full filenames.
    Unless dir is '.', return full filenames with dir prepended.
    """
    files = _find_all_simple(dir)
    if dir == os.curdir:
        make_rel = functools.partial(os.path.relpath, start=dir)
        files = map(make_rel, files)
    return list(files)


# fix findall bug in distutils (http://bugs.python.org/issue12885)
distutils.filelist.findall = findall
