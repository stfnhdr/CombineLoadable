//
//  LoadableState.swift
//  
//
//  Created by Stefan Haider on 23.02.23.
//

import Foundation
import Combine

public enum LoadableState<Output, Failure: Swift.Error> {
    case error(Failure)
    case value(Output?)
    case loading
}
