import UIKit

final class LedSettingsViewController: UIViewController {
    private let viewModel: LedSettingsViewModel
    private let marqueeView = LedMarqueeView()
    private let textField = UITextField()
    private let speedSlider = UISlider()
    private let speedValueLabel = UILabel()
    private let fontSizeSlider = UISlider()
    private let fontSizeValueLabel = UILabel()
    private let directionControl = UISegmentedControl(items: ["Left", "Right"])
    private let blinkSwitch = UISwitch()
    private let blinkRateSlider = UISlider()
    private let blinkRateValueLabel = UILabel()
    private let colorControl = UISegmentedControl(items: ["Red", "Green", "Blue", "White", "Yellow"])
    private let dotSizeSlider = UISlider()
    private let dotSpacingSlider = UISlider()
    private let glowSlider = UISlider()
    private let dotSizeValueLabel = UILabel()
    private let dotSpacingValueLabel = UILabel()
    private let glowValueLabel = UILabel()
    private let fullScreenButton = UIButton(type: .system)
    private let presetsScrollView = UIScrollView()
    private let presetsStack = UIStackView()
    private let controlsStack = UIStackView()
    private var presetButtons: [UIButton] = []
    private var textDebounceTimer: Timer?
    private var controlsHideTimer: Timer?

    init(viewModel: LedSettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LED Settings"
        view.backgroundColor = .black

        configureNavigation()
        configureMarquee()
        configureControls()
        configurePresets()
        configureLayout()
        bindViewModel()
        apply(settings: viewModel.settings)
        resetControlsAutoHide()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        marqueeView.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        marqueeView.stop()
    }

