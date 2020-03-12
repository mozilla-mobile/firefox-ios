## 요약

Adjust™의 iOS SDK에 관한 문서입니다. [adjust.com]에서 Adjust™에 대한 정보를 더 자세히 알아보세요.

앱이 Web view 를 사용하며, 자바스크립트 코드를 통해 Adjust 추적을 사용하려는 경우, [iOS 웹 보기 SDK 가이드][ios-web-views-guide]를 참조하세요.

Read this in other languages: [English][en-readme], [中文][zh-readme], [日本語][ja-readme], [한국어][ko-readme].

## 목차

* [앱 예시](#example-apps)
* [기본 연동](#basic-integration)
   * [프로젝트에 SDK 추가](#sdk-add)
   * [iOS 프레임워크 추가](#sdk-frameworks)
   * [앱에 SDK 연동](#sdk-integrate)
   * [기본 설정](#basic-setup)
        * [iMessage용 설정](#basic-setup-imessage)
   * [Adjust 로](#adjust-logging)
   * [앱 빌드하기](#build-the-app)
* [부가 기능](#additional-features)
   * [이벤트 추적](#event-tracking)
        * [매출 추적](#revenue-tracking)
        * [매출 중복 제거](#revenue-deduplication)
        * [인앱 결제 검증](#iap-verification)
        * [콜백 파라미터](#callback-parameters)
        * [파트너 파라미터](#partner-parameters)
        * [콜백 ID](#callback-id)
   * [세션 파라미터](#session-parameters)
        * [세션 콜백 파라미터](#session-callback-parameters)
        * [세션 파트너 파라미터](#session-partner-parameters)
        * [지연 시작](#delay-start)
   * [어트리뷰션 콜백](#attribution-callback)
   * [광고 매출 트래킹](#ad-revenue)
   * [이벤트 및 세션 콜백](#event-session-callbacks)
   * [추적 비활성화](#disable-tracking)
   * [오프라인 모드](#offline-mode)
   * [이벤트 버퍼링](#event-buffering)
   * [GDPR 잊혀질 권리(Right to be Forgotten)](#gdpr-forget-me)
   * [SDK 서명](#sdk-signature)
   * [백그라운드 추적](#background-tracking)
   * [기기 ID](#device-ids)
        * [iOS 광고 식별자](#di-idfa)
        * [Adjust 기기 식별자](#di-adid)
   * [사용자 어트리뷰션](#user-attribution)
   * [푸시 토큰](#push-token)
   * [사전 설치 트래커](#pre-installed-trackers)
   * [딥링크](#deeplinking)
        * [표준 딥링크 시나리오](#deeplinking-standard)
        * [iOS 8 이전 버전에서의 딥링크](#deeplinking-setup-old)
        * [iOS 9 이후 버전에서의 딥링크](#deeplinking-setup-new)
        * [지연 딥링크(deferred deeplink) 시나리오](#deeplinking-deferred)
        * [딥링크를 통한 리어트리뷰션( reattribution)](#deeplinking-reattribution)
* [문제 해결](#troubleshooting)
    * [SDK 초기화 지연 문제](#ts-delayed-init)
    * ["Adjust requires ARC" 오류가 나타납니다](#ts-arc)
    * ["\[UIDevice adjTrackingEnabled\]: unrecognized selector sent to instance" 오류가 나타납니다](#ts-categories)
    * ["Session failed (Ignoring too frequent session.)" 오류가 나타납니다](#ts-session-failed)
    * [로그에 "Install tracked"가 표시되지 않습니다](#ts-install-tracked)
    * ["Unattributable SDK click ignored" 메시지가 나타납니다](#ts-iad-sdk-click)
    * [Adjust 대시보드에 잘못된 매출 데이터가 표시됩니다](#ts-wrong-revenue-amount)
* [라이선스](#license)

## <a id="example-apps"></a>앱 예시

[`iOS(Objective-C)`][example-ios-objc], [`iOS(Swift)`][example-ios-swift], [`tvOS`][example-tvos], [`iMessage`][example-imessage] 및 [`Apple Watch`][example-iwatch]에 대한 [`examples` 디렉토리][examples]에서 앱 예시를 확인할 수 있습니다. Xcode 프로젝트를 실행하여 Adjust SDK의 연동 과정에 대한 사례를 살펴보세요.

## <a id="basic-integration">기본 연동

iOS 개발용 Xcode를 사용한다는 가정하에 iOS 프로젝트에 Adjust SDK를 연동하는 방법을 설명합니다.

### <a id="sdk-add"></a>프로젝트에 SDK 추가

[CocoaPods][cocoapods]를 사용하는 경우, 다음 내용을 `Podfile`에 추가한 후 [해당 단계](#sdk-integrate)를 완료하세요.

```ruby
pod 'Adjust', '~> 4.18.3'
```

또는:

```ruby
pod 'Adjust', :git => 'https://github.com/adjust/ios_sdk.git', :tag => 'v4.18.3'
```

---

[Carthage][carthage]를 사용하는 경우, 다음 내용을 `Cartfile`에 추가한 후 [해당 단계](#sdk-frameworks)를 완료하세요.

```ruby
github "adjust/ios_sdk"
```

---

프로젝트에 Adjust SDK를 프레임워크로 추가하여 연동할 수도 있습니다. [릴리스 페이지][releases]에서 다음 항목을 확인해 보세요.

* `AdjustSdkStatic.framework.zip`
* `AdjustSdkDynamic.framework.zip`
* `AdjustSdkTv.framework.zip`
* `AdjustSdkIm.framework.zip`

Apple은 iOS 8을 출시한 후, 임베디드 프레임워크로도 잘 알려진 동적 프레임워크(dynamic frameworks)를 도입했습니다. 앱이 iOS 8 이상 버전을 타겟팅하는 경우에는 Adjust SDK 동적 프레임워크를 사용할 수 있습니다. 필요에 따라 static 또는 dynamic 프레임워크를 선택하여 프로젝트에 추가하세요.

`tvOS`앱의 경우, `AdjustSdkTv.framework.zip` 자료에서 추출 가능한 tvOS 프레임워크와 함께 Adjust SDK를 활용할 수 있습니다.

`iMessage`앱의 경우, `AdjustSdkIm.framework.zip` 아카이브에서 추출 가능한 IM 프레임워크와 함께 Adjust SDK를 활용할 수 있습니다.

### <a id="sdk-frameworks"></a>iOS 프레임워크 추가

1. Project Navigator에서 프로젝트를 선택합니다.
2. 메인 화면 좌측에서 타겟을 선택합니다.
3. `Build Phases` 탭에서 `Link Binary with Libraries` 그룹을 확장합니다.
4. 해당 섹션의 하단에서 `+` 버튼을 선택합니다.
5. `AdSupport.framework`를 선택하고 `Add` 버튼을 클릭합니다. 
6. tvOS를 사용하는 경우를 제외하고, 같은 단계를 반복하여 `iAd.framework`와 `CoreTelephony.framework`를 추가합니다.
7. 프레임워크의 `Status`를 `Optional`로 변경합니다.

### <a id="sdk-integrate"></a>앱에 SDK 연동

Pod 리포지토리를 통해 Adjust SDK를 추가했다면, 다음 import 명령어 중 하나를 실행해야 합니다.

```objc
#import "Adjust.h"
```

또는

```objc
#import <Adjust/Adjust.h>
```

---

Adjust SDK를 static/dynamic 프레임워크로 추가했거나 Carthage를 통해 등록했다면, 다음 import 명령어 중 하나를 실행해야 합니다.

```objc
#import <AdjustSdk/Adjust.h>
```

---

tvOS 앱에서 Adjust SDK를 사용하는 경우, 다음 import 명령어 중 하나를 실행해야 합니다.

```objc
#import <AdjustSdkTv/Adjust.h>
```

---

iMessage 앱에서 Adjust SDK를 사용하는 경우, 다음 가져오기 명령어 중 하나를 실행해야 합니다.

```objc
#import <AdjustSdkIm/Adjust.h>
```

다음으로는 기본 세션 추적을 설정하겠습니다.

### <a id="basic-setup"></a>기본 설정

Project Navigator에서 애플리케이션 delegate 의 소스 파일을 실행합니다. `import` 명령어를 파일 상단에 추가한 후, 다음 콜을 앱 delegate 의 `didFinishLaunching` 또는 `didFinishLaunchingWithOptions` 메서드 내 `Adjust`에 추가합니다.

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

**참고**: Adjust SDK 초기화는 `아주 중요한` 단계입니다. 제대로 완료하지 않으면 [문제 해결 섹션](#ts-delayed-init)에서 설명하는 다양한 문제가 발생할 수 있습니다.

`{YourAppToken}`을 사용 중인 앱 토큰으로 교체한 다음, [Dashboard]에서 결과를 확인해 보세요.

테스트 또는 배포 등 어떤 목적으로 앱을 빌드하는에 따라 다음 두 값 중 하나의 `environment`(환경)으로 설정해야 합니다.

```objc
NSString *environment = ADJEnvironmentSandbox;
NSString *environment = ADJEnvironmentProduction;
```

**중요:** 앱을 테스트해야 하는 경우, 해당 값을 `ADJEnvironmentSandbox` 로 설정해야 합니다. 앱을 퍼블리시할 준비가 완료되면 환경 설정을 `ADJEnvironmentProduction` 으로 변경하고, 앱 개발 및 테스트를 새로 시작한다면 `ADJEnvironmentSandbox` 로 다시 설정하세요.

테스트 기기로 인해 발생하는 테스트 트래픽과 실제 트래픽을 구분하기 위해 다른 환경을 사용하고 있으니, 상황에 알맞은 설정을 적용하시기 바랍니다. 이는 매출을 추적하는 경우에 특히 중요합니다.

### <a id="basic-setup-imessage"></a>iMessage용 설정

**소스에서 SDK 추가:** **소스에서** Adjust SDK를 iMessage 앱에 추가하기로 선택한 경우, iMessage 프로젝트 설정에 프리 프로세서 매크로 **ADJUST_IM=1**이 설정되어 있는지 확인하세요.

**Framework(프레임워크)로 SDK 추가:** iMessage 앱에 `AdjustSdkIm.framework`를 추가했다면, `Build Phases`프로젝트 설정에 `New Copy Files Phase`를 추가하고 `AdjustSdkIm.framework`가 `Frameworks` 폴더로 복사되도록 선택했는지 확인하세요.

**세션 추적:** iMessage 에서 세션 추적을 원활하게 실행하고 싶다면, 추가적인 연동 과정을 거쳐야 합니다. 표준 iOS 앱의 경우 Adjust SDK에서 iOS 시스템 알림을 자동으로 수신하기 때문에 Adjust가 앱의 세션 정보를 파악할 수 있으나, iMessage 앱의 경우에는 그렇지 않습니다. 따라서 explicit call(명시적인 콜)을 iMessage 앱 뷰 컨트롤러 내부의 `trackSubsessionStart`와 `trackSubsessionEnd` method(매서드)에 추가해야 Adjust SDK에서 앱이foreground에 있는지 여부를 추적할 수 있습니다.

`didBecomeActiveWithConversation:` 메서드 내부의 `trackSubsessionStart`에 콜을 추가합니다.

```objc
-(void)didBecomeActiveWithConversation:(MSConversation *)conversation {
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    // Use this method to configure the extension and restore previously stored state.

    [Adjust trackSubsessionStart];
}
```
`willResignActiveWithConversation:` 메서드 내부의 `trackSubsessionEnd`에 콜을 추가합니다.

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

이렇게 설정을 완료하면, Adjust SDK를 통해 iMessage 앱 내부에서 세션을 추적할 수 있습니다.

**참고:** 빌드한 iOS 앱 및 iMessage 확장자가 서로 다른 메모리 공간에서 운영되며, 상이한 번들 식별자를 사용하고 있는지 확인해야 합니다. 두 공간에서 같은 앱 토큰으로 Adjust SDK를 초기화하면 두 개의 독립 인스턴스가 생성되며, 두 인스턴스가 각자 서로의 존재를 모르는 채로 추적하여 대시보드 데이터에서 적합하지 않은 데이터 혼합이 발생할 수 있습니다. 따라서 iMessage 앱용 Adjust 대시보드에서 별도의 앱을 생하여 다른 앱 토큰으로 SDK를 초기화하는 것이 좋습니다.

### <a id="adjust-logging"></a>Adjust 로깅(logging)

다음 파라미터 중 하나를 통해 `ADJConfig` 인스턴스에서 `setLogLevel:` 을 호출하여 테스트하는 동안 조회할 로그의 양을 늘리거나 줄일 수 있습니다.

```objc
[adjustConfig setLogLevel:ADJLogLevelVerbose];  // enable all logging
[adjustConfig setLogLevel:ADJLogLevelDebug];    // enable more logging
[adjustConfig setLogLevel:ADJLogLevelInfo];     // the default
[adjustConfig setLogLevel:ADJLogLevelWarn];     // disable info logging
[adjustConfig setLogLevel:ADJLogLevelError];    // disable warnings as well
[adjustConfig setLogLevel:ADJLogLevelAssert];   // disable errors as well
[adjustConfig setLogLevel:ADJLogLevelSuppress]; // disable all logging
```

개발 중인 앱에 Adjust SDK가 기록하는 로그를 표시하지 않으려면, `ADJLogLevelSuppress` 를 선택한 후 로그 수준 모드를 조절할 수 있는 생성자에서 `ADJConfig` 객체를 초기화해야 합니다.

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

### <a id="build-the-app"></a>앱 빌드

앱을 빌드하고 실행합니다. 빌드를 성공적으로 완료했다면, 콘솔에서 SDK 로그를 꼼꼼하게 살펴보시기 바랍니다. 앱을 처음으로 출시한 경우, `Install tracked` 로그 정보를 반드시 확인하세요.

![][run]

## <a id="additional-features">부가 기능

Adjust SDK를 프로젝트에 연동한 후에는 다음 기능을 사용할 수 있습니다.

### <a id="event-tracking">이벤트 추적

Adjust로 이벤트를 추적할 수 있습니다. 특정 버튼의 모든 탭을 추적하려는 경우 `abc123`와 같은 관련 이벤트 토큰이 있는 새 이벤트 토큰을 [대시보드](adjust.com)에서 만듭니다. 그런 다음 버튼의 `buttonDown` 메서드에 다음 행을 추가하여 클릭을 추적할 수 있습니다.

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];
[Adjust trackEvent:event];
```

버튼을 누르면 `Event tracked`가 로그에 나타납니다.

이벤트 인스턴스를 사용하여 이벤트를 추적하기 전에 더 자세한 환경 설정을 할 수 있습니다.

### <a id="revenue-tracking">매출 추적

사용자가 광고를 누르거나 인앱 구매를 통해 매출을 발생시킬 수 있는 경우 이벤트를 사용하여 해당 수익을 추적할 수 있습니다. 한 번 누를 때 0.01 유로의 수익이 발생한다고 가정할 경우 매출 이벤트를 다음과 같이 추적할 수 있습니다.

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setRevenue:0.01 currency:@"EUR"];

[Adjust trackEvent:event];
```

이것을 콜백 파라미터와 결합할 수도 있습니다.

통화 토큰을 설정하면 들어오는 매출을 Adjust가 자동으로 미리 지정한 보고용 통화로 전환해 줍니다. 통화 전환에 관한 자세한 내용은 [여기][currency-conversion]에서 확인하세요.

매출 및 이벤트 추적에 대한 자세한 내용은 [이벤트 추적 설명서](https://docs.adjust.com/ko/event-tracking/#part-5)를 참조하십시오.

### <a id="revenue-deduplication"></a>매출 중복 제거

거래 ID를 선택 사항으로 추가하여 수익 중복 추적을 피할 수 있습니다. 가장 최근에 사용한 거래 ID 10개를 기억하며, 똑같은 거래 ID로 이루어진 매출 이벤트는 중복 집계하지 않습니다. 인앱 구매 추적 시 특히 유용합니다. 사용 예는 아래에 나와 있습니다.

인앱 구매를 추적하려면 상태가 `SKPaymentTransactionStatePurchased`로 변경된 경우에만 `paymentQueue:updatedTransaction`에서 `finishTransaction` 후에 `trackEvent`를 호출해야 합니다. 이렇게 해야 실제로 발생하지 않은 매출을 추적하는 오류를 막을 수 있습니다.

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

### <a id="iap-verification">인앱 결제 검증

Adjust의 서버 측 수신 확인 도구인 구매 검증(Purchase Verification)을 사용하여 앱에서 이루어지는 구매의 유효성을 확인하려면 iOS 구매 SDK를 확인하십시오. 자세한 내용은 [여기][ios-purchase-verification]에서 확인할 수 있습니다.

### <a id="callback-parameters">콜백 파라미터

[대시보드](adjust.com)에서 이벤트 콜백 URL을 등록할 수 있습니다. 이벤트를 추적할 때마다 GET 요청이 해당 URL로 전송됩니다. 이벤트를 추적하기 전에 이벤트 인스턴스에서 `addCallbackParameter`를 호출하여 콜백 파라미터를 해당 이벤트에 추가할 수 있습니다. 그러면 해당 파라미터가 콜백 URL에 추가됩니다.

예를 들어 `http://www.adjust.com/callback` URL을 등록한 경우 이벤트를 다음과 같이 추적할 수 있습니다.

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addCallbackParameter:@"key" value:@"value"];
[event addCallbackParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

이 경우에는 이벤트를 추적하여 다음 주소로 요청을 전송합니다.

```
http://www.mydomain.com/callback?key=value&foo=bar
```

Adjust는 `{idfa}`와 같이 파라미터 값으로 사용할 수 있는 다양한 자리 표시자(placeholder)를 지원합니다. 그 결과로 생성한 콜백에서 이 자리 표시자는 현재 기기의 광고 ID로 대체됩니다. 사용자 지정 파라미터는 저장되지 않으며 콜백에만 추가됩니다. 이벤트에 대한 콜백을 등록하지 않은 경우 해당 파라미터는 읽을 수 없습니다.

사용 가능한 값의 전체 목록을 포함한 URL 콜백 사용에 대한 자세한 내용은 [콜백 설명서][callbacks-guide]를 참조하십시오.

### <a id="partner-parameters">파트너 파라미터

Adjust 대시보드에서 활성화된 연동에 대해 네트워크 파트너로 전송할
파라미터도 추가할 수 있습니다.

위에서 설명한 콜백 매개변수의 경우와 비슷하지만, `ADJEvent` 인스턴스에서 `addPartnerParameter` 메서드를 호출해야 추가할 수 있습니다.

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event addPartnerParameter:@"key" value:@"value"];
[event addPartnerParameter:@"foo" value:@"bar"];

[Adjust trackEvent:event];
```

특별 파트너와 해당 파트너와의 연동에 대한 자세한 내용은 [특별 파트너 설명서][special-partners]를 참조하십시오.

### <a id="callback-id"></a>콜백 ID
추적하고자 하는 각 이벤트에 개별 스트링 ID를 따로 붙일 수도 있습니다. 나중에 이벤트 성공/실패 콜백에서 해당 ID에 전달하여 이벤트 트래킹의 성공 또는 실패 여부를 추적할 수 있게 해 줍니다. `AdjustEvent` 인스턴스에서  `setCallbackId` 메서드를 호출하여 설정할 수 있습니다. 

```objc
ADJEvent *event = [ADJEvent eventWithEventToken:@"abc123"];

[event setCallbackId:@"Your-Custom-Id"];

[Adjust trackEvent:event];
```

### <a id="session-parameters">세션 파라미터

일부 파라미터는 Adjust SDK 이벤트 및 세션 발생시마다 전송을 위해 저장합니다. 어느 파라미터든 한 번 저장하면 로컬에 바로 저장되므로 매번 새로 추가할 필요가 없습니다. 같은 파라미터를 두 번 저장해도 효력이 없습니다.

세션 파라미터를 최초 설치 이벤트시에 전송하려면, `[Adjust appDidLaunch:]`를 통해 Adjust SDK 런칭을 하기 전에 해당 파라미터를 호출해야 합니다. 설치 시 전송하지만 필요한 값은 런칭 후에야 들어갈 수 있게 하고 싶다면 Adjust SDK 런칭 시 [예약 시작](#delay-start)을 걸 수 있습니다. 

### <a id="session-callback-parameters">세션 콜백 파라미터

[이벤트](#callback-parameters)에 등록한 콜백 파라미터는 Adjust SDK 전체 이벤트 및 세션 시 전송할 목적으로 저장할 수 있습니다.

세션 콜백 파라미터는 이벤트 콜백 파라마터와 비슷한 인터페이스를 지녔지만, 이벤트에 키와 값을 추가하는 대신 `Adjust` 인스턴스에 있는 `addSessionCallbackParameter` 메서드를 호출하여 추가합니다.

```objc
[Adjust addSessionCallbackParameter:@"foo" value:@"bar"];
```

세션 콜백 파라미터는 이벤트에 추가된 콜백 파라미터와 합쳐지며, 이벤트에 추가된 콜백 파라미터가 우선권을 지닙니다. 그러나 세션에서와 같은 키로 이벤트에 콜백 파라미터를 추가한 경우 새로 추가한 콜백 파라미터가 우선권을 가집니다.

원하는 키를 `Adjust` 인스턴스의 `removeSessionCallbackParameter` 메서드로 전달하여 특정 세션 콜백 파라미터를 제거할 수 있습니다.

```objc
[Adjust removeSessionCallbackParameter:@"foo"];
```

세션 콜백 파라미터의 키와 값을 전부 없애고 싶다면 `Adjust` 인스턴스의 `resetSessionCallbackParameters` 메서드로 재설정하면 됩니다.

```objc
[Adjust resetSessionCallbackParameters];
```

### <a id="session-partner-parameters">세션 파트너 파라미터

Adjust SDK 내 모든 이벤트 및 세션에서 전송되는 [세션 콜백 파라미터](#session-callback-parameters)가 있는 것처럼, 세션 파트너 파라미터도 있습니다.

이들 파라미터는 Adjust [대시보드](adjust.com)에서 연동을 활성화한 네트워크 파트너에게 전송할 수 있습니다.

세션 파트너 파라미터는 이벤트 파트너 파라미터와 인터페이스가 비슷하지만, 이벤트에 키와 값을 추가하는 대신 `Adjust` 인스턴스에서 `addSessionPartnerParameter` 메서드를 호출하여 추가합니다.

```objc
[Adjust addSessionPartnerParameter:@"foo" value:@"bar"];
```

세션 파트너 파라미터는 이벤트에 추가한 파트너 파라미터와 합쳐지며, 이벤트에 추가된 파트너 파라미터가 우선순위를 지닙니다. 그러나 세션에서와 같은 키로 이벤트에 파트너 파라미터를 추가한 경우, 새로 추가한 파트너 파라미터가 우선권을 가집니다.

원하는 키를 `Adjust` 인스턴스의 `removeSessionPartnerParameter` 메서드로 전달하여 특정 세션 파트너 파라미터를 제거할 수 있습니다.

```objc
[Adjust removeSessionPartnerParameter:@"foo"];
```

세션 파트너 파라미터의 키와 값을 전부 없애고 싶다면 `Adjust` 인스턴스의 `resetSessionPartnerParameters` 메서드로 재설정하면 됩니다.

```objc
[Adjust resetSessionPartnerParameters];
```

### <a id="delay-start">지연 시작

Adjust SDK에 예약 시작을 걸면 앱이 고유 식별자 등의 세션 파라미터를 얻어 설치 시에 전송할 시간을 벌 수 있습니다.

`ADJConfig` 인스턴스의 `setDelayStart` 메서드에서 예약 시작 시각을 초 단위로 설정하세요.

```objc
[adjustConfig setDelayStart:5.5];
```

이 경우 Adjust SDK는 최초 인스톨 세션 및 생성된 이벤트를 5.5초간 기다렸다가 전송합니다. 이 시간이 지난 후, 또는 그 사이에 `[Adjust sendFirstPackages]`을 호출했을 경우 모든 세션 파라미터가 지연된 인스톨 세션 및 이벤트에 추가되며 Adjust SDK는 원래대로 돌아옵니다.

**Adjust SDK의 최대 지연 예약 시작 시간은 10초입니다**.

### <a id="attribution-callback">어트리뷰션 콜백

delegate(델리게이트) 콜백을 등록하여 트래커 어트리뷰션 변경에 대한 알림을 받을 수 있습니다. 어트리뷰션에서 고려하는 소스가 각각 다르기 때문에 이 정보는 동시간에 제공할 수 없습니다. 앱 델리게이트에서 델리게이트 프로토콜(선택 사항)을 구현하려면 다음 단계를 수행하십시오.

[해당 어트리뷰션 데이터 정책][attribution-data]을 고려하십시오.

1. `AppDelegate.h`를 열고 `AdjustDelegate` 선언을 추가합니다.

```objc
@interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>
```

2. `AppDelegate.m`을 열고 다음 델리게이트 호출 함수를 앱 델리게이트 구현에 추가합니다.

```objc
- (void)adjustAttributionChanged:(ADJAttribution *)attribution {
    }
```

3. `ADJConfig` 인스턴스를 사용하여 델리게이트를 설정합니다.

```objc
[adjustConfig setDelegate:self];
```
    
델리게이트 콜백은 `ADJConfig` 인스턴스를 써서 구성하므로, `[Adjust appDidLaunch:adjustConfig]`를 호출하기 전에 `setDelegate`를 호출해야 합니다.

SDK에 최종 속성 데이터가 수신되면 델리게이트 함수가 호출됩니다.
델리게이트 함수를 통해 `attribution` 파라미터에 액세스할 수 있습니다.
각 파라미터 속성에 대한 개요는 다음과 같습니다.

- `NSString trackerToken` 현재 설치의 트래커 토큰.
- `NSString trackerName` 현재 설치의 트래커 이름.
- `NSString network` 현재 설치의 network 그룹화 기준.
- `NSString campaign` 현재 설치의 campaign 그룹화 기준.
- `NSString adgroup` 현재 설치의 ad group 그룹화 기준.
- `NSString creative` 현재 설치의 creative 그룹화 기준.
- `NSString clickLabel` 현재 설치의 클릭 레이블.
- `NSString adid` Adjust 기기 식별자.

값을 사용할 수 없을 경우 `nil`로 기본 설정됩니다.

### <a id="ad-revenue"></a>광고 매출 트래킹

다음 메서드를 호출하여 Adjust SDK로 광고 매출 정보를 트래킹할 수 있습니다.

```objc
[Adjust trackAdRevenue:source payload:payload];
```

전달해야 하는 메서드 파라미터는 다음과 같습니다.

- `source` - 광고 매출 정보의 소스를 나타내는`NSString` 객체
- `payload` - 광고 매출 JSON을 포함하는  `NSData`  객체

애드저스트는 현재 다음의 `source` 파라미터 값을 지원합니다.

- `ADJAdRevenueSourceMopub` - MoPub 미디에이션 플랫폼을 나타냄(자세한 정보는 [연동 가이드][sdk2sdk-mopub] 확인)

### <a id="event-session-callbacks">이벤트 및 세션 콜백

델리게이트 콜백을 등록하여 성공 또는 실패한 추적 대상 이벤트 및/또는 세션에 대한 알림을 받을 수 있습니다.

[어트리뷰션 콜백](#attribution-callback)에 사용되는 것과 동일한 선택적 프로토콜인 `AdjustDelegate`가 사용됩니다.

동일한 단계에 따라 이벤트 추적 성공 시에 대해 다음 델리게이트 콜백 함수를 구현하십시오.

```objc
- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
}
```

다음은 이벤트 추적 실패 시에 구현하는 델리게이트 콜백 함수입니다.

```objc
- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
}
```

세선 추적 성공의 경우입니다.

```objc
- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
}
```

그리고 추적 세션 실패의 경우입니다.

```objc
- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
}
```

델리게이트 함수는 SDK에서 서버로 패키지를 보내려고 시도한 후에 호출됩니다. 델리게이트 콜백에서는 전용 응답 데이터 개체에 액세스할 수 있습니다. 세션 응답 데이터 속성에 대한 개요는 다음과 같습니다.

- `NSString message` 서버에서 전송한 메시지 또는 SDK가 기록한 오류
- `NSString timeStamp` 서버에서 전송한 데이터의 타임스탬프
- `NSString adid` Adjust가 제공하는 고유 기기 식별자
- `NSDictionary jsonResponse` 서버로부터의 응답이 있는 JSON 개체

두 이벤트 응답 데이터 개체에는 모두 다음이 포함됩니다.

- `NSString eventToken` 트래킹 패키지가 이벤트인 경우 이벤트 토큰
- `NSString callbackid` 이벤트 객체에서 사용자가 설정하는 콜백 ID.

값을 사용할 수 없을 경우 `nil`로 기본 설정됩니다.

그리고 이벤트 및 세션 실패 개체에는 모두 다음이 포함됩니다.

- `BOOL willRetry` 나중에 패키지 재전송 시도가 있을 것임을 나타냅니다.

### <a id="disable-tracking">추적 비활성화

`setEnabled`를 `No` 파라미터로 설정한 상태로 호출하면 Adjust SDK에서 현재 장치의 모든 작업 추적을 중지할 수 있습니다. **이 설정은 세션 간에 기억되지만**, 첫 번째 세션 후에만 활성화할 수 있습니다.

```objc
[Adjust setEnabled:NO];
```

`isEnabled` 함수를 호출하여 Adjust SDK가 현재 사용 가능한지 확인할 수 있습니다. 파라미터가 `YES`로 설정된 `setEnabled`를 호출하면 Adjust SDK를 언제든 활성화할 수 있습니다.

### <a id="offline-mode">오프라인 모드

Adjust SDK를 오프라인 모드로 전환하여 Adjust 서버로 전송하는 작업을 일시 중단하고 추적 데이터를 보관하여 나중에 보낼 수 있습니다. 오프라인 모드일 때는 모든 정보가 파일에 저장되므로 너무 많은 이벤트를 촉발(trigger)하지 않도록 주의하십시오.

`setOfflineMode`를 `YES`로 설정하여 호출하면 오프라인 모드를 활성화할 수 있습니다.

```objc
[Adjust setOfflineMode:YES];
```

반대로 `setOfflineMode`를 `NO`로 설정한 상태로 호출하면 오프라인 모드를 비활성화할 수 있습니다. Adjust SDK를 다시 온라인 모드로 전환하면 저장된 정보가 모두 올바른 시간 정보와 함께 Adjust 서버로 전송됩니다.

트래킹 사용 중지와 달리 이 설정은 세션 간에 **기억되지 않습니다.** 따라서 앱을 오프라인 모드에서 종료한 경우에도 SDK는 항상 온라인 모드로 시작됩니다.

### <a id="event-buffering">이벤트 버퍼링

앱이 이벤트 추적을 많이 사용하는 경우, 매 분마다 배치(batch) 하나씩만 보내도록 하기 위해 일부 HTTP 요청을 지연시키고자 할 경우가 있을 수 있습니다. `ADJConfig` 인스턴스로 이벤트 버퍼링을 적용할 수 있습니다.

```objc
[adjustConfig setEventBufferingEnabled:YES];
```

설정한 내용이 없으면 이벤트 버퍼링은 **기본값으로 비활성화됩니다**.

### <a id="gdpr-forget-me"></a>GDPR 잊혀질 권리(Right to be Forgotten)

유럽연합(EU) 일반 개인정보 보호법 제 17조에 의거하여, 사용자가 잊힐 권리를 행사하였을 경우  Adjust에 이를 통보할 수 있습니다. 다음 매서드를 호출하면 Adjust SDK는 사용자가 잊힐 권리를 사용하기로 했음을 Adjust 백엔드에 전달합니다:

```objc
[Adjust gdprForgetMe];
```

이 정보를 받는 즉시 Adjust는 사용자의 데이터를 삭제하며 Adjust SDK는 해당 사용자 추적을 중단합니다. 향후 이 기기로부터 어떤 요청도 Adjust에 전송되지 않습니다.

### <a id="sdk-signature"></a>SDK 서명

Adjust SDK 서명이 클라이언트 간에 사용 가능합니다. 이 기능을 사용해 보고자 할 경우 계정 매니저에게 연락해 주십시오.

SDK 서명이 계정에서 이미 사용 가능 상태로 Adjust 대시보드에서 App Secret에 억세스할 수 있는 상태라면, 아래 매서드를 사용하여 SDK 서명을 앱에 연동하십시오. 

`AdjustConfig` 인스턴스에서 `setAppSecret`를 호출하면 App Secret이 설정됩니다.

```objc
[adjustConfig setAppSecret:secretId info1:info1 info2:info2 info3:info3 info4:info4];
```

### <a id="background-tracking">백그라운드 추적

Adjust SDK 기본값 행위는 앱이 백그라운드에 있을 동안에는 HTTP 요청 전송을 잠시 중지하는 것입니다. `AdjustConfig` 인스턴스에서 이를 바꿀 수 있습니다.

```objc
[adjustConfig setSendInBackground:YES];
```

설정한 내용이 없으면 백그라운드 추적은 **기본값으로 비활성화됩니다**.

### <a id="device-ids">기기 ID

Adjust SDK로 기기 식별자 몇 가지를 획득할 수 있습니다.

### <a id="di-idfa">iOS 광고 식별자

Google Analytics와 같은 서비스를 사용하려면 중복 보고가 발생하지 않도록 장치 ID와 클라이언트 ID를 조정해야 합니다.

기기 식별자 IDFA를 얻으려면 `idfa` 함수를 호출하세요.

```objc
NSString *idfa = [Adjust idfa];
```

### <a id="di-adid"></a>Adjust 기기 식별자

Adjust 백엔드는 앱을 설치한 기기에서 고유한 **Adjust 기기 식별자** (**adid**)를 생성합니다. 이 식별자를 얻으려면 `Adjust` 인스턴스에서 다음 메서드를 호출하면 됩니다.

```objc
NSString *adid = [Adjust adid];
```

**주의**: **adid** 관련 정보는 Adjust 백엔드가 앱 설치를 추적한 후에만 얻을 수 있습니다. 그 순간부터 Adjust SDK는 기기 **adid** 정보를 갖게 되며 이 메서드로 액세스할 수 있습니다. 따라서 SDK가 초기화되고 앱 인스톨 추적이 성공적으로 이루어지기 전에는 **adid** 액세스가 **불가능합니다**.

### <a id="user-attribution"></a>사용자 어트리뷰션

[어트리뷰션 콜백 섹션](#attribution-callback)에서 설명한 바와 같이, 이 콜백은 변동이 있을 때마다 새로운 어트리뷰션 관련 정보를 전달할 목적으로 촉발됩니다. 사용자의 현재 어트리뷰션 정보에 액세스하고 싶다면, `Adjust` 인스턴스에서 다음 메서드를 호출하면 됩니다.

```objc
ADJAttribution *attribution = [Adjust attribution];
```

**주의**: 사용자의 현재 어트리뷰션 정보는 Adjust 백엔드가 앱 설치를 추적하여 최초 어트리뷰션 콜백이 촉발된 후에만 얻을 수 있습니다. 그 순간부터 Adjus SDK는 사용자 어트리뷰션 정보를 갖게 되며 이 메소드로 억세스할 수 있습니다. 따라서 SDK가 초기화되고 최초 어트리뷰션 콜백이 촉발되기 전에는 사용자 어트리뷰션 값에 액세스가 **불가능합니다**. 

### <a id="push-token">푸시 토큰

Adjust로 푸시 알림 토큰을 보내려면 app delegate의 `didRegisterForRemoteNotificationsWithDeviceToken`에서 다음 호출을 `Adjust`에 추가합니다.

```objc
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Adjust setDeviceToken:deviceToken];
}
```

푸시 토큰은 Audience Builder와 클라이언트 콜백에 사용되며, 앱 제거(uninstall) 및 재설치 (reinstall) 트래킹을 위해 필수입니다.


### <a id="pre-installed-trackers">사전 설치 트래커

Adjust SDK를 사용하여 앱이 사전 설치된 기기를 지닌 사용자를 인식하고 싶다면 다음 절차를 따르세요.

1. [대시보드](adjust.com)에 새 트래커를 생성합니다.
2. 앱 델리케이트를 열어 `ADJConfig` 기본값 트래커를 다음과 같이 설정합니다.

  ```objc
  ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
  [adjustConfig setDefaultTracker:@"{TrackerToken}"];
  [Adjust appDidLaunch:adjustConfig];
  ```

`{TrackerToken}`을 2에서 생성한 트래커 토큰으로 대체합니다. 대시보드에서는 (`http://app.adjust.com/`을 포함하는) 트래커 URL을 표시한다는 사실을 명심하세요. 소스코드에서는 전체 URL을 표시할 수 없으며 6자로 이루어진 토큰만을 명시해야 합니다.

3. 앱 빌드를 실행하세요. 앱 로그 출력 시 다음과 같은 라인을 볼 수 있을 것입니다.

```
Default tracker: 'abc123'
```

### <a id="deeplinking">딥링크

URL에서 앱으로 딥링크를 거는 옵션이 있는 Adjust 트래커 URL을 사용하고 있다면, 딥링크 URL과 그 내용 관련 정보를 얻을 가능성이 있습니다. 해당 URL 클릭 시 사용자가 이미 앱을 설치한 상태(기본 딥링크)일 수도, 앱을 설치하지 않은 상태(지연된 딥링크)일 수도 있습니다. Adjust SDK는 두 가지 상황을 모두 지원하며, 어느 상황이든 트래커 URL을 클릭하여 앱이 시작되는 경우 딥링크 URL을 제공합니다. 지원합니다. 앱에서 이 기능을 사용하려면 올바로 설정해야 합니다.

#### <a id="deeplinking-standard">표준 딥링크 시나리오

사용자가 앱을 설치하고 딥링크 정보가 들어간 트래커 URL을 클릭할 경우, 앱이 열리고 딥링크 내용이 앱으로 전달되어 이를 분석하고 다음 행동을 결정하게 됩니다. Apple은 iOS 9를 런칭하면서 앱에서의 딥링크 취급 방식을 바꿨습니다. 앱에 어떤 상황을 사용하고자 하는지에 따라 (또는 다양한 장치를 지원하기 위해 두 가지 다 사용하려 할 경우) 앱이 다음 상황 중 하나 또는 두 가지 다 취급할 수 있도록 설정해야 합니다. 

#### <a id="deeplinking-setup-old">iOS 8 이전 버전에서의 딥링크

iOS 8 이하 버전 장치에서 딥링크는 사용자 설정 URL 스킴 설정을 사용하여 이루어집니다. 따라서 앱이 여는 사용자 설정 URL 스킴명을 지정해야 합니다. 이 스킴명은 `deep_link` 파라미터의 일부분인 Adjust 트래커 URL에서도 사용합니다. 앱에서 설정하려면 `Info.plist` 파일을 열고 `URL types` 열을 새로 추가합니다. 그 다음 `URL identifier`가 앱 번들 ID를 작성할 때 `URL schemes`에서 앱이 취급할 스킴명을 추가하면 됩니다. 아래 예시에서는 앱이 `adjustExample` 스킴명을 취급하도록 설정하였습니다.

![][custom-url-scheme]

이 설정을 마치면, 선택한 스킴명이 들어있는 `deep_link` 파라미터가 들어간 Adjust 트래커 URL을 클릭 시 앱이 열립니다. 앱이 열리고 나면 `AppDelegate` 클래스의 `openURL` 메서드가 촉발되어 트래커 URL의 `deep_link` 파라미터 내용이 들어간 장소를 전송합니다. 딥링크 내용에 액세스하려면 아래 메소드를 재정의하세요.

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

이렇게 하면 iOS 8 이하 버전을 사용하는 iOS 기기에서 딥링크를 성공적으로 설정할 수 있습니다.  

#### <a id="deeplinking-setup-new">iOS 9 이후 버전에서의 딥링크

iOS 9 이상 버전 장치에서 딥링크를 설정하려면 앱이 Apple 유니버설 링크를 취급하도록 해야 합니다. 유니버설 링크 및 관련 설정에 대한 자세한 정보는 [여기][universal-links]를 참조하십시오.

Adjust는 유니버설 링크 관련 다양한 내용을 취급합니다. 그러나 Adjust로 유니버설 링크를 지원하려면 대시보드에서 약간의 설정이 필요합니다. 설정 절차에 관한 자세한 내용은 다음 [문서][universal-links-guide]를 참조하십시오.

대시보드에서 유니버설 링크 기능을 성공적으로 활성화하면 앱에서 다음 절차를 수행해야 합니다.

Apple Developer Portal에서 앱 `Associated Domains`를 활성화한 후, 이를 앱 Xcode 프로젝트에서도 똑같이 수행해야 합니다. `Associated Domains` 활성화를 마치고 나면, Adjust 대시보드에 생성한 유니버설 링크를 `applinks:` 접두어를 사용하여 `Domains` 섹션에 추가합니다. 유니버설 링크에서 `http(s)` 부분을 삭제하는 걸 잊지 마세요.

![][associated-domains-applinks]

이 설정을 마치고 나면, Adjust 트래커 유니버설 링크를 클릭 시 앱이 열립니다. 앱이 열리면 `AppDelegate` 클래스의 `continueUserActivity` 메서드가 촉발되어 유니버설 링크 URL 내용이 들어간 장소를 전송합니다. 딥링크 내용에 액세스하려면 아래 메서드를 재정의하세요.

```objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = [userActivity webpageURL];

        // url object contains your universal link content
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

이렇게 하면 iOS 9 이상 버전을 사용하는 iOS 기기에서 딥링크를 성공적으로 설정할 수 있습니다.  

코드에 사용한 사용자 설정 로직이 기존 스타일 사용자 설정 URL 스킴 포맷에 도착하기 위해 딥링크 정보가 필요한 경우, Adjust는 유니버설 링크를 기존 스타일 딥링크 URL로 변환하는 도움 함수를 제공합니다. 유니버설 링크 및 딥링크 접두어로 쓸 사용자 설정 URL 스킴명으로 이 메서드를 호출할 수 있습니다. 그러면 Adjust가 사용자 설정 URL 스킴 딥링크를 생성해 드립니다.

```objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    if ([[userActivity activityType] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = [userActivity webpageURL];

        NSURL *oldStyleDeeplink = [Adjust convertUniversalLink:url scheme:@"adjustExample"];
    }

    // Apply your logic to determine the return value of this method
    return YES;
    // or
    // return NO;
}
```

#### <a id="deeplinking-deferred">지연 딥링크(deferred deeplink) 시나리오

지연된 딥링크가 열리기 전에 알림을 받을 델리게이트 콜백을 등록하고 Adjust SDK에서 딥링크를 열도록 할 것인지 결정할 수 있습니다. [속성 콜백](#attribution-callback) 및 [이벤트 및 세션 콜백](#event-session-callbacks)에 사용되는 것과 동일한 선택적 프로토콜인 `AdjustDelegate`가 사용됩니다

동일한 단계로 지연된 딥링크에 대해 다음 델리게이트 콜백 함수를 구현하십시오.

```objc
- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    // deeplink object contains information about deferred deep link content

    // Apply your logic to determine whether the adjust SDK should try to open the deep link
    return YES;
    // or
    // return NO;
}
```

콜백 함수는 SDK에서 지연된 딥링크를 서버로부터 수신한 후 딥링크를 열기 전에 호출됩니다. 콜백 함수에서 딥링크에 액세스할 수 있으며, boolean 리턴값에 의해 SDK에서 딥링크를 실행할 것인지 결정합니다. 예를 들어 딥링크를 SDK에서 지금 열지 않고 딥링크를 저장한 후 나중에 직접 열도록 할 수 있습니다.

콜백을 실행하지 않을 경우, **Adjust SDK는 항상 기본값으로 딥링크를 엽니다**.

#### <a id="deeplinking-reattribution">딥링크를 통한 리어트리뷰션(reattribution)

Adjust는 딥링크를 사용하여 광고 캠페인 리인게이지먼트(re-engagement)를 수행할 수 있게 해줍니다. 이에 대한 자세한 정보는 [관련 문서][reattribution-with-deeplinks]를 참조하세요. 

이 기능을 사용 중이라면, 사용자를 올바로 리어트리뷰트하기 위해 앱에서 호출을 하나 더 수행해야 합니다.

앱에서 딥링크 내용을 수신했다면, `appWillOpenUrl` 메서드 호출을 추가하세요. 이 호출이 이루어지면 Adjust SDK는 딥링크 내에 새로운 어트리뷰션 정보가 있는지 확인하고, 새 정보가 있으면 Adjust 백엔드로 송신합니다. 딥링크 정보가 담긴 Adjust 트래커 URL을 클릭한 사용자를 리어트리뷰트해야 할 경우, 앱에서 해당 사용자의 새 어트리뷰션 정보로 [어트리뷰션 콜백](#attribution-callback)이 촉발되는 것을 확인할 수 있습니다. 

모든 iOS 버전에서 딥링크 리어트리뷰션을 지원하기 위한 `appWillOpenUrl` 호출은 다음과 같이 이루어집니다.

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

```objc
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

## <a id="troubleshooting">문제 해결

### <a id="ts-delayed-init">SDK 초기화 지연 문제

[기본 설정 단계](#basic-setup)의 설명처럼 Adjust SDK를 앱 delegate의 `didFinishLaunching` 또는 `didFinishLaunchingWithOptions` 메서드에서 초기화하는 것이 좋습니다. SDK의 모든 기능을 사용할 수 있도록 최대한 빨리 Adjust SDK를 초기화하는 것이 중요합니다.

Adjust SDK를 초기화하지 않기로 할 경우 앱 트래킹에 중대한 영향을 미칠 수 있으므로 다음 내용에 대해 잘 알고 있어야 합니다. **앱에서 모든 종류의 추적을 수행하려면 Adjust SDK를 *초기화해야* 합니다.**

SDK를 초기화하기 전에 아래 작업 중 하나를 수행하기로 하면

* [이벤트 추적](#event-tracking)
* [딥링크를 통한 리어트리뷰션(reattribution)](#deeplinking-reattribution)
* [추적 사용 중지](#disable-tracking)
* [오프라인 모드](#offline-mode)

`해당 작업은 수행되지 않습니다`.

Adjust SDK를 실제로 초기화하기 전에 하려고 했던 모든 작업을 수행하려면 앱에 `custom actions queueing mechanism`을 만들어야 합니다.

오프라인 모드 상태는 변경되지 않으며 추적 사용 가능/사용 중지 상태도 변경되지 않습니다. 딥링크 리어트리뷰션은 수행되지 않으며 추적된 이벤트는 모두 `삭제됩니다`.

세션 추적도 지연된 SDK의 영향을 받을 수 있습니다. Adjust SDK를 실제로 초기화하기 전에는 세션 길이 정보를 수집할 수 없습니다. 이 경우 대시보드에서 DAU 수치가 올바로 추적되지 않을 수 있습니다.

예를 들어, 특정 뷰나 뷰 컨트롤러가 로드되면 Adjust SDK를 시작하고 사용자가 앱의 스플래시 화면 또는 처음 화면이 아닌 홈 화면에서 이 뷰로 이동해야 한다고 가정해 봅시다. 사용자가 앱을 다운로드하고 열면 홈 화면이 표시됩니다. 이 때 추적이 필요한 설치를 수행했는데, 이 사용자는 특정 광고 캠페인에서 왔을 수 있고 앱을 시작했으며 자신의 장치에서 세션을 만들었으므로 해당 사용자는 실제로 앱의 일일 활성 사용자였습니다. 하지만 Adjust SDK는 이런 내용에 대해 전혀 모릅니다. 사용자가 이 SDK를 초기화하기로 결정한 화면으로 이동해야 하기 때문입니다. 사용자가 홈 화면을 본 후 바로 앱을 제거하기로 결정하면, 위에서 언급한 모든 정보는 Adjust SDK에 의해 추적되거나 대시보드에 표시되지 않습니다.

#### 이벤트 추적

추적할 이벤트를 내부 대기열 메커니즘으로 정렬하여 대기열로 보낸다음 SDK가 초기화된 후 이벤트를 추적합니다. SDK를 초기화하기 전에 이벤트를 추적하면 이벤트가 `영구 삭제`되므로, SDK가 초기화되고 [사용 가능](#is-enabled)으로 설정된 후에 이벤트가 추적되는지 확인하십시오.

#### 오프라인 모드와 추적 사용/사용 중지

오프라인 모드는 SDK 초기화 후에도 계속 실행되는 기능이 아니므로 기본적으로 `false`로 설정됩니다. SDK를 초기화하기 전에 오프라인 모드를 사용하도록 설정하면 나중에 SDK를 초기화해도 `false`로 설정됩니다.

추적 사용/사용 중지 설정은 SDK 초기화 후에도 유지됩니다. SDK를 초기화하기 전에 이 값을 토글하려고 하면 그 시도는 무시됩니다. 초기화된 SDK는 토글 시도 전의 상태(사용 또는 사용 중지)로 유지됩니다.

#### 딥링크를 통한 리어트리뷰션(reattribution)

[위 단계](#deeplinking-reattribution)에서 설명한 대로, 딥링크 리어트리뷰션을 처리할 때에는 사용하는 딥링크 연결 메커니즘(이전 방식 또는 universal link)에 따라 `NSURL` 개체를 얻게 되고 그런 다음 아래와 같이 호출을 수행해야 합니다.

```objc
[Adjust appWillOpenUrl:url]
```

SDK가 초기화되기 전에 이 호출을 수행하면 사용자가 클릭하고 리어트리뷰션되었어야 할 URL의 딥링크에 대한 정보를 영구적으로 잃게 됩니다. Adjust SDK에서 사용자를 성공적으로 리어트리뷰션하려면, SDK가 초기화된 후 이 `NSURL` 개체 정보를 대기열로 보내고 `appWillOpenUrl` 메서드를 촉발시켜야 합니다.

#### 세션 추적

세션 추적은 Adjust SDK에서 자동으로 수행하므로 앱 개발자가 제어할 수 없습니다. 올바른 세션 추적을 위해서는 이 추가 정보에서 권장하는 방법으로 Adjust SDK를 초기화해야 합니다. 그렇지 않으면 올바른 세션 추적 및 대시보드의 DAU 수치에 중대한 영향을 미칩니다. 예를 들어 다음과 같은 문제가 발생할 수 있습니다.

* SDK가 초기화되기도 전에 사용자가 앱을 삭제하여 설치와 세션이 추적되지 않고, 따라서 대시보드에서 보고되지 않음.
* 자정 전에 사용자가 앱을 다운로드하고 연 다음 자정이 지난 후 Adjust SDK가 초기화됨으로써 설치 및 세션이 다른 날에 보고됨.
* 사용자가 같은 날에 앱을 사용하지 않고 자정 직후에 열고 자정이 지난 후에 SDK가 초기화되어 앱을 연 날이 아닌 날에 DAU가 보고됨.

따라서 이 설명서의 내용을 준수하고 Adjust SDK를 앱 델리게이트의 `didFinishLaunching` 또는 `didFinishLaunchingWithOptions` 메서드에서 초기화하십시오.

### <a id="ts-arc">"Adjust requires ARC" 오류가 나타납니다

빌드 시 `Adjust requires ARC` 오류가 발생할 경우 프로젝트에서 [ARC][arc]를 사용하지 않은 것이 원인일 수 있습니다. 이 경우 [ARC를 사용하도록 프로젝트를 전환][transition]하는 것이 좋습니다. ARC를 사용하지 않으려면 대상의 빌드 단계에서 Adjust의 모든 소스 파일에 ARC를 사용하도록 설정해야 합니다.

`Compile Sources` 그룹을 펼쳐 모든 Adjust 파일을 선택한 다음 `Compiler Flags`를 `-fobjc-arc`로 변경합니다. (모두 선택 후 `Return` 키를 눌러 동시에 변경)

### <a id="ts-categories">"[UIDevice adjTrackingEnabled]: unrecognized selector sent to instance" 오류가 나타납니다

이 오류는 Adjust SDK 프레임워크를 앱에 추가하는 경우 발생할 수 있습니다. Adjust SDK의 소스 파일에는 `categories`가 포함되어 있기 때문에 이 SDK 연동 방법을 선택한 경우 Xcode 프로젝트 설정에서 `-ObjC` 플래그를 `Other Linker Flags`에 추가해야 합니다. 이 플래그를 추가하면 오류가 해결됩니다.

### <a id="ts-session-failed">"Session failed (Ignoring too frequent session.)" 오류가 나타납니다

이 오류는 일반적으로 설치를 테스트할 때 발생합니다. 앱을 제거하고 다시 설치해도 새 설치를 촉발시킬 수 없습니다. 서버에서는 SDK가 로컬에서 집계된 세션 데이터를 유실했다고 판단하며 서버에 제공된 기기 관련 정보에 따라 오류 메시지를 무시합니다.

이 동작은 테스트 중에 불편을 초래할 수도 있지만, sandbox 동작이 프로덕션 환경과 최대한 일치하도록 하기 위해 필요합니다.

기기의 세션 데이터를 Adjust 서버에서 재설정할 수 있습니다. 로그에서 다음 오류 메시지를 확인합니다.

```
Session failed (Ignoring too frequent session. Last session: YYYY-MM-DDTHH:mm:ss, this session: YYYY-MM-DDTHH:mm:ss, interval: XXs, min interval: 20m) (app_token: {yourAppToken}, adid: {adidValue})
```

아래에 `{yourAppToken}` 및 `{adidValue}` 또는 `{idfaValue}`값을 입력하고 다음 링크 중 하나를 엽니다.

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&adid={adidValue}
```

```
http://app.adjust.com/forget_device?app_token={yourAppToken}&idfa={idfaValue}
```

기기가 메모리에서 삭제되면 링크에서 `Forgot device`만 반환됩니다. 장치가 이미 메모리에서 삭제되었거나 값이 올바르지 않으면 `Device not found`가 반환됩니다.

### <a id="ts-install-tracked">로그에 "Install tracked"가 표시되지 않습니다

테스트 기기에서 앱 설치 시나리오를 시뮬레이션하려는 경우 이미 앱이 설치되어 있는 테스트 기기의 Xcode에서 앱을 다시 실행하는 것만으로는 충분하지 않습니다. Xcode에서 앱을 다시 실행하면 앱 데이터가 모두 삭제되지 않고 Adjust SDK가 앱에 보관하는 모든 내부 파일이 유지되므로, Adjust SDK는 해당 파일을 확인한 후 앱이 이미 설치되어 있고 SDK가 앱에서 이미 시작되었지만 처음 열린 게 아니라 한 번 더 열렸을 뿐이라고 인식합니다.

앱 설치 시나리오를 실행하려면 다음 작업을 수행해야 합니다.

* 기기에서 앱을 제거합니다. (완전 제거)
* [위](#forget-device) 문제에서 설명한 대로 테스트 기기를 Adjust 백엔드에서 삭제합니다.
* 테스트 기기의 Xcode에서 앱을 실행하면 "Install tracked" 로그 메시지가 표시됩니다.

### <a id="ts-iad-sdk-click">"Unattributable SDK click ignored" 메시지가 표시됩니다.

앱을 `sandbox` 환경에서 테스트하는 중에 이 메시지가 표시될 수 있습니다. 이 메시지는 Apple이 `iAd.framework` 버전 3에서 변경한 내용과 관련이 있습니다. 사용자가 iAd 배너를 클릭하면 앱으로 이동될 수 있으며, 이로 인해 Adjust SDK에서 `sdk_click` 패키지를 Adjust 백엔드로 보내 클릭된 URL의 내용에 대해 알릴 수 있습니다. Apple은 iAd 배너를 클릭하지 않았는데 앱이 열릴 경우 임의의 값을 사용하여 iAd 배너 URL 클릭을 인위적으로 생성하기로 했습니다. Adjust SDK는 iAd 배너 클릭이 진짜인지 인위적으로 생성된 것인지 구별할 수 없으므로 모든 경우에 `sdk_click` 패키지를 Adjust 백엔드로 보냅니다. 로그 레벨을 `verbose` 레벨로 설정한 경우 이 `sdk_click` 패키지는 다음과 같이 표시됩니다.

```
[Adjust]d: Added package 1 (click)
[Adjust]v: Path:      /sdk_click
[Adjust]v: ClientSdk: ios4.7.0
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

이 `sdk_click`을 고려할 경우 사용자가 다른 캠페인 URL을 클릭하거나 유기적 사용자로서 앱을 열 경우 존재하지 않는 iAd 소스에 어트리뷰션되는 상황이 발생할 수 있습니다. 따라서 Adjust 백엔드는 이를 무시하고 다음 메시지를 통해 알립니다.

```
[Adjust]v: Response: {"message":"Unattributable SDK click ignored."}
[Adjust]i: Unattributable SDK click ignored.
```

따라서 이 메시지는 SDK 연동에 문제가 있다는 뜻이 아니며, Adjust 백엔드에서 사용자가 인위적으로 생성된 `sdk_click`을 무시함으로써 어트리뷰션/리어트리뷰션이 잘못 이루어되는 결과를 초래했을 가능성이 있음을 알려줄 뿐입니다.

### <a id="ts-wrong-revenue-amount">Adjust 대시보드에 잘못된 매출 데이터가 있습니다

Adjust SDK는 지정한 대상만 추적합니다. 매출을 이벤트에 연결하는 경우, 금액으로 작성하는 숫자만 Adjust 백엔드에 도달하며 대시보드에 표시되는 유일한 금액이 됩니다. Adjust SDK는 금액 값을 조작하지 않으며 Adjust 백엔드도 마찬가지입니다. 따라서 추적 금액이 틀렸다면 Adjust SDK에서 해당 금액을 추적하도록 지시받았기 때문입니다.

사용자 매출 이벤트 추적 코드는 일반적으로 다음과 같습니다.

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

추적하도록 지정한 값이 아닌 다른 값이 대시보드에 보일 경우 **금액 값 결정 로직을 확인하십시오**.


[dashboard]:   http://adjust.com
[adjust.com]:  http://adjust.com

[en-readme]:  ../../README.md
[zh-readme]:  ../chinese/README.md
[ja-readme]:  ../japanese/README.md
[ko-readme]:  ../korean/README.md

[sdk2sdk-mopub]:  ../korean/sdk-to-sdk/mopub.md

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
[event-tracking]:    https://docs.adjust.com/ko/event-tracking
[example-iwatch]:    http://github.com/adjust/ios_sdk/tree/master/examples/AdjustExample-iWatch
[callbacks-guide]:   https://docs.adjust.com/ko/callbacks
[universal-links]:   https://developer.apple.com/library/ios/documentation/General/Conceptual/AppSearch/UniversalLinks.html

[special-partners]:     https://docs.adjust.com/ko/special-partners
[attribution-data]:     https://github.com/adjust/sdks/blob/master/doc/attribution-data.md
[ios-web-views-guide]:  doc/english/web_views.md
[currency-conversion]:  https://docs.adjust.com/ko/event-tracking/#part-7

[universal-links-guide]:      https://docs.adjust.com/ko/universal-links/
[adjust-universal-links]:     https://docs.adjust.com/ko/universal-links/
[universal-links-testing]:    https://docs.adjust.com/ko/universal-links/#part-4
[reattribution-deeplinks]:    https://docs.adjust.com/ko/deeplinking/#part-6-1
[ios-purchase-verification]:  https://github.com/adjust/ios_purchase_sdk/tree/master/doc/korean

[reattribution-with-deeplinks]:   https://docs.adjust.com/ko/deeplinking/#part-6-1

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

[associated-domains-applinks]:          https://raw.github.com/adjust/sdks/master/Resources/ios/associated-domains-applinks.png
[universal-links-dashboard-values]: https://raw.github.com/adjust/sdks/master/Resources/ios/universal-links-dashboard-values5.png

## <a id="license">라이선스

Adjust SDK는 MIT 라이선스에 따라 사용이 허가됩니다.

Copyright (c) 2012-2019 Adjust GmbH, http://www.adjust.com

이로써 본 소프트웨어와 관련 문서 파일(이하 "소프트웨어")의 복사본을 받는 사람에게는 아래 조건에 따라 소프트웨어를 제한 없이 다룰 수 있는 권한이 무료로 부여됩니다. 이 권한에는 소프트웨어를 사용, 복사, 수정, 병합, 출판, 배포 및/또는 판매하거나 2차 사용권을 부여할 권리와 소프트웨어를 제공 받은 사람이 소프트웨어를 사용, 복사, 수정, 병합, 출판, 배포 및/또는 판매하거나 2차 사용권을 부여하는 것을 허가할 수 있는 권리가 제한 없이 포함됩니다.

위 저작권 고지문과 본 권한 고지문은 소프트웨어의 모든 복사본이나 주요 부분에 포함되어야 합니다.

소프트웨어는 상품성, 특정 용도에 대한 적합성 및 비침해에 대한 보증 등을 비롯한 어떤 종류의 명시적이거나 암묵적인 보증 없이 "있는 그대로" 제공됩니다. 어떤 경우에도 저작자나 저작권 보유자는 소프트웨어와 소프트웨어의 사용 또는 기타 취급에서 비롯되거나 그에 기인하거나 그와 관련하여 발생하는 계약 이행 또는 불법 행위 등에 관한 배상 청구, 피해 또는 기타 채무에 대해 책임지지 않습니다.
--END--
