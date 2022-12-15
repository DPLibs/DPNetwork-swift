//
//  DPNetworkRequestFactory.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import Foundation

public protocol DPNetworkRequestFactory {
    func produceURLRequest() throws -> URLRequest
}
