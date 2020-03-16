## Integrate Adjust with the Adobe SDK

To integrate Adjust with all Adobe SDK tracked events, you must send your Adjust attribution data to the Adobe SDK after receiving the attribution response from our backend. Follow the steps in the [attribution callback][attribution-callback] chapter of our iOS SDK guide to implement this. To use the Adobe SDK API, the callback method can be set as the following:

```objc
- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    NSMutableDictionary *adjustData= [NSMutableDictionary dictionary];

    if (attribution.network != nil) {
        // Do not change the key "Adjust Network". This key is being used in the Data Connector Processing Rule
        [adjustData setObject:@attribution.network forKey:@"Adjust Network"];
    }
    if (attribution.campaign != nil) {
        // Do not change the key "Adjust Campaign". This key is being used in the Data Connector Processing Rule
        [adjustData setObject:@attribution.campaign forKey:@"Adjust Campaign"];
    }
    if (attribution.adgroup != nil) {
        // Do not change the key "Adjust AdGroup". This key is being used in the Data Connector Processing Rule
        [adjustData setObject:@attribution.adgroup forKey:@"Adjust AdGroup"];
    }
    if (attribution.creative != nil) {
        // Do not change the key "Adjust Creative". This key is being used in the Data Connector Processing Rule
        [adjustData setObject:@attribution.creative forKey:@"Adjust Creative"];
    }

    // Send Data to Adobe using Track Action
    [ADBMobile trackAction:@"Adjust Campaign Data Received" data:adjustData];
}
```

Before you implement this interface, please take care to consider the [possible conditions for usage of some of your data][attribution-data].

[attribution-data]:     https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[attribution-callback]: https://github.com/adjust/ios_sdk#attribution-callback
