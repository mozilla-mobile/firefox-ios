// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import ComponentLibrary
import Common

protocol SearchEnginePickerDelegate: AnyObject {
    func searchEnginePicker(
        _ searchEnginePicker: SearchEnginePicker?,
        didSelectSearchEngine engine: OpenSearchEngine?
    )
}

final class SearchSettingsTableViewController: ThemedTableViewController, FeatureFlaggable {
    // MARK: - Properties
    private enum Section: Int, CaseIterable {
        case defaultEngine
        case alternateEngines
        case searchEnginesSuggestions
        case firefoxSuggestSettings

        var title: String {
            switch self {
            case .defaultEngine:
                return .Settings.Search.DefaultSearchEngineTitle
            case .alternateEngines:
                return .Settings.Search.AlternateSearchEnginesTitle
            case .searchEnginesSuggestions:
                return .Settings.Search.EnginesSuggestionsTitle
            case .firefoxSuggestSettings:
                return String.localizedStringWithFormat(
                    .Settings.Search.Suggest.AddressBarSettingsTitle,
                    AppName.shortName.rawValue
                )
            }
        }
    }

    private let profile: Profile
    private let model: SearchEnginesManager
    private let logger: Logger

    var shouldHidePrivateModeFirefoxSuggestSetting: Bool {
        return !model.shouldShowBookmarksSuggestions &&
        !model.shouldShowSyncedTabsSuggestions &&
        !model.shouldShowBrowsingHistorySuggestions
    }

    private enum SearchSuggestItem: Int, CaseIterable {
        case defaultSuggestions
        case privateSuggestions
    }

    private enum FirefoxSuggestItem: Int, CaseIterable {
        case browsingHistory
        case bookmarks
        case syncedTabs
        case nonSponsored
        case sponsored
        // Disable temporary `privateSuggestions` option for Enhanced Firefox Suggest Experiment v125.
        // https://mozilla-hub.atlassian.net/browse/FXIOS-8908
//        case privateSuggestions
        case suggestionLearnMore
    }

    private let IconSize = CGSize(width: OpenSearchEngine.UX.preferredIconSize,
                                  height: OpenSearchEngine.UX.preferredIconSize)

    private var showDeletion = false
    private var sectionsToDisplay: [SearchSettingsTableViewController.Section] = []

    private var isEditable: Bool {
        guard let defaultEngine = model.defaultEngine else { return false }

        // If the default engine is a custom one, make sure we have more than one since we can't edit the default.
        // Otherwise, enable editing if we have at least one custom engine.
        let customEngineCount = model.orderedEngines.filter({ $0.isCustomEngine }).count
        return defaultEngine.isCustomEngine ? customEngineCount > 1 : customEngineCount > 0
    }

    init(profile: Profile,
         windowUUID: WindowUUID,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
        model = profile.searchEnginesManager

        super.init(windowUUID: windowUUID)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle Methods
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

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedSubtitleTableViewCell.cellIdentifier,
            for: indexPath
        ) as? ThemedSubtitleTableViewCell else {
            logger.log("Failed to dequeue ThemedSubtitleTableViewCell at indexPath: \(indexPath)",
                       level: .fatal,
                       category: .lifecycle)
            return UITableViewCell()
        }

        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine

