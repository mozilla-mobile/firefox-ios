// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class SearchResultView: UIView, ThemeApplicable {
    private struct UX {
        static let spacing: CGFloat = 12
        static let boxHeight: CGFloat = 120
        static let cornerRadius: CGFloat = 12
        static let boxPadding: CGFloat = 12
        static let iconSize: CGFloat = 32
    }

    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title2.scaledFont()
        $0.numberOfLines = 0
    }
    private let bodyLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
    }
    private let boxesStackView: UIStackView = .build {
        $0.axis = .horizontal
        $0.spacing = UX.spacing
        $0.distribution = .fillEqually
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubviews(titleLabel, bodyLabel, boxesStackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.spacing),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            boxesStackView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: UX.spacing * 2),
            boxesStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            boxesStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            boxesStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(title: String, body: String, url: URL? = nil) {
        titleLabel.text = title
        bodyLabel.text = body
    }

    func applyTheme(theme: any Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        bodyLabel.textColor = theme.colors.textSecondary
    }
}

final class ContentView: UIView, ThemeApplicable {
    private let scrollView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    private let contentView: UIView = .build()
    private let speechResultLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
    }
    private let loadingSearchLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title2.scaledFont()
        $0.alpha = 0.0
        $0.text = "Searching ..."
    }
    private let searchResultView: SearchResultView = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(speechResultLabel, loadingSearchLabel, searchResultView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
            
            speechResultLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            speechResultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            speechResultLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            loadingSearchLabel.topAnchor.constraint(equalTo: speechResultLabel.bottomAnchor, constant: 32),
            loadingSearchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            loadingSearchLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            searchResultView.topAnchor.constraint(equalTo: speechResultLabel.bottomAnchor, constant: 32),
            searchResultView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchResultView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            searchResultView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
    }
    
    func setSpeechResult(text: String) {
        speechResultLabel.text = text
        if speechResultLabel.alpha != 1.0 {
            UIView.animate(withDuration: 0.2) { [self] in
                speechResultLabel.alpha = 1.0
                loadingSearchLabel.alpha = 0.0
                searchResultView.alpha = 0.0
            }
        }
    }
    
    func setIsLoadingSearchResult() {
        loadingSearchLabel.transform = .identity.translatedBy(x: 0.0, y: 32.0)
        UIView.animate(withDuration: 0.2) { [self] in
            loadingSearchLabel.alpha = 1.0
            loadingSearchLabel.transform = .identity
        }
    }
    
    func setSearchResult(title: String, body: String, url: URL?) {
        searchResultView.configure(title: title, body: body)
        searchResultView.transform = .identity.translatedBy(x: 0.0, y: 32.0)
        loadingSearchLabel.alpha = 0.0
        UIView.animate(withDuration: 0.2) { [self] in
            searchResultView.transform = .identity
            searchResultView.alpha = 1.0
            speechResultLabel.alpha = 0.3
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        speechResultLabel.textColor = theme.colors.textPrimary
        searchResultView.applyTheme(theme: theme)
        scrollView.backgroundColor = .clear
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
        static let contentViewTopPadding: CGFloat = 16.0
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
    private let contentView: ContentView = .build()

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol
    private let viewModel: VoiceSearchViewModel
    
    init(
        viewModel: VoiceSearchViewModel,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.viewModel = viewModel
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
        configureButtons()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        backgroundRecordEffect.startAnimating()
        audioWaveform.startAnimating()
        viewModel.onStateChange = { [weak self] in
            self?.onStateChange(state: $0)
        }
        viewModel.startRecordingVoice()
    }

    private func setupSubviews() {
        let leadingButtonContainerSpacer = UIView()
        let trailingButtonContainerSpacer = UIView()
        buttonsContainer.addArrangedSubview(leadingButtonContainerSpacer)
        buttonsContainer.addArrangedSubview(recordButton)
        buttonsContainer.addArrangedSubview(closeButton)
        buttonsContainer.addArrangedSubview(trailingButtonContainerSpacer)
        view.addSubviews(backgroundRecordEffect, backgroundBlur, contentView, audioWaveform, buttonsContainer)

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
            
            contentView.topAnchor.constraint(equalTo: audioWaveform.bottomAnchor, constant: UX.contentViewTopPadding),
            contentView.bottomAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            buttonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -UX.buttonsContainerBottomPadding),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Make spacer views expand equally to center the buttons in the button container
            leadingButtonContainerSpacer.widthAnchor.constraint(equalTo: trailingButtonContainerSpacer.widthAnchor)
        ])
        backgroundBlur.pinToSuperview()
    }
    
    private func configureButtons() {
        recordButton.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.audioWaveform.startAnimating()
                    self?.viewModel.startRecordingVoice()
                }),
            for: .touchUpInside
        )
    }
    
    private func onStateChange(state: VoiceSearchViewModel.State) {
        switch state {
        case .recordVoice(let speechResult, _):
            contentView.setSpeechResult(text: speechResult.text)
        case .loadingSearchResult:
            audioWaveform.stopAnimating()
            contentView.setIsLoadingSearchResult()
        case .showSearchResult(let searchResult, _):
            contentView.setSearchResult(
                title: searchResult.title,
                body: searchResult.body,
                url: searchResult.url
            )
        }
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
        contentView.applyTheme(theme: theme)
    }
}

@available(iOS 17, *)
#Preview {
    let controller = VoiceSearchViewController(
        viewModel: VoiceSearchViewModel(service: MockVoiceSearchService()),
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
