# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""Tests for update_release_notes.py.

    python3 -m pip install pytest pyjwt cryptography requests
    python3 -m pytest scripts/test_update_release_notes.py

The App Store Connect API is replaced by FakeSession, so nothing here touches the
network. The real AppStoreConnectClient is used throughout, so retry, pagination,
and token handling are exercised rather than stubbed.
"""

import base64
import json

import pytest
import requests
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

import update_release_notes as urn

APP_ID = "989804926"

# A realistic spread: codes that differ from the app's .lproj names, and regional
# variants that only exist on the App Store side.
LOCALES = [
    "ar-SA", "ca", "cs", "da", "de", "el", "en-AU", "en-CA", "en-GB", "en-US",
    "es-ES", "es-MX", "fi", "fr-CA", "fr-FR", "he", "hi", "hr", "hu", "id",
    "it", "ja", "ko", "ms", "nl-NL", "no", "pl", "pt-BR", "pt-PT", "ro",
    "ru", "sk", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant",
]

ENV_NAMES = (
    "APPSTORECONNECT_APIKEY_ISSUER_ID",
    "APPSTORECONNECT_APIKEY_KEY_ID",
    "APPSTORECONNECT_APIKEY_B64",
    "APPSTORE_APP_ID",
    "RELEASE_NOTES",
    "RELEASE_NOTES_FILE",
    "RELEASE_NOTES_JSON",
    "RELEASE_NOTES_VERSION",
    "RELEASE_NOTES_DRY_RUN",
    "BITRISE_RELEASE_VERSION",
)


@pytest.fixture(scope="session")
def private_key_pem():
    key = ec.generate_private_key(ec.SECP256R1())
    return key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()


class FakeResponse:
    def __init__(self, status_code, body=None, headers=None, text=None):
        self.status_code = status_code
        self._body = body
        self.headers = headers or {}
        self.text = text if text is not None else json.dumps(body or {})
        self.content = self.text.encode()

    @property
    def ok(self):
        return 200 <= self.status_code < 300

    def json(self):
        if self._body is None:
            raise ValueError("not json")
        return self._body


class FakeSession:
    """Serves the four App Store Connect endpoints the script uses."""

    def __init__(
        self,
        versions,
        locales=None,
        page_size=25,
        existing=None,
        patch_status=None,
        transient=None,
        transport_error=None,
        app_name="Firefox",
    ):
        self.versions = versions
        self.locales = LOCALES if locales is None else locales
        self.page_size = page_size
        self.existing = existing or {}
        self.patch_status = patch_status or {}
        self.transient = dict(transient or {})
        self.transport_error = dict(transport_error or {})
        self.app_name = app_name
        self.patches = {}
        self.calls = []
        self.tokens = []

    def request(self, method, url, headers=None, params=None, json=None, timeout=None):
        self.calls.append((method, url, params))
        self.tokens.append(headers["Authorization"])

        if self.transport_error.get(url, 0) > 0:
            self.transport_error[url] -= 1
            raise requests.ConnectionError("connection reset by peer")

        if self.transient.get(url, 0) > 0:
            self.transient[url] -= 1
            return FakeResponse(429, {"errors": []}, {"Retry-After": "1"})

        if method == "GET" and url.endswith(f"/apps/{APP_ID}"):
            return FakeResponse(200, {
                "data": {"id": APP_ID, "attributes": {
                    "name": self.app_name, "bundleId": "org.mozilla.ios.Firefox"}}})

        if method == "GET" and url.endswith("/appStoreVersions"):
            # Apply filter[versionString] like the real API, so a caller that filters
            # server-side genuinely cannot see the other versions.
            wanted = (params or {}).get("filter[versionString]")
            matching = [
                candidate for candidate in self.versions
                if not wanted
                or candidate["attributes"]["versionString"] == wanted
            ]
            return FakeResponse(200, {"data": matching, "links": {}})

        if method == "GET" and "appStoreVersionLocalizations" in url:
            offset = int(url.split("cursor=")[1]) if "cursor=" in url else 0
            page = self.locales[offset:offset + self.page_size]
            links = {}
            if offset + self.page_size < len(self.locales):
                links["next"] = (
                    f"{url.split('?')[0]}?cursor={offset + self.page_size}"
                )
            return FakeResponse(200, {
                "data": [
                    {"id": f"loc-{locale}", "attributes": {
                        "locale": locale, "whatsNew": self.existing.get(locale)}}
                    for locale in page
                ],
                "links": links,
            })

        if method == "PATCH":
            localization_id = url.rsplit("/", 1)[1]
            status = self.patch_status.get(localization_id)
            if status:
                return FakeResponse(status, {"errors": [
                    {"title": "Conflict", "detail": "not editable",
                     "code": "STATE_ERROR"}]})
            self.patches[localization_id] = json["data"]["attributes"]["whatsNew"]
            return FakeResponse(200, {"data": {"id": localization_id}})

        raise AssertionError(f"unexpected {method} {url}")

    def patch_count(self):
        return sum(1 for call in self.calls if call[0] == "PATCH")


def version(version_string, state, created="2026-08-01T00:00:00Z",
            state_field="appVersionState"):
    return {
        "id": f"ver-{version_string}",
        "attributes": {
            "versionString": version_string,
            state_field: state,
            "createdDate": created,
        },
    }


@pytest.fixture
def run_script(monkeypatch, private_key_pem):
    """Runs main() against a FakeSession with the real client and no sleeping."""
    def _run(session, argv=(), **environ):
        for name in ENV_NAMES:
            monkeypatch.delenv(name, raising=False)
        monkeypatch.setenv("APPSTORECONNECT_APIKEY_ISSUER_ID", "issuer-id")
        monkeypatch.setenv("APPSTORECONNECT_APIKEY_KEY_ID", "key-id")
        monkeypatch.setenv(
            "APPSTORECONNECT_APIKEY_B64",
            base64.b64encode(private_key_pem.encode()).decode(),
        )
        monkeypatch.setenv("APPSTORE_APP_ID", APP_ID)
        for name, value in environ.items():
            monkeypatch.setenv(name, value)

        client_class = urn.AppStoreConnectClient
        monkeypatch.setattr(
            urn,
            "AppStoreConnectClient",
            lambda token_provider: client_class(
                token_provider, session=session, sleep=lambda _: None
            ),
        )
        return urn.main(list(argv))
    return _run


def editable(version_string="154.1"):
    return [version(version_string, "PREPARE_FOR_SUBMISSION")]


def localization_reads(session):
    """The collection GETs, whose URLs carry the version id the run chose."""
    return [
        call[1]
        for call in session.calls
        if call[0] == "GET" and call[1].endswith("appStoreVersionLocalizations")
    ]


# --- writing release notes ---------------------------------------------------


def test_writes_the_same_text_to_every_locale(run_script):
    session = FakeSession(editable())
    assert run_script(session, ["--version", "154.1", "--notes", "Bug fixes."]) == 0
    assert len(session.patches) == len(LOCALES)
    assert set(session.patches.values()) == {"Bug fixes."}


def test_pagination_follows_links_next(run_script):
    session = FakeSession(editable(), page_size=10)
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 0
    pages = [
        call for call in session.calls
        if call[0] == "GET" and "appStoreVersionLocalizations" in call[1]
    ]
    assert len(pages) == 4
    # The cursor URL already carries the query string; resending params would reset it.
    assert pages[1][2] is None
    assert len(session.patches) == len(LOCALES)


def test_skips_locales_that_already_match(run_script):
    already = {locale: "Bug fixes." for locale in LOCALES[:12]}
    session = FakeSession(editable(), existing=already)
    assert run_script(session, ["--version", "154.1", "--notes", "Bug fixes."]) == 0
    assert session.patch_count() == len(LOCALES) - 12


def test_patch_payload_shape(run_script):
    session = FakeSession(editable(), locales=["en-US"])
    run_script(session, ["--version", "154.1", "--notes", "Line one\nLine two"])
    assert session.patches == {"loc-en-US": "Line one\nLine two"}


def test_logs_the_target_app_so_a_wrong_app_id_is_visible(run_script, capsys):
    session = FakeSession(editable(), locales=["en-US"])
    run_script(session, ["--version", "154.1", "--notes", "x"])
    assert "Firefox (org.mozilla.ios.Firefox), id 989804926" in capsys.readouterr().out


# --- dry run ----------------------------------------------------------------


def test_dry_run_writes_nothing(run_script):
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1", "--notes", "x", "--dry-run"]
    ) == 0
    assert session.patch_count() == 0


@pytest.mark.parametrize("value", ["true", "TRUE", "True", "1", "yes", "on", "ON"])
def test_dry_run_env_accepts_the_spellings_an_operator_types(run_script, value):
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1"], RELEASE_NOTES="x", RELEASE_NOTES_DRY_RUN=value
    ) == 0
    assert session.patch_count() == 0


@pytest.mark.parametrize("value", ["false", "FALSE", "0", "no", "off"])
def test_dry_run_env_falsy_values_write(run_script, value):
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1"], RELEASE_NOTES="x", RELEASE_NOTES_DRY_RUN=value
    ) == 0
    assert session.patch_count() == len(LOCALES)


@pytest.mark.parametrize("value", ["ture", "maybe", "y", "2"])
def test_unreadable_dry_run_env_fails_instead_of_writing(run_script, value):
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1"], RELEASE_NOTES="x", RELEASE_NOTES_DRY_RUN=value
    ) == 1
    assert session.calls == []


# --- choosing the version ---------------------------------------------------


def test_version_is_not_taken_from_the_branch_version_txt(run_script):
    """$BITRISE_RELEASE_VERSION follows the build's branch, not the release."""
    session = FakeSession([
        version("154.1", "PREPARE_FOR_SUBMISSION"),
        version("149.1", "PREPARE_FOR_SUBMISSION"),
    ])
    # Two editable versions and no explicit choice, so this must fail rather than
    # silently pick main's version.txt value.
    assert run_script(session, [], RELEASE_NOTES="x",
                      BITRISE_RELEASE_VERSION="154.1") == 1
    assert session.patch_count() == 0


