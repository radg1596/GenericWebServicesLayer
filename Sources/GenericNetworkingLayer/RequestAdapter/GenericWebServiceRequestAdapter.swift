//
//  GenericWebServiceRequestAdapter.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//

import Alamofire
import Foundation
import Combine

final public class GenericWebServiceRequestAdapter: GenericWebServiceRequestAdaptable {

    // MARK: - PROPERTIES
    private let constants = GenericWebServiceRequestAdapterConstants()

    // MARK: - ERROR
    enum InternalError: Error {
        case invalidUrl
        case invalidData
    }

    // MARK: - INIT
    public init() {
    }

    // MARK: - METHODS
    public func fetch<ParametersType>(request: GenericWebServiceRequestable,
                               parameters: ParametersType) -> AnyPublisher<Data, Error>
                               where ParametersType : Encodable {
        guard let requestUrl = getUrlForRequest(request: request) else {
            return Fail(outputType: Data.self,
                        failure: InternalError.invalidUrl)
            .eraseToAnyPublisher()
        }
        return AF.request(requestUrl,
                          method: request.method.alamofireEquivalent,
                          parameters: parameters,
                          encoder: getParameterEncoder(request: request),
                          headers: request.headers.adaptToAlamofireType(),
                          requestModifier: { request in
            request.cachePolicy = .reloadIgnoringCacheData
        })
        .validate(statusCode: self.constants.successStatusRange)
        .validate(contentType: self.constants.contentTypeValidation)
        .publishData()
        .tryMap(mapResponseData(alamofireResponse:))
        .eraseToAnyPublisher()
    }

    // MARK: - MAP
    private func mapResponseData(alamofireResponse: (DataResponse<Data, AFError>)) throws -> Data {
        switch alamofireResponse.result {
        case .failure:
            throw InternalError.invalidData
        case .success(let data):
            return data
        }
    }

    // MARK: - OWN METHODS
    private func getUrlForRequest(request: GenericWebServiceRequestable) -> URL? {
        let baseUrlString: String = request.baseUrl
        guard var urlComponents = URLComponents(string: baseUrlString) else {
            return nil
        }
        urlComponents.path += request.endPointPath
        if let queriesItems = request.queryItems {
            urlComponents.queryItems = queriesItems
        }
        return urlComponents.url
    }

    private func getParameterEncoder(request: GenericWebServiceRequestable) -> ParameterEncoder {
        switch request.method {
        case .get:
            return URLEncodedFormParameterEncoder(destination: .methodDependent)
        case .post, .put, .patch, .delete:
            return JSONParameterEncoder.default
        }
    }

}
