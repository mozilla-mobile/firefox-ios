## Application Services Logging

When writing code in application-services, code implemented in Rust, Kotlin,
Java, or Swift might have to write debug logs. To do so, one should generally
log using the normal logging facilities for the language. Where the logs go
depends on the application which is embedding the components.

### Accessing logs when running Fenix

On android, logs currently go to logcat. (This may change in the future.)
Android Studio can be used to view the logcat logs; connect the device over USB
and view the Logcat tab at the bottom of Android Studio. Check to make sure you
have the right device selected at the top left of the Logcat pane, and the
correct process to the right of that. One trick to avoid having to select the
correct process (as there are main and content processes) is to choose "No
Filters" from the menu on the top right of the Logcat pane. Then, use the search
box to search for the log messages you are trying to find.

There are also many other utilities, command line and graphical, that can be
used to view logcat logs from a connected android device in a more flexible
manner.

#### Changing the loglevel in Fenix

If you need more verbose logging, after the call to `RustLog.enable()` in
`FenixApplication`, you may call `RustLog.setMaxLevel(Log.Priority.DEBUG,
true)`.

### Accessing logs when running iOS

[TODO]
