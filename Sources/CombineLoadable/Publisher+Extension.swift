//
//  Publisher+Extension.swift
//  PostApp
//
//  Created by Stefan Haider on 17.01.23.
//

import Foundation
import Combine

extension Publisher {
    
    // this only emits the first signal of an observer and all other one are ignored - use with caution (caching)
    public func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }
    
    public func handleResult(result: @escaping ((Result<Output, Failure>) -> Void)) -> AnyPublisher<Output, Failure> {
        return self.handleEvents(receiveOutput: { value in
            result(.success(value))
        }, receiveCompletion: { completion in
            guard case .failure(let error) = completion else { return }
            result(.failure(error))
        }).eraseToAnyPublisher()
    }

    public func observeLoadingStatus(on subject: PassthroughSubject<Bool, Never>) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveSubscription: { _ in
            // When fetching:
            subject.send(true)
        }, receiveCompletion: { _ in
            // When finish successfully or with error:
            subject.send(false)
        }, receiveCancel: {
            // When being cancelled:
            subject.send(false)
        }).eraseToAnyPublisher()
    }
    
    public func bindOutput(to subject: CurrentValueSubject<Output?, Never>) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveOutput: { output in
            subject.send(output)
        }).eraseToAnyPublisher()
    }
    
    public func removeErrorType() -> AnyPublisher<Output, Error> {
        return mapError({ return $0 as Error }).eraseToAnyPublisher()
    }
}

extension Publisher {
    
    public func sink() -> AnyCancellable {
        self.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
    
    public func sinkWithValue(_ receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        self.sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
    
    public func sinkWithResult(result: @escaping ((Result<Output, Failure>) -> Void)) -> AnyCancellable {
        self.sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                result(.failure(error))
            }
        }, receiveValue: { value in
            result(.success(value))
        })
    }
}
