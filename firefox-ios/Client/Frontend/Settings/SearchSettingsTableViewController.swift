// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import ComponentLibrary

protocol SearchEnginePickerDelegate: AnyObject {
    func searchEnginePicker(
        _ searchEnginePicker: SearchEnginePicker?,
        didSelectSearchEngine engine: OpenSearchEngine?
    )
}

class SearchSettingsTableViewController: ThemedTableViewController, FeatureFlaggable {
    private enum Section: Int, CaseIterable {
        case defaultEngine
        case quickEngines
        case privateSession
        case firefoxSuggestSettings

        var title: String {
            switch self {
            case .defaultEngine:
                return .Settings.Search.DefaultSearchEngineTitle
            case .quickEngines:
                return .Settings.Search.QuickSearchEnginesTitle
            case .privateSession:
                return .Settings.Search.PrivateSessionTitle
            case .firefoxSuggestSettings:
                return String.localizedStringWithFormat(
                    .Settings.Search.Suggest.AddressBarSettingsTitle,
                    AppName.shortName.rawValue
                )
            }
        }
    }

    private let profile: Profile
    private let model: SearchEngines

    private let ItemDefaultEngine = 0
    private let ItemDefaultSuggestions = 1
    private let ItemSuggestionNonSponsored = 0
    private let ItemSuggestionSponsored = 1
    private let ItemSuggestionLearn = 2
    private let IconSize = CGSize(width: OpenSearchEngine.UX.preferredIconSize,
                                  height: OpenSearchEngine.UX.preferredIconSize)

    private var showDeletion = false
    private var sectionsToDisplay: [SearchSettingsTableViewController.Section] = []

    var updateSearchIcon: (() -> Void)?
    private var isEditable: Bool {
        guard let defaultEngine = model.defaultEngine else { return false }

        // If the default engine is a custom one, make sure we have more than one since we can't edit the default.
        // Otherwise, enable editing if we have at least one custom engine.
        let customEngineCount = model.orderedEngines.filter({ $0.isCustomEngine }).count
        return defaultEngine.isCustomEngine ? customEngineCount > 1 : customEngineCount > 0
    }

    init(profile: Profile) {
        self.profile = profile
        model = profile.searchEngines

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = .Settings.Search.Title

        // To allow re-ordering the list of search engines at all times.
        tableView.isEditing = true
        // So that we push the default search engine controller on selection.
        tableView.allowsSelectionDuringEditing = true

        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)
        tableView.register(ThemedSubtitleTableViewCell.self,
                           forCellReuseIdentifier: ThemedSubtitleTableViewCell.cellIdentifier)

