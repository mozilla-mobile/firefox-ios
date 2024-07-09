# Experiment Integration tests for iOS (Klaatu)


## Prerequisites


1. A running XCode with a Simulator device.
2. nimbus-cli installed and working correctly.
3. This project should be able to build and run on the simulated device.
4. Python 3.11 or higher installed


## Setup


1. Install pipenv
2. Run `pipenv install`, this will install all of the requirements needed to run the tests


## Running Tests


Depending on the specific tests you want to run you can provide different command line flags to run those tests. The test suite will automatically run tests that correspond with the experiment. So if you are testing an experiment that uses the `messaging` feature, the correct tests will be run.


`--experiment test-experiment`: must be provided with the experiment slug as the provided value.


`-m smoke_test`: this will run the smoke test suite.

`--stage`: If your experiment exists on the experimenter stage server, use this.


## Checking test reports


The tests will generate a test report after they are run. It is an HTML report and must be viewed in the browser. This will be named `index.html` and it will be located in the `results` directory. This can be viewed in the browser.
