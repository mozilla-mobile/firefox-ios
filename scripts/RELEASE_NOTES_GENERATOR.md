# Release Notes Generator

## Overview

The `generate_release_notes.py` script automatically generates release notes by comparing two git branches. It analyzes commit messages, categorizes changes, and provides statistics about code modifications.

## Features

- **Automatic Categorization**: Commits are automatically categorized based on conventional commit patterns:
  - Features
  - Bug Fixes
  - Performance improvements
  - Refactoring
  - Documentation
  - Testing
  - Dependencies
  - CI/CD
  - Other Changes

- **Statistics**: Provides summary statistics including:
  - Total number of commits
  - Files changed
  - Lines added and deleted

- **Multiple Output Formats**: Supports both Markdown and plain text formats

- **File Change Analysis**: Shows the top changed files with addition/deletion counts

## Usage

### Basic Usage

Compare a release branch with main:

```bash
./scripts/generate_release_notes.py release/v148.0 main
```

### Save to File

Generate release notes and save to a file:

```bash
./scripts/generate_release_notes.py release/v148.0 main -o release_notes.md
```

### Plain Text Format

Generate plain text output instead of Markdown:

```bash
./scripts/generate_release_notes.py release/v148.0 main -f text
```

### Specify Repository Path

If running from outside the repository:

```bash
./scripts/generate_release_notes.py release/v148.0 main -r /path/to/repo
```

## Command Line Options

```
positional arguments:
  release_branch        Release branch name (e.g., 'release/v148.0')
  main_branch          Main branch name (e.g., 'main')

optional arguments:
  -h, --help           Show help message and exit
  -o OUTPUT, --output OUTPUT
                       Output file path (default: print to stdout)
  -f {markdown,text}, --format {markdown,text}
                       Output format (default: markdown)
  -r REPO, --repo REPO
                       Path to git repository (default: current directory)
```

## Examples

### Example 1: Generate Release Notes for v148.0

```bash
cd /path/to/firefox-ios
./scripts/generate_release_notes.py release/v148.0 main -o release_notes_v148.md
```

### Example 2: View Changes in Terminal

```bash
./scripts/generate_release_notes.py release/v148.0 main | less
```

### Example 3: Generate Multiple Formats

```bash
# Markdown format for GitHub
./scripts/generate_release_notes.py release/v148.0 main -o release_notes.md

# Plain text format for email
./scripts/generate_release_notes.py release/v148.0 main -f text -o release_notes.txt
```

## Output Format

### Markdown Output

The Markdown output includes:
- Header with branch comparison and generation timestamp
- Summary section with commit and change statistics
- Changes organized by category
- Table of top changed files

### Text Output

The plain text output includes:
- Header with branch information
- Summary statistics
- Changes organized by category (simplified format)

## Commit Message Conventions

The script recognizes common commit message conventions for categorization:

- **Features**: `feat:`, `feature:`, `add:`, `implement`
- **Bug Fixes**: `fix:`, `bug:`, `bugfix`, `resolve`
- **Performance**: `perf:`, `performance`, `optimize`
- **Documentation**: `docs:`, `documentation`
- **Testing**: `test:`, `tests:`
- **Refactoring**: `refactor:`, `cleanup`, `clean up`
- **Dependencies**: `deps:`, `bump`, `update.*dependency`
- **CI/CD**: `ci:`, `build:`, `chore:.*ci`

Commits that don't match these patterns are categorized as "Other Changes".

## Integration with CI/CD

You can integrate this script into your CI/CD pipeline:

### GitHub Actions Example

```yaml
name: Generate Release Notes

on:
  push:
    branches:
      - 'release/**'

jobs:
  release-notes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Fetch all history
      
      - name: Generate Release Notes
        run: |
          ./scripts/generate_release_notes.py ${{ github.ref_name }} main -o release_notes.md
      
      - name: Upload Release Notes
        uses: actions/upload-artifact@v3
        with:
          name: release-notes
          path: release_notes.md
```

## Requirements

- Python 3.6 or higher
- Git command-line tools
- Access to a git repository with the specified branches

## Troubleshooting

### Branch Not Found

If you get an error about branches not being found:

1. Ensure you've fetched all branches: `git fetch --all`
2. Verify the branch names: `git branch -a`
3. Use the correct branch name format (e.g., `release/v148.0`, not just `v148.0`)

### No Commits Found

If the output shows "No Changes":

1. Verify both branches exist
2. Check that the release branch is behind the main branch
3. Try reversing the branch order if you want to see what's in release but not in main

### Permission Denied

If you get a "Permission denied" error:

```bash
chmod +x ./scripts/generate_release_notes.py
```

## Contributing

Improvements and bug fixes are welcome! Please follow the Mozilla contribution guidelines when submitting changes.

## License

This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
