//
//  DPNetworkResponseFactory.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import Foundation

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

enum DPNetworkEmptyResult {
    case success
    case error(Error)
}

public protocol DPNetworkDataHandlerFactory {
    associatedtype Output
    
    func handle(_ data: Data?) -> Output
}

struct DPNetworkEmptyHandler: DPNetworkDataHandlerFactory {
    func handle(_ data: Data?) -> DPNetworkEmptyResult {
        .success
    }
}

struct DPNetworkModelHanlder<Mapper: DPNetworkMapperFactory>: DPNetworkDataHandlerFactory {
    let mapper: Mapper
    
    func handle(_ data: Data?) -> Result<Mapper.Model, Error> {
        do {
            guard let data = data else {
                throw NSError(domain: "Data error", code: 0)
            }

            let response = try JSONDecoder().decode(Mapper.Response.self, from: data)
            let model = try mapper.mapResponseToModel(response)
            return .success(model)
        } catch {
            return .failure(error)
        }
    }
    
}

struct DPNetworkModelsHanlder<Mapper: DPNetworkMapperFactory>: DPNetworkDataHandlerFactory {
    let mapper: Mapper
    
    func handle(_ data: Data?) -> Result<[Mapper.Model], Error> {
        do {
            guard let data = data else {
                throw NSError(domain: "Data error", code: 0)
            }

            let response = try JSONDecoder().decode([Mapper.Response].self, from: data)
            
            let models = response.compactMap { response in
                try? self.mapper.mapResponseToModel(response)
            }
            
            return .success(models)
        } catch {
            return .failure(error)
        }
    }
    
}
