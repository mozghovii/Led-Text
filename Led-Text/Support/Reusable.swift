import UIKit

public protocol ReusableCell {
    static var reuseIdentifier: String { get }
}

public protocol Configurable {
    associatedtype Model

    /// Configures object with given model.
    func configure(with viewModel: Model)
}

protocol SelectableCellType {
    func didSelect()
}

public extension ReusableCell where Self: NSObject {

    static var reuseIdentifier: String {
        // We do care only about result consistency, not about value itself.
        return NSStringFromClass(Self.self)
    }
}
