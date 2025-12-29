import Combine
import Foundation

@MainActor
final class ArchExampleViewModel: ObservableObject {
    
    @Published private(set) var state: State = .idle
    
    private let service: ArchExampleService
    private var cancellables = Set<AnyCancellable>()
    
    init(service: ArchExampleService) {
        self.service = service
        bind()
    }
    
    func start() {
        state = .loading
        service.load()
    }
    
    private func bind() {
        service.$state
            .sink { [weak self] serviceState in
                guard let self else { return }
                
                switch serviceState {
                case .idle:
                    self.state = .idle
                case .loading:
                    self.state = .loading
                case .error:
                    self.state = .error
                case .loaded(let items):
                    configureSections(items)
                }
            }
            .store(in: &cancellables)
    }
    
    private func configureSections(_ items: [ArchExampleDTO]) {
        let section = SectionViewModel(
            items: items.map { item in
                StringItem(
                    title: item.title,
                    actionHandler: {
                        print("Tapped:", item.id)
                    }
                )
            },
            actionHandler: nil
        )
        self.state = .started(.init(sections: [section]))
    }
}
