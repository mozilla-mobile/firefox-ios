# Importing Data

> We're working on updating this documentation — thanks for your patience.
> For the moment, please refer to [Importing Data Made Easy](http://www.cimgf.com/2012/05/29/importing-data-made-easy/) at [Cocoa Is My Girlfriend](http://www.cimgf.com/). Much of this document is based upon Saul's work in that original article.
>
> <cite>MagicalRecord Team</cite>

MagicalRecord can help import data from standard NSObject instances such as NSArray and NSDictionary directly into your Core Data store.

It's a two step process to import data from an external source into your persistent store using MagicalRecord:

1. **Define how the data you're importing maps to your store** using your data model (it's pretty much codeless!)
2. **Perform the data import**


## Define Your Import

Data from external sources can be wildly variable in quality and structure, so we've done our best to make MagicalRecord's import processes flexible.

**MagicalRecord can import data from any Key-Value Coding (KVC) compliant object**. We usually find people work with `NSArray` and `NSDictionary` instances, but it works just fine with any KVC compliant `NSObject` subclass.

MagicalRecord makes use of the Xcode data modeling tool's "**User Info**" values to allow configuration of import options and mappings possible without having to edit any code.

<p align="center">
<img src="http://cl.ly/image/1e333E3W2Y3E/datamodeller_userinfogroup.png" alt="Xcode's 'User Info' group in the data modeller" width="324" height="374" style="margin: 0 auto;" />
</p>

> **For reference**: The user info keys and values are held in an NSDictionary that is attached to every entity, attribute and relationship in your data model, and can be accessed via the `userInfo` method on your `NSEntityDescription` instances.

Xcode's data modelling tools give you access to this dictionary via the Data Model Inspector's "User Info" group. When editing a data model, you can open this inspector using Xcode's menus — **View > Utilities > Show Data Model Inspector**, or press <kbd>⌥⌘3</kbd> on your keyboard.

By default, MagicalRecord will automatically try to match attribute and relationship names with the keys in your imported data. **If an attribute or relationship name in your model matches a key in your data, you don't need to do anything — the value attached to the key will be imported automatically**.

For example, if an attribute on an entity has the name 'firstName', MagicalRecord will assume the key in the data to import will also have a key of 'firstName' — if it does, your entity's `firstName` attribute will be set to the value of the `firstName` key in your data.

More often than not, the keys and structure in the data you are importing will not match your entity's attributes and relationships. In this case, you will need to tell MagicalRecord how to map your import data's keys to the correct attribute or relationship in your data model.


Each of the three key objects we deal with in Core Data — Entities, Attributes and Relationships — have options that may need to be specified via user info keys:

### Attributes

| Key | Type | Purpose |
|-----|------|---------|
| **attributeValueClassName** | String | TBD |
| **dateFormat** | String | TBD. Defaults to `yyyy-MM-dd'T'HH:mm:ssz`. |
| **mappedKeyName**       | String | Specifies the name of the keypath in your data to import the value from. Supports keypaths, delimited by `.`, eg. `location.latitude` |
| **mappedKeyName.[0-9]** | String | Specifies backup keypath names if the key specified by **mappedKeyName** doesn't exist. Supports the same syntax. |
| **useDefaultValueWhenNotPresent** | Boolean | If this is true, the default value for the attribute will be set on the imported instance if no value is found for any key. |

### Entities

| Key | Type | Purpose |
|-----|------|---------|
| **relatedByAttribute**  | String | Specifies the attribute in the target of the relationship that links the two. |

### Relationships

| Key | Type | Purpose |
|-----|------|---------|
| **mappedKeyName**       | String | Specifies the name of the keypath in your data to import the value from. Supports keypaths, delimited by `.`, eg. `location.latitude` |
| **mappedKeyName.[0-9]** | String | Specifies backup keypath names if the key specified by **mappedKeyName** doesn't exist. Supports the same syntax. |
| **relatedByAttribute**  | String | Specifies the attribute in the target of the relationship that links the two. |
| **type** | String | TBD |


