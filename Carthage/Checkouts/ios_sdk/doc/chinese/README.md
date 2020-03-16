## 摘要

这是Adjust™的iOS SDK包。您可以访问[adjust.com]了解更多有关Adjust™的信息。

如果您的应用正在使用web views，您希望Adjust通过Javascript代码跟踪，请参阅我们的[ios-web-views SDK指南][ios-web-views-guide]。

Read this in other languages: [English][en-readme], [中文][zh-readme], [日本語][ja-readme], [한국어][ko-readme].

## 目录

* [应用示例](#example-apps)
* [基本集成](#basic-integration)
   * [添加SDK至您的项目](#sdk-add)
   * [添加iOS框架](#sdk-frameworks)
   * [集成SDK至您的应用](#sdk-integrate)
   * [基本设置](#basic-setup)
      * [iMessage 的特定设置](#basic-setup-imessage)
   * [Adjust日志](#adjust-logging)
   * [构建您的应用](#build-the-app)
* [附加功能](#additional-features)
   * [事件跟踪](#event-tracking)
      * [收入跟踪](#revenue-tracking)
      * [收入重复数据删除](#revenue-deduplication)
      * [应用收入验证](#iap-verification)
      * [回调参数](#callback-parameters)
      * [合作伙伴参数](#partner-parameters)
      * [回调ID](#callback-id)
   * [会话参数](#session-parameters)
      * [会话回调参数](#session-callback-parameters)
      * [会话合作伙伴参数](#session-partner-parameters)
      * [延迟启动](#delay-start)
   * [归因回传](#attribution-callback)
   * [广告收入跟踪](#ad-revenue)
   * [会话和事件回传](#event-session-callbacks)
   * [禁用跟踪](#disable-tracking)
   * [离线模式](#offline-mode)
   * [事件缓冲](#event-buffering)
   * [GDPR 的被遗忘权](#gdpr-forget-me)
   * [SDK签名](#sdk-signature)
   * [后台跟踪](#background-tracking)
   * [设备ID](#device-ids)
      * [iOS广告ID](#di-idfa)
      * [Adjust设备ID](#di-adid)
   * [用户归因](#user-attribution)
   * [推送标签（Push token）](#push-token)
   * [预安装跟踪码](#pre-installed-trackers)
   * [深度链接](#deeplinking)
      * [标准深度链接场景](#deeplinking-standard)
      * [iOS 8及以下版本的深度链接设置](#deeplinking-setup-old)
      * [iOS 9及以上版本的深度链接设置](#deeplinking-setup-new)
      * [延迟深度链接场景](#deeplinking-deferred)
      * [通过深度链接的再归因](#deeplinking-reattribution)
* [故障排查](#troubleshooting)
   * [SDK延迟初始化问题](#ts-delayed-init)
   * [显示 "Adjust requires ARC" 出错信息](#ts-arc)
   * [显示 "\[UIDevice adjTrackingEnabled\]: unrecognized selector sent to instance" 出错信息](#ts-categories)
   * [显示 "Session failed (Ignoring too frequent session.)" 出错信息](#ts-session-failed)
   * [日志未显示 "Install tracked"](#ts-install-tracked)
   * [显示 "Unattributable SDK click ignored" 信息](#ts-iad-sdk-click)
   * [Adjust控制面板显示错误收入金额](#ts-wrong-revenue-amount)
* [许可协议](#license)

## <a id="example-apps"></a>应用示例

[`examples` 目录][examples] 内有[`iOS (Objective-C)`][example-ios-objc]、[`iOS (Swift)`][example-ios-swift]、[`tvOS`][example-tvos]、 [`iMessage`][example-imessage] 和[`Apple Watch`][example-iwatch]的应用示例。 您可以打开任何一个Xcode项目查看集成Adjust SDK的例子。

## <a id="basic-integration">基本集成

我们将介绍把Adjust SDK集成到您的iOS项目中的步骤。我们假定您将Xcode用于iOS开发。

### <a id="sdk-add">添加SDK至您的项目

如果您正在使用[CocoaPods][cocoapods],您可以将以下代码行添加至 `Podfile`，然后继续进行[此步骤](#sdk-integrate):

```ruby
pod 'Adjust', '~> 4.18.3'
```

或:

```ruby
pod 'Adjust', :git => 'https://github.com/adjust/ios_sdk.git', :tag => 'v4.18.3'
```

---

如您正在使用[Carthage][carthage], 您可以将以下代码行添加至 `Cartfile`，然后继续进行[此步骤](#sdk-frameworks):

```ruby
github "adjust/ios_sdk"
```

---

您也可以把Adjust SDK作为框架添加至您的项目中，来进行集成。在[发布专页][releases] ，您可以找到以下文档：

* `AdjustSdkStatic.framework.zip`
* `AdjustSdkDynamic.framework.zip`
* `AdjustSdkTv.framework.zip`
* `AdjustSdkIm.framework.zip`

自iOS 8发布后, Apple引进了动态框架（dynamic frameworks），又名嵌入框架 (embedded frameworks)。
如果您的应用目标受众为iOS 8或以上版本，您可以使用Adjust SDK动态框架。请先选择框架类型 – 静态或动态 – 再添加到您的项目中。

如果您正在使用`tvOS` 应用, 您可以使用Adjust SDK,也可使用我们的 tvOS 框架，该框架可从`AdjustSdkTv.framework.zip` 文档中提取。

如果您正在使用`iMessage` 应用, 您可以使用Adjust SDK,也可使用我们的 IM 框架，该框架可从`AdjustSdkIm.framework.zip` 文档中提取。

### <a id="sdk-frameworks"></a>添加iOS框架

1. 在项目导航（Project Navigator）中选择您的项目
2. 在主视图的左侧选择目标
3. 在选项`Build Phases`（构建阶段）中，扩展组`Link Binary with Libraries`（将二进制与库连接）
4. 在该部分底部点击`+`按钮
5. 选择`AdSupport.framework`，点击`Add`按钮
6. 除非您正在使用tvOS，否则重复同样步骤来添加`iAd.framework`和`CoreTelephony.framework`
7. 将两个框架的`Status`均改为`Optional`

### <a id="sdk-integrate"></a>集成SDK至您的应用

如果您从Pod库添加Adjust SDK, 请从以下导入语句中选一使用：

```objc
#import "Adjust.h"
```

或

```objc
#import <Adjust/Adjust.h>
```

---

如果您是以静态/动态框架(static/dynamic framework)或者经Carthage添加Adjust SDK，请使用以下导入语句:

```objc
#import <AdjustSdk/Adjust.h>
```

---

如果您在tvOS应用中使用Adjust SDK, 请使用以下导入语句:

```objc
#import <AdjustSdkTv/Adjust.h>
```
---

如果您在iMessage应用中使用Adjust SDK, 请使用以下导入语句:

```objc
#import <AdjustSdkIm/Adjust.h>
```

接下来，我们将设置基本会话跟踪。

### <a id="basic-setup">基本设置

在项目导航中，打开您的application delegate(应用委托)源文件。在文件顶部添加`import`（导入）语句，然后在应用委托的`didFinishLaunching`或`didFinishLaunchingWithOptions`方法中，将以下调用添加至`Adjust`：

```objc
#import "Adjust.h"
// or #import <Adjust/Adjust.h>
// or #import <AdjustSdk/Adjust.h>
// or #import <AdjustSdkTv/Adjust.h>
// or #import <AdjustSdkIm/Adjust.h>

// ...

NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment];

[Adjust appDidLaunch:adjustConfig];
```

![][delegate]

**注意**: Adjust SDK初始化设置是`非常重要`的。 否则，您有可能会遇到 [故障排除](#ts-delayed-init)中描述的多种问题。

用您的应用识别码(app token)替换`{YourAppToken}`。您可在[控制面板]中找到应用识别码。

取决于您的应用制作是用于测试或产品开发目的，您必须将`environment`（环境模式）设为以下值之一：

```objc
NSString *environment = ADJEnvironmentSandbox;
NSString *environment = ADJEnvironmentProduction;
```

**重要:** 仅当您或其他人测试您的应用时，该值应设为`ADJEnvironmentSandbox`。在您发布应用之前，请确保将环境设为`ADJEnvironmentProduction`。再次开始研发和测试时，将其设回`ADJEnvironmentSandbox`。

我们按照设置的环境来区分真实流量和测试设备的测试流量。非常重要的是，您必须始终让该值保持有意义！这一点在您进行收入跟踪时尤为重要。

### <a id="basic-setup-imessage"></a>iMessage 的特定设置

**从源代码添加 SDK:** 如果您选择**从源代码**添加 Adjust SDK 到 iMessage 应用，请确保您已在 iMessage 项目设置中设置了预处理宏**ADJUST_IM=1**。

**将 SDK 作为框架添加:** 在您将`AdjustSdkIm.framework`添加到 iMessage 应用后，请确保在`Build Phases`项目设置中添加`New Copy Files Phase`并选择将`AdjustSdkIm.framework`复制到`Frameworks`文件夹。

**会话跟踪：** 如果您希望在 iMessage 应用中正常使用会话跟踪功能，则需要执行额外的集成步骤。 在标准 iOS 应用中，Adjust SDK 会自动订阅 iOS 系统通知，让我们能够知晓应用进入或离开前台的时间。在 iMessage 应用的情况则有所不同，您需要在 iMessage 应用视图控制器中添加对`trackSubsessionStart`和`trackSubsessionEnd`方法的显示调用，以在您的应用进入前台时通知我们的 SDK。

在`didBecomeActiveWithConversation：`方式中添加对`trackSubsessionStart`的调用：

```objc
-(void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    // Use this method to configure the extension and restore previously stored state.

    [Adjust trackSubsessionStart];
}
```

在`willResignActiveWithConversation:`方式中添加对`trackSubsessionEnd`的调用:

```objc
-(void)willResignActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.

    [Adjust trackSubsessionEnd];
}
```

设置完成后，Adjust SDK 就能够在您的 iMessage 应用中成功执行会话跟踪。

**注意：** 请注意您的 iOS 应用和创建的 iMessage 扩展程序是在不同的内存空间中运行的，它们也拥有不同的 Bundle ID。如果使用相同的应用识别码来初始化 Adjust SDK ，将导致独立的两者在没有注意到彼此的状况下进行跟踪，进而使控制面板上的数据显得混杂。我们建议您在 Adjust 控制面板中为 iMessage 应用创建单独的应用，并使用单独的应用识别码来初始化SDK。

### <a id="adjust-logging">Adjust日志

您可以增加或减少在测试中看到的日志数量，方法是：用以下参数之一来调用`ADJConfig`实例上的`setLogLevel:`：

```objc
[adjustConfig setLogLevel:ADJLogLevelVerbose];  // enable all logging
[adjustConfig setLogLevel:ADJLogLevelDebug];    // enable more logging
[adjustConfig setLogLevel:ADJLogLevelInfo];     // the default
[adjustConfig setLogLevel:ADJLogLevelWarn];     // disable info logging
[adjustConfig setLogLevel:ADJLogLevelError];    // disable warnings as well
[adjustConfig setLogLevel:ADJLogLevelAssert];   // disable errors as well
[adjustConfig setLogLevel:ADJLogLevelSuppress]; // disable all logging
```

如果您不希望制作中的应用显示来自 Adjust SDK 的任何日志，请选择`ADJLogLevelSuppress`（抑制日志级别），并初始化`ADJConfig` 对象，启用抑制日志级别模式:

```objc
#import "Adjust.h"
// or #import <Adjust/Adjust.h>
// or #import <AdjustSdk/Adjust.h>
// or #import <AdjustSdkTv/Adjust.h>
// or #import <AdjustSdkIm/Adjust.h>

// ...

NSString *yourAppToken = @"{YourAppToken}";
NSString *environment = ADJEnvironmentSandbox;
ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken
                                            environment:environment
                                   allowSuppressLogLevel:YES];

[Adjust appDidLaunch:adjustConfig];
```

### <a id="build-the-app">构建您的应用

构建并运行您的应用。如果构建成功，您应当仔细阅读控制台的SDK日志。应用首次启动之后，您应当看到信息日志`Install tracked`（安装已跟踪）。

![][run]

## <a id="additional-features">附加功能

一旦您将Adjust SDK集成到您的项目中，您可以使用以下功能。

### <a id="event-tracking">事件跟踪

您可以通过Adjust来跟踪事件。假设您想要跟踪具体按钮的每一次点击，您要在[控制面板]上创建新的事件识别码，[控制面板]有相关的事件识别码，例如`abc123`等。在按钮`bottonDown`方法中，添加以下代码行以跟踪点击：

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[Adjust trackEvent:event];
```

您在点击按钮时，应当可以在日志中看到`Event tracked`（事件已跟踪）。

事件实例可以用于在跟踪之前对事件作进一步配置。

### <a id="revenue-tracking">收入跟踪

如果您的用户可以通过点击广告或应用内购为您带来收入，您可以按照事件来跟踪这些收入。假设一次点击值一欧分。那么您可以这样来跟踪收入事件：

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setRevenue:0.01 currency:@"EUR"];

[Adjust trackEvent:event];
```

当然，这可以和回调参数相结合。

当您设置货币类型时，Adjust将自动把收入转换为您选择的报告收入。阅读这里了解有关[货币转换][currency-conversion]的更多信息。

您可以在此了解更多有关收入和事件跟踪的信息[事件跟踪指南](https://docs.adjust.com/zh/event-tracking/#reference-tracking-purchases-and-revenues)。

### <a id="revenue-deduplication"></a>收入重复数据删除

您也可以输入可选的交易ID，以避免跟踪重复收入。最近的十个交易ID将被记录下来，重复交易ID的收入事件将被跳过。这对于应用内购跟踪尤其有用。参见以下例子。

如果您想要跟踪应用内购，请确保只有状态变为`SKPaymentTransactionStatePurchased`时，才在`finishTransaction`之后在`paymentQueue:updatedTransaction`中调用`trackEvent`。这样您可以避免跟踪实际未产生的收入。

```objc
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self finishTransaction:transaction];

                ADJEvent *event = [ADJEvent eventWithEventToken:...];
                [event setRevenue:... currency:...];
                [event setTransactionId:transaction.transactionIdentifier]; // avoid duplicates
                [Adjust trackEvent:event];

                break;
            // more cases
        }
    }
}
```

### <a id="iap-verification">应用收入验证

如果您希望使用收入验证——Adjust 服务器端收据验证工具,来检查应用内购的真实性，请了解我们的iOS购买SDK并[在此][ios-purchase-verification]阅读详细内容。

### <a id="callback-parameters">回调参数

在您的[控制面板][dashboard]里，您可以为事件登记回调URL。跟踪到事件时，我们会向该URL发送GET请求。您可以在跟踪事件之前调用事件的`addCallbackParameter`，向该事件添加回调参数。然后我们会将这些参数添加至您的回调URL。

例如，假设`http://www.adjust.com/callback`是您登记的回传URL，那么您可以这样来跟踪事件：

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

在此情况下，我们将跟踪事件并发送请求至：

    http://www.mydomain.com/callback?key=value&foo=bar

值得一提的是，我们支持各种可以用作参数值的占位符，例如`{idfa}`。在接下来的回调中，该占位符将被当前设备的广告ID代替。同时请注意，我们不保存您的任何定制参数，而只是将它们添加到您的回调中。如果您没有为事件输入回调地址或参数，这些参数甚至不会被读取。

您可以在我们的[回调指南][callbacks-guide]中了解到有关使用URL回调的更多信息，包括可用值的完整列表。

### <a id="partner-parameters">合作伙伴参数

您还可以针对在Adjust控制面板已经激活的渠道对接模块，添加被发送到渠道合作伙伴的参数。

工作原理和上述的回调参数相似，但是通过调用`ADJEvent`实例上的`addPartnerParameter`方法来添加。

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addPartnerParameter:@"key" value:@"value"];
[event addPartnerParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

您可以在我们的[特殊合作伙伴指南][special-partners]中了解到有关特殊合作伙伴和集成的更多信息。

### <a id="callback-id"></a>回调ID

您还可为想要跟踪的每个事件添加自定义字符串ID。此ID将在之后的事件成功和/或事件失败回调中被报告，以便您了解哪些事件跟踪成功或者失败。您可通过调用`ADJEvent` 实例上的 `setCallbackId` 方法来设置此ID:


```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setCallbackId:@"Your-Custom-Id"];

[Adjust trackEvent:event];
```

### <a id="session-parameters">会话参数

一些参数被保存发送到Adjust SDK的每一个事件和会话中。一旦您已经添加任何这些参数，您无需再每次添加它们，因为这些参数已经被保存至本地。如果您添加同样参数两次，也不会有任何效果。

如果您希望和初始安装事件一同发送会话参数，这些参数必须在Adjust SDK上线之前经`[Adjust appDidLaunch:]`被调用。如果您需要在安装同时发送参数，但只有在SDK上线后才能获得必需的值，您可以通过[延迟](#delay-start)Adjust SDK第一次上线以允许该行为。

### <a id="session-callback-parameters"> 会话回调参数

被注册在[事件](#callback-parameters)中的相同回调参数也可以被保存发送至Adjust SDK的每一个事件和会话中。

会话回调参数拥有与事件回调参数类似的接口。该参数是通过调用`Adjust` 方法 `addSessionCallbackParameter:value:`（添加会话回调参数值）被添加，而不是添加Key和值至事件:

```objc
[Adjust addSessionCallbackParameter:@"foo" value:@"bar"];
```

会话回调参数将与被添加至事件的回调参数合并。被添加至事件的回调参数拥有高于会话回调参数的优先级。这意味着，当被添加至事件的回调参数拥有与会话回调参数同样Key时，以被添加至事件的回调参数值为准。

您可以通过传递Key至`removeSessionCallbackParameter`的方法来删除特定会话回调参数。


```objc
[Adjust removeSessionCallbackParameter:@"foo"];
```

如果您希望删除会话回调参数中所有的Key及值，您可以通过`resetSessionCallbackParameters`方法重置。


```objc
[Adjust resetSessionCallbackParameters];
```

### <a id="session-partner-parameters">会话合作伙伴参数

与[会话回调参数](#session-callback-parameters)的方式一样，会话合作伙伴参数也将被发送至Ajust SDK的每一个事件和会话中。

它们将被传送至渠道合作伙伴，以集成您的Adjust[控制面板]上已经激活的模块。

会话合作伙伴参数具有与事件合作伙伴参数类似的接口。该参数是通过调用`Adjust`方法`addSessionPartnerParameter:value:`（添加会话合作伙伴参数值）被添加，而不是添加Key和值至事件:

```objc
[Adjust addSessionPartnerParameter:@"foo" value:@"bar"];
```

会话合作伙伴参数将与被添加至事件的合作伙伴参数合并。被添加至事件的合作伙伴参数具有高于会话合作伙伴参数的优先级。这意味着，当被添加至事件的合作伙伴参数拥有与会话合作伙伴参数同样Key时，以被添加至事件的合作伙伴参数值为准。

您可以通过传递Key至`removeSessionPartnerParameter`的方法来删除特定的会话合作伙伴参数。

```objc
[Adjust removeSessionPartnerParameter:@"foo"];
```

如果您希望删除会话合作伙伴参数中所有的Key及值，您可以通过`resetSessionPartnerParameters`（重置会话合作伙伴参数）的方式重置。

```objc
[Adjust resetSessionPartnerParameters];
```

### <a id="delay-start">延迟启动

延迟Adjust SDK的启动可以给您的应用一些时间获取被发送至安装的会话参数，如唯一识别码（unique identifiers）等。

通过在`ADJConfig`实例中的`setDelayStart`（设置延迟启动）方式以秒为单位设置初始延迟时间。

```objc
[adjustConfig setDelayStart:5.5];
```

在此种情况下，Adjust SDK不会在5.5秒内发送初始安装会话以及创建任何事件。在该时间过期后或您同时调用 `[Adjust sendFirstPackages]` ，每个会话参数将被添加至延迟安装的会话和事件中，Adjust SDK将恢复正常。

**Adjust SDK最长的延迟启动时间为10秒**。

### <a id="attribution-callback">归因回传

您可以注册一个委托回传，以获取跟踪链接归因变化的通知。由于考虑到归因的不同来源，归因信息无法被同时提供。遵循以下步骤在您的应用委托中启用可选的委托协议：

请务必考虑我们的[适用归因数据政策][attribution-data]。

1. 打开 `AppDelegate.h`，添加导入和`AdjustDelegate` 声明。

    ```objc
    @interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>
    ```

2. 打开`AppDelegate.m`，添加以下委托回调功能至您的应用委托执行（app delegate implementation）。

    ```objc
    - (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    }
    ```

3. 用您的`ADJConfig`实例设置委托：

    ```objc
    [adjustConfig setDelegate:self];
    ```

由于委托回调使用`ADJConfig`实例进行配置，您应当在调用`[Adjust appDidLaunch:adjustConfig]`之前调用`setDelegate`。

当SDK接收到最终归因数据时，将会获得委托功能。在委托功能内，您可以访问`attribution`(归因)参数。以下是归因属性的摘要：

- `NSString trackerToken` 目前归因的跟踪码token
- `NSString trackerName`目前归因的跟踪码名称
- `NSString network` 目前归因的渠道分组级别
- `NSString campaign` 目前归因的推广分组级别
- `NSString adgroup` 目前归因的广告组分组级别
- `NSString creative` 目前归因的创意分组级别
- `NSString clickLabel` 目前归因的点击标签
- `NSString adid` 归因提供的唯一设备ID

当值不可用时，将默认为`nil`。

### <a id="ad-revenue"></a>广告收入跟踪

您可以通过调用以下方法，使用 Adjust SDK 对广告收入进行跟踪：

```objc
[Adjust trackAdRevenue:source payload:payload];
```

您需要传递的方法参数包括：

- `source` - 表明广告收入来源信息的`NSString`对象。
- `payload` - 包含广告收入 JSON 的`NSData`对象。

目前，我们支持以下 `source` 参数值：

- `ADJAdRevenueSourceMopub` - 代表 MoPub 广告聚合平台（更多相关信息，请查看 [集成指南][sdk2sdk-mopub]）

### <a id="event-session-callbacks">事件和会话回传

您可以设置委托回调，用于在事件和/或会话跟踪成功和失败时获取通知。使用的是和[归因回传](#attribution-callback)一样的`AdjustDelegate`可选协议。

按照同样的步骤，执行以下委托回传函数，于成功跟踪事件时调用：

```objc
- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
}
```

以下为事件跟踪失败的委托回传函数：

```objc
- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
}
```

跟踪成功的会话：

```objc
- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
}
```

跟踪失败的会话：

```objc
- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
}
```

委托函数将于SDK发送包（package）到服务器后调用。在委托回传内，您能访问专为委托回传所设的响应数据对象。会话的响应数据对象字段摘要如下：

- `NSString message` 服务器信息或者SDK纪录的错误信息
- `NSString timeStamp` 服务器的时间戳
- `NSString adid` Adjust提供的设备唯一识别码
- `NSDictionary jsonResponse` JSON对象及服务器响应

两个事件响应数据对象都包含：

- 如果跟踪的包是一个事件，`NSString eventToken` 代表事件识别码。
- `NSString callbackid`为事件对象设置的自定义回调ID。

当值不可用时，将默认为`nil`。

事件和会话跟踪不成功的对象也包含：

- `BOOL willRetry` 表示稍后将再尝试发送数据包。

### <a id="disable-tracking">禁用跟踪

您可以调用参数为`NO`的`setEnabled`，停用Adjust SDK跟踪目前设备所有活动的功能。**该设置在会话间保存**，但是只能在首次会话之后激活。

```objc
[Adjust setEnabled:NO];
```

<a id="is-enabled">您可以通过调用`isEnabled`来查看Adjust SDK目前是否启用。您始终可以通过调用`setEnabled`，启用参数为`YES`，从而激活Adjust SDK。

### <a id="offline-mode">离线模式

您可以把Adjust SDK设置为离线模式，以暂停发送数据到我们的服务器，但仍然继续跟踪及保存数据并之后发送。当设为离线模式时，所有数据将存放于一个文件中，所以请注意不要于离线模式触发太多事件。

您可以调用`setOfflineMode`，启用参数为`YES`，以激活离线模式。

```objc
[Adjust setOfflineMode:YES];
```

相反地，您可以调用`setOfflineMode`，启用参数为`NO`，以终止离线模式。 当Adjust SDK回到在线模式时，所有被保存的数据将被发送到我们的服务器，并保留正确的时间信息。

跟禁用跟踪设置不同的是，此设置在会话与会话之间将**不被保存**。即使应用于离线模式终止，每当SDK启动都必定会处于在线模式。

### <a id="event-buffering">事件缓冲

如果您的应用大量使用事件跟踪，您可能会想要延迟部分HTTP请求，以便按分钟成批发送这些请求。您可以通过`ADJConfig`实例启用事件缓冲：

```objc
[adjustConfig setEventBufferingEnabled:YES];
```

如果不做任何设置，事件缓冲为 **默认禁用**。

### <a id="gdpr-forget-me"></a>GDPR 的被遗忘权

根据欧盟的《一般数据保护条例》(GDPR) 第 17 条规定，用户行使被遗忘权时，您可以通知 Adjust。调用以下方法，Adjust SDK 将会收到指示向 Adjust 后端传达用户选择被遗忘的信息：

```objc
[Adjust gdprForgetMe];
```

收到此信息后，Adjust 将清除该用户数据，并且 Adjust SDK 将停止跟踪该用户。以后不会再向 Adjust 发送来自此设备的请求。

### <a id="sdk-signature"></a>SDK签名

Adjust SDK签名功能是按客户逐一启用的。如果您希望使用该功能，请联系您的客户经理。

如果您已经在账户中启用了SDK签名，并可访问Adjust控制面板的应用密钥，请使用以下方法来集成SDK签名到您的应用。

在您的`AdjustConfig`实例中调用`setAppSecret`来设置应用密钥。

```objc
[adjustConfig setAppSecret:secretId info1:info1 info2:info2 info3:info3 info4:info4];
```

### <a id="background-tracking">后台跟踪

Adjust SDK的默认行为是当应用处于后台时暂停发送HTTP请求。您可以在 `AdjustConfig`实例中更改设置：

```objc
[adjustConfig setSendInBackground:YES];
```

如果不做任何设置，后台发送为**默认禁用**。

### <a id="device-ids">设备ID

Adjust SDK支持您获取一些设备ID。

### <a id="di-idfa"></a>iOS广告ID

某些服务（如Google Analytics）要求您协调设备及客户ID以避免重复报告。

请调用`idfa`以获取设备ID IDFA：

```objc
NSString *idfa = [Adjust idfa];
```

### <a id="di-adid"></a>Adjust设备ID

Adjust后台将为每一台安装了您应用的设备生成一个唯一的**Adjust设备ID** (**adid**)。您可通过访问`Adjust`实例的以下属性来获取该ID:

```objc
NSString *adid = [Adjust adid];
```

**注意**: 只有在Adjust后台跟踪到应用安装后，您才能获取**adid**的相关信息。自此之后，Adjust SDK已经拥有关于设备**adid**的信息，您可以使用此方法来访问它。因此，在SDK被初始化以及您的应用安装被成功跟踪之前，您将**无法访问adid**。

### <a id="user-attribution"></a>用户归因

归因回传通过[归因回传章节](#attribution-callback)所描述的方法被触发，以向您提供关于用户归因值的任何更改信息。如果您想要在任何其他时间访问用户当前归因值的信息，您可以通过对`Adjust`实例调用如下方法来实现：

```objc
ADJAttribution *attribution = [Adjust attribution];
```

**注意**: 只有在Adjust后台跟踪到应用安装和归因回传被初始触发后，您才能获取关于当前归因的信息。自此之后，Adjust SDK已经拥有关于用户归因的信息，您可以使用此方法来访问它。因此，在SDK被初始化以及归因回传被初始触发之前，您将**无法访问用户归因值**。

### <a id="push-token">推送标签（Push token）

请添加以下调用到应用委托`didRegisterForRemoteNotificationsWithDeviceToken`中的`Adjust`，发送推送标签给我们：

```objc
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];
}
```

推送标签用于Adjust受众分群工具（Audience Builder）和客户回传，且是将来发布的卸载跟踪功能的必需信息。

### <a id="pre-installed-trackers">预安装跟踪码

如果您希望使用Adjust SDK来识别已在其设备中预安装您的应用的用户，请执行以下步骤。

1. 在您的[控制面板][dashboard]中创建一个新的跟踪码。
2. 打开您的应用委托，并在`ADJConfig`中添加设置默认跟踪码:

  ```objc
  ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
  [adjustConfig setDefaultTracker:@"{TrackerToken}"];
  [Adjust appDidLaunch:adjustConfig];
  ```
用您在步骤1中创建的跟踪码替换`{TrackerToken}`（跟踪码）。请注意，控制面板中显示的是跟踪URL (包括 `http://app.adjust.com/`)。在您的源代码中，您应该仅指定六个字符的识别码，而不是整个网址（URL)。

3. 创建并运行您的应用。您应该可以看到如下的一行Xcode。

    ```
    Default tracker: 'abc123'
    ```

### <a id="deeplinking">深度链接

如果您正在使用可从网址（URL)深度链接至您的应用的Adjust跟踪URL，您将可以获取深度链接URL及其内容的相关信息。点击URL的情况发生在用户已经安装了您的应用（标准深度链接场景），或用户尚未在其设备上安装您的应用（延迟深层链接场景）。Adjust SDK支持此两种场景，在两种场景下，一旦用户点击跟踪URL启动您的应用之后，深度链接URL都将被提供给您。您必须正确设置，以便在您的应用中使用此功能。

### <a id="deeplinking-standard">标准深度链接场景

如果您的用户已经安装了您的应用，并点击了带有深度链接信息的跟踪URL，您的应用将被打开，深度链接的内容将被发送至您的应用，这样您就可以解析它们并决定下一步动作。自iOS 9推出后，Apple已经改变了在应用程序中处理深度链接的方式。取决于您希望在应用中使用哪种场景（或者您希望同时使用两种场景以支持更广泛的设备），您需要设置应用以处理以下一种或两种场景。

### <a id="deeplinking-setup-old">iOS 8及以下版本的深度链接设置

iOS 8及以下版本设备上的深度链接是通过使用自定义URL方案设置的。您需要选择一个由您的应用负责开启的自定义URL方案名。该方案名也将作为`deep_link`（深度链接）参数的一部分被用于Adjust跟踪URL。打开您的`Info.plist`文件，添加新的`URL types`，以在您的应用中设置URL方案名。在`URL identifier`输入您的应用bundle ID，于`URL schemes` 下添加您希望在应用中处理的方案名称。在以下例子中，我们已经选择应用程序处理以`adjustExample`命名的方案。

![][custom-url-scheme]

该设置完成之后，一旦点击包含自定义方案名的`deep_link` （深度链接）参数的Adjust跟踪URL， 您的应用将被打开。应用打开后，您的`AppDelegate` 中的`openURL`方式将被触发，来自跟踪URL的`deep_link`参数内容来源将被发送。如果您希望访问该深度链接内容，请改写此方法。

```objc
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // url object contains your deep link content

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

通过以上设置，您已经成功为iOS 8及以下版本的iOS设备设置深度链接。

### <a id="deeplinking-setup-new">iOS 9及以上版本的深度链接设置

为iOS 9及以上版本设备设置深度链接，您需要启用您的应用处理Apple通用链接（universal
links）的功能。查看[这里][universal-links]了解更多关于通用链接及其设置的相关信息。

Adjust在后台负责处理与通用链接相关的大部分工作。但是，为了让Adjust支持通用链接，您需要在Adjust控制面板中为通用链接做一些小的设置。请查看我们的官方[文件][universal-links-guide]以了解设置信息。

一旦在控制面板中成功启用通用链接功能，您还需要在应用中作如下设置：

在Apple Developer门户上为您的应用启用`Associated Domains`后，您需要为应用的Xcode项目作同样设置。启用`Assciated Domains`后，通过前缀`applinks:`的方式添加从Adjust控制面板中`Domains`部分生成的通用链接，并确保您同时也删除了通用链接的`http(s)`部分。

![][associated-domains-applinks]

完成该设置后，一旦点击Adjust跟踪通用链接，您的应用将被打开。应用打开后，您的`AppDelegate`中的`continueUserActivity` 方式将被触发，来自通用链接URL的内容来源将被发送。如果您希望访问该深度链接内容，请改写此方法。

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL url = [userActivity webpageURL];

        // url object contains your universal link content
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```
通过以上设置，您已经成功为iOS 9及以上版本的iOS设备设置深度链接。

如果在您的代码中包含某些自定义逻辑，其仅接受旧式自定义URL方案名格式的深度链接信息，我们为您提供一个帮助函数，可以让您将通用链接转化为旧式的深度链接URL。您可以使用通用链接以及您希望的深度链接前缀自定义URL方案名来调用该方式，我们将为您生成自定义URL方案深度链接：

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL url = [userActivity webpageURL];

        NSURL *oldStyleDeeplink = [Adjust convertUniversalLink:url scheme:@"adjustExample"];
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

### <a id="deeplinking-deferred">延迟深度链接场景

您可以注册一个委托回传，以在延迟深度链接被打开之前获取通知，并决定是否由Adjust SDK尝试打开该链接。其所使用的是和[归因回传](#attribution-callback)及[事件及会话回传](#event-session-callbacks) 同样的可选协议`AdjustDelegate`。

按照同样步骤，为延迟深度链接执行以下委托回传函数：

```objc
- (void)adjustDeeplinkResponse:(NSURL *)deeplink {
    // deeplink object contains information about deferred deep link content

    // Apply your logic to determine whether the adjust SDK should try to open the deep link
    return YES;
    // or
    // return NO;
}
```

在SDK从我们的服务器中接收指定的深度链接之后，回传函数将在打开该链接之前被调用。您可以在回传功能中访问该深度链接。返回的布尔值（boolean value）将决定是否由SDK打开该深度链接。您可以在此时不允许SDK打开该深度链接，将其保存，并在此之后由您自己打开。

如果不执行回传，**Adjust SDK将始终默认尝试打开深度链接**。

### <a id="deeplinking-reattribution">通过深度链接的再归因

Adjust支持您使用深度链接进行再参与推广活动。请查看我们的[官方文件][reattribution-with-deeplinks]了解更多相关操作信息。

如果您正在使用该功能，您需要在应用中对Adjust SDK做一个额外的调用，以便用户被正确地再归因。

一旦您已经在应用中接收到深度链接内容信息，添加一个至`appWillOpenUrl` 方式的调用。为完成该调用，Adjust SDK将会尝试在深度链接内寻找是否有任何新的归因信息，一旦找到，该信息将被发送至Adjust后台。如果您的用户因为点击带有深度链接内容的adjust跟踪URL，而应该被再归因，您将会在应用中看到 [归因回传](#attribution-callback) 被该用户新的归因信息触发。

在所有的iOS版本中，请参照如下调用`appWillOpenUrl`以设置深度链接再归因：

```objc
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // url object contains your deep link content
    
    [Adjust appWillOpenUrl:url];

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

``` objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL url = [userActivity webpageURL];

        [Adjust appWillOpenUrl:url];
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

## <a id="troubleshooting">故障排查

### <a id="ts-delayed-init">SDK延迟初始化问题

如在[基本设置步骤](#basic-setup)中所描述的,我们强烈建议您在应用委托中以`didFinishLaunching` 或者 `didFinishLaunchingWithOptions`方式初始化Adjust SDK。为了让您能够使用SDK的所有功能，您必须尽快地初始化Adjust SDK。

不立即初始化Adjust SDK将会对应用跟踪产生多种影响。**为了在您的应用中执行所有的跟踪，Adjust SDK *一定* 要被初始化。**

如果您决定执行以下任一操作：

* [事件跟踪](#event-tracking)
* [通过深度链接再归因](#deeplinking-reattribution)
* [禁用跟踪](#disable-tracking)
* [离线模式](#offline-mode)

在您初始化SDK之前，`这些操作不会被执行`。

如果您希望在Adjust SDK被真正初始化之前，跟踪以上任一操作，您必须在应用中创建`custom actions queueing mechanism`（自定义操作队列机制）。您需要将所有希望SDK执行的操作排成队列，在SDK被初始化之后执行它们。

离线模式状态不会被改变，跟踪启用/禁用状态不会被改变，深度链接再归因无法执行，所有跟踪事件将被`丢弃`。

另一个可能会被SDK延迟初始化影响的是会话跟踪。Adjust SDK在被初始化之前，不能收集任何会话长度的信息。您控制面板中的DAU数量将无法被跟踪。

举例来说，让我们假设这个场景：您正在初始化Adjust SDK，要求一些特定的视图或视图控制器（view controller)被加载。假设这不是您的应用初始启动或第一个屏幕，但是用户必须从主屏幕中导航至它们。如果用户下载并打开您的应用，主屏幕将被显示。正常情况下此时该安装应该被跟踪。然而，因为用户需要导航至
之前提到的您初始化Adjust SDK的屏幕，所以Adjust SDK无法获取任何相关信息。此外，如果用户不喜欢该应用，并在看到主屏幕之后立即卸载该应用，之上提到的所有信息将不会被我们的SDK跟踪，也不会被显示在控制面板中。

#### 事件跟踪

为跟踪事件，请使用内部队列机制将其排列，并在SDK初始化之后跟踪它们。在初始化SDK之前跟踪事件将会造成事件被`dropped`（丢弃）以及`permanently lost`（永久丢失），所以请确认您在SDK被`initialised`（初始化）并[`enabled`（启用）](#is-enabled)之后跟踪它们。

#### 离线模式和启用/禁用跟踪

离线模式功能在SDK初始化之间无法保留，所以它被默认设置为`false`。如果您尝试在SDK初始化之前启用离线模式，当SDK最终被初始化之后，将仍然被设置为 `false` 。

启用/禁用跟踪状态在SDK初始化之间保持不变。如果您尝试在SDK初始化之前切换它们，切换尝试将被忽略。当SDK被初始化之后，SDK将处于切换尝试之前的（启用或禁用）状态。

#### 通过深度链接的再归因

如[之前](#deeplinking-reattribution)所描述的，当处理深度链接再归因时，取决于您正在使用的深度链接机制（老式vs.通用链接），在进行以下调用后您将获得`NSURL` 对象：

```objc
[Adjust appWillOpenUrl:url]
```

如果您在SDK被初始化之前进行此调用，来自深度链接的归因信息将会永久丢失。如果您希望Adjust SDK成功再归因用户，您需要在SDK被初始化之后，队列`NSURL`对象信息，并触发`appWillOpenUrl`方法。

#### 会话跟踪

会话跟踪将由Adjust SDK自动执行，不受应用开发者的影响。 如本README所建议的，初始化Adjust SDK对于会话跟踪是至关重要的。否则，将对会话跟踪以及控制面板的DAU数量有着不可预测的影响。

例如：

*用户打开应用，但在SDK初始化之前删除应用，导致安装和会话从未被跟踪，因此也不会在控制面板中被报告。
*如果用户在午夜前下载并打开您的应用，然而Adjust SDK在午夜后被初始化，则所有的安装和会话数据将在错误日期被报告。
*如果用户在午夜之后短暂打开了应用，但是没有在同一天使用应用，Adjust SDK于午夜后被初始化，将DAU于非应用打开的那一天被报告。

由于各种原因，请按照本文档的说明，在您的应用委托`didFinishLaunching` 或 `didFinishLaunchingWithOptions`方式中初始化Adjust SDK。

### <a id="ts-arc">显示 "adjust requires ARC" 出错信息

如果您的构建失败，错误为`adjust requires ARC`，可能是因为您的项目没有使用[ARC][arc]。在这种情况下，我们建议[过渡您的项目][transition]至ARC。如果您不想使用ARC，您必须在目标的Build Phases中，对Adjust的所有源文件启用ARC：

展开`Compile Sources`组，选择所有Adjust文件并将`Compiler Flags`改为`-fobjc-arc`（选择全部并按下`Return`键立即全部更改）。

### <a id="ts-categories">显示 "[UIDevice adjTrackingEnabled]: unrecognized selector sent to instance" 出错信息

当添加Adjust SDK framework至您的应用时可能发生该错误。Adjust SDK源文件包含`categories`，因此如果您已经选择此种SDK集成方式，您需要添加`-ObjC` flags至Xcode项目设置中`Other Linker Flags` 。添加该flag可以解决此错误。

### <a id="ts-session-failed">显示 "Session failed (Ignoring too frequent session.)" 出错信息

此错误通常在测试安装时出现。卸载和重新安装应用并不足以触发新的安装。依据服务器中关于设备的可用信息，服务器将决定是否SDK丢失其本地汇总的会话数据并忽略错误
消息。

这种行为在测试期间可能很麻烦，但为了尽可能地让沙箱（sandbox)行为与真实情况匹配，该行为是非常必要的。

您可以在我们的服务器上重置设备会话数据。请查看日志中的错误信息：

```
Session failed (Ignoring too frequent session. Last session: YYYY-MM-DDTHH:mm:ss, this session: YYYY-MM-DDTHH:mm:ss, interval: XXs, min interval: 20m) (app_token: {yourAppToken}, adid: {adidValue})
```

<a id="forget-device">With the `{yourAppToken}` and  either `{adidValue}` or `{idfaValue}` values filled in below, open one
of the following links:

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&adid={adidValue}
```

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&idfa={idfaValue}
```

当设备被忘记，链接仅返回`Forgot device`（忘记设备）。如果设备之前已经被忘记或出现错误值，链接将返回`Device not found`（未找到设备）。

### <a id="ts-install-tracked">日志未显示 "Install tracked" 

如果您希望在测试设备上模拟应用的安装场景，仅仅在您的测试设备上重新运行Xcode开发的应用是不够的。重新运行Xcode开发的应用不会清除应用数据，SDK保存在您的应用中的所有内部数据仍然会存在。因此在重新运行时，我们的SDK将会看到这些文件并认为您的应用已被安装（SDK已被启用），应用只是又一次被打开，而不是第一次。

为了运行应用安装场景，您需要进行以下步骤：

*从您的设备中卸载应用 （完全删除应用）
*如之前[above](#forget-device)所解释的，在Adjust后台忘记您的测试设备
*在测试设备上运行Xcode开发的应用，您将会看到日志信息“安装已跟踪”

### <a id="ts-iad-sdk-click">显示 "Unattributable SDK click ignored" 信息

当您在`沙箱`（sandbox)`环境中测试您的应用时，您可能会看到该信息。这个与`iAd.framework` 版本3中Apple作出的一些更改有关。因此，点击iAd banner的用户将被定向至您的应用，导致我们的SDK发送一个`sdk_click` 包至Adjust后台并通知后台关于被点击URL的内容。由于某些原因，Apple决定如果应用在没有点击iAD banner
的情况下被打开，它们将人工生成一个带有随机值的iAd banner URL点击。我们的SDK无法区分iAd banner点击是真实或者人工生成的，所以无论在何种情况下都会发送一个 `sdk_click` 包至adjust后台。如果您已将日志级别设置为`verbose`级别，您将看到如下`sdk_click`包：

```
[Adjust]d: Added package 1 (click)
[Adjust]v: Path:      /sdk_click
[Adjust]v: ClientSdk: ios4.10.1
[Adjust]v: Parameters:
[Adjust]v:      app_token              {YourAppToken}
[Adjust]v:      created_at             2016-04-15T14:25:51.676Z+0200
[Adjust]v:      details                {"Version3.1":{"iad-lineitem-id":"1234567890","iad-org-name":"OrgName","iad-creative-name":"CreativeName","iad-click-date":"2016-04-15T12:25:51Z","iad-campaign-id":"1234567890","iad-attribution":"true","iad-lineitem-name":"LineName","iad-creative-id":"1234567890","iad-campaign-name":"CampaignName","iad-conversion-date":"2016-04-15T12:25:51Z"}}
[Adjust]v:      environment            sandbox
[Adjust]v:      idfa                   XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
[Adjust]v:      idfv                   YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY
[Adjust]v:      needs_response_details 1
[Adjust]v:      source                 iad3
```

如果由于某种原因，该`sdk_click`被接受，这表示通过点击其他推广URL或者自然搜索打开您的应用的用户，被归因到这个不存在的iAd来源。因此，我们的后台将忽略该点击，并显示以下信息：

```
[Adjust]v: Response: {"message":"Unattributable SDK click ignored."}
[Adjust]i: Unattributable SDK click ignored.
```

所以，该错误信息并不代表您的SDK集成出现问题，而仅是告知您我们的后台忽略了这个人工生成的`sdk_click` ，此点击可能会导致您的用户被错误地归因/再归因。

### <a id="ts-wrong-revenue-amount">Adjust控制面板显示错误收入金额

Adjust SDK仅跟踪您要求它跟踪的内容。如果您添加收入至事件，您所输入的金额是唯一到达Adjust后台并显示在控制面板中的金额。我们的SDK和后台都不会操纵您的金额。如果您看到错误的金额被跟踪，那是因为我们的SDK被告知跟踪该金额。

通常，跟踪收入事件的用户代码如下：

```objc
// ...

- (double)someLogicForGettingRevenueAmount {
    // This method somehow handles how user determines
    // what's the revenue value which should be tracked.

    // It is maybe making some calculations to determine it.

    // Or maybe extracting the info from In-App purchase which
    // was successfully finished.

    // Or maybe returns some predefined double value.

    double amount; // double amount = some double value

    return amount;
}

// ...

- (void)someRandomMethodInTheApp {
    double amount = [self someLogicForGettingRevenueAmount];

    ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
    [event setRevenue:amount currency:@"EUR"];
    [Adjust trackEvent:event];
}

```

如果您在控制面板中看到任何您不期望被跟踪的值，**请务必检查您决定量值的逻辑**。

[dashboard]:   http://adjust.com
[adjust.com]:  http://adjust.com

[en-readme]:  ../../README.md
[zh-readme]:  ../chinese/README.md
[ja-readme]:  ../japanese/README.md
[ko-readme]:  ../korean/README.md

[sdk2sdk-mopub]:  ../chinese/sdk-to-sdk/mopub.md

[arc]:         http://en.wikipedia.org/wiki/Automatic_Reference_Counting
[examples]:    http://github.com/adjust/ios_sdk/tree/master/examples
[carthage]:    https://github.com/Carthage/Carthage
[releases]:    https://github.com/adjust/ios_sdk/releases
[cocoapods]:   http://cocoapods.org
[transition]:  http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html

[example-tvos]:       ../../examples/AdjustExample-tvOS
[example-iwatch]:     ../../examples/AdjustExample-iWatch
[example-imessage]:   ../../examples/AdjustExample-iMessage
[example-ios-objc]:   ../../examples/AdjustExample-ObjC
[example-ios-swift]:  ../../examples/AdjustExample-Swift

[AEPriceMatrix]:     https://github.com/adjust/AEPriceMatrix
[event-tracking]:    https://docs.adjust.com/zh/event-tracking
[callbacks-guide]:   https://docs.adjust.com/zh/callbacks
[universal-links]:   https://developer.apple.com/library/ios/documentation/General/Conceptual/AppSearch/UniversalLinks.html
[special-partners]:     https://docs.adjust.com/zh/special-partners
[attribution-data]:     https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[ios-web-views-guide]:  https://github.com/adjust/ios_sdk/blob/master/doc/english/web_views.md
[currency-conversion]:  https://docs.adjust.com/zh/event-tracking/#tracking-purchases-in-different-currencies

[universal-links-guide]:      https://docs.adjust.com/zh/universal-links/
[adjust-universal-links]:     https://docs.adjust.com/zh/universal-links/#redirecting-to-universal-links-directly
[universal-links-testing]:    https://docs.adjust.com/zh/universal-links/#testing-universal-link-implementations
[reattribution-deeplinks]:    https://docs.adjust.com/zh/deeplinking/#manually-appending-attribution-data-to-a-deep-link
[ios-purchase-verification]:  https://github.com/adjust/ios_purchase_sdk

[reattribution-with-deeplinks]:   https://docs.adjust.com/zh/deeplinking/#manually-appending-attribution-data-to-a-deep-link

[run]:         https://raw.github.com/adjust/sdks/master/Resources/ios/run5.png
[add]:         https://raw.github.com/adjust/sdks/master/Resources/ios/add5.png
[drag]:        https://raw.github.com/adjust/sdks/master/Resources/ios/drag5.png
[delegate]:    https://raw.github.com/adjust/sdks/master/Resources/ios/delegate5.png
[framework]:   https://raw.github.com/adjust/sdks/master/Resources/ios/framework5.png

[adc-ios-team-id]:            https://raw.github.com/adjust/sdks/master/Resources/ios/adc-ios-team-id5.png
[custom-url-scheme]:          https://raw.github.com/adjust/sdks/master/Resources/ios/custom-url-scheme.png
[adc-associated-domains]:     https://raw.github.com/adjust/sdks/master/Resources/ios/adc-associated-domains5.png
[xcode-associated-domains]:   https://raw.github.com/adjust/sdks/master/Resources/ios/xcode-associated-domains5.png
[universal-links-dashboard]:  https://raw.github.com/adjust/sdks/master/Resources/ios/universal-links-dashboard5.png

[associated-domains-applinks]:      https://raw.github.com/adjust/sdks/master/Resources/ios/associated-domains-applinks.png
[universal-links-dashboard-values]: https://raw.github.com/adjust/sdks/master/Resources/ios/universal-links-dashboard-values5.png


## <a id="license">许可协议

The Adjust SDK is licensed under the MIT License.

Copyright (c) 2012-2019 Adjust GmbH, http://www.adjust.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
