# Localization (Transifex) — Ecosia iOS

Transifex is used to manage translations.

Install the Transifex CLI

```bash
curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash
```

Configure credentials in `~/.transifexrc` (use vault secrets).

Pull translations

```bash
tx pull -fs
```

Add or update source strings

- English source file: `Client/Ecosia/L10N/en.lproj/Ecosia.strings`
- Push source to Transifex:

```bash
tx push -s
```

Ecosify Mozilla strings (after Firefox upgrades)

```bash
python3 ecosify-strings.py firefox-ios
```

Translation completeness check (local)

```bash
# from repo root
bash firefox-ios/Ecosia/L10N/check_translations.sh
# dry run
DRY_RUN=true bash firefox-ios/Ecosia/L10N/check_translations.sh
```

Notes

- The CI pipeline runs a completeness check before TestFlight builds and will fail with a list of missing keys grouped by language.