//
//  GenericWebServiceRequestAdapter.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//

import Alamofire
import Foundation
import Combine

final public class GenericWebServiceRequestAdapter: GenericWebServiceRequestAdaptable, Sendable {

    // MARK: - PROPERTIES
    private let constants = GenericWebServiceRequestAdapterConstants()

    // MARK: - INIT
    public init() {
    }

    // MARK: - METHODS
    public func fetch<ParametersType: Sendable,
                      ErrorType: Codable & Sendable>(request: GenericWebServiceRequestable,
                                                     parameters: ParametersType,
                                                     errorType: ErrorType.Type) -> AnyPublisher<Data, Error>
                               where ParametersType : Encodable {
        guard let requestUrl = getUrlForRequest(request: request) else {
            return Fail(outputType: Data.self,
                        failure: GenericWebServiceGenericError<ErrorType>.invalidUrl)
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
        .tryMap { try self.mapResponseData(alamofireResponse: $0, errorType: errorType) }
        .eraseToAnyPublisher()
    }

    // MARK: - MAP
    private func mapResponseData<ErrorType: Codable & Sendable>(alamofireResponse: (DataResponse<Data, AFError>), errorType: ErrorType.Type) throws -> Data {
        switch alamofireResponse.result {
        case .failure(let error):
            switch error {
            case AFError.responseValidationFailed(reason: .unacceptableStatusCode(let code)):
                throw GenericWebServiceGenericError<ErrorType>.serviceFailure(statusCode: code)
            default:
                throw error
            }
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