        // Insert Done button if being presented outside of the Settings Nav stack
        if !(self.navigationController is ThemedNavigationController) {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: .SettingsSearchDoneButton,
                style: .done,
                target: self,
                action: #selector(self.dismissAnimated)
            )
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .SettingsSearchEditButton,
            style: .plain,
            target: self,
            action: #selector(beginEditing))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only show the Edit button if custom search engines are in the list.
        // Otherwise, there is nothing to delete.
        navigationItem.rightBarButtonItem?.isEnabled = isEditable
        tableView.reloadData()
        applyTheme()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setEditing(false, animated: false)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThemedSubtitleTableViewCell.cellIdentifier, for: indexPath)
        var engine: OpenSearchEngine!
        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine:
            switch indexPath.item {
            case ItemDefaultEngine:
                engine = model.defaultEngine
                cell.editingAccessoryType = .disclosureIndicator
                cell.accessibilityLabel = .Settings.Search.AccessibilityLabels.DefaultSearchEngine
                cell.accessibilityValue = engine.shortName
                cell.textLabel?.text = engine.shortName
                cell.imageView?.image = engine.image.createScaled(IconSize)
                cell.imageView?.layer.cornerRadius = 4
                cell.imageView?.layer.masksToBounds = true
            case ItemDefaultSuggestions:
                cell.textLabel?.text = .Settings.Search.ShowSearchSuggestions
                cell.textLabel?.numberOfLines = 0
                let toggle = ThemedSwitch()
                toggle.applyTheme(theme: themeManager.currentTheme)
                toggle.addTarget(self, action: #selector(didToggleSearchSuggestions), for: .valueChanged)
                toggle.isOn = model.shouldShowSearchSuggestions
                cell.editingAccessoryView = toggle
                cell.selectionStyle = .none
            default:
                // Should not happen.
                break
            }
        case .quickEngines:
            // The default engine is not a quick search engine.
            let index = indexPath.item + 1
            if index < model.orderedEngines.count {
                engine = model.orderedEngines[index]
                cell.showsReorderControl = true

                let toggle = ThemedSwitch()
                toggle.applyTheme(theme: themeManager.currentTheme)
                // This is an easy way to get from the toggle control to the corresponding index.
                toggle.tag = index
                toggle.addTarget(self, action: #selector(didToggleEngine), for: .valueChanged)
                toggle.isOn = model.isEngineEnabled(engine)

                cell.editingAccessoryView = toggle
                cell.textLabel?.text = engine.shortName
                cell.textLabel?.adjustsFontSizeToFitWidth = true
                cell.textLabel?.minimumScaleFactor = 0.5
                cell.textLabel?.numberOfLines = 0
                cell.imageView?.image = engine.image.createScaled(IconSize)
                cell.imageView?.layer.cornerRadius = 4
                cell.imageView?.layer.masksToBounds = true
                cell.selectionStyle = .none
            } else {
                cell.editingAccessoryType = .disclosureIndicator
                cell.accessibilityLabel = .SettingsAddCustomEngineTitle
                cell.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Search.customEngineViewButton
                cell.textLabel?.text = .SettingsAddCustomEngine
            }
        case .privateSession:
            cell.textLabel?.text = .Settings.Search.PrivateSessionSetting
            cell.textLabel?.numberOfLines = 0
            let toggle = ThemedSwitch()
            toggle.applyTheme(theme: themeManager.currentTheme)
            toggle.addTarget(self, action: #selector(didToggleShowSearchSuggestionsInPrivateMode), for: .valueChanged)
            toggle.isOn = model.shouldShowPrivateModeSearchSuggestions
            cell.editingAccessoryView = toggle
            cell.selectionStyle = .none
            cell.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Search.disableSearchSuggestsInPrivateMode
        case .firefoxSuggestSettings:
            switch indexPath.item {
            case ItemSuggestionNonSponsored:
                let setting = BoolSetting(
                    prefs: profile.prefs,
                    theme: themeManager.currentTheme,
                    prefKey: PrefsKeys.FirefoxSuggestShowNonSponsoredSuggestions,
                    defaultValue: profile.prefs.boolForKey(PrefsKeys.FirefoxSuggestShowNonSponsoredSuggestions) ?? true,
                    titleText: String.localizedStringWithFormat(
                        .Settings.Search.Suggest.ShowNonSponsoredSuggestionsTitle,
                        AppName.shortName.rawValue
                    ),
                    statusText: String.localizedStringWithFormat(
                        .Settings.Search.Suggest.ShowNonSponsoredSuggestionsDescription,
                        AppName.shortName.rawValue
                    )
                )
                setting.onConfigureCell(cell, theme: themeManager.currentTheme)
                setting.control.addTarget(
                    self,
                    action: #selector(didToggleEnableNonSponsoredSuggestions),
                    for: .valueChanged
                )
                cell.editingAccessoryView = setting.control
                cell.selectionStyle = .none
            case ItemSuggestionSponsored:
                let setting = BoolSetting(
                    prefs: profile.prefs,
                    theme: themeManager.currentTheme,
                    prefKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions,
                    defaultValue: profile.prefs.boolForKey(PrefsKeys.FirefoxSuggestShowSponsoredSuggestions) ?? true,
                    titleText: .Settings.Search.Suggest.ShowSponsoredSuggestionsTitle,
                    statusText: String.localizedStringWithFormat(
                        .Settings.Search.Suggest.ShowSponsoredSuggestionsDescription,
                        AppName.shortName.rawValue
                    )
                )
                setting.onConfigureCell(cell, theme: themeManager.currentTheme)
                setting.control.addTarget(
                    self,
                    action: #selector(didToggleEnableSponsoredSuggestions),
                    for: .valueChanged
                )
                cell.editingAccessoryView = setting.control
                cell.selectionStyle = .none
            case ItemSuggestionLearn:
                cell.accessibilityLabel = String.localizedStringWithFormat(
                    .Settings.Search.AccessibilityLabels.LearnAboutSuggestions,
                    AppName.shortName.rawValue
                )
                cell.textLabel?.text = String.localizedStringWithFormat(
                    .Settings.Search.Suggest.LearnAboutSuggestions,
                    AppName.shortName.rawValue
                )
                cell.imageView?.layer.cornerRadius = 4
                cell.imageView?.layer.masksToBounds = true
                cell.selectionStyle = .none

            default:
                break
            }
        }

        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = .zero

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sectionsToDisplay = [Section.defaultEngine, Section.quickEngines]
        if featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) {
            sectionsToDisplay.append(.firefoxSuggestSettings)
        }
        if featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) {
            sectionsToDisplay.append(.privateSession)
        }
        return sectionsToDisplay.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: sectionsToDisplay[section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine:
            return 2
        case .quickEngines:
            // The first engine -- the default engine -- is not shown in the quick search engine list.
            // But the option to add Custom Engine is.
            return model.orderedEngines.count
        case .privateSession:
            return 1
        case .firefoxSuggestSettings:
            return 3
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine:
            guard indexPath.item == ItemDefaultEngine else { return nil }
            let searchEnginePicker = SearchEnginePicker()
            // Order alphabetically, so that picker is always consistently ordered.
            // Every engine is a valid choice for the default engine, even the current default engine.
            searchEnginePicker.engines = model.orderedEngines.sorted { e, f in e.shortName < f.shortName }
            searchEnginePicker.delegate = self
            searchEnginePicker.selectedSearchEngineName = model.defaultEngine?.shortName
            navigationController?.pushViewController(searchEnginePicker, animated: true)
        case .quickEngines:
            let isLastItem = indexPath.item + 1 == model.orderedEngines.count
            guard isLastItem else { return nil }
            let customSearchEngineForm = CustomSearchViewController()
            customSearchEngineForm.profile = self.profile
            customSearchEngineForm.successCallback = {
                guard let window = self.view.window else { return }
                SimpleToast().showAlertWithText(.ThirdPartySearchEngineAdded,
                                                bottomContainer: window,
                                                theme: self.themeManager.currentTheme)
            }
            navigationController?.pushViewController(customSearchEngineForm, animated: true)
        case .privateSession:
            return nil
        case .firefoxSuggestSettings:
            guard indexPath.item == ItemSuggestionLearn else { return nil }
            let viewController = SettingsContentViewController()
            viewController.url = SupportUtils.URLForTopic("search-suggestions-firefox")
            navigationController?.pushViewController(viewController, animated: true)
        }
        return nil
    }

    // Don't show delete button on the left.
    override func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine, .privateSession, .firefoxSuggestSettings:
            return UITableViewCell.EditingStyle.none
        case .quickEngines:
            let isLastItem = indexPath.item + 1 == model.orderedEngines.count
            guard !isLastItem else {
                return UITableViewCell.EditingStyle.none
            }
            let index = indexPath.item + 1
            let engine = model.orderedEngines[index]
            return (self.showDeletion && engine.isCustomEngine) ? .delete : .none
        }
    }

    // Don't reserve space for the delete button on the left.
    override func tableView(
        _ tableView: UITableView,
        shouldIndentWhileEditingRowAt indexPath: IndexPath
    ) -> Bool {
        return false
    }

    override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // Change color of a thin vertical line that iOS renders between the accessoryView and the reordering control.
        for subview in cell.subviews where subview.classForCoder.description() == "_UITableViewCellVerticalSeparator" {
            subview.backgroundColor = themeManager.currentTheme.colors.borderPrimary
        }

        // Change re-order control tint color to match app theme
        for subViewA in cell.subviews where subViewA.classForCoder.description() == "UITableViewCellReorderControl" {
            for subViewB in subViewA.subviews {
                if let imageView = subViewB as? UIImageView {
                    imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
                    imageView.tintColor = themeManager.currentTheme.colors.iconSecondary
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as? ThemedTableSectionHeaderFooterView else { return nil }
        let section = Section(rawValue: sectionsToDisplay[section].rawValue) ?? .defaultEngine
        headerView.titleLabel.text = section.title

        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
        ) as? ThemedTableSectionHeaderFooterView else { return nil }
        if case .defaultEngine = Section(rawValue: section) {
            footerView.titleLabel.text = .Settings.Search.DefaultSearchEngineFooter
            footerView.titleAlignment = .top
        }
        footerView.applyTheme(theme: themeManager.currentTheme)
        return footerView
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine, .privateSession, .firefoxSuggestSettings:
            return false
        case .quickEngines:
            let isLastItem = indexPath.item + 1 == model.orderedEngines.count
            return isLastItem ? false : true
        }
    }

    override func tableView(
        _ tableView: UITableView,
        moveRowAt indexPath: IndexPath,
        to newIndexPath: IndexPath
    ) {
        // The first engine (default engine) is not shown in the list, so the indices are off-by-1.
        let index = indexPath.item + 1
        let newIndex = newIndexPath.item + 1
        let engine = model.orderedEngines.remove(at: index)
        model.orderedEngines.insert(engine, at: newIndex)
        tableView.reloadData()
    }

    // Snap to first or last row of the list of engines.
    override func tableView(
        _ tableView: UITableView,
        targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
        toProposedIndexPath proposedDestinationIndexPath: IndexPath
    ) -> IndexPath {
        // You can't drag or drop on the default engine.
        if sourceIndexPath.section == Section.defaultEngine.rawValue
            || proposedDestinationIndexPath.section == Section.defaultEngine.rawValue {
            return sourceIndexPath
        }

        // Can't drag/drop over "Add Custom Engine button"
        let sourceIndexCheck = sourceIndexPath.item + 1 == model.orderedEngines.count
        let destinationIndexCheck = proposedDestinationIndexPath.item + 1 == model.orderedEngines.count
        if sourceIndexCheck || destinationIndexCheck {
            return sourceIndexPath
        }

        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = tableView.numberOfRows(inSection: sourceIndexPath.section) - 1
            }
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let index = indexPath.item + 1
            let engine = model.orderedEngines[index]

            model.deleteCustomEngine(engine) { [weak self] in
                tableView.deleteRows(at: [indexPath], with: .right)
                // Change navigationItem's right button item title to Edit and disable the edit button
                // once the deletion is done
                self?.setEditing(false, animated: true)
            }

            // End editing if we are no longer edit since we've deleted all editable cells.
            if !isEditable {
                finishEditing()
            }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.isEditing = true
        showDeletion = editing
        UIView.performWithoutAnimation {
            self.navigationItem.rightBarButtonItem?.title = editing ? .SettingsSearchDoneButton : .SettingsSearchEditButton
        }
        navigationItem.rightBarButtonItem?.isEnabled = isEditable
        navigationItem.rightBarButtonItem?.action = editing ?
            #selector(finishEditing) : #selector(beginEditing)
        tableView.reloadData()
    }

    override func applyTheme() {
        super.applyTheme()
        tableView.separatorColor = themeManager.currentTheme.colors.borderPrimary
    }
}

