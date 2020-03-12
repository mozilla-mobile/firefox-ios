# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# A script to mirror bugilla issues into github, where we can see
# them as part of our github-and-jira-based planning procedure.
#
# For every relevant bug we find in bugzilla, we create a corresponding
# github issue that:
#
#   * has matching summary and description text
#   * has the "bugzilla" label
#   * may have additional metadata in the issue description
#
# If such an issue already exists, we update it to match the bugzilla
# bug rather than creating a new one.
#
# Note that the mirroring is (for now) entirely one-way. Changes to bug summar,
# description of status in bugzilla will be pushed to github, but any changes
# in github will not be reflected back in bugzilla.

import re
import os
import urllib.parse

import requests
from github import Github

DRY_RUN = False
VERBOSE_DEBUG = False

GH_REPO = 'mozilla/application-services-bug-mirror'
GH_OLD_REPOS = ['mozilla/application-services']
GH_LABEL = 'bugzilla'

BZ_URL = 'https://bugzilla.mozilla.org/rest'

SYNCED_ISSUE_TEXT = '\n\n---\n\N{LADY BEETLE} Issue is synchronized with Bugzilla [Bug {id}](https://bugzilla.mozilla.org/show_bug.cgi?id={id})\n'
SYNCED_ISSUE_BUGID_REGEX = re.compile(
    # N.B. we can't use a r'raw string' literal here because of the \N escape.
    '\N{LADY BEETLE} Issue is synchronized with Bugzilla \\[Bug (\\d+)\\]')
SEE_ALSO_ISSUE_REGEX_TEMPLATE = r'^https://github.com/{}/issues/\d+$'
SYNCED_ISSUE_CLOSE_COMMENT = 'Upstream bug has been closed with the following resolution: {resolution}.'

# Jira adds some metadata to issue descriptions, indicated by this separator.
# We want to preserve any lines like this from the github issue description.
JIRA_ISSUE_MARKER = '\N{BOX DRAWINGS LIGHT TRIPLE DASH VERTICAL}'

# For now, only look at recent bugs in order to preserve sanity.
MIN_CREATION_TIME = '20190801'


def log(msg, *args, **kwds):
    msg = str(msg)
    print(msg.format(*args, **kwds))


def get_json(url):
    """Fetch a URL and return the result parsed as JSON."""
    r = requests.get(url)
    r.raise_for_status()
    return r.json()


class BugSet(object):
    """A set of bugzilla bugs, which we might like to mirror into GitHub.

    This class knows how to query the bugzilla API to find bugs, and how to
    fetch appropriate metadata for mirroring into github.

    Importantly, it knows how to use a bugzilla API key to find confidential
    or security-sensitive bugs, and can report their existence without leaking
    potentially confidential details (e.g. by reporting a placeholder summary
    of "confidential issue" rather than the actual bug summary).

    Use `update_from_bugzilla()` to query for bugs and add them to an in-memory
    store, then access them as if this were a dict keyed by bug number.  Each bug
    will be a dict with the following fields:

        * `id`: The bug id, as an integer
        * `whiteboard`: The bug's whiteboard text, as a string
        * `is_open`: Whether the bug is open, as a boolean
        * `summary`: The one-line bug summry, as a string
        * `status`: The bug's status field, as a string
        * `comment0`: The bug's first comment, which is typically a longer description, as a string
    """

    def __init__(self, api_key=None):
        self.api_key = api_key
        self.bugs = {}

    def __getitem__(self, key):
        return self.bugs[str(key)]

    def __delitem__(self, key):
        del self.bugs[str(key)]

    def __iter__(self):
        return iter(self.bugs)

    def __len__(self):
        return len(self.bugs)

    def update_from_bugzilla(self, **kwds):
        """Slurp in bugs from bugzilla that match the given query keywords."""
        # First, fetch a minimal set of "safe" metadata that we're happy to put in
        # a public github issue, even for confidential bugzilla bugs.
        # This is the only query that's allowed to use a BZ API token to access
        # confidential bug info.
        url = BZ_URL + '/bug?include_fields=id,is_open,see_also'
        url += '&' + self._make_query_string(**kwds)
        if self.api_key is not None:
            url += '&api_key=' + self.api_key
        found_bugs = set()
        for bug in get_json(url)['bugs']:
            bugid = str(bug['id'])
            found_bugs.add(bugid)
            if bugid not in self.bugs:
                self.bugs[bugid] = bug
            else:
                self.bugs[bugid].update(bug)
        # Now make *unauthenticated* public API queries to fetch additional metadata
        # which we know is safe to make public. Any security-sensitive bugs will be
        # silently omitted from this query.
        if found_bugs:
            public_bugs = set()
            url = BZ_URL + '/bug?include_fields=id,is_open,see_also,summary,status,resolution'
            url += '&id=' + '&id='.join(found_bugs)
            for bug in get_json(url)['bugs']:
                bugid = str(bug['id'])
                public_bugs.add(bugid)
                self.bugs[bugid].update(bug)
            # Unlike with fetching bug metadata, trying to fetch comments for a confidential bug
            # will error the entire request rather than silently omitting it. So we have to filter
            # them out during the loop above. Note that the resulting URL is a bit weird, it's:
            #
            #   /bug/<bug1>/comment?ids=bug2,bug3...
            #
            # This allows us to fetch comments from multiple bugs in a single query.
            if public_bugs:
                url = BZ_URL + '/bug/' + public_bugs.pop() + '/comment'
                if public_bugs:
                    url += '?ids=' + '&ids='.join(public_bugs)
                for bugnum, bug in get_json(url)['bugs'].items():
                    bugid = str(bugnum)
                    self.bugs[bugid]['comment0'] = bug['comments'][0]['text']

    def _make_query_string(self, product=None, component=None, id=None, resolved=None,
                           creation_time=None, last_change_time=None):
        def listify(x): return x if isinstance(x, (list, tuple, set)) else (x,)

        def encode(x): return urllib.parse.quote(x, safe='')
        qs = []
        if product is not None:
            qs.extend('product=' + encode(p) for p in listify(product))
        if component is not None:
            qs.extend('component=' + encode(c) for c in listify(component))
        if id is not None:
            qs.extend('id=' + encode(i) for i in listify(id))
        if creation_time is not None:
            qs.append('creation_time=' + creation_time)
        if last_change_time is not None:
            qs.append('last_change_time=' + last_change_time)
        if resolved is not None:
            if resolved:
                raise ValueError(
                    "Sorry, I haven't looked up how to query for only resolved bugs...")
            else:
                qs.append('resolution=---')
        if len(qs) == 0:
            raise ValueError(
                "Cowardly refusing to query every bug in existence; please specify some filters")
        return '&'.join(qs)


