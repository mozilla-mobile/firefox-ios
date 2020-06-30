# Firefox iOS integration tests

To run these tests you will need [Python 3][] and [pipenv][] installed. Once
you have these, make sure you're in the `SyncIntegrationTests` directory and
run the following:

```
$ pipenv install
$ pipenv run pytest
```

The tests will build and install the application to the simulator, which can
cause a delay where there will be no feedback to the user. Also, note that each
XCUITest that is executed will shutdown and **erase data from all available iOS
simulators**. This assures that each execution starts from a known clean state.

[Python 3]: http://docs.python-guide.org/en/latest/starting/installation/#python-3-installation-guides
[pipenv]: http://docs.python-guide.org/en/latest/dev/virtualenvs/#installing-pipenv
