import UIKit

/// Cell provider for the ArchExample module.
/// Responsible for registration, dequeuing and Visitor dispatch.
final class ArchExampleCellProvider: ArchExampleViewModelVisitorType {

    private let collectionView: UICollectionView
    private var indexPath: IndexPath!

    init(_ collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    func prepare() {
        collectionView.register(ArchExampleCell.self)

    }

    func cell(for viewModel: ArchExampleViewModelElementType, indexPath: IndexPath) -> UICollectionViewCell {
        self.indexPath = indexPath
        return viewModel.accept(visitor: self)
    }

    func visit(viewModel: ArchExampleViewModel.StringItem) -> UICollectionViewCell {
        collectionView.dequeueCodeCell(ArchExampleCell.self, indexPath: indexPath, model: viewModel)
    }

    func visit(viewModel: ArchExampleViewModel.LoadingItem) -> UICollectionViewCell {
        UICollectionViewCell()
    }

    func visit(viewModel: ArchExampleViewModel.ErrorItem) -> UICollectionViewCell {
        UICollectionViewCell()
    }
}
