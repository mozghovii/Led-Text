import UIKit
import SnapKit

final class ArchExampleCell:
    UICollectionViewCell,
    ReusableCell,
    Configurable,
    SelectableCellType {

    private let titleLabel = UILabel()
    private var action: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    func configure(with viewModel: ArchExampleViewModel.StringItem) {
        titleLabel.text = viewModel.title
        action = viewModel.actionHandler
    }

    func didSelect() {
        action?()
    }
}
