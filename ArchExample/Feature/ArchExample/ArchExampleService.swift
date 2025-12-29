import Combine

final class ArchExampleService {

    enum State {
        case idle
        case loading
        case loaded([ArchExampleDTO])
        case error
    }

    @Published private(set) var state: State = .idle

    private let network: NetworkService
    private var cancellables = Set<AnyCancellable>()

    init(network: NetworkService) {
        self.network = network
    }

    func load() {
        state = .loading

        network.execute(endpoint: ArchExampleEndpoint.list)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.state = .error
                    }
                },
                receiveValue: { [weak self] (items: [ArchExampleDTO]) in
                    self?.state = .loaded(items)
                }
            )
            .store(in: &cancellables)
    }
}

struct ArchExampleDTO: Decodable {
    let id: String
    let title: String
}
