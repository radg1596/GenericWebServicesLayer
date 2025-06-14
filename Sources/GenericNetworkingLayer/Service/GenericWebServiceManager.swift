//
//  GenericWebServiceManager.swift
//  watchSeriesRemakeSwiftUI
//
//  Created by Ricardo Desiderio on 08/11/22.
//

import Foundation
import Combine

final public class GenericWebServiceManager<RequestType: GenericWebServiceRequestable,
                                            SuccessResponse: Codable,
                                            ErrorResponse: Codable & Sendable>: NSObject {

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
    public func fetchModel<ParametersType: Codable>(request: RequestType,
                                                    parameters: ParametersType) -> AnyPublisher<SuccessResponse, GenericWebServiceGenericError<ErrorResponse>> {
        let publisher = requestAdapter.fetch(request: request, parameters: parameters)
        return publisher
            .tryMap({ try self.tryMapToReponse(data: $0) })
            .mapError({ self.mapError(error: $0) })
            .eraseToAnyPublisher()
    }

    // MARK: - ASYNC AWAIT COMPATIBILITY
    @MainActor
    public func fetchModel<ParametersType: Codable>(request: RequestType,
                                                    parameters: ParametersType) async throws -> SuccessResponse {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SuccessResponse, Error>) in
            fetchModel(request: request,
                       parameters: parameters)
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
    private func tryMapToReponse(data: Data) throws -> SuccessResponse {
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

    private func mapError(error: Error) -> GenericWebServiceGenericError<ErrorResponse> {
        guard let mappedError = error as? GenericWebServiceGenericError<ErrorResponse> else {
            return .unknown(error: error)
        }
        return mappedError
    }

}
