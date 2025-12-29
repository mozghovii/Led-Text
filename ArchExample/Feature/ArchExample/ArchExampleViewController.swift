import UIKit
import Combine
import SnapKit

final class ArchExampleViewController: UIViewController {

    private let viewModel: ArchExampleViewModel

    private var cancellables = Set<AnyCancellable>()
    private var sections: [ArchExampleViewModel.SectionViewModel] = []

    private var collectionView: UICollectionView!

    private lazy var cellProvider = ArchExampleCellProvider(collectionView)
    private lazy var layoutProvider = ArchExampleLayoutProvider(collectionView)

    init(viewModel: ArchExampleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "ArchExample"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bind()
        viewModel.start()
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .gray
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self else { return nil }
            let type = self.sections[sectionIndex]
            return self.layoutProvider.layout(for: type)
        }
    }

    private func bind() {
        viewModel.$state
            .sink { [weak self] state in
                guard let self else { return }
                if case .started(let started) = state {
                    self.sections = started.sections
                    self.collectionView.reloadData()
                }
            }
            .store(in: &cancellables)
    }
}

extension ArchExampleViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = sections[indexPath.section].items[indexPath.item]
        return cellProvider.cell(for: item, indexPath: indexPath)
    }
}

extension ArchExampleViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? SelectableCellType)?.didSelect()
    }
}
