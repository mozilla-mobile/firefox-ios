
def test_sync_bookmark_from_device(tps, xcodebuild):
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncBookmark')
    tps.run('test_bookmark.js')

def test_sync_bookmark_from_desktop(tps, xcodebuild):
    tps.run('test_bookmark_desktop.js')
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncBookmarkDesktop')

def test_sync_history_from_device(tps, xcodebuild):
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncHistory')
    tps.run('test_history.js')

def test_sync_tabs_from_device(tps, xcodebuild):
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncTabs')
    tps.run('test_tabs.js')

def test_sync_history_from_desktop(tps, xcodebuild):
    tps.run('test_history_desktop.js')
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncHistoryDesktop')
'''
def test_sync_logins_from_device(tps, xcodebuild):
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncLogins')
    tps.run('test_password.js')
'''
def test_sync_logins_from_desktop(tps, xcodebuild):
    tps.run('test_password_desktop.js')
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncPasswordDesktop')

def test_sync_tabs_from_desktop(tps, xcodebuild):
    tps.run('test_tabs_desktop.js')
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncTabsDesktop')

def test_sync_disconnect_connect_fxa(tps, xcodebuild):
    tps.run('test_bookmark_login.js')
    xcodebuild.test('XCUITests/IntegrationTests/testFxADisconnectConnect')
 