def test_release_notes_version_env_selects_the_version(run_script):
    session = FakeSession([
        version("154.1", "PREPARE_FOR_SUBMISSION"),
        version("149.1", "PREPARE_FOR_SUBMISSION"),
    ])
    assert run_script(
        session, [], RELEASE_NOTES="x", RELEASE_NOTES_VERSION="149.1"
    ) == 0
    assert localization_reads(session) == [
        f"{urn.API_BASE}/appStoreVersions/ver-149.1/appStoreVersionLocalizations"
    ]


def test_explicit_version_wins_over_the_branch_version(run_script):
    session = FakeSession([
        version("154.1", "PREPARE_FOR_SUBMISSION"),
        version("149.1", "PREPARE_FOR_SUBMISSION"),
    ])
    assert run_script(
        session,
        [],
        RELEASE_NOTES="x",
        RELEASE_NOTES_VERSION="149.1",
        BITRISE_RELEASE_VERSION="154.1",
    ) == 0
    assert localization_reads(session) == [
        f"{urn.API_BASE}/appStoreVersions/ver-149.1/appStoreVersionLocalizations"
    ]


def test_single_editable_version_is_selected_automatically(run_script):
    session = FakeSession([
        version("154.1", "PREPARE_FOR_SUBMISSION"),
        version("154.0", "READY_FOR_DISTRIBUTION"),
        version("153.0", "REPLACED_WITH_NEW_VERSION"),
    ])
    assert run_script(session, ["--notes", "x"]) == 0
    assert len(session.patches) == len(LOCALES)


