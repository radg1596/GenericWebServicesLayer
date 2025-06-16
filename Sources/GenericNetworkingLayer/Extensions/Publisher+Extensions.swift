//
//  Publisher+Extensions.swift
//  GenericNetworkingLayer
//
//  Created by Ricardo on 14/06/25.
//
import Combine

// MARK: - PUBLISHER
public extension Publisher where Failure == GenericWebServiceGenericError<GenericWebServiceGenericErrorModel> {

    // MARK: - METHODS
    func replaceEmptyStatusCodeWith(storeInSet: inout Set<AnyCancellable>,
                                    replacement: @escaping () -> Output) -> AnyPublisher<Output, Failure> {
        let publisher = PassthroughSubject<Output, Failure>()
        sink { result in
            switch result {
            case .finished:
                publisher.send(completion: .finished)
            case .failure(let error):
                switch error {
                case .serviceFailure(statusCode: 404):
                    publisher.send(replacement())
                default:
                    publisher.send(completion: .failure(error))
                }
            }
        } receiveValue: { output in
            publisher.send(output)
        }
        .store(in: &storeInSet)
        return publisher
            .eraseToAnyPublisher()
    }

}
