# Logger

A logger library to be used by a client to log any useful information.

## Usage
Use the `DefaultLogger` or create your own `Logger` following the protocol. 

On start of the application, the `Logger` crash manager needs to be configured, as well as making sure we setup the `sendUsageData` user's preference. This preference ensure any logs won't leave the device in case a user's doesn't want their data collected.

Once setup, the `Logger` can then start logging different messages following logger categories and level. Please see more information on how to use logger categories and level following our [logging strategy](https://github.com/mozilla-mobile/firefox-ios/wiki/Logging-Strategy).