def test_ambiguous_version_choice_fails(run_script):
    session = FakeSession([
        version("154.1", "PREPARE_FOR_SUBMISSION"),
        version("155.0", "DEVELOPER_REJECTED"),
    ])
    assert run_script(session, ["--notes", "x"]) == 1
    assert session.patch_count() == 0


def test_missing_version_error_lists_the_versions_that_do_exist(run_script, capsys):
    session = FakeSession([
        version("154.0", "READY_FOR_DISTRIBUTION"),
        version("153.0", "REPLACED_WITH_NEW_VERSION"),
    ])
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 1
    message = capsys.readouterr().err
    assert "154.0 (READY_FOR_DISTRIBUTION)" in message
    assert "153.0" in message


def test_non_editable_version_is_refused(run_script):
    session = FakeSession([version("154.0", "READY_FOR_DISTRIBUTION")])
    assert run_script(session, ["--version", "154.0", "--notes", "x"]) == 1
    assert session.patch_count() == 0


def test_allow_any_state_overrides_the_state_check(run_script):
    session = FakeSession([version("154.0", "READY_FOR_DISTRIBUTION")])
    assert run_script(
        session, ["--version", "154.0", "--notes", "x", "--allow-any-state"]
    ) == 0
    assert len(session.patches) == len(LOCALES)


