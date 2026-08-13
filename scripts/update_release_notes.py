#!/usr/bin/env python
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""Writes the App Store "What's New in This Version" text to every locale.

App Store Connect stores release notes as one appStoreVersionLocalization record
per locale. This script asks the API which locales exist on the version instead
of hardcoding them, so there is nothing to map from the app's .lproj directories
onto App Store Connect locale codes (which differ: zh-Hans, pt-BR, en-GB) and
nothing to update when locales are added or dropped.

The App Store version record must already exist in App Store Connect and still
be editable. This script fills in release notes; it does not create the version.

App Store Connect API reference for the four calls this makes:

    Sign a JWT
    https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests

    Find the version
    https://developer.apple.com/documentation/appstoreconnectapi/get-v1-apps-_id_-appstoreversions

    List its localizations
    https://developer.apple.com/documentation/appstoreconnectapi/get-v1-appstoreversions-_id_-appstoreversionlocalizations

    Write the release notes
    https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-appstoreversionlocalizations-_id_

Supporting reference:

    appStoreVersionLocalization attributes, including whatsNew
    https://developer.apple.com/documentation/appstoreconnectapi/appstoreversionlocalization

    Version states
    https://developer.apple.com/documentation/appstoreconnectapi/appversionstate
    https://developer.apple.com/documentation/appstoreconnectapi/appstoreversionstate

    Cursor pagination via links.next
    https://developer.apple.com/documentation/appstoreconnectapi/pageddocumentlinks

    Rate limits and error bodies
    https://developer.apple.com/documentation/appstoreconnectapi/identifying-rate-limits
    https://developer.apple.com/documentation/appstoreconnectapi/interpreting-and-handling-errors

Credentials come from the same environment variables as
scripts/nightly_testflight_add_group.py:

    APPSTORECONNECT_APIKEY_ISSUER_ID
    APPSTORECONNECT_APIKEY_KEY_ID
    APPSTORECONNECT_APIKEY_B64     base64-encoded .p8 private key
    APPSTORE_APP_ID

The version is never inferred from version.txt: that file tracks whichever branch
the build ran from, and main runs ahead of the release branches, so it would point
at the wrong version record. State it explicitly, or leave it out and let the one
editable version be found.

Examples:

    # Same text in every locale, targeting the one editable version
    RELEASE_NOTES="Bug fixes and performance improvements." \\
        python3 scripts/update_release_notes.py

    # Preview without writing anything
    python3 scripts/update_release_notes.py --version 154.1 \\
        --notes-file notes.txt --dry-run

    # Per-locale text, with a fallback for the locales not listed
    python3 scripts/update_release_notes.py --notes-json notes.json
