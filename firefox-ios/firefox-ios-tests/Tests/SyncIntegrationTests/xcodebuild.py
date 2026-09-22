import glob
import io
import logging
import os
import shutil
import subprocess

from .xcrun import XCRun

here = os.path.dirname(__file__)
logging.getLogger(__name__).addHandler(logging.NullHandler())


class XCodeBuild(object):
    binary = 'xcodebuild'
    bundleId = 'org.mozilla.ios.Fennec'
    destination = 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
    logger = logging.getLogger()
    scheme = 'Fennec'
    testPlan = 'SyncIntegrationTestPlan'
    xcrun = XCRun()

    def __init__(self, log, app_log=None, **kwargs):
        self.scheme = kwargs.get("scheme", self.scheme)
        self.testPlan = kwargs.get("test_plan", self.testPlan)
        self.log = log
        self.app_log = app_log

    def install(self, boot=True):
        command = "find ~/Library/Developer/Xcode/DerivedData/Client-*/Build/Products/Fennec-* -type d -iname 'Client.app'"
        path = subprocess.check_output(command, shell=True, universal_newlines=True)
        if boot:
            self.xcrun.boot()
        try:
            out = subprocess.check_output(
                f"xcrun simctl install booted {path}",
                cwd=os.pardir,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                shell=True
            )
        except subprocess.CalledProcessError as e:
            out = e.output
            raise
        finally:
            with open(self.log, 'w') as f:
                f.write(out)

    def test(self, identifier, build=True, erase=True):
        run_args = "test"
        if erase:
            self.xcrun.erase()
        if not build:
            run_args = "test-without-building"
        args = [
            self.binary,
            f'{run_args}',
            '-scheme', self.scheme,
            '-destination', self.destination,
            '-only-testing:{}'.format(identifier),
            '-testPlan', self.testPlan,
            '-skipMacroValidation']
        self.logger.info('Running: {}'.format(' '.join(args)))
        try:
            out = subprocess.check_output(
                args,
                cwd=os.chdir("../../.."),
                stderr=subprocess.STDOUT,
                universal_newlines=True)
        except subprocess.CalledProcessError as e:
            out = e.output
            raise
        finally:
            with open(self.log, 'w') as f:
                f.write(out)
            self.copy_app_logs()
            os.chdir("firefox-ios-tests/Tests/SyncIntegrationTests")

    def copy_app_logs(self):
        """Copy the app's own log file out of the simulator before the next test erases it.

        The app writes to <data container>/Library/Caches/Logs/Firefox.log, which holds the
        `[sync]` category lines, including the per-sync telemetry JSON with each engine's
        outgoing record counts. Never raises: this runs from a `finally` block.
        """
        if self.app_log is None:
            return
        try:
            container = subprocess.check_output(
                ['xcrun', 'simctl', 'get_app_container',
                 self.xcrun.device(), self.bundleId, 'data'],
                stderr=subprocess.STDOUT,
                universal_newlines=True).strip()
        except (subprocess.CalledProcessError, OSError) as e:
            message = getattr(e, 'output', str(e))
            self.logger.warning('Could not locate app container: {}'.format(message))
            with open(self.app_log, 'w') as f:
                f.write('Could not locate app container for {}:\n{}'.format(self.bundleId, message))
            return

        log_dir = os.path.join(container, 'Library', 'Caches', 'Logs')
        # SwiftyBeaver rotates Firefox.log to Firefox.log.1, so read oldest first
        paths = sorted(glob.glob(os.path.join(log_dir, 'Firefox.log*')), reverse=True)
        with open(self.app_log, 'w') as out:
            if not paths:
                out.write('No Firefox.log found in {}\n'.format(log_dir))
                return
            for path in paths:
                out.write('===== {} =====\n'.format(path))
                with io.open(path, 'r', encoding='utf8', errors='replace') as f:
                    shutil.copyfileobj(f, out)