def test_legacy_app_store_state_field_is_understood(run_script):
    session = FakeSession(
        [version("154.1", "PREPARE_FOR_SUBMISSION", state_field="appStoreState")]
    )
    assert run_script(session, ["--notes", "x"]) == 0


# --- locale selection -------------------------------------------------------


def test_locales_limits_the_update(run_script):
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1", "--notes", "x", "--locales", "en-US, de"]
    ) == 0
    assert set(session.patches) == {"loc-en-US", "loc-de"}


def test_misspelled_locale_is_rejected(run_script):
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1", "--notes", "x", "--locales", "en_US"]
    ) == 1
    assert session.patch_count() == 0


def test_notes_json_uses_overrides_and_falls_back_to_default(run_script, tmp_path):
    notes = tmp_path / "notes.json"
    notes.write_text(json.dumps(
        {"default": "Bug fixes.", "de": "Fehlerbehebungen.", "zz-ZZ": "dropped"}
    ))
    session = FakeSession(editable())
    assert run_script(session, ["--version", "154.1", "--notes-json", str(notes)]) == 0
    assert session.patches["loc-de"] == "Fehlerbehebungen."
    assert session.patches["loc-fr-FR"] == "Bug fixes."
    # A locale App Store Connect no longer has must warn, not block the release.
    assert len(session.patches) == len(LOCALES)


def test_notes_json_without_default_writes_only_listed_locales(run_script, tmp_path):
    notes = tmp_path / "notes.json"
    notes.write_text(json.dumps({"de": "D", "fr-FR": "F"}))
    session = FakeSession(editable())
    assert run_script(session, ["--version", "154.1", "--notes-json", str(notes)]) == 0
    assert set(session.patches) == {"loc-de", "loc-fr-FR"}


# --- notes validation -------------------------------------------------------


def test_missing_notes_fails_before_calling_the_api(run_script):
    session = FakeSession(editable())
    assert run_script(session, ["--version", "154.1"]) == 1
    assert session.calls == []


def test_escaped_newline_in_notes_becomes_a_line_break(run_script):
    session = FakeSession(editable(), locales=["en-US"])
    assert run_script(
        session, ["--version", "154.1"], RELEASE_NOTES="First line.\\nSecond line."
    ) == 0
    assert session.patches["loc-en-US"] == "First line.\nSecond line."


def test_real_newline_in_notes_is_preserved(run_script):
    session = FakeSession(editable(), locales=["en-US"])
    assert run_script(
        session, ["--version", "154.1"], RELEASE_NOTES="First line.\nSecond line."
    ) == 0
    assert session.patches["loc-en-US"] == "First line.\nSecond line."


def test_escaped_blank_line_becomes_a_paragraph_break(run_script):
    session = FakeSession(editable(), locales=["en-US"])
    assert run_script(
        session, ["--version", "154.1"], RELEASE_NOTES="First.\\n\\nSecond."
    ) == 0
    assert session.patches["loc-en-US"] == "First.\n\nSecond."


