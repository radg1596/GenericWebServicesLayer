//
//  GenericHTTPMethod.swift
//  GenericNetworkingLayer
//
//  Created by Ricardo on 12/06/25.
//
import Foundation
import Alamofire

public enum GenericHTTPMethod {

    // MARK: - CASES
    case get
    case post
    case put
    case patch
    case delete

    // MARK: - ADAPT
    var alamofireEquivalent: HTTPMethod {
        switch self {
        case .get:
            return .get
        case .post:
            return .post
        case .put:
            return .put
        case .patch:
            return .patch
        case .delete:
            return .delete
        }
    }

}
