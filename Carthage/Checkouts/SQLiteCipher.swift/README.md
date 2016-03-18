# SQLiteCipher.swift

A [SQLCipher][]-ready version of [SQLite.swift][].

[SQLCipher]: https://www.zetetic.net/sqlcipher/
[SQLite.swift]: https://github.com/stephencelis/SQLite.swift


## Usage

``` swift
import SQLiteCipher

let db = try Connection("path/to/db.sqlite3")

try db.key("secret")
```


## Installation

> _Note:_ SQLiteCipher.swift requires Swift 2 (and [Xcode][] 7) or greater.


### Carthage

[Carthage][] is a simple, decentralized dependency manager for Cocoa. To
install SQLiteCipher.swift with Carthage:

 1. Make sure Carthage is [installed][Carthage Installation].

 2. Update your Cartfile to include the following:

    ```
    github "stephencelis/SQLiteCipher.swift" "master"
    ```

 3. Run `carthage update` and [add the appropriate framework][Carthage Usage].

[Carthage]: https://github.com/Carthage/Carthage
[Carthage Installation]: https://github.com/Carthage/Carthage#installing-carthage
[Carthage Usage]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application


### CocoaPods

[CocoaPods][] is a dependency manager for Cocoa projects. To install
SQLiteCipher.swift with CocoaPods:

 1. Make sure CocoaPods is [installed][CocoaPods Installation].
    (SQLiteCipher.swift requires version 0.37 or greater.)

 2. Update your Podfile to include the following:

    ``` ruby
    use_frameworks!

    pod 'SQLiteCipher.swift',
      git: 'https://github.com/stephencelis/SQLiteCipher.swift.git'
    ```

 3. Run `pod install`.

[CocoaPods]: https://cocoapods.org
[CocoaPods Installation]: https://guides.cocoapods.org/using/getting-started.html#getting-started


### Manual

To install SQLiteCipher.swift as an Xcode sub-project:

 1. Drag the **SQLiteCipher.xcodeproj** file into your own project.
    ([Submodule][] or clone the project first.)

 2. In your target’s **General** tab, click the **+** button under **Linked
    Frameworks and Libraries**.

 3. Select the appropriate **SQLiteCipher.framework** for your platform.

 4. Click **Add**.


[Xcode]: https://developer.apple.com/xcode/downloads/
[Submodule]: http://git-scm.com/book/en/Git-Tools-Submodules


## License

SQLiteCipher.swift is available under the MIT license. See [the LICENSE
file](./LICENSE.txt) for more information.
