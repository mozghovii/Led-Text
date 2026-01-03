import UIKit

final class LedFullScreenViewController: UIViewController {
    private let viewModel: LedSettingsViewModel
    private let marqueeView = LedMarqueeView()
    private let previewWidth: CGFloat
    private var speedScale: CGFloat = 1
    private var latestSettings: LedSettingsViewModel.Settings?

    init(viewModel: LedSettingsViewModel, previewWidth: CGFloat) {
        self.viewModel = viewModel
        self.previewWidth = previewWidth
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
            marqueeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            marqueeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            marqueeView.topAnchor.constraint(equalTo: view.topAnchor),
            marqueeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss))
        view.addGestureRecognizer(tapGesture)

        viewModel.addObserver { [weak self] settings in
            self?.apply(settings: settings)
        }
        apply(settings: viewModel.settings)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSpeedScale()
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
        latestSettings = settings
        marqueeView.text = settings.text
        marqueeView.scrollSpeed = settings.speed * speedScale
        marqueeView.direction = settings.direction
        marqueeView.blinkEnabled = settings.blinkEnabled
        marqueeView.textColor = settings.textColor
        marqueeView.dotSize = settings.dotSize
        marqueeView.dotSpacing = settings.dotSpacing
        marqueeView.glowIntensity = settings.glowIntensity
        view.backgroundColor = settings.backgroundColor
        marqueeView.backgroundColor = settings.backgroundColor
    }

    private func updateSpeedScale() {
        guard marqueeView.bounds.width > 0 else { return }
        speedScale = max(previewWidth / marqueeView.bounds.width, 0.5)
        if let settings = latestSettings {
            apply(settings: settings)
        }
    }

    @objc private func handleTapToDismiss() {
        dismiss(animated: true) {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
