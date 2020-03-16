---
title: Changing your primary email in Firefox Accounts
author: Vijay Budhram 
---

The Firefox Accounts team recently introduced the ability for a user to change their primary email address. Being one of the main developers to work this feature, I wanted to share my experience and give a summary on what it took to get this feature to our users.

<!--truncate-->

### Our motivation

Based on user feedback, the most common scenario for changing your primary email was losing access to that email account. This email was often associated with work or an organization they no longer were apart of.

Most account systems would simply allow the user to continue logging in with their old email. However, because your Firefox Account can contain sensitive information, we needed to have an extra layer of security. This came in the form of us running heuristics on the login attempt and prompting you to verify that email address. For example, logging in from a device that has not had a login in over 3 days would require an email confirmation.

If you can no longer access that email address, you are locked out of your account and the data it contains. This caters on the side of security versus user experience. The most common workaround was to create a new account and sync your existing data. This method meant that you could lose data on the old account if you were syncing from a new device.

### Design decisions

Once we decided to move forward with the feature, [we created a high level plan](https://github.com/mozilla/fxa-content-server/pull/4996) on how it was going to be done. Exploratory work was already done a few years ago that outlined the risks and a possible solution. We used this as a basis for our initial design.

One of the complexities of changing your Firefox Account email is that our login procedure combines email and password to derive a strong encryption key. This original design decision was driven by a security requirement and meant that we could not perform an email change in one operation, because we would lose part of the key.

Considering these factors, we opted to create an intermediate feature, adding a secondary email address, that would solve a few of the original problems while being designed to allow easy changes to the user’s primary email. Secondary email addresses also receive security notifications and can verify login requests.

![](/application-services/img/blog/2018-03-08/secondary_email.png)

While implementing secondary emails, we migrated from a single email on the account database table, to supporting multiple emails in separate `emails` table. Each email has a couple of flags to signify whether or not they are they primary and verified. Additionally, we wrote several migration scripts that populated our new emails table while falling back to using the account table if there wasn’t any email. Doing this phased approached allowed us to safely rollback if any issues were found.

After adding the secondary email feature, we were able to simplify our database which allowed the actual email change to be flipping the `isPrimary` flag on an email. After that, our quality assurance team made sure there were no regressions and everything worked as expected.

### Updating browsers and our services

Once the secondary emails feature landed, we then set our focus on updating all of our clients and services to support changing the primary email. In addition to the server side changes, updates were needed for each browser and service that uses a Firefox Account.

Before any of the browsers would pickup the email change, they needed to be updated to properly detect and fetch the updated profile information. The Desktop, Android, iOS, Pocket, AMO and Basket  teams each had unique problems while trying to add support for this feature. If interested, you can check out [the complete bug tree](https://bugzilla.mozilla.org/show_bug.cgi?id=1384170). Each one of the updates could be worthy of their own blog post.

After adding and verifying a secondary email, you now have the option to make it your primary!

![](/application-services/img/blog/2018-03-08/change_email.png)

### Turning it on

While the Firefox Account team’s development schedule is fairly fixed, we could not risk turning this feature on until all of the clients and services were updated. This meant that we had to wait on external teams to finish testing and integrating the changes. Each browser and team could have a different schedule and timeline for getting fixes in.

While the complete feature rollout took several months, we were able to test the majority of the change email feature by putting it behind a feature flag and having users opt into it. Several bugs were found this way as it gave our QA a way to access feature in production.

The final bug to remove the feature flag was merged in February which turned it on for everyone.

### Final thoughts

Our team kept putting this feature off because of the complexity and all the components involved. While the final verdict on how well this retains users is not out, I am happy that we were able to push through these and give a long requested feature to our user base. Below is a usage graph that shows that users are already changing their address and keeping their account updated.

<img src=/application-services/img/blog/2018-03-08/change_email_chart.png width=400 />

Thanks to everyone and teams that helped review, development and push the changes needed for this feature!