# Code Review & PR Conventions

## PR & Branch Naming

- PR title: `[MOB-XXXX] {name of the feature}` (Jira ticket reference)
- Branch name usually starts with engineer initials (e.g. Jane Doe, `jd-`)
- Branch name usually includes ticket reference `MOB-XXXX` (e.g., `jd-mob-1234-feature-name`)
- No ticket? No ticket reference needed

## Commit Standards

- Split file changes into separate, logical commits
- Commit messages are auto-prefixed with ticket numbers — don't add manually
- Maintain clean commit history — avoid numerous small commits
- Skip `.gitignore` changes by default unless specifically requested

## Review Rules

- Don't explain what the PR does — only include points that require change
- Only focus on changes made in this PR and intended changes described in the PR description
- Verify the project builds successfully before committing
- Address linter errors (max 3 iterations per file)
- Ensure CI/CD checks pass before requesting review

## Branch Management

- Production code is on the `main` branch
- New features branch off `main`
- Use descriptive branch names that reflect the feature or fix
