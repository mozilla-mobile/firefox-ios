# shavar-prod-lists
This repo serves as a staging area for [shavar](https://github.com/mozilla-services/shavar)/[tracking protection](https://wiki.mozilla.org/Security/Tracking_protection) lists prior to [production deployment to Firefox](https://mana.mozilla.org/wiki/display/SVCOPS/Shavar+-+aka+Mozilla's+Tracking+Protection). This repo gives Mozilla a chance to manually review all updates before they go live, a fail-safe to prevent accidental deployment of a list that could break Firefox.


## Lists
These two JSON files power Tracking Protection in Firefox.

* `disconnect-blacklist.json` is a version controlled copy of the Disconnect.me public GPL anti-tracking list available here: <https://services.disconnect.me/disconnect-plaintext.json>
* `disconnect-entitylist.json` is a transformed version of the public GPL list that Disconnect reformats for Firefox, in order to reduce the size of the entity list we send to Firefox via the Shavar service.

These lists are processed and transformed and sent to Firefox via
[Shavar](https://mana.mozilla.org/wiki/display/SVCOPS/Shavar+-+aka+Mozilla's+Tracking+Protection).


### Blacklist
The blacklist is the core of tracking protection in Firefox. Firefox ships two
versions of the blacklist: the "Basic protection" list, which excludes the
"Content" category URLs, and the "Strict protection" list which includes the
"Content" category URLs for blocking.

A vestige of the list is the "Disconnect" category, which contains Facebook,
Twitter, and Google domains. Domains from this category are remapped into the
Social, Advertising, or Analytics categories as described
[here](https://github.com/mozilla-services/shavar-list-creation/blob/master/disconnect_mapping.json).
This remapping occurs at the time of list creation, so the Social, Analytics,
and Advertising lists consumed by Firefox will contain these domains.

### Entity list
Tracking protection technically works by blocking loads from blocked domains. But the Entity List conceptually changes it, so that it is no longer about domains, but about the companies. If you are visiting a website, engaged 1-on-1 with them, Tracking Protection will block the other companies who the user may not realize are even present and didn't explicitly intend to interact with.

Tracking Protection blocks loads on the blacklist when they are third-party. The Entity list whitelists different domains that are wholly owned by the same company. For example, if abcd.com owns efgh.com and efgh.com is on the blacklist, it will not be blocked on abcd.com. Instead, efgh.com will be treated as first-party on abcd.com, since the same company owns both. But since efgh.com is on the blacklist it will be blocked on other third-party domains that are not all owned by the same parent company.

## Updating
This repo is configured with [Travis CI
builds](https://travis-ci.org/mozilla-services/shavar-prod-lists/builds) that
run the `scripts/json_verify.py` script to verify all pull request changes to
the list are valid.

This Travis CI status check must pass before any commit can be merged or pushed
to master.

### Making changes to the format
When making changes to the list formats, corresponding changes to the
`scripts/json_verify.py` script must also be made.

To help validate the validator (such meta!), use the list fixtures in the
`tests` directory. Run the script against a specific file like this:

```
./scripts/json_verify.py -f <filename>
```

* `tests/disconnect_blacklist_invalid.json` - copy of
  `disconnect-blacklist.json` with an invalid `"dnt"` value
* `tests/disconnect_blacklist_valid.json` - copy of `disconnect-blacklist.json`
  with all valid values
* `tests/google_mapping_invalid.json` - copy of `google_mapping.json` with
  invalid JSON


```
$ ./scripts/json_verify.py -f tests/disconnect_blacklist_valid.json

tests/disconnect_blacklist_valid.json : valid

$ ./scripts/json_verify.py -f tests/disconnect_blacklist_invalid.json

tests/disconnect_blacklist_invalid.json : invalid
Facebook has bad DNT value: bogus

$ ./scripts/json_verify.py -f tests/google_mapping_invalid.json

tests/google_mapping_invalid.json : invalid
Error: Expecting property name: line 1  column 2 (char 1)
```