        switch section {
        case .defaultEngine:
            guard let engine = model.defaultEngine else { break }
            cell.editingAccessoryType = .disclosureIndicator
            cell.accessibilityLabel = .Settings.Search.AccessibilityLabels.DefaultSearchEngine
            cell.accessibilityValue = engine.shortName
            cell.textLabel?.text = engine.shortName
            cell.imageView?.image = engine.image.createScaled(IconSize)
            cell.imageView?.layer.cornerRadius = 4
            cell.imageView?.layer.masksToBounds = true
            cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))

        case .alternateEngines:
            // The default engine is not an alternate search engine.
            let index = indexPath.item + 1
            if index < model.orderedEngines.count {
                let engine = model.orderedEngines[index]
                cell.showsReorderControl = true

                let toggle = ThemedSwitch()
                toggle.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
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
                cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            } else {
                cell.editingAccessoryType = .disclosureIndicator
                cell.accessibilityLabel = .SettingsAddCustomEngineTitle
                cell.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Search.customEngineViewButton
                cell.textLabel?.text = .SettingsAddCustomEngine
                cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }

        case .searchEnginesSuggestions:
            switch indexPath.item {
            case SearchSuggestItem.defaultSuggestions.rawValue:
                buildSettingWith(
                    prefKey: PrefsKeys.SearchSettings.showSearchSuggestions,
                    defaultValue: model.shouldShowSearchSuggestions,
                    titleText: String.localizedStringWithFormat(
                        .Settings.Search.ShowSearchSuggestions
                    ),
                    cell: cell,
                    selector: #selector(didToggleSearchSuggestions)
                )

            case SearchSuggestItem.privateSuggestions.rawValue:
                if featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) {
                    buildSettingWith(
                        prefKey: PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions,
                        defaultValue: model.shouldShowPrivateModeSearchSuggestions,
                        titleText: String.localizedStringWithFormat(
                            .Settings.Search.PrivateSessionSetting
                        ),
                        statusText: String.localizedStringWithFormat(
                            .Settings.Search.PrivateSessionDescription
                        ),
                        cell: cell,
                        selector: #selector(didToggleShowSearchSuggestionsInPrivateMode)
                    )
                }
            default: break
            }

        case .firefoxSuggestSettings:
            switch indexPath.item {
            case FirefoxSuggestItem.browsingHistory.rawValue:
                buildSettingWith(
                    prefKey: PrefsKeys.SearchSettings.showFirefoxBrowsingHistorySuggestions,
                    defaultValue: model.shouldShowBrowsingHistorySuggestions,
                    titleText: String.localizedStringWithFormat(
                        .Settings.Search.Suggest.SearchBrowsingHistory
                    ),
                    cell: cell,
                    selector: #selector(didToggleBrowsingHistorySuggestions)
                )

            case FirefoxSuggestItem.bookmarks.rawValue:
                buildSettingWith(
                    prefKey: PrefsKeys.SearchSettings.showFirefoxBookmarksSuggestions,
                    defaultValue: model.shouldShowBookmarksSuggestions,
                    titleText: String.localizedStringWithFormat(
                        .Settings.Search.Suggest.SearchBookmarks
                    ),
                    cell: cell,
                    selector: #selector(didToggleBookmarksSuggestions)
                )

            case FirefoxSuggestItem.syncedTabs.rawValue:
                buildSettingWith(
                    prefKey: PrefsKeys.SearchSettings.showFirefoxSyncedTabsSuggestions,
                    defaultValue: model.shouldShowSyncedTabsSuggestions,
                    titleText: String.localizedStringWithFormat(
                        .Settings.Search.Suggest.SearchSyncedTabs
                    ),
                    cell: cell,
                    selector: #selector(didToggleSyncedTabsSuggestions)
                )

            case FirefoxSuggestItem.nonSponsored.rawValue:
                if featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) {
                    buildSettingWith(
                        prefKey: PrefsKeys.SearchSettings.showFirefoxNonSponsoredSuggestions,
                        defaultValue: model.shouldShowFirefoxSuggestions,
                        titleText: String.localizedStringWithFormat(
                            .Settings.Search.Suggest.ShowNonSponsoredSuggestionsTitle
                        ),
                        statusText: String.localizedStringWithFormat(
                            .Settings.Search.Suggest.ShowNonSponsoredSuggestionsDescription,
                            AppName.shortName.rawValue
                        ),
                        cell: cell,
                        selector: #selector(didToggleEnableNonSponsoredSuggestions)
                    )
                }

            case FirefoxSuggestItem.sponsored.rawValue:
                if featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) {
                    buildSettingWith(
                        prefKey: PrefsKeys.SearchSettings.showFirefoxSponsoredSuggestions,
                        defaultValue: model.shouldShowSponsoredSuggestions,
                        titleText: String.localizedStringWithFormat(
                            .Settings.Search.Suggest.ShowSponsoredSuggestionsTitle
                        ),
                        statusText: String.localizedStringWithFormat(
                            .Settings.Search.Suggest.ShowSponsoredSuggestionsDescription,
                            AppName.shortName.rawValue
                        ),
                        cell: cell,
                        selector: #selector(didToggleEnableSponsoredSuggestions)
                    )
                }

