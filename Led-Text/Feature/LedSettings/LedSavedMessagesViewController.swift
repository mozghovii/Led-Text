import UIKit

final class LedSavedMessagesViewController: UITableViewController {
    private let messages: [LedSavedMessage]
    private let onSelect: (LedSavedMessage) -> Void

    init(messages: [LedSavedMessage], onSelect: @escaping (LedSavedMessage) -> Void) {
        self.messages = messages
        self.onSelect = onSelect
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Saved Messages"
        tableView.register(LedSavedMessageCell.self, forCellReuseIdentifier: LedSavedMessageCell.reuseIdentifier)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        tableView.backgroundColor = .black
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LedSavedMessageCell.reuseIdentifier, for: indexPath) as? LedSavedMessageCell
        let message = messages[indexPath.row]
        cell?.configure(message: message)
        cell?.selectionStyle = .none
        cell?.backgroundColor = .black
        return cell ?? UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect(messages[indexPath.row])
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

final class LedSavedMessageCell: UITableViewCell {
    static let reuseIdentifier = "LedSavedMessageCell"
    private let marqueeView = LedMarqueeView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        marqueeView.translatesAutoresizingMaskIntoConstraints = false
        marqueeView.isUserInteractionEnabled = false
        contentView.addSubview(marqueeView)

        NSLayoutConstraint.activate([
            marqueeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            marqueeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            marqueeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            marqueeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            marqueeView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: LedSavedMessage) {
        let preset = LedStylePreset.preset(for: message.presetId)
        marqueeView.text = message.text
        marqueeView.scrollSpeed = 0
        marqueeView.direction = .left
        marqueeView.blinkEnabled = false
        marqueeView.textColor = preset.textColor
        marqueeView.backgroundColor = preset.backgroundColor
        marqueeView.glowIntensity = preset.glowIntensity
        marqueeView.dotMatrixEnabled = preset.dotMatrixEnabled
        marqueeView.letterSpacing = preset.letterSpacing
        marqueeView.font = UIFont(name: preset.fontName, size: CGFloat(message.fontSize)) ?? UIFont.monospacedSystemFont(ofSize: CGFloat(message.fontSize), weight: .bold)
        marqueeView.stop()
    }
}
