# Environment as getter

- In the context of: `making the Environment getter only from the Browser app` ([Jira ticket](https://ecosia.atlassian.net/browse/MOB-1817))
- facing: `the possibility of update the Environment at any point in the app`
- we decided: `to add a PRODUCTION macro on Release only`
- and neglected `any other workaround and/or code change that would break the SOLID principles`,
- to achieve: `The smallest yet robust code changes between the Core module and the Browser app. As we know, SPM currently provides us with only .debug and .release build configurations. There are many proposals to make it "flavored" but, so far, nothing hasn't even reached beta. The way SPM chooses which configuration to pick, ironically, is purely empirical. It basically picks .debug only in case the hosting build configuration contains Development or Debug (case-insensitive). This PRODUCTION macro is being read within the Core package, and decide which Environment assign to it. Depending on the Environment a set of protocol-based URLs mimicking the older architecture is loaded in memory.`
- accepting that: `unconventionally recognised Build Configuration prefixes have been added to the TestFlight and AppCenter configs in the browser app (e.g.: Development_)`

## Related Code

- [Package.swift](../Package.swift)
- [Environment.swift](../Sources/Environment/Environment.swift)
