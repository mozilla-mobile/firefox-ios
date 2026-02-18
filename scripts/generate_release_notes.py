#!/usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Generate release notes from the diff between two branches.

This script compares the release branch (e.g., release/v148.0) with the main branch
and generates structured release notes based on the commit messages and changes.
"""

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from typing import List, Dict, Tuple


class ReleaseNotesGenerator:
    """Generator for release notes from git branch diffs."""

    def __init__(self, release_branch: str, main_branch: str, repo_path: str = "."):
        """
        Initialize the release notes generator.

        Args:
            release_branch: The release branch name (e.g., 'release/v148.0')
            main_branch: The main branch name (e.g., 'main')
            repo_path: Path to the git repository (default: current directory)
        """
        self.release_branch = release_branch
        self.main_branch = main_branch
        self.repo_path = repo_path

    def run_git_command(self, command: List[str]) -> str:
        """
        Run a git command and return its output.

        Args:
            command: List of command arguments

        Returns:
            Command output as string

        Raises:
            subprocess.CalledProcessError: If command fails
        """
        try:
            result = subprocess.run(
                ["git"] + command,
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"Error running git command: {e}", file=sys.stderr)
            print(f"stderr: {e.stderr}", file=sys.stderr)
            raise

    def get_commit_range(self) -> str:
        """
        Get the commit range between release and main branches.

        Returns:
            Commit range string suitable for git log
        """
        # Get commits that are in main but not in release branch
        return f"{self.release_branch}..{self.main_branch}"

    def get_commits(self) -> List[Dict[str, str]]:
        """
        Get commits that differ between the two branches.

        Returns:
            List of commit dictionaries with hash, author, date, and message
        """
        commit_range = self.get_commit_range()
        
        # Get commit info with a delimiter that won't appear in commit messages
        delimiter = "---COMMIT-DELIMITER---"
        format_string = f"%H{delimiter}%an{delimiter}%ae{delimiter}%ad{delimiter}%s{delimiter}%b{delimiter}"
        
        try:
            log_output = self.run_git_command([
                "log",
                commit_range,
                f"--pretty=format:{format_string}",
                "--date=short",
                "--no-merges"
            ])
        except subprocess.CalledProcessError:
            print(f"Warning: Could not get commit log for {commit_range}", file=sys.stderr)
            return []

        if not log_output:
            return []

        commits = []
        # Split the output by delimiter and process in groups of 6
        parts = log_output.split(delimiter)
        
        # Process parts in groups of 6 (hash, author, email, date, subject, body)
        i = 0
        while i + 5 < len(parts):
            commit = {
                "hash": parts[i].strip(),
                "author": parts[i+1].strip(),
                "email": parts[i+2].strip(),
                "date": parts[i+3].strip(),
                "subject": parts[i+4].strip(),
                "body": parts[i+5].strip() if i+5 < len(parts) else "",
            }
            if commit["hash"]:  # Only add if hash is not empty
                commits.append(commit)
            i += 6

        return commits

    def get_file_changes(self) -> Dict[str, Tuple[int, int]]:
        """
        Get file change statistics between branches.

        Returns:
            Dictionary mapping file paths to (additions, deletions) tuples
        """
        commit_range = self.get_commit_range()
        
        try:
            diff_output = self.run_git_command([
                "diff",
                "--numstat",
                commit_range
            ])
        except subprocess.CalledProcessError:
            print(f"Warning: Could not get diff stats for {commit_range}", file=sys.stderr)
            return {}

        file_changes = {}
        for line in diff_output.split("\n"):
            if not line.strip():
                continue
            parts = line.split("\t")
            if len(parts) >= 3:
                try:
                    additions = int(parts[0]) if parts[0] != "-" else 0
                    deletions = int(parts[1]) if parts[1] != "-" else 0
                    filepath = parts[2]
                    file_changes[filepath] = (additions, deletions)
                except ValueError:
                    continue

        return file_changes

    def categorize_commits(self, commits: List[Dict[str, str]]) -> Dict[str, List[Dict[str, str]]]:
        """
        Categorize commits based on their subject lines.

        Args:
            commits: List of commit dictionaries

        Returns:
            Dictionary mapping categories to lists of commits
        """
        categories = defaultdict(list)
        
        # Define category patterns
        patterns = {
            "Features": [
                r"^feat[:(]",
                r"^feature[:(]",
                r"^add[:(]",
                r"^implement",
            ],
            "Bug Fixes": [
                r"^fix[:(]",
                r"^bug[:(]",
                r"^bugfix",
                r"^resolve",
            ],
            "Performance": [
                r"^perf[:(]",
                r"^performance",
                r"^optimize",
            ],
            "Documentation": [
                r"^docs?[:(]",
                r"^documentation",
            ],
            "Testing": [
                r"^test[:(]",
                r"^tests?[:(]",
            ],
            "Refactoring": [
                r"^refactor[:(]",
                r"^cleanup",
                r"^clean up",
            ],
            "Dependencies": [
                r"^deps?[:(]",
                r"^bump",
                r"^update.*dependency",
                r"^upgrade.*dependency",
            ],
            "CI/CD": [
                r"^ci[:(]",
                r"^build[:(]",
                r"^chore[:(].*ci",
            ],
        }

        for commit in commits:
            subject_lower = commit["subject"].lower()
            categorized = False

            for category, category_patterns in patterns.items():
                for pattern in category_patterns:
                    if re.match(pattern, subject_lower):
                        categories[category].append(commit)
                        categorized = True
                        break
                if categorized:
                    break

            if not categorized:
                categories["Other Changes"].append(commit)

        return dict(categories)

    def generate_markdown(self) -> str:
        """
        Generate release notes in Markdown format.

        Returns:
            Markdown-formatted release notes
        """
        output = []
        
        # Header
        output.append(f"# Release Notes")
        output.append(f"\nComparing `{self.release_branch}` to `{self.main_branch}`")
        output.append(f"\nGenerated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

        # Get commits
        commits = self.get_commits()
        
        if not commits:
            output.append("\n## No Changes\n")
            output.append(f"No commits found between `{self.release_branch}` and `{self.main_branch}`.\n")
            return "\n".join(output)

        # Summary
        output.append(f"\n## Summary\n")
        output.append(f"- Total commits: **{len(commits)}**")
        
        # Get file changes
        file_changes = self.get_file_changes()
        if file_changes:
            total_additions = sum(adds for adds, _ in file_changes.values())
            total_deletions = sum(dels for _, dels in file_changes.values())
            output.append(f"- Files changed: **{len(file_changes)}**")
            output.append(f"- Lines added: **{total_additions}**")
            output.append(f"- Lines deleted: **{total_deletions}**")

        # Categorized commits
        categorized = self.categorize_commits(commits)
        
        output.append("\n## Changes by Category\n")
        
        # Order categories for display
        category_order = [
            "Features",
            "Bug Fixes",
            "Performance",
            "Refactoring",
            "Documentation",
            "Testing",
            "Dependencies",
            "CI/CD",
            "Other Changes",
        ]

        for category in category_order:
            if category in categorized:
                output.append(f"### {category}\n")
                for commit in categorized[category]:
                    # Format: - subject (hash)
                    short_hash = commit["hash"][:7]
                    output.append(f"- {commit['subject']} (`{short_hash}`)")
                    # Add body if present and informative
                    if commit.get("body") and len(commit["body"]) > 5:
                        # Indent body lines
                        body_lines = commit["body"].split("\n")
                        for line in body_lines[:3]:  # Limit to first 3 lines
                            if line.strip():
                                output.append(f"  {line.strip()}")
                output.append("")

        # File changes section
        if file_changes:
            output.append("\n## Top Changed Files\n")
            # Sort by total changes
            sorted_files = sorted(
                file_changes.items(),
                key=lambda x: x[1][0] + x[1][1],
                reverse=True
            )[:20]  # Top 20 files
            
            output.append("| File | Additions | Deletions |")
            output.append("|------|-----------|-----------|")
            for filepath, (adds, dels) in sorted_files:
                output.append(f"| `{filepath}` | +{adds} | -{dels} |")

        return "\n".join(output)

    def generate_text(self) -> str:
        """
        Generate release notes in plain text format.

        Returns:
            Plain text release notes
        """
        output = []
        
        # Header
        output.append("=" * 80)
        output.append(f"RELEASE NOTES")
        output.append("=" * 80)
        output.append(f"\nComparing: {self.release_branch} to {self.main_branch}")
        output.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

        # Get commits
        commits = self.get_commits()
        
        if not commits:
            output.append("\nNo commits found between branches.\n")
            return "\n".join(output)

        # Summary
        output.append("-" * 80)
        output.append("SUMMARY")
        output.append("-" * 80)
        output.append(f"Total commits: {len(commits)}")
        
        # Get file changes
        file_changes = self.get_file_changes()
        if file_changes:
            total_additions = sum(adds for adds, _ in file_changes.values())
            total_deletions = sum(dels for _, dels in file_changes.values())
            output.append(f"Files changed: {len(file_changes)}")
            output.append(f"Lines added: {total_additions}")
            output.append(f"Lines deleted: {total_deletions}")

        # Categorized commits
        categorized = self.categorize_commits(commits)
        
        output.append("\n" + "-" * 80)
        output.append("CHANGES BY CATEGORY")
        output.append("-" * 80)
        
        # Order categories for display
        category_order = [
            "Features",
            "Bug Fixes",
            "Performance",
            "Refactoring",
            "Documentation",
            "Testing",
            "Dependencies",
            "CI/CD",
            "Other Changes",
        ]

        for category in category_order:
            if category in categorized:
                output.append(f"\n{category}:")
                output.append("-" * len(category))
                for commit in categorized[category]:
                    short_hash = commit["hash"][:7]
                    output.append(f"  * {commit['subject']} ({short_hash})")

        return "\n".join(output)


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Generate release notes from git branch differences",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate release notes comparing release/v148.0 to main
  %(prog)s release/v148.0 main

  # Output to a file
  %(prog)s release/v148.0 main -o release_notes.md

  # Generate plain text format
  %(prog)s release/v148.0 main -f text
        """
    )
    parser.add_argument(
        "release_branch",
        help="Release branch name (e.g., 'release/v148.0')"
    )
    parser.add_argument(
        "main_branch",
        help="Main branch name (e.g., 'main')"
    )
    parser.add_argument(
        "-o", "--output",
        help="Output file path (default: print to stdout)",
        default=None
    )
    parser.add_argument(
        "-f", "--format",
        choices=["markdown", "text"],
        default="markdown",
        help="Output format (default: markdown)"
    )
    parser.add_argument(
        "-r", "--repo",
        default=".",
        help="Path to git repository (default: current directory)"
    )

    args = parser.parse_args()

    # Create generator
    generator = ReleaseNotesGenerator(
        args.release_branch,
        args.main_branch,
        args.repo
    )

    # Generate notes
    try:
        if args.format == "markdown":
            notes = generator.generate_markdown()
        else:
            notes = generator.generate_text()

        # Output
        if args.output:
            with open(args.output, "w") as f:
                f.write(notes)
            print(f"Release notes written to: {args.output}")
        else:
            print(notes)

    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to generate release notes", file=sys.stderr)
        print(f"Make sure both branches exist and you're in a git repository", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
