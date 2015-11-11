# shavar-prod-lists
This repo serves as a staging area for shavar/tracking protection lists prior to production deployment to Firefox. This repo gives Mozilla a chance to manually review all updates before they go live, a fail-safe to prevent accidental deployment of a list that could break Firefox.


### Raw lists
These two JSON files power Tracking Protection in Firefox. 

* disconnect-blacklist.json is a version controlled copy of the Disconnect.me public GPL anti-tracking list available here: https://services.disconnect.me/disconnect-plaintext.json
* disconnect-entitylist.json is a transformed version of the public GPL list that Disconnect reformats for Firefox, in order to reduce the size of the entity list we send to Firefox via the Shavar service. 

These lists are processed and transformed and sent to Firefox via Shavar. 


### Blacklist
The blacklist is the core of tracking protection in Firefox. Firefox 42 ships a single processed version of the blacklist, and that list excludes the "Content" category URLs. This is the "Basic protection" list. Firefox 43 adds a second "Strict protection" list which includes the "Content" category URLs for blocking.

A vestige of the list is the "Disconnect" category, which contains Facebook, Twitter, and Google domains. We re-map the Facebook and Twitter domains to the Social category, per Disconnect guidance. The google_mapping.json file is used to remap the individual Google domains to their respective categories. This remapping is temporary while until the list is updated to fix these issues.

### Entity list
Tracking protection technically works by blocking loads from blocked domains. But the Entity List conceptually changes it, so that it is no longer about domains, but about the companies. If you are visiting a website, engaged 1-on-1 with them, Tracking Protection will block the other companies who the user may not realize are even present and didn't explicitly intend to interact with.

Tracking Protection blocks loads on the blacklist when they are third-party. The Entity list whitelists different domains that are wholly owned by the same company. For example, if abcd.com owns efgh.com and efgh.com is on the blacklist, it will not be blocked on abcd.com. Instead, efgh.com will be treated as first-party on abcd.com, since the same company owns both. But since efgh.com is on the blacklist it will be blocked on other third-party domains that are not all owned by the same parent company.


