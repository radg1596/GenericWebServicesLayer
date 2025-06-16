//
//  GenericWebServiceRequestAdaptable.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//

import Foundation
import Combine

public protocol GenericWebServiceRequestAdaptable: AnyObject {
    func fetch<ParametersType: Codable,
               ErrorType: Codable & Sendable>(request: GenericWebServiceRequestable,
                                              parameters: ParametersType,
                                              errorType: ErrorType.Type)-> AnyPublisher<Data, Error>
}
