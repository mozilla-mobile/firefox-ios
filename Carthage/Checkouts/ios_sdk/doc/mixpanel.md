##Integrate adjust with Mixpanel SDK

The Mixpanel API allows to register common properties to be sent in all activities as `super properties`, as it is explained in the [Mixpanel page][mixpanel_ios]. To integrate adjust with all tracked events of Mixpanel, you must set the `super properties` after receiving the attribution data. Follow the steps of the [delegate callbacks][response_callbacks] chapter in our iOS SDK guide to implement it. 
The delegate function can be set as the following, to use the Mixpanel API: 

```objc
- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];

    // The adjust properties will be sent
    // with all future track calls.
    if (attribution.network != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Network":  attribution.network}];
    if (attribution.campaign != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Campaign": attribution.campaign}];
    if (attribution.adgroup != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Adgroup":  attribution.adgroup}];
    if (attribution.creative != nil)
        [mixpanel registerSuperProperties:@{@"[Adjust]Creative": attribution.creative}];
}
```

Before you implement this interface, please take care to consider [possible conditions for usage of some of your data][attribution_data].

[mixpanel_ios]: https://mixpanel.com/help/reference/ios#super-properties
[attribution_data]: https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[response_callbacks]: https://github.com/adjust/ios_sdk#9-receive-delegate-callbacks
