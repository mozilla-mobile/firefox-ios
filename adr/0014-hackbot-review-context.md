# 14. Repository-Managed Hackbot Review Context

Date: 2026-10-30

## Status

Accepted

## Context

Hackbot reviews changes across a monorepo containing Firefox for iOS, Focus, and shared BrowserKit code. Effective review requires project-specific knowledge as well as the requirements of the change. Supplying the same guidance for every change can add irrelevant context, while keeping it outside the repository makes it harder to review and maintain alongside the code it describes.

The team needs a maintainable way to select relevant guidance based on the files in a pull request. The matching mechanism uses file paths and extensions.

## Decision

We will maintain Hackbot review context in this repository. A root `review-context.toml` file will map changed-file conditions to guidance files. We will keep review-specific checklists in `.claude/review/` and reusable domain knowledge in `.claude/skills/`, so that guidance can be reviewed and changed with the codebase.

Rules can apply broadly or target specific parts of the codebase. For example, a rule could load accessibility guidance for Swift changes, while another could load navigation guidance for changes under a coordinator directory. We can add or refine rules and guidance as review needs evolve.

We will validate the manifest in GitHub Actions using a pinned version of the Bugbug review-context schema validator. The workflow runs when the manifest or validation workflow changes, on matching pushes to `main`, and by manual dispatch.

## Consequences

### Positive

- Review guidance is versioned with the project and can evolve through normal pull request review.
- File-based rules select relevant domain context without requiring every review to load every piece of guidance.
- Schema validation catches invalid manifest configuration before it is used.

### Negative

- Maintainers must keep the rules and guidance accurate as the codebase and review needs change. Path-based rules can miss relevant changes when code moves or lives outside the specified paths.
- Broad rules can introduce irrelevant context. For example, matching all Swift changes to accessibility guidance may include non-UI code, while restricting the rule to specific directories could miss UI code elsewhere.
- The validator checks the manifest against its pinned schema, but does not establish that the guidance is correct, complete, or effective. The pinned validator also needs maintenance as the schema evolves. Hackbot findings still require human judgment.

## References

- [PR #36060: Hackbot review context](https://github.com/mozilla-mobile/firefox-ios/pull/36060)
- [Bugbug review-context schema validator at the pinned revision](https://github.com/mozilla/bugbug/blob/b2c767e9684d0347ba6fe84f2c16def7d5ed9b4f/bugbug/tools/code_review/review_context_schema.py)
