def test_sync_bookmark_from_device(tps, xcodebuild):
    xcodebuild.test('XCUITests/IntegrationTests/testFxASyncBookmark')
    tps.run('test_bookmark.js')
