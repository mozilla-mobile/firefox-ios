# Firefox iOS integration tests

To run these tests you will need [Python 3.12][] and [pipenv][] installed. Once
you have these, make sure you're in the `SyncIntegrationTests` directory and
run the following:

```
$ export CI_WAF_TOKEN=[token]
$ pipenv install --python 3.12
$ pipenv run pytest
```

`CI_WAF_TOKEN` can be obtained via the FxA team or 1Password vault for Mobile Test Engineering.
This variable will be used in the `fxa-ci` header to bypass the Mozilla Accounts WAF challenges
during automated testing (see [PyFxA CI WAF bypass][]).

[PyFxA CI WAF bypass]: https://github.com/mozilla/PyFxA/blob/main/README.rst#ci-waf-bypass

The tests will build and install the application to the simulator, which can
cause a delay where there will be no feedback to the user. Also, note that each
XCUITest that is executed will shutdown and **erase data from all available iOS
simulators**. This assures that each execution starts from a known clean state.

[Python 3]: http://docs.python-guide.org/en/latest/starting/installation/#python-3-installation-guides
[pipenv]: http://docs.python-guide.org/en/latest/dev/virtualenvs/#installing-pipenv