class MirrorIssueSet(object):
    """A set of mirror issues from GitHub, which can be synced to bugzilla bugs.

    Given a `BugSet` containing the bugs that you want to appear in github, use
    like so:

        issues = MirrorIssueSet(GITHUB_TOKEN)
        issues.sync_from_bugset(bugs)

    This will ensure that every bug in the bugset has a corresponding mirror issue,
    creating or updating issues as appropriate. It will also close out any miror issues
    that do not appear in the bugset, on the assumption that they've been closed in
    bugzilla.
    """

    def __init__(self, repo, label, api_key=None):
        self._gh = Github(api_key)
        self._repo = self._gh.get_repo(repo)
        self._repo_name = repo
        self._label = self._repo.get_label(label)
        self._see_also_regex = re.compile(
            SEE_ALSO_ISSUE_REGEX_TEMPLATE.format(repo))
        # The mirror issues, indexes by bugzilla bugid.
        self.mirror_issues = {}

    def sync_from_bugset(self, bugs, updates_only=False):
        """Sync the mirrored issues with the given BugSet (which might be modified in-place)."""
        self.update_from_github()
        log('Found {} mirror issues in github', len(self.mirror_issues))
        # Fetch details for any mirror issues that are not in the set.
        # They might be e.g. closed, or have been moved to a different component,
        # but we still want to update them in github.
        missing_bugs = [
            bugid for bugid in self.mirror_issues if bugid not in bugs]
        if missing_bugs:
            log('Fetching info for {} missing bugs from bugzilla', len(missing_bugs))
            bugs.update_from_bugzilla(id=missing_bugs)
        num_updated = 0
        for bugid in bugs:
            if updates_only and bugid not in self.mirror_issues:
                if VERBOSE_DEBUG:
                    log('Not creating new bug {} in old repo', bugid)
                continue
            if self.sync_issue_from_bug_info(bugid, bugs[bugid]):
                num_updated += 1
        if num_updated > 0:
            log('Updated {} issues from bugzilla to github', num_updated)
        else:
            log('Looks like everything is up-to-date in {}', self._repo_name)

    def update_from_github(self):
        """Find mirror issues in the github repo.

        We assume they have a special label for easy searching, and some text in the issue
        description that tells us what bug it links to.
        """
        for issue in self._repo.get_issues(state='open', labels=[self._label]):
            match = SYNCED_ISSUE_BUGID_REGEX.search(issue.body)
            if not match:
                log("WARNING: Mirror issue #{} does not have a bugzilla bugid", issue.number)
                continue
            bugid = match.group(1)
            if bugid in self.mirror_issues:
                log("WARNING: Duplicate mirror issue #{} for Bug {}",
                    issue.number, bugid)
                continue
            self.mirror_issues[bugid] = issue

    def sync_issue_from_bug_info(self, bugid, bug_info):
        issue = self.mirror_issues.get(bugid, None)
        issue_info = self._format_issue_info(bug_info, issue)
        if issue is None:
            if bug_info['is_open']:
                # As a light hack, if the bugzilla bug has a "see also" link to an issue in our repo,
                # we assume that's an existing mirror issue and avoid creating a new one. This lets us
                # keep the bug open in bugzilla but close it in github without constantly creating new
                # mirror issues.
                for see_also in bug_info.get('see_also', ()):
                    if self._see_also_regex.match(see_also) is not None:
                        log('Ignoring bz{id}, which links to {} via see-also',
                            see_also, **bug_info)
                        break
                else:
                    issue_info.pop('state')
                    log('Creating mirror issue for bz{id}', **bug_info)
                    if DRY_RUN:
                        issue = {}
                    else:
                        issue = self._repo.create_issue(**issue_info)
                    self.mirror_issues[bugid] = issue
                    return True
        else:
            changed_fields = [
                field for field in issue_info if issue_info[field] != getattr(issue, field)]
            if changed_fields:
                # Note that this will close issues that have not open in bugzilla.
                log('Updating mirror issue #{} for bz{id} (changed: {})',
                    issue.number, changed_fields, **bug_info)
                # Weird API thing where `issue.edit` accepts strings rather than label refs...
                issue_info['labels'] = [l.name for l in issue_info['labels']]
                # Explain why we are closing this issue.
                if not DRY_RUN:
                    if not bug_info['is_open'] and 'state' in changed_fields and 'resolution' in bug_info:
                        issue.create_comment(SYNCED_ISSUE_CLOSE_COMMENT.format(resolution=bug_info['resolution']))
                    issue.edit(**issue_info)
                return True
            else:
                if VERBOSE_DEBUG:
                    log('No change for issue #{}', issue.number)
        return False

    def _format_issue_info(self, bug_info, issue):
        issue_info = {
            'state': 'open' if bug_info['is_open'] else 'closed'
        }
        if 'summary' in bug_info:
            issue_info['title'] = bug_info['summary']
        else:
            issue_info['title'] = 'Confidential Bugzilla issue'
        if 'comment0' in bug_info:
            issue_info['body'] = bug_info['comment0']
        else:
            issue_info['body'] = 'No description is available for this confidential bugzilla issue.'

        if issue is None:
            issue_info['labels'] = [self._label]
        else:
            issue_info['labels'] = issue.labels
            if self._label not in issue.labels:
                issue_info['labels'].append(self._label)

        # Ensure we include a link to the bugzilla bug for reference.
        issue_info['body'] += SYNCED_ISSUE_TEXT.format(**bug_info)

        # Preserve any Jira sync lines in the issue body.
        if issue is not None:
            for ln in issue.body.split("\n"):
                if ln.startswith(JIRA_ISSUE_MARKER):
                    issue_info['body'] += '\n' + ln
            # Jira seems to sometimes add a trailing newline, try to match it to avoid spurious updates.
            if issue.body.endswith('\n') and not issue_info['body'].endswith('\n'):
                issue_info['body'] += '\n'

        return issue_info


