//
//  DPNetworkMapperFactory.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import Foundation

public protocol DPNetworkMapperFactory {
    associatedtype Response: Decodable
    associatedtype Model
    
    func mapResponseToModel(_ response: Response) throws -> Model
}
