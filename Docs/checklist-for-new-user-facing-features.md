## New Feature Development Checklist

So you've added a new feature. Users will see it!

You've landed the code, it's indented properly, it looks lovely! What's Next!?

###  Has your feature got tests yet?

  * perhaps existing tests will cover it, may be adding another unit test will be enough.
  * If you're adding new UI:
    - ensure widgets have `accessbilityIdentifiers`. 
    - Add it to FxScreenGraph.swift.
    - XCUITests should be used, but as a last resort.

### Should your new feature be keyboard navigable?

  * Adding UIKeyCommands will help.
  * Getting to the new features is as important as using your feature.

### Accessibility for new UI

  * Add accessibilityLabels
  * Have you tested it with VoiceOver?

### Has your feature got new Strings?

  * Is it `NSLocalizable`? 
  * It should probably go in `Strings.swift`. Ask about String export deadlines.
  * Are the strings screenshotted? The `L10nScreenshotTests` are there to help diagnose layout issues caused by missing or long strings and right to left issues.

### How do you know if your new feature is used?

  * Add event telemetry
  * Consider performance telemetry.
  * Add a Telemetry dashboard — this will help make decisions about your feature in the future.

### You're feature is awesome! Have you told anyone outside of Engineering or UX about it?

  * Should it go on the What's New page? (to tell the users)
  * Should it be documented?
  * Have you told These Weeks in Mobile Firefox?
  * Have you told Marketing?

### Have you found something you should do for other features, but isn't on this checklist?

  * Add it to this checklist.