def sync_bugzilla_to_github():
    # Find the sets of bugs in bugzilla that we want to mirror.
    log('Finding relevant bugs in bugzilla...')
    bugs = BugSet(os.environ.get('BZ_API_KEY'))
    bugs.update_from_bugzilla(product='Firefox', component='Firefox Accounts',
                              resolved=False, creation_time=MIN_CREATION_TIME)
    bugs.update_from_bugzilla(product='Firefox', component='Sync',
                              resolved=False, creation_time=MIN_CREATION_TIME)
    log('Found {} bugzilla bugs', len(bugs))

    gh_token = os.environ.get('GITHUB_TOKEN')

    # Find any that are already represented in old github repos.
    # We don't want to make duplicates of them in the current repo!
    for old_repo in GH_OLD_REPOS:
        log('Syncing to old github repo at {}', old_repo)
        old_issues = MirrorIssueSet(old_repo, GH_LABEL, gh_token)
        old_issues.sync_from_bugset(bugs, updates_only=True)
        done_count = 0
        for bugid in old_issues.mirror_issues:
            if bugid in bugs:
                del bugs[bugid]
                done_count += 1
        log('Synced {} bugs, now {} left to sync', done_count, len(bugs))

    log('Syncing to github repo at {}', GH_REPO)
    issues = MirrorIssueSet(GH_REPO, GH_LABEL, gh_token)
    issues.sync_from_bugset(bugs)
    log('Done!')


if __name__ == "__main__":
    sync_bugzilla_to_github()
