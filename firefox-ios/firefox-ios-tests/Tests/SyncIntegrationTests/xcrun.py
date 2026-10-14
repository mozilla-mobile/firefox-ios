import logging
import os
import subprocess

logging.getLogger(__name__).addHandler(logging.NullHandler())


class XCRun(object):
    binary = 'xcrun'
    logger = logging.getLogger()

    def _run(self, *args):
        args = [self.binary, 'simctl'] + list(args)
        self.logger.info('Running: {}'.format(' '.join(args)))
        subprocess.check_call(args)

    def device(self, device='iPhone 17'):
        return os.environ.get("SIMULATOR_UDID", device)

    def boot(self, device='iPhone 17'):
        self._run('boot', self.device(device))

    def install(self, device='all'):
        self._run('install', device)

    def shutdown(self, device='all'):
        self._run('shutdown', device)

    def erase(self, device='all'):
        self.shutdown(device)
        self._run('erase', device)
