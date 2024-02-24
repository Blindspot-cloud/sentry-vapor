//
//  HTTPHeaders+SentryTrace.swift
//
//
//  Created by Max Müller on 24.02.2024.
//

import Vapor


public extension HTTPHeaders.Name {
    static let sentryTrace = HTTPHeaders.Name("sentry-trace")
}
