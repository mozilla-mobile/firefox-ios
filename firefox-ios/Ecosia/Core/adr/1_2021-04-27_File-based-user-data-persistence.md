# File based user data persistence

- In the context of: `having persistence for user data and settings`
- facing: `loading user data via UserDefaults delayed app launch, lacked the ability to scale and were flaky in unit tests`
- we decided: `to store user data in JSON-encoded files`
- and neglected: `the use of UserDefaults`
- to achieve: `ease of use, extensibility, speed of access, consistency and predictable unit test results`
- accepting that: `we need to implement persistence (storing, loading, caching) of the json-files ourselves`

## Related Code

- [User.swift](../Sources/User.swift)
