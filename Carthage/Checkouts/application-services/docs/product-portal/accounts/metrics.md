---
id: metrics
title: Metrics for Reliers
sidebar_label: Metrics for Reliers
---

*Last updated 2018-08-20*<br />
*Compiled by Leif Oines loines at mozilla dot com*

**This file is WIP**. In the future it will be a combined resource detailing data collection, metrics definitions, pipeline information, etc. For now it mainly documents metrics parameters (e.g. utm_*) that reliers pass to Firefox Accounts servers.

You should start at [this page](https://mozilla.github.io/application-services/docs/accounts/welcome.html) for more general information on how to integrate with Firefox Accounts.

## Self-Hosted Email Forms and Metrics Tracking (AKA the "FxA email-first flow")

As of July 2018, reliers must do either one of the following when integrating with Firefox Accounts:
1. Self-host the first step in the FxA authentication flow themselves (e.g. the form capturing the user's email)
2. Send users to a FxA-hosted form at https://accounts.firefox.com/.

This means that pages that host an iFrame containing an FxA hosted form are **no longer an option** moving forward due to performance and security precautions.

In the case when the email entry form is self hosted, **we ask that you do the following so that we can properly track top-of-funnel metrics** (such as volume of email form views) associated with the page that hosts your FxA form:

1. When the page that hosts your FxA form loads, have it make an XHR call to `https://accounts.firefox.com/metrics-flow`. The domain name of the request should match the FxA page that is being redirected to (e.g. https://accounts.firefox.com). You can use `fetch` to get this info.
2. Include the following query parameters in the above request (see chart below for descriptions):
  * `entrypoint`
  * `entrypoint_experiment`
  * `entrypoint_variation`
  * `utm_source`
  * `utm_campaign`
  * `form_type`
  * An example: `https://accounts.firefox.com/metrics-flow?entrypoint=my_page&utm_source=my_referrer&utm_campaign=my_campaign&form_type=email`
3. The response to metrics-flow will be a JSON object that contains the fields `flowId` and `flowBeginTime`. These values will need to be propagated to FxA as query parameters, which can be done using hidden form fields with the names `flow_id` and `flow_begin_time`. You can see an example of how the [about:welcome](about:welcome) page does this by looking [here](https://github.com/mozilla/activity-stream/blob/06aeeb331e9dd497e4d115d0e6cba51b9b25b36c/content-src/asrouter/templates/StartupOverlay/StartupOverlay.jsx#L30).

By following these instructions you provide both of our teams with data needed to monitor the health of your page.

## Descriptions of Metrics-Related Query Parameters

**If you are a developer, please read the following before checking the chart below.** The values that are passed in the parameters below are subject to validation via regular expressions. **If the parameter values do not conform to their associated regexes in [this file](https://github.com/mozilla/fxa-content-server/blob/0921bc53e92f3b8e4e796f51cc46202d1cfae25e/server/lib/flow-event.js) then all metrics events associated with the nonconforming parameters will fail to be logged!**

|Name|Description|Example Values|Validation regex|Amplitude Chart Example|
|----|-----------|--------------|----------------|-----------------------|
|`entrypoint`|The specific page or browser UI element containing the first step of the FxA sign-in/sign-up process (e.g., enter email form)|`firstrun`|<!--begin-validation-entrypoint-->^[\w.:-]+$<!--end-validation-entrypoint-->|[Firstrun form views](https://analytics.amplitude.com/mozilla-corp/chart/n8cd9no)|
|`entrypoint_experiment`|Identifier for the experiment the user is part of (if any)||<!--begin-validation-entrypoint_experiment-->^[\w.:-]+$<!--end-validation-entrypoint_experiment-->||
|`entrypoint_variation`|Identifier for the experiment variation the user is part of (if any)||<!--begin-validation-entrypoint_variation-->^[\w.:-]+$<!--end-validation-entrypoint_variation-->||
|`form_type`|For self-hosted forms only (see above) the type of form that the user submits to begin the FxA flow|either: `email` if the form captures the user's email, otherwise `other`||NA|
|`utm_source`|Unambiguous identifier of site or browser UI element that linked to the page containing the beginning of the FxA sign-in/sign-up process |`blog.mozilla.org`|<!--begin-validation-utm_source-->^[\w\/.%-]+$<!--end-validation-utm_source-->|[Registration form views segmented by utm_source](https://analytics.amplitude.com/mozilla-corp/chart/f5sz7kt)|
|`utm_campaign`|More general label for the campaign that the site is part of|`firstrun`|<!--begin-validation-utm_campaign-->^[\w\/.%-]+$<!--end-validation-utm_campaign-->|TBD|
|`utm_content`|Used to track the name of an A-B test|`my-experiment`|<!--begin-validation-utm_content-->^[\w\/.%-]+$<!--end-validation-utm_content-->|TBD|
|`utm_term`|Used to track the cohort or variation in an A-B test|`my-experiment-var-a`|<!--begin-validation-utm_term-->^[\w\/.%-]+$<!--end-validation-utm_term-->|TBD|
|`utm_medium`|What type of link was used to direct to the page, if it came through a marketing campaign|`email`, `cpc`|<!--begin-validation-utm_medium-->^[\w\/.%-]+$<!--end-validation-utm_medium-->|TBD|
|`context`|Not relevant to metrics, but this is **required** to be set to one of `fx_desktop_v3`, `fx_fennec_v1` or `fx_ios_v1` if `service=sync`. Please use the value that reflects the most likely operating system of the user.|`fx_desktop_v3`, `fx_fennec_v1`, `fx_ios_v1`|<!--begin-validation-context-->^[0-9a-z_-]+$<!--end-validation-context-->/|NA|

**Note these may not be all the parameters you need to pass for your integration to work!** A more exhaustive but [less detailed list can be found here.](https://github.com/mozilla/fxa-content-server/blob/549fc459b851088ea910da182e17e748fa157f26/docs/query-params.md#context) What is documented above are only the parameters that are relevant for metrics analysis in (e.g.) amplitude.

Other Notes:
* You must have access to the mozilla amplitude account to see the example charts. If you are a Mozilla employee, please contact Leif for information on gaining access to amplitude.

* You can use the amplitude graphs linked in the chart as templates for tracking the login and registration performance of your own page. Simply change the value of `entrypoint`, `service`, `utm_source`, etc as appropriate. Contact Leif if you need any help.

* Regarding `utm_term`: note that the current usage of this parameter is different from what is typical. In most scenarios, it is used to track the search terms that led the users to the page. If you would like to use the parameter in this way, please inform the Firefox Accounts team.
