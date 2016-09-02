## Sociomantic plugin

Integrate adjust with Sociomantic events by following these steps:

1. Locate the `plugin/Sociomantic` folder inside the downloaded archive from our [releases page](https://github.com/adjust/ios_sdk/releases).

2. Drag the `ADJSociomantic.h` and `ADJSociomantic.m` files into the `Adjust` folder inside your project.

3. In the dialog `Choose options for adding these files` make sure to check the checkbox
to `Copy items if needed` and select the radio button to `Create groups`.

4. You know have access to the Sociomantic events methods as well as constants that you should use for property names of your dictionaries:

    ```objc
    NSString *const SCMCategory;
    NSString *const SCMProductName;
    NSString *const SCMSalePrice;
    NSString *const SCMAmount;
    NSString *const SCMCurrency;
    NSString *const SCMProductURL;
    NSString *const SCMProductImageURL;
    NSString *const SCMBrand;
    NSString *const SCMDescription;
    NSString *const SCMTimestamp;
    NSString *const SCMValidityTimestamp;
    NSString *const SCMQuantity;
    NSString *const SCMScore;
    NSString *const SCMProductID;
    NSString *const SCMAmount;
    NSString *const SCMCurrency;
    NSString *const SCMQuantity;
    NSString *const SCMAmount;
    NSString *const SCMCurrency;
    NSString *const SCMActionConfirmed;
    NSString *const SCMActionConfirmed;
    NSString *const SCMCustomerAgeGroup;
    NSString *const SCMCustomerEducation;
    NSString *const SCMCustomerGender;
    NSString *const SCMCustomerID;
    NSString *const SCMCustomerMHash;
    NSString *const SCMCustomerSegment;
    NSString *const SCMCustomerTargeting;
    ```
    
5. Before sending any Sociomantic you should set a partner id as shown below:

    ```objc
    #import "ADJSociomantic.h"

    [ADJSociomantic injectPartnerIdIntoSociomanticEvents:@"{sociomanticPartnerId}"];
    ```

6. Now you can integrate each of the different Sociomantic events, like in the following examples:

### Customer Event

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:ANY_TOKEN];
NSDictionary *customerData = @{
    SCMCustomerID: @"123456"
};

[ADJSociomantic injectCustomerDataIntoEvent:event withData:customerData];
[Adjust trackEvent:event];
```

### View Home Page

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:HOMEPAGE_TOKEN];

[ADJSociomantic injectHomePageIntoEvent:event];
[Adjust trackEvent:event];
```

### View Listing

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:LISTING_TOKEN];
NSArray *categories = @[@"category_1", @"category_2", @"category_3"];
NSString *date = @"1427792434";

[ADJSociomantic injectViewListingIntoEvent:event withCategories:categories];
// You also can provide a date like this
[ADJSociomantic injectViewListingIntoEvent:event withCategories:categories withDate:date];
[Adjust trackEvent:event];
```

### View Product

```objc
#import "ADJSociomantic.h"

ADJEvent *event      = [ADJEvent eventWithEventToken:PRODUCT_VIEW_TOKEN];
NSDictionary *params = @{
    SCMCategory     : @[@"cat1", @"cat2"],
    SCMProductName  : @"stuff",
    SCMDescription  : @"pure awesomeness"
};

