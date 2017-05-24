# Push more state into TabManager 
- Proposal 001
- Author: Farhan 
- Status: first draft


## Introduction
The TabManger, like the name suggests manages the tab object in the Firefox iOS browser. It handles creation/deletion of tabs, holds an array of all the open tabs and is also responsible for restoring and saving tabs between sessions. It is a class void of any UI and one I think that should have more responsibility. It is easy to test and a good place to store logic that is replicated between BVC/Toptabs/tabtray. We should try to push more things into TabManger which would simplify BVC,TopTabs and TabTray in the process. 

## Motivation

Pushing more things into TabManager will make it easier to test the complicated state. Right now things like switching between Private/Normal tabs happens outside of TM by moving it into the tabmanger we can easily write unit tests to test this behaviour. It’ll also make it so this logic only lives in one place. Right now this behaviour is duplicated between Toptabs and BVC. 
This also complicates TabManager events and how the UI reacts to it. For example when a user on an Ipad presses the private tab button the following happens. 

`tap event-> selectedTabEventFired ->BVC.SelectedTabEventCalled -> BVC.applyTheme -> TopTabs.applyTheme`

This makes it hard to understand Toptabs on its own. You need to understand how BVC behaves in order to understand TopTabs. 
 
## Proposed Solution
My solution is to add more events to the TabManger. By creating events for willEnterPrivateMode/didEnterPrivateMode, concerned classes can easily listen to these events and update their UI accordingly. We can store things such as which tab was the previously selected tab in TabManger itself instead of in TopTabs. We can write unit tests to make sure these events fire the way we like. Another thing we can move into the TabManager is checking if private tabs should be wiped when leaving private mode. Right now this check happens in a few different places and in the past we have missed this check and left private tabs lingering when they should have been deleted.

## Examples
The example in the motivation would become something like.
Tap event -> willEnterPrivateModeFired -> selectedTabEeventFired -> didEnterPrivateMode -> TopTabs.applyTheme.

## Impact on existing code
Because of how delicate the state is between BVC->TopTabs->TabTray this is a medium level change. Tests will not be able to cover this properly because a lot of the errors will be visual (the correct tab color not being applied.) But because this new functionality will be properly tested I feel that it’ll be worth the change.

## Alternatives Considered
None.





