import UIKit

final class LedFullScreenViewController: UIViewController {
    private let viewModel: LedSettingsViewModel
    private let marqueeView = LedMarqueeView()

    init(viewModel: LedSettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        marqueeView.translatesAutoresizingMaskIntoConstraints = false
        marqueeView.backgroundColor = .black
        view.addSubview(marqueeView)

        NSLayoutConstraint.activate([
            marqueeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            marqueeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            marqueeView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            marqueeView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss))
        view.addGestureRecognizer(tapGesture)

        viewModel.addObserver { [weak self] settings in
            self?.apply(settings: settings)
        }
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeRight
    }

    private func apply(settings: LedSettingsViewModel.Settings) {
        marqueeView.text = settings.text
        marqueeView.scrollSpeed = settings.speed
        marqueeView.direction = settings.direction
        marqueeView.blinkEnabled = settings.blinkEnabled
        marqueeView.textColor = settings.textColor
        marqueeView.dotSize = settings.dotSize
        marqueeView.dotSpacing = settings.dotSpacing
        marqueeView.glowIntensity = settings.glowIntensity
        view.backgroundColor = settings.backgroundColor
        marqueeView.backgroundColor = settings.backgroundColor
    }

    @objc private func handleTapToDismiss() {
        dismiss(animated: true)
    }
}
