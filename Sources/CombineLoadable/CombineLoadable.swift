//
//  Loadable.swift
//  
//
//  Created by Stefan Haider on 23.01.23.
//

import Foundation
import Combine

public class Loadable<Output, Failure: Swift.Error>: ObservableObject {
    
    // MARK: - private properties
    
    private var cancellables = Set<AnyCancellable>()
    
    private let stateSubject = CurrentValueSubject<LoadableState<Output, Failure>, Never>(.value(nil))
    
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    
    private let errorSubject = PassthroughSubject<Failure?, Never>()
    
    private let outputSubject = CurrentValueSubject<Output?, Never>(nil)
    
    // MARK: - public computed properties
    
    public var value: Output? {
        return outputSubject.value
    }
    
    public var errorValue: Failure? {
        guard case let .error(error) = stateSubject.value else { return nil }
        return error
    }
    
    public var isLoading: Bool {
        guard case .loading = stateSubject.value else { return false }
        return true
    }
    
    public var currentState: LoadableState<Output, Failure> {
        return stateSubject.value
    }
    
    public var state: AnyPublisher<LoadableState<Output, Failure>, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    public var output: AnyPublisher<Output?, Never> {
        return outputSubject.eraseToAnyPublisher()
    }
    
    public var error: AnyPublisher<Failure?, Never> {
        return errorSubject.eraseToAnyPublisher()
    }
    
    public var loading: AnyPublisher<Bool, Never> {
        return isLoadingSubject.eraseToAnyPublisher()
    }
    
    // MARK: - public functions
    
    public init() {
        setupBindings()
    }
    
    public func setState(_ state: LoadableState<Output, Failure>) {
        stateSubject.send(state)
    }
    
    public func setValue(_ value: Output?) {
        stateSubject.send(.value(value))
    }
    
    // MARK: - private functions
    
    private func setupBindings() {
        stateSubject.sinkWithValue({ [weak self] state in
            guard let self = self else { return }

            switch state {
            case .loading:
                self.isLoadingSubject.send(true)
            case .error(let error):
                self.errorSubject.send(error)
                self.isLoadingSubject.send(false)
            case .value(let value):
                self.outputSubject.send(value)
                self.isLoadingSubject.send(false)
            }
        }).store(in: &cancellables)
    }
}
