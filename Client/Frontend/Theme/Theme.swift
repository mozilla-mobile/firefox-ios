/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import Foundation

protocol Themeable {
    func applyTheme()
}

protocol PrivateModeUI {
    func applyUIMode(isPrivate: Bool)
}

extension UIColor {
    static var theme: Theme {
        return ThemeManager.instance.current
    }
}

enum BuiltinThemeName: String {
    case normal
    case dark
}

// Convenience reference to these normal mode colors which are used in a few color classes.
fileprivate let defaultBackground = UIColor.Photon.Grey10
fileprivate let defaultSeparator = UIColor.Photon.Grey30

class TableViewColor {
    var rowBackground: UIColor { return UIColor.Photon.White100 }
    var rowText: UIColor { return UIColor.Photon.Grey90 }
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 }
    var separator: UIColor { return defaultSeparator }
    var headerBackground: UIColor { return defaultBackground }
    var headerText: UIColor { return UIColor.Photon.Grey50 }
    var rowActionAccessory: UIColor { return UIColor.Photon.Blue50 }
    var controlTint: UIColor { return rowActionAccessory }
    var syncText: UIColor { return UIColor.Photon.Grey80 }
    var errorText: UIColor { return UIColor.Photon.Red50 }
    var warningText: UIColor { return UIColor.Photon.Orange50 }
}

class URLBarColor {
    var border: UIColor { return UIColor.Photon.Grey50 }
    var activeBorder: UIColor { return UIColor.Photon.Blue50A30 }
    var tint: UIColor { return UIColor.Photon.Blue50A30 }
}

class BrowserColor {
    var background: UIColor { return defaultBackground }
    var urlBarDivider: UIColor { return UIColor.Photon.Grey90A10 }
    var locationBarBackground: UIColor { return UIColor.Photon.Grey30 }
    var tint: UIColor { return UIColor.Photon.Grey80 }
}

// The back/forward/refresh/menu button (bottom toolbar)
class ToolbarButtonColor {
    var selectedTint: UIColor { return UIColor.Photon.Blue40 }
    var disabledTint: UIColor { return UIColor.Photon.Grey30 }
}

class LoadingBarColor {
    var start: UIColor { return UIColor.Photon.Blue50A30 }
    var end: UIColor { return UIColor.Photon.Blue50 }
}

class TabTrayColor {
    var tabTitleText: UIColor { return UIColor.black }
    var background: UIColor { return UIColor.Photon.Grey80 }
    var cellBackground: UIColor { return defaultBackground }
    var toolbar: UIColor { return defaultBackground }
    var toolbarButtonTint: UIColor { return UIColor.Photon.Grey80 }
    var privateModeLearnMore: UIColor { return UIColor.Photon.Purple60 }
    var privateModePurple: UIColor { return UIColor.Defaults.MobilePrivatePurple }

    var privateModeButtonOffTint: UIColor { return toolbarButtonTint }
    var privateModeButtonOnTint: UIColor { return UIColor.Photon.Grey10 }
}

class TopTabsColor {
    var background: UIColor { return UIColor.Photon.Grey80 }
    var selectedLineNormalMode: UIColor { return UIColor.Photon.Blue60 }
    var selectedLinePrivateMode: UIColor { return UIColor.Photon.Purple50 }
    var buttonTint: UIColor { return UIColor.Photon.Grey40 }
    var privateModeButtonOffTint: UIColor { return buttonTint }
    var privateModeButtonOnTint: UIColor { return UIColor.Photon.Grey10 }
}

class TextFieldColor {
    var background: UIColor { return .white }
    var textAndTint: UIColor { return UIColor.Photon.Grey80 }
    var highlight: UIColor { return UIColor.Defaults.iOSTextHighlightBlue }
    var readerModeButtonSelected: UIColor { return UIColor.Photon.Blue40 }
    var readerModeButtonUnselected: UIColor { return UIColor.Photon.Grey50 }
    var pageOptionsSelected: UIColor { return readerModeButtonSelected }
    var pageOptionsUnselected: UIColor { return UIColor.theme.browser.tint }
    var separator: UIColor { return defaultSeparator }
}

class SearchInputColor {
    var title: UIColor { return UIColor.Photon.Grey40 }
    var input: UIColor { return UIColor.Photon.Blue50 }
    var border: UIColor { return defaultSeparator }
}

class HomePanelColor {
    var toolbarBackground: UIColor { return defaultBackground }
    var toolbarHighlight: UIColor { return UIColor.Photon.Blue50 }
    var toolbarTint: UIColor { return UIColor.Photon.Grey50 }

    var panelBackground: UIColor { return UIColor.white }
    var appBackground: UIColor { return defaultBackground }
    var separator: UIColor { return defaultSeparator }
    var border: UIColor { return UIColor.Photon.Grey60 }
    var buttonContainerBorder: UIColor { return separator }
    var backgroundColorPrivateMode: UIColor { return UIColor.Photon.Grey50 }
}

class SnackBarColor {
    var highlight: UIColor { return UIColor.Defaults.iOSTextHighlightBlue.withAlphaComponent(0.9) }
    var highlightText: UIColor { return UIColor.Photon.Blue60 }
    var border: UIColor { return UIColor.Photon.Grey30 }
    var title: UIColor { return UIColor.Photon.Blue50 }
}

class GeneralColor {
    var passcodeDot: UIColor { return UIColor.Photon.Grey60 }
    var highlightBlue: UIColor { return UIColor.Photon.Blue50 }
    var destructiveRed: UIColor { return UIColor.Photon.Red50 }
    var separator: UIColor { return defaultSeparator }
}

protocol Theme {
    var name: String { get }
    var tableView: TableViewColor { get }
    var urlbar: URLBarColor { get }
    var browser: BrowserColor { get }
    var toolbarButton: ToolbarButtonColor { get }
    var loadingBar: LoadingBarColor { get }
    var tabTray: TabTrayColor { get }
    var topTabs: TopTabsColor { get }
    var textField: TextFieldColor { get }
    var homePanel: HomePanelColor { get }
    var snackbar: SnackBarColor { get }
    var general: GeneralColor { get }
    var searchInput: SearchInputColor { get }
}

class NormalTheme: Theme {
    var name: String { return BuiltinThemeName.normal.rawValue }
    var tableView: TableViewColor { return TableViewColor() }
    var urlbar: URLBarColor { return URLBarColor() }
    var browser: BrowserColor { return BrowserColor() }
    var toolbarButton: ToolbarButtonColor { return ToolbarButtonColor() }
    var loadingBar: LoadingBarColor { return LoadingBarColor() }
    var tabTray: TabTrayColor { return TabTrayColor() }
    var topTabs: TopTabsColor { return TopTabsColor() }
    var textField: TextFieldColor { return TextFieldColor() }
    var homePanel: HomePanelColor { return HomePanelColor() }
    var snackbar: SnackBarColor { return SnackBarColor() }
    var general: GeneralColor { return GeneralColor() }
    var searchInput: SearchInputColor { return SearchInputColor() }
}
