//
//  GenericWebServiceGenericError.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//

import Foundation

public enum GenericWebServiceGenericError<ErrorModelType: Codable>: Error {
    case invalidUrl
    case serviceFailure(statusCode: Int)
    case unknow(error: Error)
    case decodeError(error: Error)
    case modelError(model: ErrorModelType)
}
