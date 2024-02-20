//
//  SentryVaporMiddleware.swift
//
//
//  Created by Max Müller on 09.02.2024.
//

import Vapor
import SentrySwift



/// Sentry middleware for Vapor
/// It makes every request a transaction and sets Task local hub for the request
///
/// ```
/// app.middleware.use(SentryVaporMiddleware())
/// ```
/// > Warning: Sentry SDK should be initialized else this middleware will do nothing
///
public struct SentryVaporMiddleware: AsyncMiddleware {
    private let filter: (Vapor.Request) -> Bool;
    
    public init(filter: (@escaping (Vapor.Request) -> Bool) = { _ in true }) {
        self.filter = filter
    }
    
    public func respond(to request: Vapor.Request, chainingTo next: AsyncResponder) async throws -> Response {
        if self.filter(request) == false {
            return try await next.respond(to: request)
        }
        
        request.logger.info("Createing new HUB: \(request.url.path)")
        let hub = Hub.new_from_top(other: Hub.current())
        
        request.logger.info("Starting Task with new HUB: \(request.url.path)")
        return try await Hub.run(with: hub) {
            request.logger.info("Parsing metadata: \(request.url.path)")
            let name = "\(request.method) \(request.url.path)"
            let headers = Dictionary(uniqueKeysWithValues: request.headers.map { $0 })
            let req = SentrySwift.Request(
                method: request.method.string,
                url: request.url.path,
                query_string: request.url.query,
                headers: headers
            )
            
            request.logger.info("Starting Transaction: \(request.url.path)")
            let tr = Sentry.start_transaction(name: name, op: .http_server, headers: headers)
            hub.configure_scope {
                $0.set_span(span: tr)
            }
            tr.set_name_source(.route)
            tr.set_request(req)
            
            
            do {
                request.logger.info("Running next middleware: \(request.url.path)")
                let response = try await next.respond(to: request)
                tr.set_status(response.status.intoSpanStatus())
                
                request.logger.info("Finished: \(request.url.path)")
                tr.finish()
                
                return response
            }catch {
                request.logger.info("Catching error: \(request.url.path)")
                switch error {
                case let abort as AbortError:
                    tr.set_status(abort.status.intoSpanStatus())
                default:
                    Sentry.capture_error(error: error)
                }
            
                tr.finish()
                request.logger.info("Throwing error: \(request.url.path)")
                throw error
            }
        }
    }
}


extension HTTPResponseStatus {
    func intoSpanStatus() -> SpanStatus {
        switch self.code {
        case 401:
            return .unauthenticated
        case 403: 
            return .permission_denied
        case 404:
            return .not_found
        case 429:
            return .resource_exhausted
        case 400...499:
            return .invalid_argument
        case 501:
            return .unimplemented
        case 503:
            return .unavailable
        case 500...599:
            return .internal_error
        case 200...299:
            return .ok
        default:
            return .unknown
        }
    }
}
