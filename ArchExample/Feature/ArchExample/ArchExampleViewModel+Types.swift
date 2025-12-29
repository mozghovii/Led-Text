protocol ArchExampleViewModelElementType {
    func accept<V: ArchExampleViewModelVisitorType>(visitor: V) -> V.Result
}

protocol ArchExampleViewModelVisitorType {
    associatedtype Result
    func visit(viewModel: ArchExampleViewModel.StringItem) -> Result
    func visit(viewModel: ArchExampleViewModel.LoadingItem) -> Result
    func visit(viewModel: ArchExampleViewModel.ErrorItem) -> Result
}

extension ArchExampleViewModel {

    enum State {
        case idle
        case loading
        case started(StartedState)
        case error
    }

    struct StartedState {
        let sections: [SectionViewModel]
    }

    struct SectionViewModel {
        let items: [ArchExampleViewModelElementType]
        let actionHandler: (() -> Void)?
    }

    struct StringItem: ArchExampleViewModelElementType {
        let title: String
        let actionHandler: (() -> Void)?

        func accept<V: ArchExampleViewModelVisitorType>(visitor: V) -> V.Result {
            visitor.visit(viewModel: self)
        }
    }

    struct LoadingItem: ArchExampleViewModelElementType {
        func accept<V: ArchExampleViewModelVisitorType>(visitor: V) -> V.Result {
            visitor.visit(viewModel: self)
        }
    }

    struct ErrorItem: ArchExampleViewModelElementType {
        func accept<V: ArchExampleViewModelVisitorType>(visitor: V) -> V.Result {
            visitor.visit(viewModel: self)
        }
    }
}
