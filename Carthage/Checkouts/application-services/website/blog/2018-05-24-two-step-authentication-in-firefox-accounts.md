---
title: Two-step authentication in Firefox Accounts
author: Vijay Budhram
authorURL: https://github.com/vbudhram
---

## Two-step authentication in Firefox Accounts

Starting on 5/23/2018, we are beginning a phased rollout to allow Firefox Accounts
users to opt into two-step authentication. If you enable this feature,
then in addition to your password, an additional security code will be
required to log in.

<!--truncate-->

We chose to implement this feature
using the well-known authentication standard TOTP (Time-based One-Time Password).
TOTP codes can be generated using a variety of authenticator applications. For example, Google Authenticator, Duo and Authy all support generating TOTP codes.

Additionally, we added support for single-use recovery codes in the event
you lose access to the TOTP application. It is recommend that you save your
recovery codes in a safe spot since they can be used to bypass TOTP.

To enable two-step authentication, go to your Firefox Accounts [preferences](https://accounts.firefox.com/settings) and
click “Enable” on the “Two-step authentication” panel.

![](/application-services/img/blog/2018-05-24/open_menu.gif)

Note: If you do not see the Two-step authentication panel, you can manually enable
it by following these [instructions](https://support.mozilla.org/en-US/kb/secure-firefox-account-two-step-authentication).

Using one of the authenticator applications, scan the QR code and then enter
the security code it displays. Doing this will confirm your device, enable
TOTP and show your recovery codes.

![](/application-services/img/blog/2018-05-24/save_2fa.gif)

Note: After setup, make sure you download and save your recovery codes in a
safe location! You will not be able to see them again, unless you generate new ones.

Once two-step authentication is enabled, every login will require a
security code from your TOTP device.

![](/application-services/img/blog/2018-05-24/2fa_login.png)

Thanks to everyone that helped to work on this feature including UX designers,
engineers, quality assurance and security teams!
