## Facebook像素集成

[Facebook像素](https://www.facebook.com/business/help/952192354843755)是由Facebook提供的仅限于Web的分析工具。在过去，我们无法使用Facebook SDK来跟踪应用网页视图（Webview）中的像素事件。[FB SDK](https://developers.facebook.com/docs/analytics)4.34版本的发布使之成为可能，并通过[混合移动应用事件（Hybrid Mobile App Events）](https://developers.facebook.com/docs/app-events/hybrid-app-events)将Facebook像素事件转化为Facebook应用事件。

您现在还可通过Adjust SDK跟踪Facebook像素，而无需集成FB SDK。

## Facebook集成

### 示例应用

[`AdjustExample-FbPixel`目录][example-fbpixel]中的示例应用向您演示了如何使用Adjust网页视图SDK跟踪Facebook像素事件。

### Facebook应用ID

虽然无需集成FB SDK，但您必须遵循与FB SDK相同的一些集成步骤以将Facebook像素集成到Adjust SDK中。

如[FB SDK iOS SDK指南]（https://developers.facebook.com/docs/ios/getting-started/#xcode）中所述，您须将Facebook应用ID添加到应用中。 您可按照该指南中的步骤操作，同时我们将步骤复制如下：

- 在Xcode中，右键单击项目的`Info.plist`文件，然后选择Open As(打开方式) - > Source Code（源代码）。
- 在最后的`</ dict>`元素前将以下XML代码片段插入到文件正文中：

    ```xml
    <dict>
      ...
      <key>FacebookAppID</key>
      <string>{your-app-id}</string>
      ...
    </dict>
    ```

- 将`{your-app-id}`替换为您应用的应用ID（该ID可在*Facebook应用控制面板*中找到）。

### Facebook像素配置

请参考Facebook指南了解如何集成Facebook像素。Javascript代码应如下所示：

```js
<!-- Facebook Pixel Code -->
<script>
  !function(f,b,e,v,n,t,s)
    ...
  fbq('init', <YOUR_PIXEL_ID>);
  fbq('track', 'PageView');
</script>
...
<!-- End Facebook Pixel Code -->
```

现在，正如[混合移动应用事件指南]（https://developers.facebook.com/docs/app-events/hybrid-app-events）`Update Your Pixel（更新您的像素）`部分所述，您须更新Facebook像素代码如下：

```js
fbq('init', <YOUR_PIXEL_ID>);
fbq('set', 'mobileBridge', <YOUR_PIXEL_ID>, <YOUR_FB_APP_ID>);
```

**注意**：**非常重要**的一点是您必须首先调用''init'`并且之后立即调用`'set'`方法。Facebook提供给您需粘贴到HTML网页的代码片段（如上所示）包含调用`'init'`方法后的页面视图事件的`'track'`方法。为了正确跟踪此页面视图事件，请务必在两者之间调用`'set'`方法！

## Adjust集成

### 加载网页视图

请按照[iOS Web视图]（web_views.md）应用的集成指南进行操作。如下文加载网页视图桥：

```objc
- (void)viewWillAppear:(BOOL)animated {
    ...
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    // or with WKWebView:
    // WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];

    // add @property (nonatomic, strong) AdjustBridge *adjustBridge; on your interface
    self.adjustBridge = [[AdjustBridge alloc] init];
    [self.adjustBridge loadUIWebViewBridge:webView];
    // optionally you can add a web view delegate so that you can also capture its events
    // [self.adjustBridge loadUIWebViewBridge:webView webViewDelegate:(UIWebViewDelegate*)self];
    
    // or with WKWebView:
    // [self.adjustBridge loadWKWebViewBridge:webView];
    // optionally you can add a web view delegate so that you can also capture its events
    // [self.adjustBridge loadWKWebViewBridge:webView wkWebViewDelegate:(id<WKNavigationDelegate>)self];
    ...
```

无论您选择如何将网页视图加载到Adjust桥，请通过添加以下行来执行该步骤：

```objc
[self.adjustBridge augmentHybridWebView];
```

### 事件名称配置

Adjust网桥SDK将Facebook像素事件转化为Adjust事件。

因此，您必须将Facebook像素映射到特定的Adjust事件，或者在启动Adjust SDK和跟踪任意Facebook像素事件***之前***配置默认的Adjust事件识别码，包括从Facebook像素配置中复制粘贴的`fbq('track', 'PageView');`。

为了将Facebook像素事件映射到Adjust事件，请在初始化Adjust SDK之前在`adjustConfig`实例中调用`addFbPixelMapping（fbEventNameKey，adjEventTokenValue）`。应类似以下示例：

```js
adjustConfig.addFbPixelMapping('fb_mobile_search', adjustEventTokenForSearch);
adjustConfig.addFbPixelMapping('fb_mobile_purchase', adjustEventTokenForPurchase);
```

请注意，在跟踪Facebook像素事件：`fbq('track', 'Search', ...);` 和 `fbq('track', 'Purchase', ...);` 时应可实现匹配。但遗憾的是我们无法访问Javascript中跟踪的事件名称与FB SDK使用的事件名称之间的完整映射方案。

以下为到目前为止我们收集的事件名称信息，供您参考：

| 像素事件名称 | 对应Facebook应用事件名称
| ---------------- | -------------------------------------
| ViewContent      | fb_mobile_content_view
| Search           | fb_mobile_search
| AddToCart        | fb_mobile_add_to_cart
| AddToWishlist    | fb_mobile_add_to_wishlist
| InitiateCheckout | fb_mobile_initiated_checkout
| AddPaymentInfo   | fb_mobile_add_payment_info
| Purchase         | fb_mobile_purchase
| CompleteRegistration | fb_mobile_complete_registration

以上列表也许还不完整;Facebook也可能添加或更新当前列表。在测试时，请查看Adjust日志以获取提示信息，例如：

```
未就名称为：'fb_mobile_search'的事件配置默认事件识别码或找到匹配。它将不会被Adjust作为事件来跟踪。
```

如果您未配置映射，还可以选择使用默认的Adjust事件。您只需在初始化Adjust SDK之前调用`adjustConfig.setFbPixelDefaultEventToken（defaultEventToken）;`。

[example-fbpixel]:  ../../examples/AdjustExample-FbPixel