//            case FirefoxSuggestItem.privateSuggestions.rawValue:
//                buildSettingWith(
//                    prefKey: PrefsKeys.SearchSettings.showPrivateModeFirefoxSuggestions,
//                    defaultValue: model.shouldShowPrivateModeFirefoxSuggestions,
//                    titleText: String.localizedStringWithFormat(
//                        .Settings.Search.PrivateSessionSetting
//                    ),
//                    statusText: String.localizedStringWithFormat(
//                        .Settings.Search.Suggest.PrivateSessionDescription
//                    ),
//                    cell: cell,
//                    selector: #selector(didToggleShowFirefoxSuggestionsInPrivateMode)
//                )
//                cell.isHidden = shouldHidePrivateModeFirefoxSuggestSetting

            case FirefoxSuggestItem.suggestionLearnMore.rawValue:
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
                cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))

            default:
                break
            }
        }

        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = .zero

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sectionsToDisplay = [
            .defaultEngine,
            .alternateEngines,
            .searchEnginesSuggestions,
            .firefoxSuggestSettings
        ]
        return sectionsToDisplay.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Section(rawValue: sectionsToDisplay[section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine:
            return 1
        case .alternateEngines:
            // The first engine -- the default engine -- is not shown in the alternate search engines list.
            // But the option to add a Search Engine is.
            return model.orderedEngines.count
        case .searchEnginesSuggestions:
            return featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
            ? SearchSuggestItem.allCases.count : 1
        case .firefoxSuggestSettings:
            return featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser)
            ? FirefoxSuggestItem.allCases.count : 3
        }
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine:
            guard indexPath.item == 0 else { return nil }
            let searchEnginePicker = SearchEnginePicker(windowUUID: windowUUID)
            // Order alphabetically, so that picker is always consistently ordered.
            // Every engine is a valid choice for the default engine, even the current default engine.
            searchEnginePicker.engines = model.orderedEngines.sorted { e, f in e.shortName < f.shortName }
            searchEnginePicker.delegate = self
            searchEnginePicker.selectedSearchEngineName = model.defaultEngine?.shortName
            navigationController?.pushViewController(searchEnginePicker, animated: true)
        case .alternateEngines:
            let isLastItem = indexPath.item + 1 == model.orderedEngines.count
            guard isLastItem else { return nil }
            let customSearchEngineForm = CustomSearchViewController(windowUUID: windowUUID)
            customSearchEngineForm.profile = self.profile
            customSearchEngineForm.successCallback = {
                guard let window = self.view.window else { return }
                SimpleToast().showAlertWithText(.ThirdPartySearchEngineAdded,
                                                bottomContainer: window,
                                                theme: self.themeManager.getCurrentTheme(for: self.windowUUID))
            }
            navigationController?.pushViewController(customSearchEngineForm, animated: true)
        case .searchEnginesSuggestions:
            return nil
        case .firefoxSuggestSettings:
            guard indexPath.item == FirefoxSuggestItem.suggestionLearnMore.rawValue else { return nil }
            let viewController = SettingsContentViewController(windowUUID: windowUUID)
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
        case .defaultEngine, .searchEnginesSuggestions, .firefoxSuggestSettings:
            return UITableViewCell.EditingStyle.none
        case .alternateEngines:
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

