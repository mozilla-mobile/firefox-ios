## Criteo plugin

Integrate adjust with Criteo events by following these steps:

1. Locate the `plugin/Criteo` folder inside the downloaded archive from our [releases page](https://github.com/adjust/ios_sdk/releases).

2. Drag the `ADJCriteo.h` and `ADJCriteo.m` files into the `Adjust` folder inside your project.

3. In the dialog `Choose options for adding these files` make sure to check the checkbox
to `Copy items if needed` and select the radio button to `Create groups`.

Now you can integrate each of the different Criteo events, like in the following examples:

### View Listing

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{viewListingEventToken}"];

NSArray *productIds = @[@"productId1", @"productId2", @"product3"];

[ADJCriteo injectViewListingIntoEvent:event productIds:productIds customerId:@"customerId1"];

[Adjust trackEvent:event];
```

### View Product

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{viewProductEventToken}"];

[ADJCriteo injectViewProductIntoEvent:event productId:@"productId1" customerId:@"customerId1"];

[Adjust trackEvent:event];
```

### Cart

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{cartEventToken}"];

ADJCriteoProduct *product1 = [ADJCriteoProduct productWithId:@"productId1" price:100.0 quantity:1];
ADJCriteoProduct *product2 = [ADJCriteoProduct productWithId:@"productId2" price:77.7 quantity:3];
ADJCriteoProduct *product3 = [ADJCriteoProduct productWithId:@"productId3" price:50 quantity:2];
NSArray *products = @[product1, product2, product3];

[ADJCriteo injectCartIntoEvent:event products:products customerId:@"customerId1"];

[Adjust trackEvent:event];
```

### Transaction confirmation

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{transactionConfirmedEventToken}"];

ADJCriteoProduct *product1 = [ADJCriteoProduct productWithId:@"productId1" price:100.0 quantity:1];
ADJCriteoProduct *product2 = [ADJCriteoProduct productWithId:@"productId2" price:77.7 quantity:3];
ADJCriteoProduct *product3 = [ADJCriteoProduct productWithId:@"productId3" price:50 quantity:2];
NSArray *products = @[product1, product2, product3];

[ADJCriteo injectTransactionConfirmedIntoEvent:event products:products 
  transactionId:@"transactionId1" customerId:@"customerId1"];

[Adjust trackEvent:event];
```

### User Level

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{userLevelEventToken}"];

[ADJCriteo injectUserLevelIntoEvent:event uiLevel:1 customerId:@"customerId1"];

[Adjust trackEvent:event];
```

### User Status

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{userStatusEventToken}"];

[ADJCriteo injectUserStatusIntoEvent:event uiStatus:@"uiStatusValue" customerId:@"customerId1"];

[Adjust trackEvent:event];
```

### Achievement Unlocked

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{achievementUnlockedEventToken}"];

[ADJCriteo injectAchievementUnlockedIntoEvent:event uiAchievement:@"uiAchievementValue" customerId:@"customerId"];

[Adjust trackEvent:event];
```

### Custom Event

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{customEventEventToken}"];

[ADJCriteo injectCustomEventIntoEvent:event uiData:@"uiDataValue" customerId:@"customerId"];

[Adjust trackEvent:event];
```

### Custom Event 2

```objc
#import "ADJCriteo.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{customEvent2EventToken}"];

[ADJCriteo injectCustomEvent2IntoEvent:event uiData2:@"uiDataValue2" uiData3:3 customerId:@"customerId"];

[Adjust trackEvent:event];
```

### Hashed Email

It's possible to attach an hashed email in every Criteo event with the `injectHashedEmailIntoCriteoEvents` method.
The hashed email will be sent with every Criteo event for the duration of the application lifecycle,
so it must be set again when the app is re-lauched.
The hashed email can be removed by setting the `injectHashedEmailIntoCriteoEvents` value with `nil`.

```objc
#import "ADJCriteo.h"

[ADJCriteo injectHashedEmailIntoCriteoEvents:@"8455938a1db5c475a87d76edacb6284e"];
```

### Search dates

It's possible to attach a check-in and check-out date to every Criteo event with the `injectViewSearchDatesIntoCriteoEvent` method. The dates will be sent with every Criteo event for the duration of the application lifecycle, so it must be set again when the app is re-lauched.

The search dates can be removed by setting the `injectViewSearchDatesIntoCriteoEvents` values with `nil`.

```objc
#import "ADJCriteo.h"

[ADJCriteo injectViewSearchDatesIntoCriteoEvents:@"2015-01-01" checkOutDate:@"2015-01-07"];
```

### Partner id

It's possible to attach a partner id to every Criteo event with the `injectPartnerIdIntoCriteoEvent` method. The partner id will be sent with every Criteo event for the duration of the application lifecycle, so it must be set again when the app is re-lauched.

The search dates can be removed by setting the `injectPartnerIdIntoCriteoEvent` value with `nil`.

```objc
#import "ADJCriteo.h"

[ADJCriteo injectPartnerIdIntoCriteoEvents:@"{criteoPartnerId}"];
```