    private func configureNavigation() {
        let saveItem = UIBarButtonItem(image: UIImage(systemName: "star"), style: .plain, target: self, action: #selector(saveMessage))
        let listItem = UIBarButtonItem(image: UIImage(systemName: "tray.full"), style: .plain, target: self, action: #selector(openSavedMessages))
        navigationItem.rightBarButtonItems = [listItem, saveItem]
    }

    private func configureMarquee() {
        marqueeView.translatesAutoresizingMaskIntoConstraints = false
        marqueeView.backgroundColor = .black
        marqueeView.layer.borderColor = UIColor.darkGray.cgColor
        marqueeView.layer.borderWidth = 1
        marqueeView.layer.cornerRadius = 12
    }

    private func configureControls() {
        textField.placeholder = "Enter text"
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.layer.cornerRadius = 8
        textField.setLeftPadding(12)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        speedSlider.minimumValue = 1
        speedSlider.maximumValue = 100
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedValueLabel.textColor = .white
        speedValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        speedValueLabel.textAlignment = .right

        fontSizeSlider.minimumValue = 18
        fontSizeSlider.maximumValue = 64
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        fontSizeValueLabel.textColor = .white
        fontSizeValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        fontSizeValueLabel.textAlignment = .right

        directionControl.selectedSegmentIndex = 0
        directionControl.addTarget(self, action: #selector(directionChanged), for: .valueChanged)

        blinkSwitch.addTarget(self, action: #selector(blinkChanged), for: .valueChanged)

        colorControl.selectedSegmentIndex = 0
        colorControl.addTarget(self, action: #selector(colorChanged), for: .valueChanged)

        dotSizeSlider.minimumValue = 3
        dotSizeSlider.maximumValue = 10
        dotSizeSlider.addTarget(self, action: #selector(dotSizeChanged), for: .valueChanged)

        dotSpacingSlider.minimumValue = 1
        dotSpacingSlider.maximumValue = 6
        dotSpacingSlider.addTarget(self, action: #selector(dotSpacingChanged), for: .valueChanged)

        glowSlider.minimumValue = 0
        glowSlider.maximumValue = 1
        glowSlider.addTarget(self, action: #selector(glowChanged), for: .valueChanged)

        [dotSizeValueLabel, dotSpacingValueLabel, glowValueLabel, fontSizeValueLabel].forEach { label in
            label.textColor = .white
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
            label.textAlignment = .right
        }

        blinkRateSlider.minimumValue = 0.2
        blinkRateSlider.maximumValue = 2.0
        blinkRateSlider.addTarget(self, action: #selector(blinkRateChanged), for: .valueChanged)
        blinkRateValueLabel.textColor = .white
        blinkRateValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        blinkRateValueLabel.textAlignment = .right

        fullScreenButton.setTitle("Full Screen Preview", for: .normal)
        fullScreenButton.setTitleColor(.white, for: .normal)
        fullScreenButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        fullScreenButton.layer.cornerRadius = 8
        fullScreenButton.layer.borderWidth = 1
        fullScreenButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        fullScreenButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        fullScreenButton.addTarget(self, action: #selector(openFullScreen), for: .touchUpInside)
    }

    private func configurePresets() {
        presetsScrollView.showsHorizontalScrollIndicator = false
        presetsStack.axis = .horizontal
        presetsStack.spacing = 8
        presetsStack.alignment = .center
        presetsStack.translatesAutoresizingMaskIntoConstraints = false

        for preset in LedStylePreset.all {
            let button = UIButton(type: .system)
            button.setTitle(preset.name, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            button.tag = presetButtons.count
            button.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
            presetButtons.append(button)
            presetsStack.addArrangedSubview(button)
        }
    }

    private func configureLayout() {
        controlsStack.axis = .vertical
        controlsStack.spacing = 16
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        let speedStack = UIStackView(arrangedSubviews: [speedSlider, speedValueLabel])
        speedStack.axis = .horizontal
        speedStack.spacing = 12
        speedValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let fontSizeStack = UIStackView(arrangedSubviews: [fontSizeSlider, fontSizeValueLabel])
        fontSizeStack.axis = .horizontal
        fontSizeStack.spacing = 12
        fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let dotSizeStack = UIStackView(arrangedSubviews: [dotSizeSlider, dotSizeValueLabel])
        dotSizeStack.axis = .horizontal
        dotSizeStack.spacing = 12
        dotSizeValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let dotSpacingStack = UIStackView(arrangedSubviews: [dotSpacingSlider, dotSpacingValueLabel])
        dotSpacingStack.axis = .horizontal
        dotSpacingStack.spacing = 12
        dotSpacingValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let glowStack = UIStackView(arrangedSubviews: [glowSlider, glowValueLabel])
        glowStack.axis = .horizontal
        glowStack.spacing = 12
        glowValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let blinkRateStack = UIStackView(arrangedSubviews: [blinkRateSlider, blinkRateValueLabel])
        blinkRateStack.axis = .horizontal
        blinkRateStack.spacing = 12
        blinkRateValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        controlsStack.addArrangedSubview(marqueeView)
        controlsStack.addArrangedSubview(makeRow(title: "Text", control: textField))
        controlsStack.addArrangedSubview(makeRow(title: "Speed", control: speedStack))
        controlsStack.addArrangedSubview(makeRow(title: "Font Size", control: fontSizeStack))
        controlsStack.addArrangedSubview(makeRow(title: "Direction", control: directionControl))
        controlsStack.addArrangedSubview(makeRow(title: "Blink", control: blinkSwitch))
        controlsStack.addArrangedSubview(makeRow(title: "Blink Rate", control: blinkRateStack))
        controlsStack.addArrangedSubview(makeRow(title: "Color", control: colorControl))
        controlsStack.addArrangedSubview(makeRow(title: "Dot Size", control: dotSizeStack))
        controlsStack.addArrangedSubview(makeRow(title: "Dot Gap", control: dotSpacingStack))
        controlsStack.addArrangedSubview(makeRow(title: "Glow", control: glowStack))
        controlsStack.addArrangedSubview(fullScreenButton)

        presetsScrollView.translatesAutoresizingMaskIntoConstraints = false
        presetsScrollView.addSubview(presetsStack)

        view.addSubview(controlsStack)
        view.addSubview(presetsScrollView)

        NSLayoutConstraint.activate([
            marqueeView.heightAnchor.constraint(equalToConstant: 120),

            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            presetsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            presetsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            presetsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            presetsScrollView.heightAnchor.constraint(equalToConstant: 44),

            presetsStack.leadingAnchor.constraint(equalTo: presetsScrollView.leadingAnchor),
            presetsStack.trailingAnchor.constraint(equalTo: presetsScrollView.trailingAnchor),
            presetsStack.topAnchor.constraint(equalTo: presetsScrollView.topAnchor),
            presetsStack.bottomAnchor.constraint(equalTo: presetsScrollView.bottomAnchor),
            presetsStack.heightAnchor.constraint(equalTo: presetsScrollView.heightAnchor)
        ])
    }

    private func makeRow(title: String, control: UIView) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let rowStack = UIStackView(arrangedSubviews: [titleLabel, control])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        return rowStack
    }

    private func bindViewModel() {
        viewModel.addObserver { [weak self] settings in
            self?.apply(settings: settings)
        }
    }

    private func apply(settings: LedSettingsViewModel.Settings) {
        textField.text = settings.text
        speedSlider.value = Float(settings.speed)
        speedValueLabel.text = String(format: "%.0f", settings.speed)
        fontSizeSlider.value = Float(settings.fontSize)
        fontSizeValueLabel.text = String(format: "%.0f", settings.fontSize)
        directionControl.selectedSegmentIndex = settings.direction == .left ? 0 : 1
        blinkSwitch.isOn = settings.blinkEnabled
        view.backgroundColor = settings.backgroundColor
        marqueeView.backgroundColor = settings.backgroundColor
        marqueeView.text = settings.text
        marqueeView.scrollSpeed = settings.speed
        marqueeView.direction = settings.direction
        marqueeView.blinkEnabled = settings.blinkEnabled
        marqueeView.blinkInterval = settings.blinkInterval
        marqueeView.textColor = settings.textColor
        marqueeView.dotSize = settings.dotSize
        marqueeView.dotSpacing = settings.dotSpacing
        marqueeView.glowIntensity = settings.glowIntensity
        marqueeView.dotMatrixEnabled = settings.dotMatrixEnabled
        marqueeView.letterSpacing = settings.letterSpacing
        marqueeView.font = UIFont(name: settings.fontName, size: settings.fontSize) ?? UIFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .bold)
        dotSizeSlider.value = Float(settings.dotSize)
        dotSpacingSlider.value = Float(settings.dotSpacing)
        glowSlider.value = Float(settings.glowIntensity)
        dotSizeValueLabel.text = String(format: "%.1f", settings.dotSize)
        dotSpacingValueLabel.text = String(format: "%.1f", settings.dotSpacing)
        glowValueLabel.text = String(format: "%.2f", settings.glowIntensity)
        blinkRateSlider.value = Float(settings.blinkInterval)
        blinkRateValueLabel.text = String(format: "%.2f", settings.blinkInterval)
        updatePresetSelection(settings.presetId)
    }

    private func updatePresetSelection(_ selectedId: String) {
        for (index, preset) in LedStylePreset.all.enumerated() {
            let button = presetButtons[index]
            let isSelected = preset.id == selectedId
            button.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.white.withAlphaComponent(0.4).cgColor
            button.backgroundColor = isSelected ? UIColor.white.withAlphaComponent(0.25) : UIColor.white.withAlphaComponent(0.08)
        }
    }

    private func resetControlsAutoHide() {
        controlsHideTimer?.invalidate()
        controlsStack.alpha = 1
        controlsStack.isUserInteractionEnabled = true
        presetsScrollView.alpha = 1
        presetsScrollView.isUserInteractionEnabled = true

        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.setControlsHidden(true)
        }
    }

    private func setControlsHidden(_ hidden: Bool) {
        let alpha: CGFloat = hidden ? 0 : 1
        UIView.animate(withDuration: 0.2) {
            self.controlsStack.alpha = alpha
            self.presetsScrollView.alpha = alpha
        }
        controlsStack.isUserInteractionEnabled = !hidden
        presetsScrollView.isUserInteractionEnabled = !hidden
    }

    @objc private func handleViewTap() {
        setControlsHidden(false)
        resetControlsAutoHide()
    }

    @objc private func textFieldDidChange() {
        textDebounceTimer?.invalidate()
        let latestText = textField.text ?? ""
        textDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.viewModel.updateText(latestText)
        }
        resetControlsAutoHide()
    }

    @objc private func speedChanged() {
        viewModel.updateSpeed(CGFloat(speedSlider.value))
        resetControlsAutoHide()
    }

    @objc private func fontSizeChanged() {
        viewModel.updateFontSize(CGFloat(fontSizeSlider.value))
        resetControlsAutoHide()
    }

    @objc private func directionChanged() {
        let direction: LedMarqueeView.Direction = directionControl.selectedSegmentIndex == 0 ? .left : .right
        viewModel.updateDirection(direction)
        resetControlsAutoHide()
    }

    @objc private func blinkChanged() {
        viewModel.updateBlinkEnabled(blinkSwitch.isOn)
        resetControlsAutoHide()
    }

    @objc private func blinkRateChanged() {
        let interval = TimeInterval(blinkRateSlider.value)
        blinkRateValueLabel.text = String(format: "%.2f", interval)
        viewModel.updateBlinkInterval(interval)
        resetControlsAutoHide()
    }

    @objc private func colorChanged() {
        let color: UIColor
        switch colorControl.selectedSegmentIndex {
        case 1:
            color = .systemGreen
        case 2:
            color = .systemBlue
        case 3:
            color = .white
        case 4:
            color = .systemYellow
        default:
            color = .systemRed
        }
        viewModel.updateTextColor(color)
        resetControlsAutoHide()
    }

    @objc private func dotSizeChanged() {
        viewModel.updateDotSize(CGFloat(dotSizeSlider.value))
        resetControlsAutoHide()
    }

    @objc private func dotSpacingChanged() {
        viewModel.updateDotSpacing(CGFloat(dotSpacingSlider.value))
        resetControlsAutoHide()
    }

    @objc private func glowChanged() {
        viewModel.updateGlowIntensity(CGFloat(glowSlider.value))
        resetControlsAutoHide()
    }

    @objc private func openFullScreen() {
        let fullScreenVC = LedFullScreenViewController(viewModel: viewModel)
        fullScreenVC.modalPresentationStyle = .fullScreen
        present(fullScreenVC, animated: true)
        resetControlsAutoHide()
    }

    @objc private func presetTapped(_ sender: UIButton) {
        let preset = LedStylePreset.all[sender.tag]
        viewModel.applyPreset(preset)
        resetControlsAutoHide()
    }

    @objc private func saveMessage() {
        viewModel.saveCurrentMessage()
        let alert = UIAlertController(title: "Saved", message: "Message saved.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func openSavedMessages() {
        let messages = viewModel.loadSavedMessages()
        let savedVC = LedSavedMessagesViewController(messages: messages) { [weak self] message in
            self?.viewModel.applySavedMessage(message)
            self?.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: savedVC)
        present(nav, animated: true)
        resetControlsAutoHide()
    }
}

private extension UITextField {
    func setLeftPadding(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = padding
        leftViewMode = .always
    }
}
