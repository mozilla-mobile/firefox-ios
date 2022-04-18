/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class DataSource: UITableViewDiffableDataSource<SectionType, SectionItem> {

    init(
        tableView: UITableView,
        cellProvider: @escaping UITableViewDiffableDataSource<SectionType, SectionItem>.CellProvider,
        headerForSection: @escaping (SectionType) -> String?,
        footerForSection: @escaping (SectionType) -> String?
    ) {
        self.headerForSection = headerForSection
        self.footerForSection = footerForSection
        super.init(tableView: tableView, cellProvider: cellProvider)
    }

    private var headerForSection: (SectionType) -> String?
    private var footerForSection: (SectionType) -> String?

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = self.snapshot().sectionIdentifiers[section]
        return headerForSection(sectionType)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionType = self.snapshot().sectionIdentifiers[section]
        return footerForSection(sectionType)
    }
}
