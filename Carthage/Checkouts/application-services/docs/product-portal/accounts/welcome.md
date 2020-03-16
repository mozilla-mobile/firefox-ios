---
id: welcome
title: About Firefox Accounts
sidebar_label: Welcome
---

**Firefox Accounts (FxA)** is an identity provider that provides authentication and user profile data for Mozilla cloud services.  We are also exploring the possibility of allowing non-Mozilla services to delegate authentication to Firefox Accounts.

Creating a Firefox Account requires a user to give us a pre-existing email address and choose a password. The user must verify their email address via an email link sent to the email address she provided. The user will not be able to login to attached services prior to verifying her email address. 

To login to an existing Firefox Account, the user must provide the email address and password given during account creation. If the user forgets her password, she can reset via an email link sent to the email address given during account creation. 

All new relying services should integrate with Firefox Accounts via the [OAuth 2.0 API](https://github.com/mozilla/fxa/blob/master/packages/fxa-auth-server/docs/api.md).  There is also a legacy API based on the BrowserID protocol, which is available only in some Firefox user agents and is not supported for new applications.

OAuth 2.0 API
-------------

The OAuth 2.0 API is the currently supported method of integrating with Firefox Accounts.  It is built on open standards, is available across all platforms, and gives relying services access to user profile data.  To delegate authentication to Firefox Accounts in this manner, you will first need to register for OAuth relier credentials, then add support for a HTTP redirection-based login flow to your service.

### Becoming a Firefox Accounts relier

Firefox Accounts integration is currently recommended only for Mozilla-hosted services. We are exploring the possibility of allowing non-Mozilla services to delegated authentication to Firefox Accounts, and would welcome discussion of potential use-cases on the [mailing list](https://mail.mozilla.org/pipermail/dev-fxacct/).

All reliers need to register the following information with Firefox Accounts:

*   **name** \- a user friendly name for your service, e.g., "Firefox Send".
*   **redirect_uri** - a HTTPS endpoint on your service, to which we can return the user after authentication has completed.

In return, your service will be allocated a set of OAuth client credentials:

*   **client_id** \- an 8 byte hex encoded client identifier for your service. This value is not secret.
*   **client_secret** \- a 32 byte hex encoded secret for your service to authenticate itself to the back end FxA OAuth service. **This value is secret.** Despite its name, this value should **never** be stored on or given to untrusted client code on users' machines. It should only be used from the service's backend machines to access authenticated API endpoints on the Firefox Accounts OAuth server (e.g., [https://github.com/mozilla/fxa-oauth-server/blob/master/docs/api.md#post-v1token](https://github.com/mozilla/fxa-oauth-server/blob/master/docs/api.md#post-v1token)).

For **development purposes** you can use the [Firefox Accounts OAuth Credential Management dashboard](/en-US/Firefox_Accounts_OAuth_Dashboard) to provision relier credentials.  Our development environments support "127.0.0.1" and "localhost" as valid "redirectUri" values to ease local development.

Registration of new **production reliers** is currently a manual process.  Send an email to [dev-fxacct@mozilla.org](https://mail.mozilla.org/listinfo/dev-fxacct) to inform us of your desire to be a relying service, and include the desired **name** and **redirect_uri**.  We will work with you to provision client credentials, possibly with multiple versions for different environments (e.g., production, development, etc.):

Note that the **client_secret** is _your responsibility_ to keep safe. If you lose it, we have no way to recover it, and it will be necessary to issue you a new secret. 

We also recommend that you subscribe to the [Firefox Accounts notices](https://mail.mozilla.org/listinfo/fxacct-notices) mailing list, a low-traffic list that is used to publish important feature updates and security information.

### Authenticating with Firefox Accounts

Firefox Accounts provides a [OAuth 2.0 API](https://github.com/mozilla/fxa-oauth-server/blob/master/docs/api.md) that implements a subset of [OpenID Connect](http://openid.net/connect/). Reliers can use this to build a redirect or popup based Firefox Accounts login flow. Currently, using this API directly is the only integration choice for Web applications. Longer term we recommend using the below Javascript client libraries, but these are still a work in progress.

#### Endpoint Discovery

Given the URL of the Firefox Accounts server, reliers should fetch the [OpenID Connect Discovery Document](http://openid.net/specs/openid-connect-discovery-1_0.html) from [/.well-known/openid-configuration](https://accounts.firefox.com/.well-known/openid-configuration).  This will return a JSON document with all the endpoint URLs necessary to complete the login flow.  In particular it will contain:

*   "authorization_endpoint": the URL to which the client should be directed to begin the authentication flow
*   "introspection_endpoint": the URL at which a token is checked for validity
*   "token_endpoint": the URL at which an OAuth access code can be exchanged for an access token
*   "userinfo_endpoint": the URL at which additional user profile data can be obtained

#### Initiating login

The recommended steps for initiating login with the HTTP API directly are:

1.  **Establish a session with the client.** This session is between the relying service (i.e., your server) and the client wishing to authenticate itself. The implementation details of this session are up to the relying service, e.g., it could use cookies.
2.  **Provide the OAuth parameters to the client.** These parameters include:
    *   **client_id** \- the 8 byte hex encoded client identifier for your relying service established during the provisioning of your service with the FxA team
    *   **redirect_uri** \- the **redirect_uri** you gave the FxA team during the provisioning of your service
    *   **scope** \- the requested scope of FxA user data or API access. Currently, only **profile** and related sub-scopes (e.g., **profile:email**) are supported.
    *   **state -** an alphanumeric value created by the relying service and associated with client's session. It's up to the relying service how this can be used, but it's primary and recommended purpose is to prevent forgery attacks.
3.  **Navigate the user's client to the FxA OAuth authorization endpoint.**  This URL should come from the "authorization_endpoint" key in the discovery document, and the request must include URL query parameters for the service's **client_id **and a **state** value. Refer to the [FxA OAuth documentation](https://github.com/mozilla/fxa-oauth-server/blob/master/docs/api.md#get-v1authorization) for further information about this step and optional parameters.

#### Authenticating the user

After navigating the user's client to the authorization endpoint, the user will be asked to authenticate with her Firefox account or create an account if she doesn't have one:

[![](https://cloud.githubusercontent.com/assets/2365255/3786584/98e45f56-19dc-11e4-9e97-3a997e210972.png)](https://cloud.githubusercontent.com/assets/2365255/3786584/98e45f56-19dc-11e4-9e97-3a997e210972.png)

#### Redirect back to the relying service

After the user authenticates herself, Firefox Accounts transfers control back to the relying service. On the Web, this happens by redirecting the user's browser back to the **redirect_uri** endpoint provisioned for the relier. The following information will be provided in the query parameters:

*   **client_id** \- the 8 byte hex encoded client identifier for your relying service
*   **state** - the state value provided by the relying service when it navigated the user's client to the FxA OAuth authorization endpoint
*   **code** - an alphanumeric string that the relying service can exchange for an Firefox Accounts OAuth 2.0 access token for the user. A **code** typically has a lifetime of 15 minutes.

The relying service should make the following security checks:

*   Verify the **client_id** in the redirect request matches its own **client_id**.
*   Verify the **state** in the redirect request matches the **state** value previously associated with the client session.

A failure in either of these verifications indicates a security error and the relying service should re-start the login flow. If the relying service receives one of these requests when the client session is already associated with a FxA user, it should be ignored.

#### Checking authorization status for OAuth token

To check whether a refresh token is still valid, instead of calling the authorization endpoint and waiting
for an error to be thrown, the return value of `oauth::check_authorization_status` will return
metadata about user's refresh token.

#### Obtaining an OAuth access token

If the above security checks pass, the relying service can proceed to exchange the **code** provided in the redirect from Firefox Accounts for an **OAuth token** for the user. This **must** be done from the relying service's backend server and not from untrusted client code. The service can exchange the **code** using the ["token_endpoint"](https://github.com/mozilla/fxa-oauth-server/blob/master/docs/api.md#post-v1token) URL from the discovery document. Refer to the linked documentation for further details. 

#### Accessing profile data

The access token can now be used to fetch the user's profile data.  Make a GET request to the "userinfo_endpoint" URL obtained from the discovery document, passing the access in the Authorization header as a [bearer token](http://tools.ietf.org/html/rfc6750).  The response will be a JSON document which may include the following fields:

*   uid:  the user's opaque, stable account identifier
*   email:  the user's verified email address
*   displayName:  the user's preferred human-readable display name
*   avater: the URL of the user's profile picture

Some fields may be missing if the appropriate scopes were not requested, or the user declined to share the information.

#### Security considerations

The FxA OAuth token should **_only _**be used as an authentication token to access FxA APIs. It should not:

*   be sent to untrusted parties
*   be used as a sessioning mechanism to track logged in users.

Relying services should have their own sessioning mechanism independent of FxA OAuth tokens.

### Login with FxAccountsOAuthClient on Firefox Desktop

For chrome code in Firefox Desktop, we provide [FxAccountsOAuthClient.jsm](/en-US/docs/Mozilla/JavaScript_code_modules/FxAccountsOAuthClient.jsm) for easy integration with FxA OAuth. Relying services must first [become an FxA OAuth relier](#Becoming_a_Firefox_Accounts_OAuth_relier). 

### Login with OAuth into Firefox Desktop WebExtensions

You can use the existing [identity.launchWebAuthFlow](/en-US/docs/Mozilla/Add-ons/WebExtensions/API/identity/launchWebAuthFlow) APIs to integrate your WebExtensions with Firefox Accounts. The system also supports [PKCE](/en-US/docs/) OAuth public clients to create extensions without server components. The [fxa-crypto-relier library](/en-US/docs/) provides an abstraction for Firefox Accounts login in WebExtensions:

const fxaKeysUtil = new fxaCryptoRelier.OAuthUtils();

fxaKeysUtil.launchWebExtensionKeyFlow('YOUR\_CLIENT\_ID', {
  redirectUri: browser.identity.getRedirectURL(),
  scopes: \['profile', 'https://identity.mozilla.com/apps/lockbox'\],
}).then((loginDetails) => {
  const key = loginDetails.keys\['https://identity.mozilla.com/apps/lockbox'\];
  const credentials = {
    access\_token: loginDetails.access\_token,
    refresh\_token: loginDetails.refresh\_token,
    key
};

![](https://www.lucidchart.com/publicSegments/view/c83f8946-5bee-4fdd-bc77-22960c680356/image.jpeg)

End-to-end encryption feature
-----------------------------

Firefox Accounts offers an end-to-end encryption feature for OAuth reliers by deriving a strong encryption key from user's password. You can find more information about this feature on its [own documentation page](https://developer.mozilla.org/en-US/docs/Mozilla/Tech/Firefox_Accounts/Firefox_Accounts_End-to-end_encryption).

Legacy BrowserID API
--------------------

Integrating services should use the OAuth2.0 API. The BrowserID API is reserved for existing legacy applications.

The Firefox Accounts BrowserID is available to chrome code in Firefox Desktop and Firefox of Android.

### Firefox Desktop

The BrowserID based FxA API is currently used by Firefox Sync. Going forward, we recommend chrome based services in Firefox Desktop integrate with [FxA OAuth](#Oauth_API) using the [FxAccountsOAuthClient](/en-US/docs/Mozilla/JavaScript_code_modules/FxAccountsOAuthClient.jsm).

Implementation of the BrowserID based FxA API on Desktop: [https://github.com/mozilla/gecko-dev/blob/master/services/fxaccounts/FxAccounts.jsm](https://github.com/mozilla/gecko-dev/blob/master/services/fxaccounts/FxAccounts.jsm)

### Firefox for Android

WIP

Firefox Accounts user data
--------------------------

Firefox Accounts only stores core identity data and associated profile information about users. Firefox Accounts does not store user data specific to relying services. This is responsibility of each relying service. Core identity data stored in Firefox Accounts includes:

*   a stable user identifier (uid)
*   the user provided email address
*   a cryptographically stretched password verifier
*   the user's locale provided by her browser during account creation
*   optional display name
*   optional profile image

### ​Using a OAuth token

After a relying service has obtained an FxA OAuth access token for a FxA user, it can access Mozilla service APIs that use FxA OAuth. This is largely a work in progress, and we expect the number of APIs that use FxA OAuth will grow and evolve over time.

#### Firefox Accounts profile server

The Firefox Accounts profile server stores and provides user "profile data". Please refer to the [FxA profile server documentation](https://github.com/mozilla/fxa-profile-server/blob/master/docs/API.md) for further information. We provide [FxAccountsProfileClient.jsm ](/en-US/docs/Mozilla/JavaScript_code_modules/FxAccountsProfileClient.jsm)for easier Firefox Desktop integration.

Firefox Accounts example relier
-------------------------------

We created a test relier that delegates authentication to Firefox Accounts called [123done](https://123done-prod.dev.lcip.org), a simple TODO application. You can use this Web application to create a Firefox Accounts and use it to log in to 123done. Refer to the [123done source code](https://github.com/mozilla/123done/tree/oauth) for further details.

Firefox Accounts deployments
----------------------------

URLs for various production, stage, and development deployments. To use these, you can follow the directions in the [Run your own FXA server HOWTO](https://docs.services.mozilla.com/howtos/run-fxa.html), or you might consider using [vladikoff's fxa-dev-launcher](https://github.com/vladikoff/fxa-dev-launcher/).

### Production

*   FxA OAuth 2.0 endpoint: [https://oauth.accounts.firefox.com/v1](https://oauth.accounts.firefox.com/v1)
*   FxA profile endpoint: [https://profile.accounts.firefox.com/v1](https://profile.accounts.firefox.com/v1)
*   FxA content (UI) server: [https://accounts.firefox.com](https://accounts.firefox.com)
*   FxA authentication server: [https://api.accounts.firefox.com/v1](https://api.accounts.firefox.com/v1)
*   FxA example relier: [https://123done-prod.dev.lcip.org](https://123done-prod.dev.lcip.org)

### Stage

*   FxA OAuth 2.0 endpoint: [https://oauth.stage.mozaws.net/v1](https://oauth.stage.mozaws.net/v1)
*   FxA profile endpoint: [https://profile.stage.mozaws.net/v1](https://profile.stage.mozaws.net/v1)
*   FxA content (UI) server: [https://accounts.stage.mozaws.net](https://accounts.stage.mozaws.net)
*   FxA authentication server: [https://api-accounts.stage.mozaws.net/v1](https://api-accounts.stage.mozaws.net/v1)
*   FxA example relier: [https://123done-stage.dev.lcip.org](https://123done-stage.dev.lcip.org)

### Stable development (production clone)

*   FxA OAuth 2.0 endpoint: [https://oauth-stable.dev.lcip.org/v1](https://oauth-stable.dev.lcip.org/v1)
*   FxA OAuth 2.0 management console (login requires @mozilla.com email): [https://oauth-stable.dev.lcip.org/console](https://oauth-stable.dev.lcip.org/console)
*   FxA profile endpoint: [https://stable.dev.lcip.org/profile/v1](https://stable.dev.lcip.org/profile/v1)
*   FxA content (UI) server: [https://stable.dev.lcip.org](https://stable.dev.lcip.org)
*   FxA authentication server: [https://stable.dev.lcip.org/auth/v1](https://stable.dev.lcip.org/auth/v1)
*   FxA example relier: [https://123done-stable.dev.lcip.org](https://123done-stable.dev.lcip.org)

### Latest development (updated continuously from master)

*   FxA OAuth 2.0 endpoint: [https://oauth-latest.dev.lcip.org/v1](https://oauth-latest.dev.lcip.org/v1)
*   FxA OAuth 2.0 management console (login requires @mozilla.com email): [https://oauth-latest.dev.lcip.org/console](https://oauth-latest.dev.lcip.org/console)
*   FxA profile endpoint: [https://latest.dev.lcip.org/profile/v1/profile](https://latest.dev.lcip.org/profile/v1/profile)
*   FxA content (UI) server: [https://latest.dev.lcip.org](https://latest.dev.lcip.org)
*   FxA authentication server: [https://latest.dev.lcip.org/auth/v1](https://latest.dev.lcip.org/auth/v1)
*   FxA example relier: [https://123done-latest.dev.lcip.org](https://123done-latest.dev.lcip.org)
*   Add this [user.js](https://bug1098694.bmoattachments.org/attachment.cgi?id=8759426) file to your profile directory to configure Firefox Sync with this environment

Contact
-------

*   Dev list: [dev-fxacct@mozilla.org](mailto:dev-fxacct@mozilla.org)
*   Slack or IRC: #fxa

Additional resources
--------------------

*   [APIs attached to Firefox Accounts](/en-US/docs/Mozilla/APIs_attached_to_Firefox_Accounts)
*   [Original FxA OAuth design document](https://github.com/mozilla/fxa-oauth-server/wiki/oauth-design)
*   [FxA OAuth 2.0 API docs](https://github.com/mozilla/fxa-oauth-server/blob/master/docs/api.md)
*   [FxA OAuth server codebase](https://github.com/mozilla/fxa-oauth-server/)
*   [OAuth 2.0 RFC 6749](http://tools.ietf.org/html/rfc6749)
*   [Handling Mozilla Security Bugs](https://www.mozilla.org/en-US/about/governance/policies/security-group/bugs/)
