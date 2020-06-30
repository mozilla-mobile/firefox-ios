import logging
import os
import subprocess

from .xcrun import XCRun

here = os.path.dirname(__file__)
logging.getLogger(__name__).addHandler(logging.NullHandler())


class XCodeBuild(object):
    binary = 'xcodebuild'
    destination = 'platform=iOS Simulator,name=iPhone 11'
    logger = logging.getLogger()
    scheme = 'Fennec_Enterprise_XCUITests_Integration'
    xcrun = XCRun()

    def __init__(self, log):
        self.log = log

    def test(self, identifier):
        self.xcrun.erase()
        args = [
            self.binary,
            'test',
            '-scheme', self.scheme,
            '-destination', self.destination,
            '-only-testing:{}'.format(identifier)]
        self.logger.info('Running: {}'.format(' '.join(args)))
        try:
            out = subprocess.check_output(
                args,
                cwd=os.path.join(here, os.pardir),
                stderr=subprocess.STDOUT,
                universal_newlines=True)
        except subprocess.CalledProcessError as e:
            out = e.output
            raise
        finally:
            with open(self.log, 'w') as f:
                f.write(out)

