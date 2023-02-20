//
//  DPNetworkEmptyResult.swift
//  Demo
//
//  Created by Дмитрий Поляков on 29.01.2023.
//

import Foundation

// TODO: - 1. Implement paging
// TODO: - 2. URLRequest constructor
// TODO: - 3. Tasks array (show Almofare)
// TODO: - 4. Flags: isLoading, isLoadAll

public typealias DPNResult<Success> = Result<Success, Error>

public struct DPNError: LocalizedError, Equatable {
    
    // MARK: - Init
    public init(id: String, message: String) {
        self.id = id
        self.message = message
    }
    
    // MARK: - Props
    public let id: String
    public let message: String
    
    // MARK: - LocalizedError
    public var errorDescription: String? {
        self.message
    }
    
    public var failureReason: String? {
        self.message
    }
    
    // MARK: - Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Store
    public static let failtureMap = DPNError(id: "failtureMap", message: "Failture map")
    public static let failtureURLRequest = DPNError(id: "failtureURLRequest", message: "Failture URLRequest")
    public static let emptyData = DPNError(id: "emptyData", message: "Empty data")
    public static let emptyURLResponse = DPNError(id: "emptyURLResponse", message: "Empty URLResponse")
    
    public static func failtureURLResponseStatusCode(_ statusCode: Int) -> DPNError {
        DPNError(id: "failtureURLResponseStatusCode", message: "Failture URLResponse statusCode - \(statusCode)")
    }
    
}

public protocol DPNMapperFactory {
    associatedtype Input
    associatedtype Output
    
    func map(_ input: Input) throws -> Output
}

extension DPNMapperFactory {
    
    func toArrayMapper() -> DPNArrayMapper<Self> {
        DPNArrayMapper<Self>(mapper: self)
    }
    
}

public struct DPNArrayMapper<Mapper: DPNMapperFactory>: DPNMapperFactory {
    
    // MARK: - Init
    public init(mapper: Mapper) {
        self.mapper = mapper
    }
    
    // MARK: - Props
    public let mapper: Mapper
    
    // MARK: - Methods
    public func map(_ input: [Mapper.Input]) throws -> [Mapper.Output] {
        var outputs: [Mapper.Output] = []
        var mappingError: Error?
        
        for inputElement in input {
            do {
                let output = try self.mapper.map(inputElement)
                outputs.append(output)
            } catch {
                mappingError = error
                break
            }
        }
        
        if let error = mappingError {
            throw error
        } else {
            return outputs
        }
    }
}

public protocol DPNURLRequestFactory {
    func produce() throws -> URLRequest
}

public struct DPNURLRequest: DPNURLRequestFactory {
    
    public let url: URL?
    
    public func produce() throws -> URLRequest {
        guard let url = self.url else { throw DPNError.failtureURLRequest }
        
        return URLRequest(url: url)
    }
    
}

public struct DPNEmptyMapper: DPNMapperFactory {
    public func map(_ input: DPNEmptyResponse) throws -> Void {}
}

public struct DPNEmptyResponse: Decodable {}

public protocol DPNServiceInterface: AnyObject {
    func loadData(request: DPNURLRequestFactory, completion: @escaping (DPNResult<Data?>) -> Void) -> URLSessionTask?
    func load<Mapper: DPNMapperFactory>(request: DPNURLRequestFactory, mapper: Mapper, completion: @escaping (DPNResult<Mapper.Output>) -> Void) -> URLSessionTask? where Mapper.Input: Decodable
}

open class DPNService: NSObject, DPNServiceInterface {

    // MARK: - Init
    public init(urlSession: URLSession = .shared, jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.urlSession = urlSession
        self.jsonDecoder = jsonDecoder
    }

    // MARK: - Props
    open var urlSession: URLSession
    open var jsonDecoder: JSONDecoder
    open private(set) var task: URLSessionTask?

