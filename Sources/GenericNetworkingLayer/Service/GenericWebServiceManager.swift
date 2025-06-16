//
//  GenericWebServiceManager.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//

import Foundation
import Combine

final public class GenericWebServiceManager<RequestType: GenericWebServiceRequestable>: NSObject {

    // MARK: - PROPERTIES
    private let requestAdapter: GenericWebServiceRequestAdaptable
    private let jsonDecoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - INIT
    public init(requestAdapter: GenericWebServiceRequestAdaptable = GenericWebServiceRequestAdapter()) {
        self.requestAdapter = requestAdapter
        super.init()
    }

    // MARK: - METHODS
    public func fetchModel<ParametersType: Codable,
                           SuccessResponse: Codable,
                           ErrorResponse: Codable & Sendable>(request: RequestType,
                                                              parameters: ParametersType,
                                                              successResponseType: SuccessResponse.Type,
                                                              errorResponseType: ErrorResponse.Type) -> AnyPublisher<SuccessResponse, GenericWebServiceGenericError<ErrorResponse>> {
        let publisher = requestAdapter.fetch(request: request,
                                             parameters: parameters,
                                             errorType: errorResponseType)
        return publisher
            .tryMap({ try self.tryMapToReponse(data: $0,
                                               successResponseType: successResponseType,
                                               errorResponseType: errorResponseType) })
            .mapError({ self.mapError(error: $0,
                                      errorResponsType: errorResponseType) })
            .eraseToAnyPublisher()
    }

    // MARK: - ASYNC AWAIT COMPATIBILITY
    @MainActor
    public func fetchModel<ParametersType: Codable,
                           SuccessResponse: Codable,
                           ErrorResponse: Codable & Sendable>(request: RequestType,
                                                              parameters: ParametersType,
                                                              successResponseType: SuccessResponse.Type,
                                                              errorResponseType: ErrorResponse.Type) async throws -> SuccessResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SuccessResponse, Error>) in
            fetchModel(request: request,
                       parameters: parameters,
                       successResponseType: successResponseType,
                       errorResponseType: errorResponseType)
            .receive(on: DispatchQueue.main)
            .sink { result in
                switch result {
                case .finished:
                    return
                case .failure(let error):
                    Task { @MainActor in
                        continuation.resume(throwing: error)
                    }
                }
            } receiveValue: { response in
                Task { @MainActor in
                    continuation.resume(returning: response)
                }
            }
            .store(in: &cancellables)
        }
    }

    // MARK: - OWN METHODS
    private func tryMapToReponse<SuccessResponse: Codable,
                                 ErrorResponse: Codable & Sendable,>(data: Data,
                                                                    successResponseType: SuccessResponse.Type,
                                                                    errorResponseType: ErrorResponse.Type) throws -> SuccessResponse {
        do {
            let responseModel = try jsonDecoder.decode(SuccessResponse.self, from: data)
            return responseModel
        } catch {
            if let errorModel = try? jsonDecoder.decode(ErrorResponse.self,
                                                        from: data) {
                throw GenericWebServiceGenericError<ErrorResponse>.modelError(model: errorModel)
            } else {
                throw GenericWebServiceGenericError<ErrorResponse>.decodeError(error: error)
            }
        }
    }

    private func mapError<ErrorResponse: Codable & Sendable>(error: Error,
                                                             errorResponsType: ErrorResponse.Type) -> GenericWebServiceGenericError<ErrorResponse> {
        guard let mappedError = error as? GenericWebServiceGenericError<ErrorResponse> else {
            return .unknown(error: error)
        }
        return mappedError
    }

}
