import UIKit

final class LedSettingsViewController: UIViewController {
    private let viewModel: LedSettingsViewModel
    private let marqueeView = LedMarqueeView()
    private let textField = UITextField()
    private let speedSlider = UISlider()
    private let speedValueLabel = UILabel()
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
    private let previewContainer = UIView()
    private let controlsContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let controlsOverlay = UIView()
    private var textDebounceTimer: Timer?

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

        configureMarquee()
        configureControls()
        configureLayout()
        bindViewModel()
        apply(settings: viewModel.settings)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        marqueeView.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        marqueeView.stop()
    }

    private func configureMarquee() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = .black
        previewContainer.layer.cornerRadius = 20
        previewContainer.layer.borderWidth = 1
        previewContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        previewContainer.clipsToBounds = true

        marqueeView.translatesAutoresizingMaskIntoConstraints = false
        marqueeView.backgroundColor = .black
    }

    private func configureControls() {
        textField.placeholder = "LED Text"
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        textField.setLeftPadding(14)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        speedSlider.minimumValue = 20
        speedSlider.maximumValue = 100
        styleSlider(speedSlider)
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedValueLabel.textColor = .white
        speedValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        speedValueLabel.textAlignment = .right
        speedValueLabel.isHidden = true

        directionControl.setTitle("", forSegmentAt: 0)
        directionControl.setTitle("", forSegmentAt: 1)
        directionControl.setImage(UIImage(systemName: "arrow.left"), forSegmentAt: 0)
        directionControl.setImage(UIImage(systemName: "arrow.right"), forSegmentAt: 1)
        directionControl.selectedSegmentIndex = 0
        directionControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.15)
        directionControl.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        directionControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        directionControl.addTarget(self, action: #selector(directionChanged), for: .valueChanged)

        blinkSwitch.addTarget(self, action: #selector(blinkChanged), for: .valueChanged)

        (0..<colorControl.numberOfSegments).forEach { index in
            colorControl.setTitle("", forSegmentAt: index)
        }
        colorControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        colorControl.selectedSegmentTintColor = .clear
        colorControl.backgroundColor = .clear
        colorControl.selectedSegmentIndex = 0
        updateColorControlImages(selectedIndex: 0)
        colorControl.addTarget(self, action: #selector(colorChanged), for: .valueChanged)

        dotSizeSlider.minimumValue = 3
        dotSizeSlider.maximumValue = 10
        styleSlider(dotSizeSlider)
        dotSizeSlider.addTarget(self, action: #selector(dotSizeChanged), for: .valueChanged)

        dotSpacingSlider.minimumValue = 1
        dotSpacingSlider.maximumValue = 6
        styleSlider(dotSpacingSlider)
        dotSpacingSlider.addTarget(self, action: #selector(dotSpacingChanged), for: .valueChanged)

        glowSlider.minimumValue = 0
        glowSlider.maximumValue = 1
        styleSlider(glowSlider)
        glowSlider.addTarget(self, action: #selector(glowChanged), for: .valueChanged)

        [dotSizeValueLabel, dotSpacingValueLabel, glowValueLabel].forEach { label in
            label.textColor = .white
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
            label.textAlignment = .right
            label.isHidden = true
        }

        blinkRateSlider.minimumValue = 0.2
        blinkRateSlider.maximumValue = 2.0
        styleSlider(blinkRateSlider)
        blinkRateSlider.addTarget(self, action: #selector(blinkRateChanged), for: .valueChanged)
        blinkRateValueLabel.textColor = .white
        blinkRateValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        blinkRateValueLabel.textAlignment = .right
        blinkRateValueLabel.isHidden = true

        fullScreenButton.setTitle("Full Screen Preview", for: .normal)
        fullScreenButton.setTitleColor(.white, for: .normal)
        fullScreenButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        fullScreenButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        fullScreenButton.layer.cornerRadius = 16
        fullScreenButton.layer.borderWidth = 1
        fullScreenButton.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        fullScreenButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        fullScreenButton.addTarget(self, action: #selector(openFullScreen), for: .touchUpInside)
    }

    private func configureLayout() {
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.layer.cornerRadius = 20
        controlsContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        controlsContainer.clipsToBounds = true

        controlsOverlay.translatesAutoresizingMaskIntoConstraints = false
        controlsOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        controlsContainer.contentView.addSubview(controlsOverlay)
        NSLayoutConstraint.activate([
            controlsOverlay.leadingAnchor.constraint(equalTo: controlsContainer.contentView.leadingAnchor),
            controlsOverlay.trailingAnchor.constraint(equalTo: controlsContainer.contentView.trailingAnchor),
            controlsOverlay.topAnchor.constraint(equalTo: controlsContainer.contentView.topAnchor),
            controlsOverlay.bottomAnchor.constraint(equalTo: controlsContainer.contentView.bottomAnchor)
        ])

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let speedRow = makeRow(iconName: "speedometer", control: speedSlider)

        let dotSizeRow = makeRow(iconName: "circle.grid.2x2", control: dotSizeSlider)

        let dotSpacingRow = makeRow(iconName: "rectangle.split.3x1", control: dotSpacingSlider)

        let glowRow = makeRow(iconName: "sun.max", control: glowSlider)

        let blinkRateRow = makeRow(iconName: "timer", control: blinkRateSlider)

        let directionRow = makeRow(iconName: "arrow.left.arrow.right", control: directionControl)
        let blinkRow = makeRow(iconName: "bolt", control: blinkSwitch)
        let colorRow = makeRow(iconName: "paintpalette", control: colorControl)
        let textRow = makeRow(iconName: "textformat", control: textField)

        contentStack.addArrangedSubview(textRow)
        contentStack.addArrangedSubview(speedRow)
        contentStack.addArrangedSubview(directionRow)
        contentStack.addArrangedSubview(blinkRow)
        contentStack.addArrangedSubview(blinkRateRow)
        contentStack.addArrangedSubview(colorRow)
        contentStack.addArrangedSubview(dotSizeRow)
        contentStack.addArrangedSubview(dotSpacingRow)
        contentStack.addArrangedSubview(glowRow)
        contentStack.addArrangedSubview(fullScreenButton)

        view.addSubview(previewContainer)
        previewContainer.addSubview(marqueeView)
        view.addSubview(controlsContainer)
        controlsContainer.contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.68),

            marqueeView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            marqueeView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),
            marqueeView.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            marqueeView.heightAnchor.constraint(equalTo: previewContainer.heightAnchor, multiplier: 0.35),

            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controlsContainer.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 12),

            contentStack.leadingAnchor.constraint(equalTo: controlsContainer.contentView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: controlsContainer.contentView.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: controlsContainer.contentView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: controlsContainer.contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        fullScreenButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    private func makeRow(iconName: String, control: UIView) -> UIStackView {
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = UIColor.white.withAlphaComponent(0.7)
        iconView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        let rowStack = UIStackView(arrangedSubviews: [iconView, control])
        rowStack.axis = .horizontal
        rowStack.spacing = 14
        rowStack.alignment = .center
        return rowStack
    }

    private func styleSlider(_ slider: UISlider) {
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.2)
        slider.transform = CGAffineTransform(scaleX: 1, y: 1.3)
    }

    private func updateColorControlImages(selectedIndex: Int) {
        let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue, .white, .systemYellow]
        for (index, color) in colors.enumerated() {
            let isSelected = index == selectedIndex
            colorControl.setImage(colorChipImage(color: color, selected: isSelected), forSegmentAt: index)
        }
    }

    private func colorChipImage(color: UIColor, selected: Bool) -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            color.setFill()
            path.fill()
            if selected {
                UIColor.white.withAlphaComponent(0.9).setStroke()
                path.lineWidth = 2
                path.stroke()
            }
        }.withRenderingMode(.alwaysOriginal)
    }

    private func colorSegmentIndex(for color: UIColor) -> Int {
        switch color {
        case UIColor.systemGreen:
            return 1
        case UIColor.systemBlue:
            return 2
        case UIColor.white:
            return 3
        case UIColor.systemYellow:
            return 4
        default:
            return 0
        }
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
        colorControl.selectedSegmentIndex = colorSegmentIndex(for: settings.textColor)
        updateColorControlImages(selectedIndex: colorControl.selectedSegmentIndex)
        dotSizeSlider.value = Float(settings.dotSize)
        dotSpacingSlider.value = Float(settings.dotSpacing)
        glowSlider.value = Float(settings.glowIntensity)
        dotSizeValueLabel.text = String(format: "%.1f", settings.dotSize)
        dotSpacingValueLabel.text = String(format: "%.1f", settings.dotSpacing)
        glowValueLabel.text = String(format: "%.2f", settings.glowIntensity)
        blinkRateSlider.value = Float(settings.blinkInterval)
        blinkRateValueLabel.text = String(format: "%.2f", settings.blinkInterval)
    }

    @objc private func textFieldDidChange() {
        textDebounceTimer?.invalidate()
        let latestText = textField.text ?? ""
        textDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.viewModel.updateText(latestText)
        }
    }

    @objc private func speedChanged() {
        viewModel.updateSpeed(CGFloat(speedSlider.value))
    }

    @objc private func directionChanged() {
        let direction: LedMarqueeView.Direction = directionControl.selectedSegmentIndex == 0 ? .left : .right
        viewModel.updateDirection(direction)
    }

    @objc private func blinkChanged() {
        viewModel.updateBlinkEnabled(blinkSwitch.isOn)
    }

    @objc private func blinkRateChanged() {
        let interval = TimeInterval(blinkRateSlider.value)
        blinkRateValueLabel.text = String(format: "%.2f", interval)
        viewModel.updateBlinkInterval(interval)
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
        updateColorControlImages(selectedIndex: colorControl.selectedSegmentIndex)
        viewModel.updateTextColor(color)
    }

    @objc private func dotSizeChanged() {
        viewModel.updateDotSize(CGFloat(dotSizeSlider.value))
    }

    @objc private func dotSpacingChanged() {
        viewModel.updateDotSpacing(CGFloat(dotSpacingSlider.value))
    }

    @objc private func glowChanged() {
        viewModel.updateGlowIntensity(CGFloat(glowSlider.value))
    }

    @objc private func openFullScreen() {
        let fullScreenVC = LedFullScreenViewController(viewModel: viewModel)
        fullScreenVC.modalPresentationStyle = .fullScreen
        present(fullScreenVC, animated: true)
    }
}

private extension UITextField {
    func setLeftPadding(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = padding
        leftViewMode = .always
    }
}
