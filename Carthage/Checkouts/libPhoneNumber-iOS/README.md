[![CocoaPods](https://img.shields.io/cocoapods/p/libPhoneNumber-iOS.svg?style=flat)](http://cocoapods.org/?q=libPhoneNumber-iOS)
[![CocoaPods](https://img.shields.io/cocoapods/v/libPhoneNumber-iOS.svg?style=flat)](http://cocoapods.org/?q=libPhoneNumber-iOS)
[![Travis](https://travis-ci.org/iziz/libPhoneNumber-iOS.svg?branch=master)](https://travis-ci.org/iziz/libPhoneNumber-iOS)
[![Coveralls](https://coveralls.io/repos/iziz/libPhoneNumber-iOS/badge.svg?branch=master&service=github)](https://coveralls.io/github/iziz/libPhoneNumber-iOS?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# **libPhoneNumber for iOS**

 - NBPhoneNumberUtil
 - NBAsYouTypeFormatter
 - NBTextFiled.swift (Swift 2)

> ARC only, or add the **"-fobjc-arc"** flag for non-ARC

## Update Log
[https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log](https://github.com/iziz/libPhoneNumber-iOS/wiki/Update-Log)

## Install 

#### Using [CocoaPods](http://cocoapods.org/?q=libPhoneNumber-iOS)
```
source 'https://github.com/CocoaPods/Specs.git'
pod 'libPhoneNumber-iOS', '~> 0.8'
```

#### Using [Carthage](https://github.com/Carthage/Carthage)

 Carthage is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

 You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate libPhoneNumber into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "iziz/libPhoneNumber-iOS"
```

And set the **Embedded Content Contains Swift** to "Yes" in your build settings.

#### Setting up manually
 Add source files to your projects from libPhoneNumber
    - Add "CoreTelephony.framework"

See sample test code from
> [libPhoneNumber-iOS/libPhoneNumberTests/ ... Test.m] (https://github.com/iziz/libPhoneNumber-iOS/tree/master/libPhoneNumberTests)

## Usage - **NBPhoneNumberUtil**
```obj-c
 NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
 NSError *anError = nil;
 NBPhoneNumber *myNumber = [phoneUtil parse:@"6766077303"
                              defaultRegion:@"AT" error:&anError];
 if (anError == nil) {
     // Should check error
     NSLog(@"isValidPhoneNumber ? [%@]", [phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");

     // E164          : +436766077303
     NSLog(@"E164          : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatE164
                                              error:&anError]);
     // INTERNATIONAL : +43 676 6077303
     NSLog(@"INTERNATIONAL : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                              error:&anError]);
     // NATIONAL      : 0676 6077303
     NSLog(@"NATIONAL      : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatNATIONAL
                                              error:&anError]);
     // RFC3966       : tel:+43-676-6077303
     NSLog(@"RFC3966       : %@", [phoneUtil format:myNumber
                                       numberFormat:NBEPhoneNumberFormatRFC3966
                                              error:&anError]);
 } else {
     NSLog(@"Error : %@", [anError localizedDescription]);
 }

 NSLog (@"extractCountryCode [%@]", [phoneUtil extractCountryCode:@"823213123123" nationalNumber:nil]);

 NSString *nationalNumber = nil;
 NSNumber *countryCode = [phoneUtil extractCountryCode:@"823213123123" nationalNumber:&nationalNumber];

 NSLog (@"extractCountryCode [%@] [%@]", countryCode, nationalNumber);
```
##### Output
```
2014-07-06 12:39:37.240 libPhoneNumberTest[1581:60b] isValidPhoneNumber ? [YES]
2014-07-06 12:39:37.242 libPhoneNumberTest[1581:60b] E164          : +436766077303
2014-07-06 12:39:37.243 libPhoneNumberTest[1581:60b] INTERNATIONAL : +43 676 6077303
2014-07-06 12:39:37.243 libPhoneNumberTest[1581:60b] NATIONAL      : 0676 6077303
2014-07-06 12:39:37.244 libPhoneNumberTest[1581:60b] RFC3966       : tel:+43-676-6077303
2014-07-06 12:39:37.244 libPhoneNumberTest[1581:60b] extractCountryCode [82]
2014-07-06 12:39:37.245 libPhoneNumberTest[1581:60b] extractCountryCode [82] [3213123123]
```

#### with Swift
##### Case (1) with Framework
```
import libPhoneNumber
```

##### Case (2) with Bridging-Header
```swift
// Manually added
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

// CocoaPods (check your library path)
#import "libPhoneNumber_iOS/NBPhoneNumberUtil.h"
#import "libPhoneNumber_iOS/NBPhoneNumber.h"

// add more if you want...
```

##### Case (3) with CocoaPods
import libPhoneNumber_iOS


##### - in swift class file
###### 2.x
```swift
override func viewDidLoad() {
    super.viewDidLoad()

    let phoneUtil = NBPhoneNumberUtil()

    do {
        let phoneNumber: NBPhoneNumber = try phoneUtil.parse("01065431234", defaultRegion: "KR")
        let formattedString: String = try phoneUtil.format(phoneNumber, numberFormat: .E164)

        NSLog("[%@]", formattedString)
    }
    catch let error as NSError {
        print(error.localizedDescription)
    }
}
```

###### 1.x
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    let phoneUtil = NBPhoneNumberUtil()

    var errorPointer:NSError?
    var number:NBPhoneNumber? = phoneUtil.parse("01041241282", defaultRegion:"KR", error:&errorPointer)
    if errorPointer == nil && number != nil {
       println("number is: \(number)")
    } else {
       println("number error: \(errorPointer?.localizedDescription)")
    }
}
```

## Usage - **NBAsYouTypeFormatter**
```obj-c
    NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    NSLog(@"%@", [f inputDigit:@"6"]); // "6"
    NSLog(@"%@", [f inputDigit:@"5"]); // "65"
    NSLog(@"%@", [f inputDigit:@"0"]); // "650"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 2"
    NSLog(@"%@", [f inputDigit:@"5"]); // "650 25"
    NSLog(@"%@", [f inputDigit:@"3"]); // "650 253"

    // Note this is how a US local number (without area code) should be formatted.
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 2532"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 22"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 222"
    NSLog(@"%@", [f inputDigit:@"2"]); // "650 253 2222"
    // Can remove last digit
    NSLog(@"%@", [f removeLastDigit]); // "650 253 222"

    NSLog(@"%@", [f inputString:@"16502532222"]); // 1 650 253 2222
```

##### Visit [libphonenumber](https://github.com/googlei18n/libphonenumber) for more information or mail (zen.isis@gmail.com)
