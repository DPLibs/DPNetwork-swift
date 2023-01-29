//
//  DPNetworkEmptyResult.swift
//  Demo
//
//  Created by Дмитрий Поляков on 29.01.2023.
//

import Foundation

enum DPNetworkResultEmpty<Failure: Error> {
    case success
    case failure(Failure)
}
