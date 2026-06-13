// SergioGuzmanPruebaTests/Helpers/MockURLProtocol.swift
//
//  URLProtocol subclass that intercepts all HTTP requests.
//  Returns predefined responses without hitting the network.
//  Thread-safe via static properties.

import Foundation

final class MockURLProtocol: URLProtocol {

    /// Handler that provides (response, data, error) for each request.
    /// Set this before each test to control what the "network" returns.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true  // Intercept all requests
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