    // MARK: - Methods
    @discardableResult
    open func loadData(request: DPNURLRequestFactory, completion: @escaping (DPNResult<Data?>) -> Void) -> URLSessionTask? {
        do {
            let urlRequest = try request.produce()

            let task = self.urlSession.dataTask(with: urlRequest) { [weak self] data, urlResponse, error in
                guard let self = self else { return }

                do {
                    try self.serilizeDataTaskCompletion(data: data, urlResponse: urlResponse, error: error)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            }
            self.task = task
            self.task?.resume()
            return task
        } catch {
            completion(.failure(error))
            return nil
        }
    }
    
    @available(iOS 13.0.0, *)
    open func loadData(request: DPNURLRequestFactory) async throws -> Data? {
        do {
            let urlRequest = try request.produce()
            let (data, urlResponse) = try await self.urlSession.data(for: urlRequest)
            try self.serilizeDataTaskCompletion(data: data, urlResponse: urlResponse, error: nil)
            return data
        } catch {
            throw error
        }
    }

    @discardableResult
    open func load<Mapper: DPNMapperFactory>(
        request: DPNURLRequestFactory,
        mapper: Mapper = DPNEmptyMapper(),
        completion: @escaping (DPNResult<Mapper.Output>) -> Void
    ) -> URLSessionTask? where Mapper.Input: Decodable {
        self.loadData(request: request) { [weak self] result in
            guard let self = self else { return }

            do {
                switch result {
                case let .failure(error):
                    throw error
                case let .success(data):
                    let response: Mapper.Input = try self.decodeData(data)
                    let success: Mapper.Output = try mapper.map(response)
                    completion(.success(success))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    @available(iOS 13.0.0, *)
    open func load<Mapper: DPNMapperFactory>(request: DPNURLRequestFactory, mapper: Mapper = DPNEmptyMapper()) async throws -> Mapper.Output where Mapper.Input: Decodable {
        do {
            let data = try await self.loadData(request: request)
            let response: Mapper.Input = try self.decodeData(data)
            let success: Mapper.Output = try mapper.map(response)
            return success
        } catch {
            throw error
        }
    }

    open func serilizeDataTaskCompletion(data: Data?, urlResponse: URLResponse?, error: Error?) throws {
        if let error = error {
            throw error
        } else {
            guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
                throw DPNError.emptyURLResponse
            }

            switch httpURLResponse.statusCode {
            case 200..<300:
                return
            default:
                throw DPNError.failtureURLResponseStatusCode(httpURLResponse.statusCode)
            }
        }
    }

    open func decodeData<Response: Decodable>(_ data: Data?) throws -> Response {
        if let data = data {
            return try self.jsonDecoder.decode(Response.self, from: data)
        } else {
            throw DPNError.emptyData
        }
    }

}

open class DPNArrayTask<Mapper: DPNMapperFactory>: NSObject where Mapper.Input: Decodable {
    
    // MARK: - Init
    public init(mapper: Mapper) {
        self.mapper = mapper
        self.isLoadAll = false
    }
    
    // MARK: - Props
    open var mapper: Mapper
    open fileprivate(set) var isLoadAll: Bool
    open fileprivate(set) weak var task: URLSessionTask?
    
    // MARK: - Methods
    open func produce(request: DPNURLRequestFactory) throws -> URLRequest {
        try request.produce()
    }
}

extension DPNService {
    
//    func loadArray<Mapper: DPNMapperFactory>(_ task: DPNArrayTask<Mapper>) {
//        do {
//            let urlRequest = try task.produce(request: <#T##DPNURLRequestFactory#>)
//        } catch {
//            
//        }
//    }
    
}

/// 1. Array service container
//open class DPNArrayService: NSObject {
//
//    // MARK: - Init
//    public init(service: DPNServiceInterface = DPNService()) {
//        self.service = service
//        self.isLoadAll = false
//    }
//
//    // MARK: - Props
//    open var service: DPNServiceInterface
//    open private(set) var isLoadAll: Bool
//    open private(set) var task: URLSessionTask?
//
//    public var isLoading: Bool {
//        self.task?.state == .running
//    }
//
//    // MARK: - Methods
//    open func load<Mapper: DPNMapperFactory>(
//        request: DPNURLRequestFactory,
//        mapper: Mapper,
//        isReload: Bool,
//        limit: Int = 10,
//        completion: @escaping (DPNResult<[Mapper.Output]>) -> Void
//    ) where Mapper.Input: Decodable {
//        if isReload {
//            self.isLoadAll = false
//            self.task?.cancel()
//        }
//
//        guard !self.isLoading, !self.isLoadAll else { return }
//
//        self.task = self.service.load(request: request, mapper: mapper.toArrayMapper()) { [weak self] result in
//            guard let self = self else { return }
//
//            switch result {
//            case let .failure(error):
//                completion(.failure(error))
//            case let .success(array):
//                self.isLoadAll = array.count < limit
//                completion(.success(array))
//            }
//        }
//    }
//
//}
//
//extension DPNService {
//
//    func toArrayService() -> DPNArrayService {
//        DPNArrayService(service: self)
//    }
//
//}


//public protocol DPNDecoderFactory {
//    associatedtype Output
//
//    func decodeData(_ data: Data?) throws -> Output
//}
//
//open class DPNEmptyDecoder: DPNDecoderFactory {
//    open func decodeData(_ data: Data?) throws -> Void {}
//}
//
//open class DPNDecoder<Mapper: DPNMapperFactory>: DPNDecoderFactory where Mapper.Input: Decodable {
//
//    // MARK: - Init
//    public init(mapper: Mapper, jsonDecoder: JSONDecoder = JSONDecoder()) {
//        self.mapper = mapper
//        self.jsonDecoder = JSONDecoder()
//    }
//
//    // MARK: - Props
//    open var mapper: Mapper
//    open var jsonDecoder: JSONDecoder
//
//    // MARK: - Methods
//    open func decodeData(_ data: Data?) throws -> Mapper.Output {
//        guard let data = data else {
//            throw DPNError.emptyData
//        }
//
//        do {
//            let response = try self.jsonDecoder.decode(Mapper.Input.self, from: data)
//            let output = try mapper.map(response)
//            return output
//        } catch {
//            throw error
//        }
//    }
//
//}


/// 1. Serilize in service. Two methods
//open class DPNService: NSObject {
//
//    // MARK: - Init
//    public override init() {
//        self.urlSession = URLSession.shared
//        self.jsonDecoder = JSONDecoder()
//    }
//
//    // MARK: - Props
//    open var urlSession: URLSession
//    open var jsonDecoder: JSONDecoder
//
//    // MARK: - Methods
//    open func load(request: DPNURLRequestFactory, completion: @escaping (DPNResult<Data?>) -> Void) {
//        do {
//            let urlRequest = try request.produce()
//
//            let task = self.urlSession.dataTask(with: urlRequest) { [weak self] data, urlResponse, error in
//                guard let self = self else { return }
//
//                do {
//                    try self.serilizeDataTaskCompletion(data: data, urlResponse: urlResponse, error: error)
//                    completion(.success(data))
//                } catch {
//                    completion(.failure(error))
//                }
//            }
//        } catch {
//            completion(.failure(error))
//        }
//    }
//
//    open func load<Mapper: DPNMapperFactory>(request: DPNURLRequestFactory, mapper: Mapper, completion: @escaping (DPNResult<Mapper.Output>) -> Void) where Mapper.Input: Decodable {
//        self.load(request: request) { [weak self] result in
//            guard let self = self else { return }
//
//            do {
//                switch result {
//                case let .failure(error):
//                    throw error
//                case let .success(data):
//                    let response: Mapper.Input = try self.decodeData(data)
//                    let output: Mapper.Output = try mapper.map(response)
//                    completion(.success(output))
//                }
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    }
//
//    open func serilizeDataTaskCompletion(data: Data?, urlResponse: URLResponse?, error: Error?) throws {
//        if let error = error {
//            throw error
//        } else {
//            guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
//                throw DPNError.emptyURLResponse
//            }
//
//            switch httpURLResponse.statusCode {
//            case 200...299:
//                return
//            default:
//                throw DPNError.failtureURLResponseStatusCode(httpURLResponse.statusCode)
//            }
//        }
//    }
//
//    open func decodeData<Response: Decodable>(_ data: Data?) throws -> Response {
//        if let data = data {
//            return try self.jsonDecoder.decode(Response.self, from: data)
//        } else {
//            throw DPNError.emptyData
//        }
//    }
//
//}

/// 2. With serilizer
//open class DPNService: NSObject {
//
//    // MARK: - Init
//    public override init() {
//        self.urlSession = URLSession.shared
//        self.jsonDecoder = JSONDecoder()
//    }
//
//    // MARK: - Props
//    open var urlSession: URLSession
//    open var jsonDecoder: JSONDecoder
//
//    // MARK: - Methods
//    open func load<Decoder: DPNSerilizerFactory>(request: DPNURLRequestFactory, decoder: Decoder, completion: @escaping (DPNResult<Decoder.Output>) -> Void) {
//        do {
//            let urlRequest = try request.produce()
//
//            let task = self.urlSession.dataTask(with: urlRequest) { [weak self] data, urlResponse, error in
//                guard let self = self else { return }
//
//                do {
//                    try self.serilizeDataTaskCompletion(data: data, urlResponse: urlResponse, error: error)
//                    let success = try decoder.decodeData(data)
//                    completion(.success(success))
//                } catch {
//                    completion(.failure(error))
//                }
//            }
//        } catch {
//            completion(.failure(error))
//        }
//    }
//
//    open func serilizeDataTaskCompletion(data: Data?, urlResponse: URLResponse?, error: Error?) throws {
//        if let error = error {
//            throw error
//        } else {
//            guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
//                throw DPNError.emptyURLResponse
//            }
//
//            switch httpURLResponse.statusCode {
//            case 200...299:
//                return
//            default:
//                throw DPNError.failtureURLResponseStatusCode(httpURLResponse.statusCode)
//            }
//        }
//    }
//
//    open func decodeData<Response: Decodable>(_ data: Data?) throws -> Response {
//        if let data = data {
//            return try self.jsonDecoder.decode(Response.self, from: data)
//        } else {
//            throw DPNError.emptyData
//        }
//    }
//
//}
//public enum DPNResultEmpty {
//    case success
//    case failure(Error)
//}
//typealias DPNDataTaskCompletion = (data: Data?, urlResponse: URLResponse?, error: Error?)
//typealias DPNSerilizeResult = DPNResult<Data>
