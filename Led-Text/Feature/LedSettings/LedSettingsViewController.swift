import UIKit

final class LedSettingsViewController: UIViewController {
    private let viewModel: LedSettingsViewModel
    private let marqueeView = LedMarqueeView()
    private let textField = UITextField()
    private let speedSlider = UISlider()
    private let speedValueLabel = UILabel()
    private let directionControl = UISegmentedControl(items: ["Left", "Right"])
    private let blinkSwitch = UISwitch()
    private let colorControl = UISegmentedControl(items: ["Red", "Green", "Blue", "White", "Yellow"])

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
        speedSlider.maximumValue = 200
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        speedValueLabel.textColor = .white
        speedValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        speedValueLabel.textAlignment = .right

        directionControl.selectedSegmentIndex = 0
        directionControl.addTarget(self, action: #selector(directionChanged), for: .valueChanged)

        blinkSwitch.addTarget(self, action: #selector(blinkChanged), for: .valueChanged)

        colorControl.selectedSegmentIndex = 0
        colorControl.addTarget(self, action: #selector(colorChanged), for: .valueChanged)
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

        contentStack.addArrangedSubview(marqueeView)
        contentStack.addArrangedSubview(makeRow(title: "Text", control: textField))
        contentStack.addArrangedSubview(makeRow(title: "Speed", control: speedStack))
        contentStack.addArrangedSubview(makeRow(title: "Direction", control: directionControl))
        contentStack.addArrangedSubview(makeRow(title: "Blink", control: blinkSwitch))
        contentStack.addArrangedSubview(makeRow(title: "Color", control: colorControl))

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
        viewModel.onChange = { [weak self] settings in
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
        marqueeView.textColor = settings.textColor
    }

    @objc private func textFieldDidChange() {
        viewModel.updateText(textField.text ?? "")
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
}

private extension UITextField {
    func setLeftPadding(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = padding
        leftViewMode = .always
    }
}
