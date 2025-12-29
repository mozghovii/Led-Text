import Foundation
import Combine

final class NetworkService {

    struct Request {
        enum Method: String { case GET, POST, PUT, PATCH, DELETE }

        let method: Method
        let path: String
        let query: [String: String]?

        init(method: Method, path: String, query: [String: String]? = nil) {
            self.method = method
            self.path = path
            self.query = query
        }
    }

    enum Error: Swift.Error {
        case network
        case decoding
        case backend(Int)
        case unknown
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func execute<Value: Decodable>(endpoint: Endpoint) -> AnyPublisher<Value, Error> {
        let req = endpoint.request

        var components = URLComponents(
            url: baseURL.appendingPathComponent(req.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = req.query?.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components?.url else {
            return Fail(error: .unknown).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = req.method.rawValue

        return session.dataTaskPublisher(for: request)
            .mapError { _ in Error.network }
            .tryMap { [decoder] data, response in
                guard let http = response as? HTTPURLResponse else {
                    throw Error.unknown
                }
                guard 200..<300 ~= http.statusCode else {
                    throw Error.backend(http.statusCode)
                }
                return try decoder.decode(Value.self, from: data)
            }
            .mapError { error in
                if error is DecodingError {
                    return .decoding
                }
                if let error = error as? Error {
                    return error
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
}
