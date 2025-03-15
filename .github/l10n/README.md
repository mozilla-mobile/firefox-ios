# L10n reference linter configurations

This folder includes configurations for the linter used to analyze reference
strings (en-US) for Firefox and Focus for iOS.

The linter is based on a Python package called
[moz-xliff-linter](https://pypi.org/project/moz-xliff-linter/), and it checks
the reference content for:

* Hard-coded brand names (defined in `brand_names` within the config).
* Incorrect typography (`'` instead of `’`, `""` instead of `“”`, 3 dots instead
  of `…`).
* Missing comments for strings with placeables (the comment must include
  references to each placeable present in the text, e.g. `%@` or `%1$@`).

The only case for which developers should add exceptions is when there are
hard-coded brand names. Normally, we want strings to use placeables, but there
are edge cases for which we want to hard-code Firefox or Mozilla (for example,
crash reports are only sent to Mozilla, independently of an organization
repackaging the browser with a different name).

Before adding new exceptions, always consult with the Localization Team to
confirm that an exception is actually needed. The string ID (e.g.
`focus-ios.xliff:Onboarding.Title`) is listed in the error log of the GitHub
workflow.
