
# Sentry Vapor 

This library contains Sentry integration for Vapor swift framework

# Usage

Sentry needs to be initialized for the middleware to work.

So for example:
```swift
let dsn = try Dsn(
    fromString: "SENTRY_DSN"
)
let sentryGuard = try Sentry.initialize(dsn: dsn)

app.middleware.use(SentryVaporMiddleware())

//Do something

try await sentryGuard.close
```