[ADJSociomantic injectViewProductIntoEvent:event productId:@"productId_4" withParameters:params];
[Adjust trackEvent:event];
```
*Available product parameters for reporting product view*

<table>
<colgroup>
    <col width="8%" />
    <col width="5%" />
    <col width="21%" />
    <col width="64%" />
</colgroup>
<thead>
<tr class="header">
    <th align="left">Parameter name</th>
    <th align="left">Requirement</th>
    <th align="left">Description</th>
    <th align="left">Note</th>
</tr>
</thead>
<tbody>

<tr class="odd">
    <td align="left">SCMCategory</td>
    <td align="left">Required*</td>
    <td align="left">Product category (entire category path)</td>
    <td align="left">Category information provided in the tracking code on category or listing pages should match the category information provided in the feed or in the tracking code of product pages.</td>
</tr>
<tr class="even">
    <td align="left">SCMProductName</td>
    <td align="left">Required*</td>
    <td align="left">Product name</td>
    <td align="left">Special characters should not be encoded but provided in proper UTF-8. Do not use any HTML markup.</td>
</tr>
<tr class="odd">
    <td align="left">SCMSalePrice</td>
    <td align="left">Required*</td>
    <td align="left">Sale price as decimal value (e.g. 2.99)</td>
    <td align="left">Please use a dot as a decimal separator and do not use any thousand separators.</td>
</tr>
<tr class="even">
    <td align="left">SCMAmount</td>
    <td align="left">Required*</td>
    <td align="left">Regular price as decimal value (e.g. 3.99)</td>
    <td align="left">Please use a dot as a decimal separator and do not use any thousand separators.</td>
</tr>
<tr class="odd">
    <td align="left">SCMCurrency</td>
    <td align="left">Required*</td>
    <td align="left">Currency code in ISO 4217 format (e.g. EUR)</td>
    <td align="left">Fixed currency code. Should have been provided to you in the tracking code examples.</td>
</tr>
<tr class="even">
    <td align="left">SCMProductURL></td>
    <td align="left">Required*</td>
    <td align="left">Product URL (deeplink)</td>
    <td align="left">Please provide a working deeplink ideally without any click tracking parameter (Google Analytics, HURRA, Eulerian, etc.), Please always use deeplinks with http://</td>
</tr>
<tr class="odd">
    <td align="left">SCMProductImageURL</td>
    <td align="left">Required*</td>
    <td align="left">Product image URL</td>
    <td align="left">Please provide images in a reasonable size. For an optimal appearance in the ads the images should be at least 200x200px and should have the same aspect ratio.</td>
</tr>
<tr class="even">
    <td align="left">SCMBrand</td>
    <td align="left">Required*</td>
    <td align="left">Product brand</td>
    <td align="left">Special characters should not be encoded but provided in proper UTF-8 (Same as SCMProductName above). Do not use any HTML markup.</td>
</tr>
<tr class="odd">
    <td align="left">SCMDescription</td>
    <td align="left">Optional</td>
    <td align="left">Short product description</td>
    <td align="left">Special characters should not be encoded but provided in proper UTF-8 (Same as SCMProductName above). Do not use any HTML markup.</td>
</tr>
<tr class="even">
    <td align="left">SCMTimestamp</td>
    <td align="left">Optional</td>
    <td align="left">Timestamp until when the product is available (please use GMT time)</td>
    <td align="left">Please provide the date a visitor has searched for. It should be an NSTimeInterval wrapped in NSNumber (see example).</td>
</tr>
<tr class="odd">
    <td align="left">SCMValidityTimestamp</td>
    <td align="left">Optional</td>
    <td align="left">Timestamp until when the product is available (please use GMT time)</td>
    <td align="left">Please provide the unix timestamp until when the product is available. Please use 0 for products that are always available. It should be an NSTimeInterval wrapped in NSNumber (Same as SCMTimestamp above).</td>
</tr>
<tr class="even">
    <td align="left">SCMQuantity</td>
    <td align="left">Optional</td>
    <td align="left">Number of products in stock</td>
    <td align="left">Please integrate this field only after discussion with your personal Sociomantic contact</td>
</tr>
<tr class="odd">
    <td align="left">SCMScore</td>
    <td align="left">Optional</td>
    <td align="left">Priority score of the product (value range is between 0 to 10.0)</td>
    <td align="left">Please integrate this field only after discussion with your personal Sociomantic contact</td>
</tr>

</tbody>
</table>

\*optional, if provided in the feed

If you’re not certain what setup you should use please contact your Technical Account Manager at Sociomantic.

### Cart

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:CART_TOKEN];
NSDictionary *product5 = @{
    SCMAmount    : @100,
    SCMCurrency  : @"EUR",
    SCMQuantity  : @1,
    SCMProductID : @"productId_5",
};
NSString *product6 = @"productId_6";
NSDictionary *product7 = @{
    SCMProductID : @"productId_7"
};


NSArray * productList = @[product5, product6, product7];

[ADJSociomantic injectCartIntoEvent:event cart:productList];
[Adjust trackEvent:event];
```

*Available cart parameters for reporting cart view*

<table>
<colgroup>
    <col width="8%" />
    <col width="5%" />
    <col width="21%" />
    <col width="64%" />
</colgroup>
<thead>
<tr class="header">
    <th align="left">Parameter name</th>
    <th align="left">Requirement</th>
    <th align="left">Description</th>
    <th align="left">Note</th>
