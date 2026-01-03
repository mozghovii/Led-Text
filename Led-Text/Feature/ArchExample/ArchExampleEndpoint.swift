enum ArchExampleEndpoint: Endpoint {
    case list

    var request: NetworkService.Request {
        switch self {
        case .list:
            return .init(method: .GET, path: "/arch-example", query: nil)
        }
    }
}
