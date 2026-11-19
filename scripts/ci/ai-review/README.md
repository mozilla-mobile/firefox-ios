# AI code review

An experimental AI code review of a pull request, triggered manually with a GitHub label.
It reads the change, its linked ticket, the discussion so far and the
project's review guidance, then posts one GitHub review: a short summary, and
inline comments on the issues it found.

The review is advice. It doesn't approve or block a pull request, and its
findings can be wrong.

## Using it

1. Add the **`ai-review`** label to a pull request. Only people with write
   access to the repository can add labels, so only they can start a review.
2. Allow the **AI code review** workflow action to run.
3. Read the review on the pull request. The label is removed when the run ends,
   whether it succeeded or not.

To review again, for example after pushing fixes, add the label again. A later
review should not repeat itself or it's findings: see [Follow-up reviews](#follow-up-reviews).

Pull requests from forks are reviewed the same way.

## What it posts

### The summary

The review opens with:

- Two to five bullets on the changes a reviewer would care about: behavior
  users will notice, changed APIs or shared components, and risky areas such
  as migrations, threading or persisted state.
- A **Ticket:** line saying whether the change does what the ticket asks: met,
  partly met, not met, or can't tell, and why.
- **Earlier findings**, on follow-up reviews: a link to each earlier finding
  the new commits tried to fix, and whether they did.
- **Other findings**, for findings on lines outside the diff, which GitHub
  can't take as inline comments.
- A footer linking to the reviewed commit and to the workflow run.

### Inline comments

Each finding is one issue at one place in the diff:

- **[P0–P3] Title**: P0 should theoretically block any merge, P1 is a bug users or developers will
  hit, P2 is a real but lesser problem, P3 is minor.
- A sentence or two on what goes wrong, and when.
- **Fix:** the smallest fix, and why it works.
- **Reproduce**, folded away: steps to reproduce, expected and actual results, when practical.

There are at most 10 findings, the most important first. A review with none is
a normal outcome for a sound change.

There is specific guidance to not report style that SwiftLint enforces, personal
preferences, problems the change didn't introduce or make worse, issues people
have already raised, or anything it can't support from the code.

## Follow-up reviews

When a pull request already has an AI review, the next one covers only what's
new:

- **No repeats.** Issues an earlier review or a person already raised aren't
  reported again, unless a later change made them worse.
- **A shorter summary.** It describes only the author's changes since the last
  AI review, and leaves out changes from rebasing onto or merging the base
  branch. The **Ticket:** line appears only if the assessment changed. If
  nothing worth describing changed, the summary is one line.
- **Replies on earlier findings.** For each earlier finding that new commits
  tried to address, the review replies on its thread with ✅ **Fixed**,
  🟡 **Partly fixed** or ❌ **Not fixed**, and a sentence on what changed or
  what's still needed. The reviewer checks the code, not just a commit message or
  a reply saying it's fixed. The threads of fixed findings are resolved.
  Findings no change touched get no reply.

## Model

Reviews use **Claude Opus 5.5** (`claude-opus-5-5`) at **high** reasoning
effort, run through Anthropic's `claude-code-action` with at most 80 turns.
The model, effort and turn limit are set in `claude_args` in the workflow.

## How it works

`.github/workflows/ai-code-review.yml` runs two jobs when the label is added.

**Review** (read-only token):

1. Checks out the review setup from the base branch: these scripts, the
   prompt, `review-context.toml`, `AGENTS.md` and `.claude/`. A pull request
   can't change the reviewer that reviews it.
2. Checks out the pull request's head commit into `pr-head/`, only for the
   model to read. It's never built or run.
3. `gather_context.py` writes what the reviewer reads into `pr-context/`:
   - `pr.md`: the title, author, branches and description.
   - `diff.patch` and `files.json`: the diff.
   - `comments.md`: the discussion, reviews and inline comments, with earlier
     AI reviews and their findings marked.
   - `since-last-review.md`: the changes since the last AI review.
   - `tickets.md`: linked GitHub issues and their comments.
