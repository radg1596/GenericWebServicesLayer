//
//  GenericHTTPHeader.swift
//  GenericNetworkingLayer
//
//  Created by Ricardo on 12/06/25.
//
import Foundation
import Alamofire

public struct GenericHTTPHeader {

    // MARK: - PROPERTIES
    let name: String
    let value: String

    // MARK: - INIT
    public init(name: String,
                value: String) {
        self.name = name
        self.value = value
    }

}

// MARK: - ADAPT ALAMO
extension Array where Element == GenericHTTPHeader {

    func adaptToAlamofireType() -> HTTPHeaders {
        var headers: HTTPHeaders = [:]
        for header in self {
            headers.add(.init(name: header.name,
                              value: header.value))
        }
        return headers
    }
}
