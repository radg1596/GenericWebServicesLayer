//
//  GenericWebServiceRequestable.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//
import Foundation

public protocol GenericWebServiceRequestable {
    var baseUrl: String { get }
    var endPointPath: String { get }
    var method: GenericHTTPMethod { get }
    var headers: [GenericHTTPHeader] { get }
    var timeOut: Double { get }
    var queryItems: [URLQueryItem]? { get }
}