def test_notes_file_content_is_not_unescaped(run_script, tmp_path):
    """A file can hold real newlines, so a literal backslash-n stays literal."""
    notes = tmp_path / "notes.txt"
    notes.write_text("Real\nbreak and a literal \\n sequence.")
    session = FakeSession(editable(), locales=["en-US"])
    assert run_script(
        session, ["--version", "154.1", "--notes-file", str(notes)]
    ) == 0
    assert session.patches["loc-en-US"] == "Real\nbreak and a literal \\n sequence."


def test_blank_notes_env_counts_as_unset(run_script):
    session = FakeSession(editable())
    assert run_script(session, ["--version", "154.1"], RELEASE_NOTES="   ") == 1


def test_two_notes_sources_are_rejected(run_script, tmp_path):
    notes = tmp_path / "notes.json"
    notes.write_text(json.dumps({"de": "D"}))
    session = FakeSession(editable())
    assert run_script(
        session, ["--version", "154.1", "--notes", "a", "--notes-json", str(notes)]
    ) == 1


def test_overlong_notes_are_rejected_before_calling_the_api(run_script):
    session = FakeSession(editable())
    long_text = "x" * (urn.WHATS_NEW_MAX_LENGTH + 1)
    assert run_script(session, ["--version", "154.1", "--notes", long_text]) == 1
    assert session.calls == []


# --- failure handling -------------------------------------------------------


def test_one_locale_failing_does_not_abandon_the_rest(run_script):
    session = FakeSession(editable(), patch_status={"loc-de": 422, "loc-ja": 422})
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 1
    assert len(session.patches) == len(LOCALES) - 2


def test_systemic_failure_stops_instead_of_retrying_every_locale(run_script):
    session = FakeSession(
        editable(), patch_status={f"loc-{locale}": 409 for locale in LOCALES}
    )
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 1
    assert session.patch_count() == 1


def test_rate_limited_request_is_retried(run_script):
    url = (
        f"{urn.API_BASE}/appStoreVersions/ver-154.1/appStoreVersionLocalizations"
    )
    session = FakeSession(editable(), transient={url: 2})
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 0
    assert len(session.patches) == len(LOCALES)


def test_transport_error_is_retried_then_reported_cleanly(run_script, capsys):
    url = f"{urn.API_BASE}/apps/{APP_ID}"
    session = FakeSession(editable(), transport_error={url: urn.MAX_ATTEMPTS})
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 1
    assert "ConnectionError" in capsys.readouterr().err


def test_transport_error_that_recovers_completes_the_run(run_script):
    url = f"{urn.API_BASE}/apps/{APP_ID}"
    session = FakeSession(editable(), transport_error={url: 1})
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 0
    assert len(session.patches) == len(LOCALES)


def test_non_json_success_body_is_reported_cleanly(run_script, capsys):
    session = FakeSession(editable())

    def html(method, url, headers=None, params=None, json=None, timeout=None):
        return FakeResponse(200, None, text="<html>proxy</html>")

    session.request = html
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 1
    assert "not JSON" in capsys.readouterr().err