//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        switch indexPath {
//        case IndexPath(
//                row: FirefoxSuggestItem.privateSuggestions.rawValue,
//                section: Section.firefoxSuggestSettings.rawValue):
//            if shouldHidePrivateModeFirefoxSuggestSetting { return 0 }
//        default: return UITableView.automaticDimension
//        }
//        return UITableView.automaticDimension
//    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
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

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: sectionsToDisplay[indexPath.section].rawValue) ?? .defaultEngine
        switch section {
        case .defaultEngine, .searchEnginesSuggestions, .firefoxSuggestSettings:
            return false
        case .alternateEngines:
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
        // Make drag or drop available only for alternateEngines section
        guard proposedDestinationIndexPath.section == Section.alternateEngines.rawValue else {
            return sourceIndexPath
        }

        // Can't drag/drop over "Add Search Engine" button.
        if [sourceIndexPath.item, proposedDestinationIndexPath.item]
            .contains(where: { $0 + 1 == model.orderedEngines.count }) {
            return sourceIndexPath
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

    // MARK: - Private Methods
    private func buildSettingWith(
        prefKey: String,
        defaultValue: Bool,
        titleText: String,
        statusText: String? = nil,
        cell: UITableViewCell,
        selector: Selector
    ) {
        let setting = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            prefKey: prefKey,
            defaultValue: defaultValue,
            titleText: titleText,
            statusText: statusText
        )
        setting.onConfigureCell(cell, theme: themeManager.getCurrentTheme(for: windowUUID))
        setting.control.switchView.addTarget(
            self,
            action: selector,
            for: .valueChanged
        )
        cell.editingAccessoryView = setting.control
        cell.selectionStyle = .none
    }

    private func didToggleFirefoxSuggestions(
        _ toggle: ThemedSwitch,
        suggestionType: FirefoxSuggestItem
    ) {
//        var shouldShowPrivateSuggestionsSetting = false
        switch suggestionType {
        case .browsingHistory:
            model.shouldShowBrowsingHistorySuggestions = toggle.isOn
//            shouldShowPrivateSuggestionsSetting = model.shouldShowBrowsingHistorySuggestions &&
//            !model.shouldShowBookmarksSuggestions &&
//            !model.shouldShowSyncedTabsSuggestions
        case .bookmarks:
            model.shouldShowBookmarksSuggestions = toggle.isOn
//            shouldShowPrivateSuggestionsSetting = model.shouldShowBookmarksSuggestions &&
//            !model.shouldShowBrowsingHistorySuggestions &&
//            !model.shouldShowSyncedTabsSuggestions
        case .syncedTabs:
            model.shouldShowSyncedTabsSuggestions = toggle.isOn
//            shouldShowPrivateSuggestionsSetting = model.shouldShowSyncedTabsSuggestions &&
//            !model.shouldShowBrowsingHistorySuggestions &&
//            !model.shouldShowBookmarksSuggestions
        default: break
        }

//        if shouldShowPrivateSuggestionsSetting {
//            updateCells(
//                at: [IndexPath(
//                    row: FirefoxSuggestItem.privateSuggestions.rawValue,
//                    section: Section.firefoxSuggestSettings.rawValue
//                )]
//            )
//        } else if shouldHidePrivateModeFirefoxSuggestSetting {
//            model.shouldShowPrivateModeFirefoxSuggestions = false
//            updateCells(
//                at: [IndexPath(
//                    row: FirefoxSuggestItem.privateSuggestions.rawValue,
//                    section: Section.firefoxSuggestSettings.rawValue
//                )]
//            )
//        }
    }

    private func updateCells(at indexPaths: [IndexPath]) {
        tableView.reloadRows(at: indexPaths, with: .automatic)
    }

    // MARK: - Theming System
    override func applyTheme() {
        super.applyTheme()
        tableView.separatorColor = themeManager.getCurrentTheme(for: windowUUID).colors.borderPrimary
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
    func didToggleShowFirefoxSuggestionsInPrivateMode(_ toggle: ThemedSwitch) {
        model.shouldShowPrivateModeFirefoxSuggestions = toggle.isOn
    }

    @objc
    func didToggleBrowsingHistorySuggestions(_ toggle: ThemedSwitch) {
        didToggleFirefoxSuggestions(toggle, suggestionType: .browsingHistory)
    }

    @objc
    func didToggleBookmarksSuggestions(_ toggle: ThemedSwitch) {
        didToggleFirefoxSuggestions(toggle, suggestionType: .bookmarks)
    }

    @objc
    func didToggleSyncedTabsSuggestions(_ toggle: ThemedSwitch) {
        didToggleFirefoxSuggestions(toggle, suggestionType: .syncedTabs)
    }

    @objc
    func didToggleEnableNonSponsoredSuggestions(_ toggle: ThemedSwitch) {
        model.shouldShowFirefoxSuggestions = toggle.isOn
        notificationCenter.post(name: .SponsoredAndNonSponsoredSuggestionsChanged)
    }

    @objc
    func didToggleEnableSponsoredSuggestions(_ toggle: ThemedSwitch) {
        model.shouldShowSponsoredSuggestions = toggle.isOn
        notificationCenter.post(name: .SponsoredAndNonSponsoredSuggestionsChanged)
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
            NotificationCenter.default.post(name: .SearchSettingsDidUpdateDefaultSearchEngine)
            self.tableView.reloadData()

            let engineID: String = engine.isCustomEngine ? "custom" : engine.engineID
            let extras = [TelemetryWrapper.EventExtraKey.preference.rawValue: "defaultSearchEngine",
                          TelemetryWrapper.EventExtraKey.preferenceChanged.rawValue: engineID]
            TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting, extras: extras)
        }
        _ = navigationController?.popViewController(animated: true)
    }
}