"""

import argparse
import base64
import binascii
import json
import os
import sys
import time
from typing import NamedTuple, Optional

import jwt
import requests

API_BASE = "https://api.appstoreconnect.apple.com/v1"
PLATFORM = "IOS"

# App Store Connect truncates release notes past this length.
WHATS_NEW_MAX_LENGTH = 4000

# App Store Connect rejects tokens that live longer than 20 minutes, and recommends
# the full 20 for a long-running process making many requests. Writing ~40 locales
# can outlast a single short-lived token, so tokens are reminted on the fly.
# https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests
TOKEN_LIFETIME_SECONDS = 15 * 60
TOKEN_REFRESH_MARGIN_SECONDS = 60

MAX_ATTEMPTS = 4
RETRYABLE_STATUS_CODES = frozenset({429, 500, 502, 503, 504})

# Retry-After on a rate-limited response can name an hour or more, which would park
# the build in sleep until it times out. Back off, but keep the run interruptible.
# https://developer.apple.com/documentation/appstoreconnectapi/identifying-rate-limits
MAX_RETRY_DELAY_SECONDS = 60

# Statuses that mean the whole run is wrong, not one locale: bad credentials, a key
# without App Manager rights, a deleted version, or a version that stopped being
# editable. Retrying these against the remaining locales only burns rate limit.
SYSTEMIC_STATUS_CODES = frozenset({401, 403, 404, 409})

TRUTHY_ENV_VALUES = frozenset({"1", "true", "yes", "on"})
FALSY_ENV_VALUES = frozenset({"0", "false", "no", "off"})

# States in which App Store Connect still accepts metadata edits. Both the current
# appVersionState and the older appStoreState use these names.
# https://developer.apple.com/documentation/appstoreconnectapi/appversionstate
EDITABLE_VERSION_STATES = frozenset(
    {
        "PREPARE_FOR_SUBMISSION",
        "READY_FOR_REVIEW",
        "DEVELOPER_REJECTED",
        "REJECTED",
        "METADATA_REJECTED",
        "INVALID_BINARY",
    }
)

# Key reserved in a --notes-json file for the text used by unlisted locales.
DEFAULT_NOTES_KEY = "default"


class ReleaseNotesError(Exception):
    """A problem with the inputs, credentials, or the selected App Store version."""


class AppStoreConnectError(Exception):
    """A failure talking to the App Store Connect API.

    status_code is None for transport failures, which have no HTTP status.
    """

    def __init__(self, message, status_code=None):
        self.status_code = status_code
        super().__init__(message)

    @classmethod
    def from_response(cls, method, url, response):
        return cls(
            f"{method} {url} failed with HTTP {response.status_code}: "
            f"{describe_api_errors(response)}",
            status_code=response.status_code,
        )

    @classmethod
    def from_transport_error(cls, method, url, error):
        return cls(f"{method} {url} failed: {type(error).__name__}: {error}")


def describe_api_errors(response):
    """Pulls the human-readable parts out of an App Store Connect error body."""
    try:
        errors = response.json().get("errors", [])
    except ValueError:
        return response.text[:500]

    messages = []
    for error in errors:
        parts = [error.get("title"), error.get("detail")]
        message = " - ".join(part for part in parts if part)
        code = error.get("code")
        messages.append(f"{message} [{code}]" if code else message)
    return "; ".join(messages) or response.text[:500]


class Credentials(NamedTuple):
    issuer_id: str
    key_id: str
    private_key: str
    app_id: str


class PlannedUpdate(NamedTuple):
    localization_id: str
    locale: str
    whats_new: str
    current_whats_new: Optional[str]

    @property
    def needs_update(self):
        return self.current_whats_new != self.whats_new


class Summary(NamedTuple):
    updated: int
    unchanged: int
    failures: list
    not_attempted: int = 0


class TokenProvider:
    """Mints App Store Connect JWTs, reminting them as they approach expiry."""

    def __init__(self, credentials, clock=time.time):
        self._credentials = credentials
        self._clock = clock
        self._token = None
        self._expires_at = 0

    def token(self):
        now = self._clock()
        refresh_at = self._expires_at - TOKEN_REFRESH_MARGIN_SECONDS
        if self._token is None or now >= refresh_at:
            self._expires_at = int(now) + TOKEN_LIFETIME_SECONDS
            self._token = jwt.encode(
                {
                    "iss": self._credentials.issuer_id,
                    "exp": self._expires_at,
                    "aud": "appstoreconnect-v1",
                },
                self._credentials.private_key,
                algorithm="ES256",
                headers={"kid": self._credentials.key_id, "typ": "JWT"},
            )
        return self._token

    def invalidate(self):
        """Forces the next token() call to mint a fresh token."""
        self._token = None


class AppStoreConnectClient:
    """Minimal App Store Connect client with retries and cursor pagination."""

    def __init__(self, token_provider, session=None, sleep=time.sleep):
        self._token_provider = token_provider
        self._session = session or requests.Session()
        self._sleep = sleep

    def request(self, method, url, params=None, payload=None):
        attempt = 0
        reminted = False
        while True:
            attempt += 1
            try:
                response = self._session.request(
                    method,
                    url,
                    headers={
                        "Authorization": f"Bearer {self._token_provider.token()}",
                        "Content-Type": "application/json",
                    },
                    params=params,
                    json=payload,
                    timeout=60,
                )
            except requests.RequestException as error:
                # A reset connection or read timeout partway through ~40 sequential
                # writes is ordinary, so treat it like any other retryable failure.
                if attempt >= MAX_ATTEMPTS:
                    raise AppStoreConnectError.from_transport_error(
                        method, url, error
                    ) from error
                delay = backoff_delay(attempt)
                print(f"  {method} {url} failed: {error}, retrying in {delay}s")
                self._sleep(delay)
                continue

            if response.ok:
                return decode_json(method, url, response)

            # An expired token, or one rejected because the build machine's clock
            # drifted past the refresh margin, arrives as 401. Mint a new one and
            # try once before concluding the credentials are wrong.
            if response.status_code == 401 and not reminted:
                reminted = True
                self._token_provider.invalidate()
                print(f"  {method} {url} returned HTTP 401, retrying with a new token")
                continue

            retryable = response.status_code in RETRYABLE_STATUS_CODES
            if retryable and attempt < MAX_ATTEMPTS:
                delay = retry_delay(response, attempt)
                print(
                    f"  {method} {url} returned HTTP {response.status_code}, "
                    f"retrying in {delay}s"
                )
                self._sleep(delay)
                continue
            raise AppStoreConnectError.from_response(method, url, response)

    def get_all(self, url, params=None):
        """Reads every page of a collection, following links.next."""
        records = []
        while url:
            body = self.request("GET", url, params=params)
            records.extend(body.get("data", []))
            url = body.get("links", {}).get("next")
            # links.next already carries the original query string.
            params = None
        return records


def decode_json(method, url, response):
    """Decodes a success body, which an egress proxy or error page may not fill in."""
    if not response.content:
        return {}
    try:
        return response.json()
    except ValueError as error:
        raise AppStoreConnectError(
            f"{method} {url} returned HTTP {response.status_code} with a body that is "
            f"not JSON: {response.text[:200]}",
            status_code=response.status_code,
        ) from error


def backoff_delay(attempt):
    return min(MAX_RETRY_DELAY_SECONDS, 2**attempt)


def retry_delay(response, attempt):
    """Honours Retry-After when present, otherwise backs off exponentially."""
    retry_after = response.headers.get("Retry-After")
    if retry_after:
        try:
            # int(float(...)) also rejects "inf" and "nan", which would not clamp.
            return min(MAX_RETRY_DELAY_SECONDS, max(1, int(float(retry_after))))
        except (ValueError, OverflowError):
            pass
    return backoff_delay(attempt)


def parse_bool_env(name):
    """Reads a boolean environment variable, refusing values it cannot interpret.

    An unrecognised value must never be read as "write to production", so a typo
    like RELEASE_NOTES_DRY_RUN=ture fails instead of silently going live.
    """
    value = env(name)
    if value is None:
        return False
    normalized = value.lower()
    if normalized in TRUTHY_ENV_VALUES:
        return True
    if normalized in FALSY_ENV_VALUES:
        return False
    raise ReleaseNotesError(
        f"{name} is set to {value!r}, which is neither true nor false. Use one of: "
        f"{', '.join(sorted(TRUTHY_ENV_VALUES | FALSY_ENV_VALUES))}."
    )


def env(name):
    """Reads an environment variable, treating blank values as unset."""
    value = os.environ.get(name)
    return value.strip() if value and value.strip() else None


def load_credentials():
    missing = [
        name
        for name in (
            "APPSTORECONNECT_APIKEY_ISSUER_ID",
            "APPSTORECONNECT_APIKEY_KEY_ID",
            "APPSTORECONNECT_APIKEY_B64",
            "APPSTORE_APP_ID",
        )
        if not env(name)
    ]
    if missing:
        raise ReleaseNotesError(
            f"Missing required environment variables: {', '.join(missing)}"
        )

    encoded_key = env("APPSTORECONNECT_APIKEY_B64")
    try:
        # Secret stores sometimes wrap base64 across lines; drop the whitespace.
        private_key = base64.b64decode(
            "".join(encoded_key.split()), validate=True
        ).decode("utf-8")
    except (binascii.Error, UnicodeDecodeError) as error:
        raise ReleaseNotesError(
            f"APPSTORECONNECT_APIKEY_B64 is not base64-encoded UTF-8: {error}"
        ) from error

    credentials = Credentials(
        issuer_id=env("APPSTORECONNECT_APIKEY_ISSUER_ID"),
        key_id=env("APPSTORECONNECT_APIKEY_KEY_ID"),
        private_key=private_key,
        app_id=env("APPSTORE_APP_ID"),
    )

    # Valid base64 of the wrong bytes still decodes, so the usual misconfiguration -
    # a truncated or re-encoded .p8 in the secret store - only shows up when the key
    # signs something. Sign now so it reports as an error rather than a traceback.
    try:
        TokenProvider(credentials).token()
    except Exception as error:
        raise ReleaseNotesError(
            "APPSTORECONNECT_APIKEY_B64 does not contain a usable App Store Connect "
            f"ES256 private key: {type(error).__name__}: {error}"
        ) from error

    return credentials


def validate_notes(text, label):
    stripped = text.strip()
    if not stripped:
        raise ReleaseNotesError(f"Release notes for {label} are empty.")
    if len(stripped) > WHATS_NEW_MAX_LENGTH:
        raise ReleaseNotesError(
            f"Release notes for {label} are {len(stripped)} characters; App Store "
            f"Connect allows at most {WHATS_NEW_MAX_LENGTH}."
        )
    return stripped


def unescape_newlines(text):
    r"""Turns the two characters \n into a real newline.

    RELEASE_NOTES is typed into a single-line CI field, and newlines in Bitrise
    variables are unreliable enough that the API key is base64 encoded to avoid
    them. Only \n is translated, and only for text given directly; --notes-file
    holds real newlines already and --notes-json gets them from JSON decoding.
    """
    return text.replace("\\n", "\n")


def read_notes_file(path):
    try:
        with open(path, encoding="utf-8") as notes_file:
            return notes_file.read()
    except OSError as error:
        raise ReleaseNotesError(f"Could not read {path}: {error}") from error


def resolve_notes(args):
    """Returns (default text or None, per-locale overrides) from the chosen source."""
    sources = {
        "--notes": args.notes,
        "--notes-file": args.notes_file,
        "--notes-json": args.notes_json,
    }
    provided = sorted(name for name, value in sources.items() if value)
    if not provided:
        raise ReleaseNotesError(
            "No release notes given. Pass one of --notes, --notes-file, or "
            "--notes-json, or set RELEASE_NOTES, RELEASE_NOTES_FILE, or "
            "RELEASE_NOTES_JSON."
        )
    if len(provided) > 1:
        raise ReleaseNotesError(
            f"Release notes given more than once: {', '.join(provided)}. Pick one."
        )

    if args.notes:
        return validate_notes(unescape_newlines(args.notes), "all locales"), {}
    if args.notes_file:
        return validate_notes(read_notes_file(args.notes_file), args.notes_file), {}

    try:
        parsed = json.loads(read_notes_file(args.notes_json))
    except json.JSONDecodeError as error:
        raise ReleaseNotesError(
            f"{args.notes_json} is not valid JSON: {error}"
        ) from error
    if not isinstance(parsed, dict) or not all(
        isinstance(value, str) for value in parsed.values()
    ):
        raise ReleaseNotesError(
            f"{args.notes_json} must be a JSON object mapping locale to text, for "
            f'example {{"{DEFAULT_NOTES_KEY}": "Bug fixes.", "de": "Fehler."}}'
        )

    overrides = {
        locale: validate_notes(text, locale)
        for locale, text in parsed.items()
        if locale != DEFAULT_NOTES_KEY
    }
    default_notes = parsed.get(DEFAULT_NOTES_KEY)
    if default_notes is not None:
        default_notes = validate_notes(default_notes, DEFAULT_NOTES_KEY)
    if not overrides and default_notes is None:
        raise ReleaseNotesError(f"{args.notes_json} contains no release notes.")
    return default_notes, overrides


def describe_app(client, app_id):
    """Names the app being written to, so the wrong APPSTORE_APP_ID is visible.

    The value lives in CI secrets and cannot be checked from the repository, and a
    wrong one can otherwise succeed silently against another app's metadata.
    """
    body = client.request("GET", f"{API_BASE}/apps/{app_id}")
    attributes = body.get("data", {}).get("attributes", {})
    name = attributes.get("name") or "unknown app"
    return f"{name} ({attributes.get('bundleId')}), id {app_id}"


def version_state(version):
    attributes = version.get("attributes", {})
    return attributes.get("appVersionState") or attributes.get("appStoreState")


def describe_versions(versions, limit=10):
    """Renders the most recently created versions for use in error messages."""
    ordered = sorted(
        versions,
        key=lambda version: version["attributes"].get("createdDate") or "",
        reverse=True,
    )
    described = ", ".join(
        f"{version['attributes'].get('versionString')} ({version_state(version)})"
        for version in ordered[:limit]
    )
    if not described:
        return "none"
    if len(ordered) > limit:
        described += f", and {len(ordered) - limit} more"
    return described


def select_version(versions, version_string, allow_any_state):
    """Picks the App Store version to write to, or explains why it cannot."""
    if version_string:
        matches = [
            version
            for version in versions
            if version["attributes"].get("versionString") == version_string
        ]
        if not matches:
            raise ReleaseNotesError(
                f"No App Store version {version_string} exists for this app. Create "
                "the version record in App Store Connect before running this script. "
                f"Existing versions: {describe_versions(versions)}"
            )
        version = max(
            matches, key=lambda version: version["attributes"].get("createdDate") or ""
        )
    else:
        editable = [
            version
            for version in versions
            if version_state(version) in EDITABLE_VERSION_STATES
        ]
        if not editable:
            raise ReleaseNotesError(
                "No editable App Store version was found. Create the version record "
                "in App Store Connect first, or pass --version to target a specific "
                f"one. Existing versions: {describe_versions(versions)}"
            )
        if len(editable) > 1:
            raise ReleaseNotesError(
                "Found more than one editable App Store version; pass --version to "
                f"pick one. Candidates: {describe_versions(editable)}"
            )
        version = editable[0]

    state = version_state(version)
    if state not in EDITABLE_VERSION_STATES and not allow_any_state:
        raise ReleaseNotesError(
            f"App Store version {version['attributes'].get('versionString')} is in "
            f"state {state}, which does not accept metadata edits. Editable states "
            f"are {', '.join(sorted(EDITABLE_VERSION_STATES))}. Pass "
            "--allow-any-state to try anyway."
        )
    return version


def build_plan(localizations, default_notes, overrides, only_locales):
    """Maps each localization record to the release notes it should end up with."""
    available = {
        localization["attributes"]["locale"]: localization
        for localization in localizations
    }

    # A bad --locales value is a typo on the command line, so fail on it. A stale
    # locale in a --notes-json file is config drift and must not block a release.
    if only_locales:
        unknown = sorted(set(only_locales) - set(available))
        if unknown:
            raise ReleaseNotesError(
                f"--locales names locales this version does not have: "
                f"{', '.join(unknown)}. Available: {', '.join(sorted(available))}"
            )
    for locale in sorted(set(overrides) - set(available)):
        print(f"warning: ignoring release notes for unknown locale {locale}")

    plan = []
    for locale in sorted(available):
        if only_locales and locale not in only_locales:
            continue
        whats_new = overrides.get(locale, default_notes)
        if whats_new is None:
            print(f"  {locale}: skipped, no release notes provided")
            continue
        attributes = available[locale]["attributes"]
        plan.append(
            PlannedUpdate(
                localization_id=available[locale]["id"],
                locale=locale,
                whats_new=whats_new,
                current_whats_new=attributes.get("whatsNew"),
            )
        )
    return plan


def apply_plan(client, plan, dry_run):
    updated = 0
    unchanged = 0
    failures = []
    not_attempted = 0
    for index, update in enumerate(plan):
        if not update.needs_update:
            unchanged += 1
            print(f"  {update.locale}: already up to date")
            continue
        if dry_run:
            updated += 1
            print(f"  {update.locale}: would update")
            continue
        try:
            client.request(
                "PATCH",
                f"{API_BASE}/appStoreVersionLocalizations/{update.localization_id}",
                payload={
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "id": update.localization_id,
                        "attributes": {"whatsNew": update.whats_new},
                    }
                },
            )
        except AppStoreConnectError as error:
            failures.append((update.locale, str(error)))
            print(f"  {update.locale}: FAILED - {error}")
            if error.status_code in SYSTEMIC_STATUS_CODES:
                not_attempted = len(plan) - index - 1
                print(
                    f"  stopping: HTTP {error.status_code} applies to the whole run, "
                    f"so {not_attempted} remaining locales were not attempted"
                )
                break
            continue
        updated += 1
        print(f"  {update.locale}: updated")
    return Summary(
        updated=updated,
        unchanged=unchanged,
        failures=failures,
        not_attempted=not_attempted,
    )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Write the App Store 'What's New in This Version' text to every locale "
            "of an App Store Connect version."
        ),
        epilog=(
            "The App Store version record must already exist in App Store Connect "
            "and still be editable."
        ),
    )
    # Deliberately not defaulted from $BITRISE_RELEASE_VERSION: that comes from
    # version.txt on whichever branch the build was started from, and main runs ahead
    # of the release branches, so it would quietly target the wrong version record.
    parser.add_argument(
        "--version",
        default=env("RELEASE_NOTES_VERSION"),
        help=(
            "App Store version string to update, for example 154.1. Defaults to "
            "$RELEASE_NOTES_VERSION. When unset, the one editable version is used, "
            "and an ambiguous choice is an error."
        ),
    )
    parser.add_argument(
        "--notes",
        default=env("RELEASE_NOTES"),
        help=(
            "Release notes text to write to every locale, in which \\n becomes a "
            "line break. Defaults to $RELEASE_NOTES."
        ),
    )
    parser.add_argument(
        "--notes-file",
        default=env("RELEASE_NOTES_FILE"),
        help=(
            "File holding the release notes text for every locale. Defaults to "
            "$RELEASE_NOTES_FILE."
        ),
    )
    parser.add_argument(
        "--notes-json",
        default=env("RELEASE_NOTES_JSON"),
        help=(
            "JSON file mapping locale to release notes, with an optional "
            f'"{DEFAULT_NOTES_KEY}" key for the remaining locales. Defaults to '
            "$RELEASE_NOTES_JSON."
        ),
    )
    parser.add_argument(
        "--locales",
        help="Comma-separated locales to limit the update to, for example en-US,de.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=parse_bool_env("RELEASE_NOTES_DRY_RUN"),
        help=(
            "Report what would change without writing anything. Also enabled by "
            "$RELEASE_NOTES_DRY_RUN set to any of: "
            f"{', '.join(sorted(TRUTHY_ENV_VALUES))}."
        ),
    )
    parser.add_argument(
        "--allow-any-state",
        action="store_true",
        help="Write to the version even if its state normally rejects metadata edits.",
    )
    return parser.parse_args(argv)


def run(args):
    credentials = load_credentials()
    default_notes, overrides = resolve_notes(args)
    only_locales = (
        {locale.strip() for locale in args.locales.split(",") if locale.strip()}
        if args.locales
        else set()
    )

    client = AppStoreConnectClient(TokenProvider(credentials))

    print(f"Target app: {describe_app(client, credentials.app_id)}")

    # versionString is matched locally rather than with filter[versionString] so that
    # the "no such version" error can list the versions that do exist.
    versions = client.get_all(
        f"{API_BASE}/apps/{credentials.app_id}/appStoreVersions",
        {"filter[platform]": PLATFORM, "limit": "50"},
    )
    version = select_version(versions, args.version, args.allow_any_state)
    print(
        f"Using App Store version {version['attributes'].get('versionString')} "
        f"(id {version['id']}, state {version_state(version)})"
    )

    localizations = client.get_all(
        f"{API_BASE}/appStoreVersions/{version['id']}/appStoreVersionLocalizations",
        {"limit": "50"},
    )
    if not localizations:
        raise ReleaseNotesError(
            "This version has no appStoreVersionLocalizations records to write to."
        )
    print(f"Found {len(localizations)} locales")

    plan = build_plan(localizations, default_notes, overrides, only_locales)
    if not plan:
        raise ReleaseNotesError("No locales left to update.")

    if default_notes:
        indented = "\n".join(f"    {line}" for line in default_notes.splitlines())
        print(f"Release notes:\n{indented}")
    if overrides:
        print(f"Localized overrides: {', '.join(sorted(overrides))}")

    print(f"{'Previewing' if args.dry_run else 'Writing'} release notes:")
    summary = apply_plan(client, plan, args.dry_run)

    verb = "would be updated" if args.dry_run else "updated"
    done = (
        f"Done: {summary.updated} {verb}, {summary.unchanged} already up to date, "
        f"{len(summary.failures)} failed"
    )
    if summary.not_attempted:
        done += f", {summary.not_attempted} not attempted"
    print(done)
    if summary.failures:
        print("Failed locales:", ", ".join(locale for locale, _ in summary.failures))
        return 1
    return 0


def main(argv=None):
    try:
        return run(parse_args(argv))
    except (ReleaseNotesError, AppStoreConnectError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
