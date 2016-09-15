## Trademob plugin

Integrate adjust with Trademob events by following these steps:

1. Locate the `plugin/Trademob` folder inside the downloaded archive from our [releases page](https://github.com/adjust/ios_sdk/releases).

2. Drag the `ADJTrademob.h` and `ADJTrademob.m` files into the `Adjust` folder inside your project.

3. In the dialog `Choose options for adding these files` make sure to check the checkbox
to `Copy items if needed` and select the radio button to `Create groups`.

For questions regarding this plugin, please reach out to `eugenio.warglien@trademob.com`

You can now use Trademob events in the following ways:

### View Listing

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{viewListingEventToken}"];

NSArray *itemIds = @[@"itemId1", @"itemId2", @"itemId3"];

NSDictionary *metadata = @{@"info1":@"value1", @"info2":@"value2"};

[ADJTrademob injectViewListingIntoEvent:event itemIds:itemIds metadata:metadata];

[Adjust trackEvent:event];
```

### View Item

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{viewItemEventToken}"];

NSDictionary *metadata = @{@"info1":@"value1", @"info2":@"value2"};

[ADJTrademob injectViewItemIntoEvent:event itemId:@"itemId" metadata:metadata];

[Adjust trackEvent:event];
```

### Add to Basket

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{addToBasketEventToken}"];

ADJTrademobItem *item1 = [[ADJTrademobItem alloc] initWithId:@"itemId1" price:120.4 quantity:1];
ADJTrademobItem *item2 = [[ADJTrademobItem alloc] initWithId:@"itemId2" price:20.1 quantity:4];

NSArray *items = @[item1, item2];

[ADJTrademob injectAddToBasketIntoEvent:event items:items metadata:nil];

[Adjust trackEvent:event];
```

### Checkout

```objc
#import "ADJTrademob.h"

ADJEvent *event = [ADJEvent eventWithEventToken:@"{checkoutEventToken}"];

ADJTrademobItem *item1 = [[ADJTrademobItem alloc] initWithId:@"itemId1" price:120.4 quantity:1];
ADJTrademobItem *item2 = [[ADJTrademobItem alloc] initWithId:@"itemId2" price:20.1 quantity:4];

NSArray *items = @[item1, item2];

NSDictionary *metadata = @{@"info1":@"value1", @"info2":@"value2"};

[ADJTrademob injectCheckoutIntoEvent:event items:items metadata:metadata];

[Adjust trackEvent:event];
```
