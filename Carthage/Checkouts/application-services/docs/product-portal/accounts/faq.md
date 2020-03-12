---
id: faq
title: Frequently Asked Questions
sidebar_label: Frequently Asked Questions
---

## Am I required to create a Firefox Account to use Firefox?
No. A Firefox Account is only required for Mozilla Services that require authentication, such as Firefox Sync and advanced features on addons.mozilla.org like posting reviews, publishing new add-ons, etc.

## Why does Firefox Accounts require me to choose a password?
One of the primary services that uses Firefox Accounts is Firefox Sync, which encrypts all your data client-side before submitting it to the server. The password is used to securely derive an encryption key.

## What information does Firefox Accounts store about the user?

Firefox Accounts only stores core identity data and associated profile information about users.
Firefox Accounts does not store user data specific to relying services.
This is responsibility of each relying service. Core identity data stored in Firefox Accounts includes:

* a stable user identifier (uid)
* the user provided email address
* a cryptographically stretched password verifier
* the user's locale provided by her browser during account creation
* optional display name
* optional profile image

## Can I use Firefox Accounts to store user data for my application or service?
In general no.

Firefox Accounts only stores information that will deliver significant user value across applications or is tightly related to the user's identity. It will not store user data for relying services. Relying Mozilla services can use Firefox Accounts for authentication, but application data storage is the responsibility of the individual applications.


## Can I use my Firefox Account to log in to non-Mozilla services?
Not initially, but it's something we'd like to support in the future.

## Does Firefox Accounts provide email?
No.

## Is it possible to host your own Firefox Accounts service, like with Firefox Sync?
[Yes.](https://mozilla-services.readthedocs.io/en/latest/howtos/run-fxa.html)


# OAuth Integration

## Why am I getting "Invalid OAuth parameter: scope"?

If you are requesting a full `profile` scope, then you need to make sure that your OAuth client is marked as `trusted` Mozilla
client. This can be done in the OAuth Dev Console or in the database.

## Where are the OAuth API docs?

You can find them here: https://github.com/mozilla/fxa-auth-server/blob/master/fxa-oauth-server/docs/api.md

## Do `accessTokens` expire?

Yes. You should look at the `expires` field in the token response to find out when the token will expire.

## Do `refreshTokens` expire?

The `refreshTokens` do not currently have an expiry, but they can be revoked for different reasons. For example,
the user may revoke the token using the Firefox Accounts settings page. You should first try to use the `refreshToken` to
obtain a new access token, if that fails you probably want to restart the authentication flow and obtain a new `refreshToken`.

# Profile API

## What are the `amrValues` in the profile response?

Those are the "Authentication Method Reference Values". See https://tools.ietf.org/html/draft-jones-oauth-amr-values-00#section-2
for more details.
