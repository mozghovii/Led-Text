//
//  ArchExampleLayoutProvider.swift
//  ArchExample
//
//  Created by brainf on 16.12.2025.
//

import UIKit

final class ArchExampleLayoutProvider {
    
    private let collectionView: UICollectionView
    
    // MARK: - Init
    
    init(_ collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    func layout(for type: ArchExampleViewModel.SectionViewModel) -> NSCollectionLayoutSection {
        return exampleLayout()
    }

    
    private func exampleLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(78),
            heightDimension: .absolute(24)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(24)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        group.interItemSpacing = .fixed(8)
        let section = NSCollectionLayoutSection(group: group)
        
        section.contentInsets.bottom = 16
        section.contentInsets.top = 16

        return section
    }
}
