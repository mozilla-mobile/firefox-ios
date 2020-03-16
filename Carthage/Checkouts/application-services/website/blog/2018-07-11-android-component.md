---
title: Firefox Accounts Android Component
author: Vlad Filippov
authorURL: https://github.com/vladikoff
---

The initial version of the Firefox Accounts Android component has been released as part of [android-components 0.12](https://github.com/mozilla-mobile/android-components/releases) several weeks ago.


<!--truncate-->


This new component consumes the new [fxa-client](https://github.com/mozilla/application-services/tree/master/components/fxa-client), which allows us to write things once and later cross-compile the code to different mobile platforms. As part of developing this component we utilize the following technologies: Rust, Kotlin, JNA, JOSE and more.

Since the initial release the [team](https://github.com/mozilla-mobile/android-components/graphs/contributors) already made various improvements, such as making method calls asynchronous, improving error handling and slimming down the size of the library. The component is available as a “tech preview” and you can try it in a [sample Android app](https://github.com/mozilla-mobile/android-components/tree/master/samples/firefox-accounts).

Here's some example code from the sample app:


```kt
open class MainActivity : AppCompatActivity() {

    // ...

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<View>(R.id.button).setOnClickListener {
            openOAuthTab()
        }

        Config.custom(CONFIG_URL).then { value: Config? ->
            value?.let {
                account = FirefoxAccount(it, CLIENT_ID)
                FxaResult.fromValue(account)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.action
        val data = intent.dataString

        if (Intent.ACTION_VIEW == action && data != null) {
            val txtView: TextView = findViewById(R.id.txtView)
            val url = Uri.parse(data)
            val code = url.getQueryParameter("code")
            val state = url.getQueryParameter("state")

            val handleAuth = { _: AccessTokenInfo? -> account?.getProfile() }
            val handleProfile = { value: Profile? ->
                value?.let {
                    runOnUiThread {
                        txtView.text = getString(R.string.signed_in, "${it.displayName ?: ""} ${it.email}")
                    }
                }
                FxaResult<Void>()
            }
            account?.completeOAuthFlow(code, state)?.then(handleAuth)?.then(handleProfile)
        }
    }

    private fun openTab(url: String) {
        val customTabsIntent = CustomTabsIntent.Builder()
                .addDefaultShareMenuItem()
                .setShowTitle(true)
                .build()

        customTabsIntent.intent.data = Uri.parse(url)
        customTabsIntent.launchUrl(this@MainActivity, Uri.parse(url))
    }

    private fun openOAuthTab() {
        val valueListener = { value: String? ->
            value?.let { openTab(it) }
            FxaResult<Void>()
        }

        account?.beginOAuthFlow(REDIRECT_URL, scopes, false)?.then(valueListener)
    }
    
    // ...
}
```

![](/application-services/img/blog/2018-07-11/and-comp2.jpg)