def test_expired_token_is_reminted_and_the_request_retried(run_script):
    session = FakeSession(editable(), locales=["en-US"])
    real_request = session.request
    state = {"rejected": False}

    def reject_once(method, url, headers=None, **kwargs):
        if not state["rejected"] and method == "PATCH":
            state["rejected"] = True
            session.tokens.append(headers["Authorization"])
            return FakeResponse(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
        return real_request(method, url, headers=headers, **kwargs)

    session.request = reject_once
    assert run_script(session, ["--version", "154.1", "--notes", "x"]) == 0
    assert session.patches == {"loc-en-US": "x"}


# --- credentials ------------------------------------------------------------


@pytest.mark.parametrize("missing", ENV_NAMES[:4])
def test_each_missing_credential_is_named(
    monkeypatch, capsys, private_key_pem, missing
):
    for name in ENV_NAMES:
        monkeypatch.delenv(name, raising=False)
    monkeypatch.setenv("APPSTORECONNECT_APIKEY_ISSUER_ID", "issuer-id")
    monkeypatch.setenv("APPSTORECONNECT_APIKEY_KEY_ID", "key-id")
    monkeypatch.setenv(
        "APPSTORECONNECT_APIKEY_B64",
        base64.b64encode(private_key_pem.encode()).decode(),
    )
    monkeypatch.setenv("APPSTORE_APP_ID", APP_ID)
    monkeypatch.delenv(missing)

    assert urn.main(["--version", "154.1", "--notes", "x"]) == 1
    assert missing in capsys.readouterr().err


def test_key_that_is_valid_base64_but_not_a_key_is_reported(run_script, capsys):
    session = FakeSession(editable())
    assert run_script(
        session,
        ["--version", "154.1", "--notes", "x"],
        APPSTORECONNECT_APIKEY_B64=base64.b64encode(b"not a key").decode(),
    ) == 1
    assert "not contain a usable" in capsys.readouterr().err


def test_key_that_is_not_base64_is_reported(run_script, capsys):
    session = FakeSession(editable())
    assert run_script(
        session,
        ["--version", "154.1", "--notes", "x"],
        APPSTORECONNECT_APIKEY_B64="!!! not base64 !!!",
    ) == 1
    assert "base64" in capsys.readouterr().err


# --- units ------------------------------------------------------------------


def test_token_is_reused_then_reminted_at_the_refresh_margin(private_key_pem):
    clock = [1_000_000.0]
    provider = urn.TokenProvider(
        urn.Credentials("issuer", "key", private_key_pem, APP_ID),
        clock=lambda: clock[0],
    )
    first = provider.token()
    assert provider.token() == first
    clock[0] += urn.TOKEN_LIFETIME_SECONDS - urn.TOKEN_REFRESH_MARGIN_SECONDS
    assert provider.token() != first


def test_invalidate_forces_a_new_token(monkeypatch, private_key_pem):
    minted = []

    def fake_encode(*args, **kwargs):
        minted.append(f"token-{len(minted)}")
        return minted[-1]

    monkeypatch.setattr(urn.jwt, "encode", fake_encode)
    provider = urn.TokenProvider(
        urn.Credentials("issuer", "key", private_key_pem, APP_ID),
        clock=lambda: 1_000_000.0,
    )

    first = provider.token()
    assert provider.token() == first, "an unexpired token must be reused"
    provider.invalidate()
    # The clock has not moved, so only invalidate() can explain a second minting.
    assert provider.token() != first
    assert len(minted) == 2


@pytest.mark.parametrize(
    "header,expected",
    [
        ("1", 1),
        ("30", 30),
        ("3600", urn.MAX_RETRY_DELAY_SECONDS),
        ("86400", urn.MAX_RETRY_DELAY_SECONDS),
        ("0", 1),
        ("inf", 2),
        ("nan", 2),
        ("soon", 2),
    ],
)
def test_retry_delay_is_clamped_and_never_raises(header, expected):
    response = FakeResponse(429, {}, {"Retry-After": header})
    assert urn.retry_delay(response, attempt=1) == expected


def test_backoff_delay_is_capped():
    assert urn.backoff_delay(1) == 2
    assert urn.backoff_delay(20) == urn.MAX_RETRY_DELAY_SECONDS


def test_describe_versions_caps_a_long_history():
    versions = [
        version(f"1{index}.0", "REPLACED_WITH_NEW_VERSION") for index in range(50)
    ]
    described = urn.describe_versions(versions)
    assert "and 40 more" in described


def test_select_version_prefers_the_newest_duplicate_version_string():
    older = version("154.1", "PREPARE_FOR_SUBMISSION", created="2026-01-01T00:00:00Z")
    newer = version("154.1", "PREPARE_FOR_SUBMISSION", created="2026-07-01T00:00:00Z")
    newer["id"] = "ver-newer"
    chosen = urn.select_version([older, newer], "154.1", allow_any_state=False)
    assert chosen["id"] == "ver-newer"
