import logging
import os

from mozrunner import FirefoxRunner

logging.getLogger(__name__).addHandler(logging.NullHandler())

TIMEOUT = 60


class TPS(object):
    logger = logging.getLogger()

    def __init__(self, firefox, firefox_log, tps_log, profile):
        self.firefox = firefox
        self.firefox_log = open(firefox_log, 'w')
        self.tps_log = tps_log
        self.profile = profile

    def _log(self, line):
        # This receives bytes from process output, not a string.
        self.firefox_log.write(line.decode() + '\n')

    def run(self, test, phase='phase1', ignore_unused_engines=True):
        self.profile.set_preferences({
            'testing.tps.testFile': os.path.abspath(test),
            'testing.tps.testPhase': phase,
            'testing.tps.ignoreUnusedEngines': ignore_unused_engines,
        })
        args = ['-marionette']
        process_args = {'processOutputLine': [self._log]}
        self.logger.info('Running: {} {}'.format(self.firefox, ' '.join(args)))
        self.logger.info('Using profile at: {}'.format(self.profile.profile))
        runner = FirefoxRunner(
            binary=self.firefox,
            cmdargs=args,
            profile=self.profile,
            process_args=process_args)
        runner.start(timeout=TIMEOUT)
        runner.wait(timeout=TIMEOUT)
        self.firefox_log.close()

        with open(self.tps_log) as f:
            for line in f.readlines():
                if 'CROSSWEAVE ERROR: ' in line:
                    raise TPSError(line.partition('CROSSWEAVE ERROR: ')[-1])

        with open(self.tps_log) as f:
            assert 'test phase {}: PASS'.format(phase) in f.read()


class TPSError(Exception):
    pass
