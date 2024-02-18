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
    public init() {}
    
    public func respond(to request: Vapor.Request, chainingTo next: AsyncResponder) async throws -> Response {
        let hub = Hub.new_from_top(other: Hub.current())
        
        return try await Hub.run(with: hub) {
            let name = "\(request.method) \(request.url.path)"
            let headers = Dictionary(uniqueKeysWithValues: request.headers.map { $0 })
            let req = SentrySwift.Request(
                method: request.method.string,
                url: request.url.path,
                query_string: request.url.query,
                headers: headers
            )
            
            let tr = Sentry.start_transaction(name: name, op: .http_server, headers: headers)
            hub.configure_scope {
                $0.set_span(span: tr)
            }
            tr.set_name_source(.route)
            tr.set_request(req)
            
            
            do {
                let response = try await next.respond(to: request)
                tr.set_status(response.status.intoSpanStatus())
                tr.finish()
                
                return response
            }catch {
                switch error {
                case let abort as AbortError:
                    tr.set_status(abort.status.intoSpanStatus())
                default:
                    Sentry.capture_error(error: error)
                }
            
                tr.finish()
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