// MARK: - Selectors
extension SearchSettingsTableViewController {
    @objc
    func didToggleEngine(_ toggle: ThemedSwitch) {
        let engine = model.orderedEngines[toggle.tag] // The tag is 1-based.
        if toggle.isOn {
            model.enableEngine(engine)
        } else {
            model.disableEngine(engine)
        }
    }

    @objc
    func didToggleSearchSuggestions(_ toggle: ThemedSwitch) {
        // Setting the value in settings dismisses any opt-in.
        model.shouldShowSearchSuggestions = toggle.isOn
    }

    @objc
    func didToggleShowSearchSuggestionsInPrivateMode(_ toggle: ThemedSwitch) {
        model.shouldShowPrivateModeSearchSuggestions = toggle.isOn
    }

    @objc
    func didToggleEnableNonSponsoredSuggestions(_ toggle: ThemedSwitch) {
        profile.prefs.setBool(toggle.isOn, forKey: PrefsKeys.FirefoxSuggestShowNonSponsoredSuggestions)
    }

    @objc
    func didToggleEnableSponsoredSuggestions(_ toggle: ThemedSwitch) {
        profile.prefs.setBool(toggle.isOn, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions)
    }

    func cancel() {
        _ = navigationController?.popViewController(animated: true)
    }

    @objc
    func dismissAnimated() {
        notificationCenter.post(name: .SearchSettingsChanged)
        dismiss(animated: true, completion: nil)
    }

    @objc
    func beginEditing() {
        setEditing(true, animated: false)
    }

    @objc
    func finishEditing() {
        setEditing(false, animated: false)
    }
}

extension SearchSettingsTableViewController: SearchEnginePickerDelegate {
    func searchEnginePicker(
        _ searchEnginePicker: SearchEnginePicker?,
        didSelectSearchEngine searchEngine: OpenSearchEngine?
    ) {
        if let engine = searchEngine {
            model.defaultEngine = engine
            updateSearchIcon?()
            self.tableView.reloadData()

            let extras = [TelemetryWrapper.EventExtraKey.preference.rawValue: "defaultSearchEngine",
                          TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: engine.engineID ?? "custom"]
            TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting, extras: extras)
        }
        _ = navigationController?.popViewController(animated: true)
    }
}
