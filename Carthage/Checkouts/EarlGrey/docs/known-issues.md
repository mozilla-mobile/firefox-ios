# Known Issues

* EarlGrey cannot interact with system permission dialogs. We plan to implement this in the EarlGrey APIs, but in the meantime we recommend that you use other means to dismiss system permission dialogs in your test code.

* EarlGrey cannot run with [Address Sanitizer](https://github.com/google/sanitizers/wiki/AddressSanitizer), as it interferes with synchronization.

* EarlGrey does not currently support [3D-Touch gestures](http://www.apple.com/iphone-6s/3d-touch/) introduced with iPhone 6s.

* You can find a complete list of issues on [GitHub Issues](https://github.com/google/EarlGrey/issues)
