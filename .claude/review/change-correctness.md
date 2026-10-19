# Change correctness review

- Compare the implementation with the PR description and any supplied linked-issue requirements, including acceptance criteria. Trace normal, failure, and boundary cases.
- Follow affected callers and state transitions to identify regressions across Firefox, Focus, BrowserKit, and shared components.
- Check that tests demonstrate the intended behavior and would detect an incorrect implementation. Tie any test-gap finding to a concrete failure scenario.

If linked-issue requirements are unavailable, state the missing context rather than inventing acceptance criteria.

Report only concrete issues introduced by the change, with supporting evidence and their user impact.
