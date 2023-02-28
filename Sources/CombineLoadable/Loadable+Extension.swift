//
//  Publisher+Extension.swift
//  
//
//  Created by Stefan Haider on 23.02.23.
//

import Foundation
import Combine

// MARK: - Loadable Extensions

extension Publisher {
    public func bind(to loadable: Loadable<Output, Failure>) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveSubscription: { _ in
            loadable.setState(.loading)
        }, receiveOutput: { output in
            loadable.setState(.value(output))
        }, receiveCompletion: { result in
            if case .failure(let error) = result {
                loadable.setState(.error(error))
            }
        }).eraseToAnyPublisher()
    }
    
}
