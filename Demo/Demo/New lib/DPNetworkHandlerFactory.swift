//
//  DPNetworkResponseFactory.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import Foundation



//protocol SerilizerFactory {
//    associatedtype SerilizeResult
//    
//    func serilize(data: Data?, urlResponse: URLResponse?, error: Error?) -> SerilizeResult
//}
//
//struct SerilizerFactory2<Mapper: DPNetworkMapperFactory>: SerilizerFactory where Mapper.Input: Decodable {
//    typealias SerilizeResult = Result<Mapper.Output, Error>
//    
//    let mapper: Mapper
//    var jsonDecoder = JSONDecoder()
//    
//    func serilize(data: Data?, urlResponse: URLResponse?, error: Error?) -> SerilizeResult {
//        if let error = error {
//            return .failure(error)
//        } else if let data = data {
//            do {
//                let json = try self.jsonDecoder.decode(Mapper.Input.self, from: data)
//                let output = try self.mapper.map(json)
//                return .success(output)
//            } catch {
//                return .failure(error)
//            }
//        } else {
//            return .failure(NSError(domain: "", code: 0))
//        }
//    }
//}
//
//struct SerilizerFactory1: SerilizerFactory {
//    
//    func serilize(data: Data?, urlResponse: URLResponse?, error: Error?) -> DPNetworkResultEmpty {
//        if let error = error {
//            return .failure(error)
//        } else {
//            return .success
//        }
//    }
//}
//
//struct Mapper: DPNetworkMapperFactory {
//    func map(_ input: Never) throws -> Never {}
//}
//
////protocol SerilizerFactory2: SerilizerFactory {
////    associatedtype Failture: Error
////    associatedtype Mapper: DPNetworkMapperFactory
////    associatedtype SerilizeResult = Result<Mapper.Output, Failture>
////
////    var mapper: Mapper { get set }
////
////    func serilize(data: Data?, urlResponse: URLResponse?, error: Error?) -> SerilizeResult
////}
//
////protocol SerilizerFactory1: SerilizerFactory {
////    associatedtype Failture: Error
////    associatedtype SerilizeResult = DPNetworkResultEmpty<Failture>
////
////    func serilize(data: Data?, urlResponse: URLResponse?, error: Error?) -> SerilizeResult
////}
//
//struct Iii: DPNetworkRequestFactory {
//    
//    func produceURLRequest() throws -> URLRequest {
//        guard let url = URL(string: "jhjh") else {
//            throw NSError(domain: "", code: 0)
//        }
//        return URLRequest(url: url)
//    }
//    
//}
//
//open class Service {
//
//    var jsonDecoder = JSONDecoder()
//    var outpuQueue: DispatchQueue = .main
//    
//    func ttt() {
//        let service = Service()
////        service.load(request: Iii(), mapper: Mapper()) { result in
////            switch result {
////            case .success(let success):
////            print("!!!", success)
////            case .failure(let failure):
////                print("!!!", failure)
////            }
////        }
//    }
//    
//    func load<Serilizer: SerilizerFactory>(
//        request: DPNetworkRequestFactory,
//        serlizer: Serilizer,
//        completion: @escaping (Serilizer.SerilizeResult) -> Void
//    ) {
//        do {
//            let urlRequest = try request.produceURLRequest()
//            
//            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { [weak self] data, urlResponse, error in
//                let result = serlizer.serilize(data: data, urlResponse: urlResponse, error: error)
//                completion(result)
//            })
//        } catch {
////            completion(.failure(error))
//        }
//    }
//    
//    func load<Mapper: DPNetworkMapperFactory>(
//        request: DPNetworkRequestFactory,
//        mapper: Mapper,
//        completion: @escaping (Result<Mapper.Output, Error>) -> Void
//    ) where Mapper.Input: Decodable {
//        do {
//            let urlRequest = try request.produceURLRequest()
//            
//            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { [weak self] data, urlResponse, error in
//                self?.serilize(mapper: mapper, data: data, urlResponse: urlResponse, error: error, completion: completion)
//            })
//        } catch {
//            completion(.failure(error))
//        }
//    }
//    
//    func serilize<Mapper: DPNetworkMapperFactory>(
//        mapper: Mapper,
//        data: Data?,
//        urlResponse: URLResponse?,
//        error: Error?,
//        completion: @escaping (Result<Mapper.Output, Error>) -> Void
//    ) where Mapper.Input: Decodable {
//        if let error = error {
//            completion(.failure(error))
//        } else if let data = data {
//            do {
//                let json = try self.jsonDecoder.decode(Mapper.Input.self, from: data)
//                let output = try mapper.map(json)
//                completion(.success(output))
//            } catch {
//                completion(.failure(error))
//            }
//        }
//    }
//    
//}

//public protocol DPNetworkHandlerFactory {
//    associatedtype Mapper: DPNetworkMapperFactory
//    associatedtype Output
//    typealias HandlerResult = Result<Output, Error>
//
//    func prepareURLResponse(data: Data?, mapper: Mapper) -> HandlerResult
//}
//
//class DPNetworkModelHandler<Mapper: DPNetworkMapperFactory>: DPNetworkHandlerFactory {
//
//
//    func prepareURLResponse(data: Data?, mapper: Mapper) -> Result<Mapper.Model, Error> {
//        do {
//            guard let data = data else {
//                throw NSError(domain: "Data error", code: 0)
//            }
//
//            let response = try JSONDecoder().decode(Mapper.Response.self, from: data)
//            let model = try mapper.mapResponseToModel(response)
//            return .success(model)
//        } catch {
//            return .failure(error)
//        }
//    }
//
//}

//public protocol DPNetworkDataHandlerFactory {
//    associatedtype Output
//    
//    func handle(_ data: Data?) -> Output
//}
//
//struct DPNetworkEmptyHandler: DPNetworkDataHandlerFactory {
//    func handle(_ data: Data?) -> DPNetworkEmptyResult {
//        .success
//    }
//}
//
//struct DPNetworkModelHanlder<Mapper: DPNetworkMapperFactory>: DPNetworkDataHandlerFactory {
//    let mapper: Mapper
//    
//    func handle(_ data: Data?) -> Result<Mapper.Model, Error> {
//        do {
//            guard let data = data else {
//                throw NSError(domain: "Data error", code: 0)
//            }
//
//            let response = try JSONDecoder().decode(Mapper.Response.self, from: data)
//            let model = try mapper.mapResponseToModel(response)
//            return .success(model)
//        } catch {
//            return .failure(error)
//        }
//    }
//    
//}
//
//struct DPNetworkModelsHanlder<Mapper: DPNetworkMapperFactory>: DPNetworkDataHandlerFactory {
//    let mapper: Mapper
//    
//    func handle(_ data: Data?) -> Result<[Mapper.Model], Error> {
//        do {
//            guard let data = data else {
//                throw NSError(domain: "Data error", code: 0)
//            }
//
//            let response = try JSONDecoder().decode([Mapper.Response].self, from: data)
//            
//            let models = response.compactMap { response in
//                try? self.mapper.mapResponseToModel(response)
//            }
//            
//            return .success(models)
//        } catch {
//            return .failure(error)
//        }
//    }
//    
//}