## Importing Objects

To import data into your store using MagicalRecord, you need to know two things:

1. The format of the data you're importing, and how it

The basic idea behind MagicalRecord's importing is that you know the entity the data should be imported into, so you then write a single line of code tying this entity with the data to import. There are a couple of options to kick off the import process.

To automatically create a new instance from the object, you can use the following, shorter approach:

```objective-c
NSDictionary *contactInfo = // Result from JSON parser or some other source

Person *importedPerson = [Person MR_importFromObject:contactInfo];
```

You can also use a two-stage approach:

```objective-c
NSDictionary *contactInfo = // Result from JSON parser or some other source

Person *person = [Person MR_createEntity]; // This doesn't have to be a new entity
[person MR_importValuesForKeysWithObject:contactInfo];
```

The two-stage approach can be helpful if you’re looking to update an existing object by overwriting its attributes.

`+MR_importFromObject:` will look for an existing object based on the configured lookup value (see the _relatedByAttribute_ and _attributeNameID_). Also notice how this follows the built in paradigm of importing a list of key-value pairs in Cocoa, as well as following the safe way to import data.

The `+MR_importFromObject:` class method provides a wrapper around creating a new object using the previously mentioned `-MR_importValuesForKeysWithObject:` instance method, and returns the newly created object filled with data.

A key item of note is that both these methods are synchronous. While some imports will take longer than others, it’s still highly advisable to perform *all imports* in the background so as to not impact user interaction. As previously discussed, MagicalRecord provides a handy API to make using background threads more manageable:

```objective-c
[MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *)localContext {
  Person *importedPerson = [Person MR_importFromObject:personRecord inContext:localContext];
}];
```

## Importing Arrays

It’s common for a list of data to be served using a JSON array, or you’re importing a large list of a single type of data. The details of importing such a list are taken care of in the `+MR_importFromArray:` class method.

```objective-c
NSArray *arrayOfPeopleData = /// result from JSON parser
NSArray *people = [Person MR_importFromArray:arrayOfPeopleData];
```

This method, like `+MR_importFromObject:` is also synchronous, so for background importing, use the previously mentioned helper method for performing blocks in the background.

If your import data exactly matches your Core Data model, then read no further because the aforementioned methods are all you need to import your data into your Core Data store. However, if your data, like most, has little quirks and minor deviations, then read on, as we’ll walk through some of the features of MagicalRecord that will help you handle several commonly encountered deviations.


## Best Practice

### Handling Bad Data When Importing

APIs can often return data that has inconsistent formatting or values. The best way to handle this is to use the import category methods on your entity classes. There are three provided:

Method                          | Purpose
--------------------------------|---------
`- (BOOL) shouldImport;`        | Called before an data is imported. Use this to cancel importing data on a specific instance of an entity by returning `NO`.
`- (void) willImport:(id)data;` | Called immediately before data is imported.
`- (void) didImport:(id)data;`  | Called immediately after data has been imported.


Generally, if your data is bad you'll want to fix what the import did after an attempt has been made to import any values.

A common scenario is importing JSON data where numeric strings can often be misinterpreted as an actual number. If you want to ensure that a value is imported as a string, you could do the following:

```obj-c

@interface MyGreatEntity

@property(readwrite, nonatomic, copy) NSString *identifier;

@end

@implementation MyGreatEntity

@dynamic identifier;

- (void)didImport:(id)data
{
  if (NO == [data isKindOfClass:[NSDictionary class]]) {
    return;
  }

  NSDictionary *dataDictionary = (NSDictionary *)data;

  id identifierValue = dataDictionary[@"my_identifier"];

  if ([identifierValue isKindOfClass:[NSNumber class]]) {
    NSNumber *numberValue = (NSNumber *)identifierValue;

    self.identifier = [numberValue stringValue];
  }
}

@end
```
