# Features
EarlGrey offers features that make testing your app easier and more effective.


## Synchronization

Typically, you shouldn’t be concerned about synchronization as EarlGrey automatically synchronizes with the
UI, network requests, main [Dispatch Queue](https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html),
and the main [NSOperationQueue](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSOperationQueue_class/).
To support cases where you want to wait for some event to occur before the next UI interaction happens,
EarlGrey provides Synchronization APIs that allow you to control EarlGrey's synchronization behavior. You can
use these APIs to increase the stability of your tests. EarlGrey current synchronizes with the
following:

App Resource
-------------------------|
Main Dispatch Queues
Main NSOperationQueue
Animations
Gestures
Network
View Controller Appearance / Disappearance
Keyboard Typing
Scrolling
Main Run Loop
Web View

EarlGrey's synchronization works by tracking the states of different resources that can affect the
app's state and performing an action or an assertion only when the app is found to be idle. Based
on the structure of the app, this can affect the performance of the app when tested. EarlGrey
provides different `GREYConfiguration` values for mitigating these effects, such as changing the
maximum animation duration with `kGREYConfigKeyCALayerMaxAnimationDuration`, blacklisting long
network calls with kGREYConfigKeyURLBlacklistRegex or so.

## Visibility Checks<a name="visibility-checks"></a>

EarlGrey uses screenshot differential comparison (also known as 'screenshot diffs') to determine the
visibility of UI elements before interacting with them. As a result, you can be certain that a user can see
and interact with the UI that EarlGrey interacts with.

Note: Out-of-process (i.e. system generated) alert views and other modal dialogs that obscure the UI can
interfere with this process.

## User-Like Interaction

Taps and swipes are performed using app-level touch events, instead of using element-level event handlers.
Before every UI interaction, EarlGrey asserts that the elements being interacted with are actually visible
(see [Visibility Checks](#visibility-checks)) and not just present in the view hierarchy. EarlGrey's UI
interactions simulate how a real user would interact with your app's UI, and help you to find and fix the
same bugs that users would encounter in your app.

## Next Steps

* To get started with EarlGrey, see [Install and run](install-and-run.md).
* To learn about the EarlGrey APIs, see [APIs](api.md).
* To learn about known issues with EarlGrey, see [Known Issues](known-issues.md).
