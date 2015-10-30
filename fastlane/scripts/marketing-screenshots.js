#import "SnapshotHelper.js"
UIALogger.logDebug(deviceLanguage)
var link = "links/links_"+ deviceLanguage +".js"
UIALogger.logDebug(link)
#import link

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

UIALogger.logStart("MarketingScreenshots");

target.pushTimeout(40);

for(var i = 1; i < window.buttons().length; i++) {
    var button = window.buttons()[i];
    if (button.isVisible()) {
        button.tap();
    }
}

target.popTimeout();
captureLocalizedScreenshot('0-top-sites')
 
window.buttons()[4].tap();
captureLocalizedScreenshot('3-synced-tabs')

window.buttons()[1].tap();

target.pushTimeout(20);
window.staticTexts().firstWithName("1").tap();
target.popTimeout();

var addTab = window.buttons()[3]
if(addTab.checkIsValid()) {
    addTab.tap();
    window.textFields()["url"].tap();
    
    app.keyboard().typeString(links[0]);
    
    for(var i = 0; i < window.buttons().length; i++) {
        var button = window.buttons()[i];
        UIALogger.logDebug(i +": "+ button.label() +": "+ button.isVisible());
    }
    if( window.buttons()[7].checkIsValid() && window.buttons()[7].isVisible()){
        window.buttons()[7].tap();
    }
    
    app.keyboard().typeString("\n");
    target.delay(3);
    
    window.staticTexts().firstWithName("2").tap();
    window.buttons()[3].tap();
    window.textFields()["url"].tap();
    app.keyboard().typeString(links[1] +"\n");
    target.delay(3);
    
    window.staticTexts().firstWithName("3").tap();
    window.buttons()[3].tap();
    window.textFields()["url"].tap();
    app.keyboard().typeString(links[2] +"\n");
    target.delay(3);
    
    window.staticTexts().firstWithName("4").tap();
    window.buttons()[3].tap();
    window.textFields()["url"].tap();
    app.keyboard().typeString(links[3] +"\n");
    target.delay(3);
    window.textFields()["url"].tap();
    app.keyboard().typeString(links[4] +"\n");
    target.delay(3);
    
    window.staticTexts().firstWithName("5").tap();
    captureLocalizedScreenshot('2-tab-tray');

    window.collectionViews()[0].cells()["home"].tap();
    window.textFields()["url"].tap();
    app.keyboard().typeString("firefo");
    captureLocalizedScreenshot('1-search-results');
    
    window.buttons()[1].tap()
    
    UIALogger.logPass("MarketingScreenshots");
} else {
    UIALogger.logFail("MarketingScreenshots: Couldn't find 'Add Tab'");
}