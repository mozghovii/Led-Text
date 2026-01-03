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

        speedSlider.minimumValue = 20
        speedSlider.maximumValue = 100
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedValueLabel.textColor = .white
        speedValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        speedValueLabel.textAlignment = .right

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

        [dotSizeValueLabel, dotSpacingValueLabel, glowValueLabel].forEach { label in
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

    private func configureLayout() {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let speedStack = UIStackView(arrangedSubviews: [speedSlider, speedValueLabel])
        speedStack.axis = .horizontal
        speedStack.spacing = 12
        speedValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

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

        contentStack.addArrangedSubview(marqueeView)
        contentStack.addArrangedSubview(makeRow(title: "Text", control: textField))
        contentStack.addArrangedSubview(makeRow(title: "Speed", control: speedStack))
        contentStack.addArrangedSubview(makeRow(title: "Direction", control: directionControl))
        contentStack.addArrangedSubview(makeRow(title: "Blink", control: blinkSwitch))
        contentStack.addArrangedSubview(makeRow(title: "Blink Rate", control: blinkRateStack))
        contentStack.addArrangedSubview(makeRow(title: "Color", control: colorControl))
        contentStack.addArrangedSubview(makeRow(title: "Dot Size", control: dotSizeStack))
        contentStack.addArrangedSubview(makeRow(title: "Dot Gap", control: dotSpacingStack))
        contentStack.addArrangedSubview(makeRow(title: "Glow", control: glowStack))
        contentStack.addArrangedSubview(fullScreenButton)

        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            marqueeView.heightAnchor.constraint(equalToConstant: 120),

            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
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
