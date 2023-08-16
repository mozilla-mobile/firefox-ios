import logging
import subprocess

logging.getLogger(__name__).addHandler(logging.NullHandler())


class XCRun(object):
    binary = 'xcrun'
    logger = logging.getLogger()

    def _run(self, *args):
        args = [self.binary, 'simctl'] + list(args)
        self.logger.info('Running: {}'.format(' '.join(args)))
        subprocess.check_call(args)

    def boot(self, device='iPhone 14'):
        self._run('boot', device)

    def install(self, device='all'):
        self._run('install', device)

    def shutdown(self, device='all'):
        self._run('shutdown', device)

    def erase(self, device='all'):
        self.shutdown(device)
        self._run('erase', device)
