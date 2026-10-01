#  TabDataStore

The purpose of this library is to manage tab data used in the process of the store and restore of the tabs. The system is backward compatible with the current system. 

To use this library you need to import TabDataStore and create a DefaultTabDataStore or any other class that conforms to TabDataStore protocol. The API allows saving and fetching window data, as well as clear all Window data from the disk.

# WindowData

WindowData allows multitasking on iPad where each scene will have its own window. WindowData is the root object saved in the store containing a UUID, a flag to know if this is the primary window, the UUID of the selected tab and the array of TabData. 

# TabData

Contains the saved tab data used to restore the Tab information. TabData contains the tab site url, title, group and more.

# TabSessionData

Saves the session data associated with a tab used during the process of tab restoration. Using the new API available from iOS 15 forwards the App doesn't need to handle previously saved session data.

# TabFileManager 

Wrapper over FileManager that provides the option to get the directory where tab session data and window data should be stored.

# Migration

During the migration we create a WindowData object and adapt the LegacySavedTab from the previous store system to the array of TabData of TabDataStore. We are using screenshotUUID from LegacySavedTab as the UUID for TabData struct.