4. `load_guidance.py` matches `review-context.toml` against the changed files
   and writes the matching guidance to `review-guidance.md` (see
   [Review guidance](#review-guidance)).
5. The model reviews the change, following `prompt.md`, and returns its review as JSON in a
   fixed schema.
6. The run's summary page gets a table with the estimated cost, turns,
   duration and token counts.

**Post** (write token):

1. `post_review.py` checks that the pull request's head is still the reviewed
   commit. If someone pushed during the run, it posts a comment saying the
   review was skipped instead.
2. It posts the review. A finding becomes an inline comment when its lines are
   in the diff, and goes under **Other findings** otherwise. GitHub rejects a
   whole review over one misplaced comment, so if posting fails, it posts
   again with every finding in the body.
3. It posts the follow-up replies, and resolves the threads of fixed findings.
4. If the review job failed, it comments on the pull request with a link to the
   run. In every case it removes the label.

### One snapshot

Everything is reviewed at the head commit in the label's event. The diff comes
from GitHub's compare API at that commit, not from the pull request's live
files, so it always matches the checked-out code. A push during the run makes
the review stale, and it's skipped rather than posted on the wrong code.

### Review guidance

`review-context.toml` is handled in code, the same way as bugbug's review
helper, rather than by the model:

- It's parsed and validated with bugbug's own `review_context_schema.py`, at
  the commit `validate-review-context.yml` pins, so the review and the
  validator agree on what's valid. An invalid file fails the run.
- Rules are matched against the changed files, highest `priority` first, and
  each guidance file is loaded once, however many rules match it.
- Guidance is read from the base branch commit, never from the pull request.
- Only `file` actions from this repository are loaded. Other actions are
  skipped with a warning. Bugzilla, review and patch conditions never match,
  because a GitHub pull request has none of that metadata.

To add guidance for an area of the code, add a rule to `review-context.toml`.
The next review picks it up.

## Security

The workflow uses `pull_request_target`, so that pull requests from forks get
the API key. That makes everything in the pull request untrusted, so:

- Only people with write access can start a review, by adding the label.
- The pull request's code is only read, never built or run.
- The model has only Read, Grep and Glob: no shell, no web access, no file edits
  and no GitHub access. Its context is gathered beforehand with a read-only
  token.
- The model is told to treat everything from the pull request, its tickets and
  comments as material to review, never as instructions.
- Only the post job can write to the pull request, and it runs only these
  scripts from the base branch. It has `contents: write` to resolve threads:
  with `pull-requests: write` alone, GitHub refused.
- The model proposes follow-ups, but the post job replies only on unresolved
  threads an earlier AI review started. Text in a pull request can't get it to
  reply on or resolve anyone else's thread.
- The run's summary page shows only numbers, never text the model wrote.

## Limitations

- **Jira tickets are ignored for now**: they aren't public, so they can't be
  read. Only linked GitHub issues are read. Without one, the **Ticket:** line
  judges the change against the pull request's description.
- **Large pull requests**: the compare API lists at most 300 files, so a
  larger change is reviewed on its first 300 files, and the diff says so.
- **Reviews of an unchanged commit**: adding the label again without new
  commits still runs the model, and costs about as much as a full review.
- **Extra timeline entries**: each follow-up reply also appears in the pull
  request's timeline as an empty review by github-actions. That's how GitHub's
  reply API works.

## Setup

The workflow needs:

- An Anthropic API key in the `TEMP_CLAUDE_PR_KEY` repository secret.
- An `ai-review` label.
- GitHub Actions enabled.

The workflow only runs from the base branch of the pull request, so it has to
be on that branch, normally `main`, before a label starts it.

## Files

| File | What it does |
|---|---|
| `.github/workflows/ai-code-review.yml` | The workflow, its permissions and the model and tool settings |
| `prompt.md` | The model's review instructions: what to look for and the output format |
| `gather_context.py` | Collects the pull request's context for the model |
| `load_guidance.py` | Matches `review-context.toml` and loads the guidance |
| `post_review.py` | Posts the review, the follow-ups and stale or failure notices |
| `common.py` | GitHub helpers shared by the scripts |

## Trying changes locally

The scripts need Python 3.12 and an authenticated `gh`. For example, to see
what the model would get for a pull request, and what would be posted:

```sh
python3 scripts/ci/ai-review/gather_context.py \
  --repo mozilla-mobile/firefox-ios --pr 12345 --commit <head sha> --out /tmp/pr-context

# bugbug's review_context_schema.py, from the commit validate-review-context.yml pins
PYTHONPATH=scripts/ci/ai-review:/path/to/schema-dir python3 scripts/ci/ai-review/load_guidance.py \
  --repo mozilla-mobile/firefox-ios --ref <base sha> --config review-context.toml \
  --files /tmp/pr-context/files.json --out /tmp/review-guidance.md

# review.json in the workflow's schema
python3 scripts/ci/ai-review/post_review.py --repo mozilla-mobile/firefox-ios --pr 12345 \
  --commit <head sha> --review review.json --files /tmp/pr-context/files.json --dry-run
```

`--dry-run` prints the review and replies without posting them.
