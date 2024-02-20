
# Sentry Vapor 

This library contains Sentry integration for Vapor swift framework.


## What it does?

* Creates per request Task local Hub - because of that every request has own Hub instance used for scopes etc.
* Tracks incoming requests as transactions and accepts `sentry-trace` header to continue trace.
* Reports any non-HTTP errors throwed by routes/middleware as errors to sentry

## How to use it

```swift
import Vapor
import SentryVapor
 
let app = try Application(.detect())
defer { app.shutdown() }

// Initialize Sentry Middleware
app.middleware.use(SentryVaporMiddleware() { req in 
    // Filter out endpoints that contain __health in path
    return !req.url.path.contains("__health")
})

app.get("hello") { req in
    return "Hello, world."
}

try app.run()

```