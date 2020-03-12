### Pull Request checklist ###
<!-- Before submitting the PR, please address each item -->
- [ ] **Quality**: This PR builds and tests run cleanly
  - `automation/all_tests.sh` runs to completion and produces no failures
  - Note: For changes that need extra cross-platform testing, consider adding `[ci full]` to the PR title.
- [ ] **Tests**: This PR includes thorough tests or an explanation of why it does not
- [ ] **Changelog**: This PR includes a changelog entry in [CHANGES_UNRELEASED.md](../CHANGES_UNRELEASED.md) or an explanation of why it does not need one
  - Any breaking changes to Swift or Kotlin binding APIs are noted explicitly
- [ ] **Dependencies**: This PR follows our [dependency management guidelines](https://github.com/mozilla/application-services/blob/master/docs/dependency-management.md)
  - Any new dependencies are accompanied by a summary of the due dilligence applied in selecting them.
