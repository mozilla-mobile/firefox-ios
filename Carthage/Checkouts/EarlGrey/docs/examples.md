# EarlGrey Usage Examples
Add any example of custom matchers, asserts etc. that you have found very useful in your EarlGrey tests.

Example 1: **Selecting the first match via a custom Swift matcher**

When an application has exact duplicate elements (every attribute is the same,
including their hierarchy), then the correct fix is to update the app to avoid
duplicating the UI. When that's not possible, a workaround is to match on
the first element.

```swift
// Swift Custom Matcher
/**
 *  Example Usage:
 *
 *  EarlGrey.selectElement(with:grey_allOfMatchers([
 *    grey_accessibilityID("some_id"),
 *    grey_interactable(),
 *    grey_firstElement()])).assert(grey_notNil())
 *
 *  Only intended to be used with selectElementWithMatcher.
 */
func grey_firstElement() -> GREYMatcher {
  var firstMatch = true
  let matches: MatchesBlock = { (element: AnyObject!) -> Bool in
    if firstMatch {
      firstMatch = false
      return true
    }

    return false
  }

  let description: DescribeToBlock = { (description: GREYDescription!) -> Void in
    guard let description = description else {
      return
    }
    description.appendText("first match")
  }

  return GREYElementMatcherBlock.init(matchesBlock: matches, descriptionBlock: description)
}
```
