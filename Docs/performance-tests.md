Performance tests
==================

There are several scenarios in which having performance tests to measure how the app performs is really important. The data bases for Bookmarks, History, Tabs could be very big and impact in the time it takes to launch the app or use it. 

Being able to pre-load existing data bases with heavy profiles has helped to implement these tests. It is possible to launch a test with a specific profile and measure different data that could help to find issues for the app in that situation.

Currently in the repository there are performance tests for Tabs. In the future similar ones will be added for History and Bookmarks.


Tabs tests
-----------
These tests are defined in the [CronTabsPerformanceTest test suite](https://github.com/mozilla-mobile/firefox-ios/blob/main/XCUITests/CronTabsPerfTests.swift). They don't run as part of the CI test execution for two reasons:
* There is not a good way to retrieve the data and analyze it
* To get accurate data it is better to run these tests on real devices

So the tests are disabled but can be run in any device by clicking on the play '>' button to run them as regular tests.
Once they run the following performance data is available on Xcode in the Report navigator


Performance data
-----------
The data gathered after running these tests is:
* Duration (s)
* CMT (s) : Clock Monotonic Time
* CPU Cycles (kC)
* CPU Time (s)
* Mem Physical (kB)
* Mem Physical Peak (kB)
* CPU Instructions retired (kl)
* Disk logical writes (kB)


As a first approach the data is being recorded in a [doc](https://docs.google.com/spreadsheets/d/1ERhNf1IY7Rqfzvcvb2PJldUiHWNArh81yEx6rJ-BA-U/edit?usp=sharing) after running the tests on physical device.

The tests are using a low size profile (with 20 tabs) and a heavy profile (with 1280 tabs), there are two scenarios covered for each profile:
* Launch app
* Open Tabs Tray

It was decided to use those profiles and maybe add more in the future depending on the data retrieved and how the app performs.

Those profiles are stored in the [test-fixtures](https://github.com/mozilla-mobile/firefox-ios/tree/main/test-fixtures)folder and in addition to those there are more availables (40, 60, 80 tabs in this folder in case they are needed in the future)

In case it is needed, there is also a test that will generate as many tabs as needed. Also, a script was implemented to generate the archive file that contains the number of tabs desired, it is called tabs-archive-maker.sh and is also available in the test-fixtures folder.

When a test starts the corresponding archive file is loaded containing a specific number of tabs so it starts running having that tabs file. This is configured in the SetUp for each test. 
