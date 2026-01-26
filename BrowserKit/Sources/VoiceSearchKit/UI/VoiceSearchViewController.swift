// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class SearchContentView: UIView, UITableViewDelegate, UITableViewDataSource, ThemeApplicable {
    enum Content {
        case speechToTextResult(String)
        case aiResult(NSAttributedString)
    }
    
    private lazy var tableView: UITableView = .build {
        $0.delegate = self
        $0.dataSource = self
        $0.separatorStyle = .none
        $0.allowsSelection = false
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "speachResult")
    }

    // Sample data - replace with your actual search results
    private var items: [Content] = [
        .speechToTextResult("What was the results of Juve - Milan ?"),
        .aiResult(makeCustomAIResultAttributedString(title: "Juventus 2-1 Manchester City", content: "The match was won by the result of it an", links: ["google.com", "youtube.com"]))
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(tableView)
        tableView.pinToSuperview()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        switch item {
        case .speechToTextResult(let result):
            let cell = tableView.dequeueReusableCell(withIdentifier: "speachResult", for: indexPath)

            // Configure cell using UIListContentConfiguration
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = result
            contentConfiguration.textProperties.font = FXFontStyles.Regular.title2.scaledFont()

            cell.contentConfiguration = contentConfiguration
            cell.backgroundColor = .clear
            return cell

        case .aiResult(let attributedString):
            let cell = tableView.dequeueReusableCell(withIdentifier: "speachResult", for: indexPath)

            // Configure cell using UIListContentConfiguration with attributed text
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.attributedText = attributedString

            cell.contentConfiguration = contentConfiguration
            cell.backgroundColor = .clear
            return cell
        }
    }

    // MARK: - Attributed String Builders
    private static func makeCustomAIResultAttributedString(
        title: String,
        content: String,
        links: [String]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: FXFontStyles.Bold.title3.scaledFont(),
            .foregroundColor: UIColor.label
        ]
        let titleText = NSAttributedString(string: "\(title)\n", attributes: titleAttributes)
        result.append(titleText)

        // Spacing
        result.append(NSAttributedString(string: "\n"))

        // Content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: FXFontStyles.Regular.body.scaledFont(),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let contentText = NSAttributedString(
            string: "\(content)\n\n",
            attributes: contentAttributes
        )
        result.append(contentText)

        // Square link results
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: FXFontStyles.Regular.caption1.scaledFont(),
            .foregroundColor: UIColor.systemBlue,
            .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.1)
        ]

        for (index, linkText) in links.enumerated() {
            let paddedText = "  \(linkText)  "
            let linkString = NSAttributedString(string: paddedText, attributes: linkAttributes)
            result.append(linkString)

            if index < links.count - 1 {
                result.append(NSAttributedString(string: "  "))
            }
        }

        return result
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        tableView.backgroundColor = .clear
        backgroundColor = .clear
    }
}

public final class VoiceSearchViewController: UIViewController, Themeable {
    private struct UX {
        static let buttonPadding: CGFloat = 26.0
        static let buttonContentInset = NSDirectionalEdgeInsets(
            top: UX.buttonPadding,
            leading: UX.buttonPadding,
            bottom: UX.buttonPadding,
            trailing: UX.buttonPadding
        )
        static let buttonsSpacing: CGFloat = 11.0
        static let buttonsContainerBottomPadding: CGFloat = 12.0
        static let recordWaveEffectSize: CGFloat = 400.0
        static let recordWaveEffectBottomPadding = recordWaveEffectSize / 3.0
        static let audioWaveformTopPadding: CGFloat = 37.0
        static let audioWaveformSize = CGSize(width: 18.0, height: 35)
    }

    // MARK: - Properties
    private let backgroundBlur: UIVisualEffectView = .build {
        $0.effect = UIBlurEffect(style: .systemMaterial)
    }
    private let backgroundRecordEffect: GradientCircleView = .build()
    private let audioWaveform: AudioWaveformView = .build()
    private let recordButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.microphone)?
            .withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.buttonContentInset
    }
    private let closeButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.buttonContentInset
    }
    private let buttonsContainer: UIStackView = .build {
        $0.axis = .horizontal
        $0.spacing = UX.buttonsSpacing
    }
    private let searchContentView: SearchContentView = .build()

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol

    init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        backgroundRecordEffect.startAnimating()
        audioWaveform.startAnimating()
    }

    private func setupSubviews() {
        let leadingButtonContainerSpacer = UIView()
        let trailingButtonContainerSpacer = UIView()
        buttonsContainer.addArrangedSubview(leadingButtonContainerSpacer)
        buttonsContainer.addArrangedSubview(recordButton)
        buttonsContainer.addArrangedSubview(closeButton)
        buttonsContainer.addArrangedSubview(trailingButtonContainerSpacer)
        view.addSubviews(backgroundRecordEffect, backgroundBlur, searchContentView, audioWaveform, buttonsContainer)

        NSLayoutConstraint.activate([
            audioWaveform.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                               constant: UX.audioWaveformTopPadding),
            audioWaveform.heightAnchor.constraint(equalToConstant: UX.audioWaveformSize.height),
            audioWaveform.widthAnchor.constraint(equalToConstant: UX.audioWaveformSize.width),
            audioWaveform.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            backgroundRecordEffect.widthAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.heightAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundRecordEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                           constant: UX.recordWaveEffectBottomPadding),
            
            searchContentView.topAnchor.constraint(equalTo: audioWaveform.bottomAnchor),
            searchContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchContentView.bottomAnchor.constraint(equalTo: buttonsContainer.topAnchor),

            buttonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -UX.buttonsContainerBottomPadding),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Make spacer views expand equally to center the buttons in the button container
            leadingButtonContainerSpacer.widthAnchor.constraint(equalTo: trailingButtonContainerSpacer.widthAnchor)
        ])
        backgroundBlur.pinToSuperview()
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer2
        recordButton.configuration?.baseBackgroundColor = theme.colors.iconPrimary
        recordButton.configuration?.baseForegroundColor = theme.colors.layer2
        closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
        closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        backgroundRecordEffect.applyTheme(theme: theme)
        audioWaveform.applyTheme(theme: theme)
        searchContentView.applyTheme(theme: theme)
    }
}

@available(iOS 17, *)
#Preview {
    let controller = VoiceSearchViewController(
        windowUUID: .XCTestDefaultUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
    )
    let theme = LightTheme()
    controller.view.subviews.forEach { view in
        if let buttonContainer = view as? UIStackView {
            buttonContainer.arrangedSubviews.forEach { view in
                guard let button = view as? UIButton else { return }
                if button.configuration?.baseBackgroundColor == theme.colors.iconPrimary {
                    button.configuration?.image = UIImage(systemName: "mic.fill")
                } else {
                    button.configuration?.image = UIImage(systemName: "xmark")
                }
            }
        }
    }
    return controller
}
