//
//  CollectionView.swift
//  ArchExample
//
//  Created by brainf on 16.12.2025.
//
import UIKit

extension UICollectionView {


    /// Registers specified cell type.
    func register<Cell: UICollectionViewCell & ReusableCell>(_ cellType: Cell.Type) {
        register(cellType, forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }

    
    /// Registers specified supplementary view.
    func registerSupplementary<View: UICollectionReusableView & ReusableCell>(_ viewType: View.Type, kind: String) {
        register(viewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: viewType.reuseIdentifier)
    }

    
    func dequeueCodeCell<Cell: UICollectionViewCell>(
        _ cellType: Cell.Type, indexPath: IndexPath
    ) -> Cell where Cell: ReusableCell {
        return dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath) as! Cell
    }
    
    func dequeueCodeSupplementary<View: UICollectionReusableView>(
        _ viewType: View.Type, kind: String, indexPath: IndexPath
    ) -> View where View: ReusableCell {
        return dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: viewType.reuseIdentifier, for: indexPath
        ) as! View
    }
    
    func dequeueCodeCell<Cell: UICollectionViewCell & Configurable>(
        _ cellType: Cell.Type, indexPath: IndexPath, model: Cell.Model
    ) -> UICollectionViewCell where Cell: ReusableCell {
        let cell = dequeueCodeCell(Cell.self, indexPath: indexPath)
        cell.configure(with: model)
        return cell
    }
    
    func dequeueCodeSupplementary<View: UICollectionReusableView & Configurable>(
        _ viewType: View.Type, kind: String, indexPath: IndexPath, model: View.Model
    ) -> UICollectionReusableView where View: ReusableCell {
        let view = dequeueCodeSupplementary(viewType, kind: kind, indexPath: indexPath)
        view.configure(with: model)
        return view
    }
}