</tr>
</thead>
<tbody>
<tr class="odd">
    <td align="left">SCMProductID</td>
    <td align="left">Required</td>
    <td align="left">Product ID</td>
    <td align="left">Please provide the product ID without any subIDs for any color or size variations.</td>
</tr>
<tr class="even">
    <td align="left">SCMAmount</td>
    <td align="left">Optional</td>
    <td align="left">Product price as decimal value (e.g. 2.99)</td>
    <td align="left">Please use a dot as a decimal separator and do not use any thousand separators. Please only provide price per product, even if quantity has a value larger than 1.</td>
</tr>
<tr class="odd">
    <td align="left">SCMCurrency</td>
    <td align="left">Optional</td>
    <td align="left">Currency code in ISO 4217 format (e.g. EUR)</td>
    <td align="left">Fixed currency code. Should have been provided to you in the tracking code examples.</td>
</tr>
<tr class="even">
    <td align="left">SCMQuantity</td>
    <td align="left">Optional</td>
    <td align="left">Quantity of the product selected</td>
    <td align="left">Please use an integer value.</td>
</tr>

</tbody>
</table>

### Unconfirmed Transaction

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray * productList = @[product5, product6];

[ADJSociomantic injectTransactionIntoEvent:event transactionId:@"123456" withProducts:productList];
[Adjust trackEvent:event];
```

Or with parameters:

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray *productList = @[product5, product6];
NSDictionary *parameters = @{
    SCMQuantity: @4  // 3 times product6 and 1 product5
};

[ADJSociomantic injectTransactionIntoEvent:event transactionId:@"123456" withProducts:productList withParameters:parameters];
[Adjust trackEvent:event];
```

### Confirmed Transaction

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray * productList = @[product5, product6];

[ADJSociomantic injectConfirmedTransactionIntoEvent:event transactionId:@"123456" withProducts:productList];
[Adjust trackEvent:event];
```

Or with parameters:

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:TRANSACTION_TOKEN];
NSString *product5 =  @"productId_5";
NSDictionary *product6 = @{
    SCMQuantity  : @3,
    SCMProductID : @"productId_6"
};
NSArray *productList = @[product5, product6];
NSDictionary *parameters = @{
    SCMQuantity: @4  // 3 times product6 and 1 product5
};

[ADJSociomantic injectConfirmedTransactionIntoEvent:event transactionId:@"123456" withProducts:productList withParameters:parameters];
[Adjust trackEvent:event];
```

*Available cart parameters for reporting transaction view*

See cart parameters

*Available transaction parameters for reporting transaction views*

<table>
<colgroup>
    <col width="8%" />
    <col width="5%" />
    <col width="21%" />
    <col width="64%" />
</colgroup>
<thead>
<tr class="header">
    <th align="left">Parameter name</th>
    <th align="left">Requirement</th>
    <th align="left">Description</th>
    <th align="left">Note</th>
</tr>
</thead>
<tbody>
<tr class="odd">
    <td align="left">SCMAmount</td>
    <td align="left">Optional</td>
    <td align="left">Product price as decimal value (e.g. 2.99)</td>
    <td align="left">Please use a dot as a decimal separator and do not use any thousand separators. Please only provide price per product, even if quantity has a value larger than 1.</td>
</tr>
<tr class="even">
    <td align="left">SCMCurrency</td>
    <td align="left">Optional</td>
    <td align="left">Currency code in ISO 4217 format (e.g. EUR)</td>
    <td align="left">Fixed currency code. Should have been provided to you in the tracking code examples.</td>
</tr>
<tr class="odd">
    <td align="left">SCMQuantity</td>
    <td align="left">Optional</td>
    <td align="left">Quantity of the product selected</td>
    <td align="left">Please use an integer value.</td>
</tr>

</tbody>
</table>

### Lead Event

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:LEAD_TOKEN];

[ADJSociomantic injectLeadIntoEvent:event leadID:@"123456789"];
[Adjust trackEvent:event];
```

Or confirmed lead:

```objc
#import "ADJSociomantic.h"

ADJEvent *event = [ADJEvent eventWithEventToken:LEAD_TOKEN];

[ADJSociomantic injectLeadIntoEvent:event leadID:@"123456789" andConfirmed:YES];
[Adjust trackEvent:event];
```
