//
//  HTTPNetworkClient.swift
//  Networking
//
//  Created by Bartłomiej Nowak on 06.05.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import Foundation

public protocol HTTPNetworkClientInterface
{
    typealias Path = String
    
    func request(_ method: HTTPMethod, path: String, callback: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
    func stub(_ path: Path, _ method: HTTPMethod, statusCode: Int, body: Any?, headers: [String: String]?) throws
}

public class HTTPNetworkClient
{
    public struct URLResponseGenerationError: Error {}
    
    public var timeoutInterval = 20.0
    public var headerFields = [String: String]()
    private let generator: URLGenerator
    private var stubbedResponses = [Path: [HTTPMethod: HTTPResponseStub]]()
    
    public init(timeoutInterval: TimeInterval, generator: URLGenerator = URLGenerator())
    {
        self.timeoutInterval = timeoutInterval
        self.generator = generator
    }
}

extension HTTPNetworkClient: HTTPNetworkClientInterface
{
    /// Performs a request for provided path and method.
    public func request(_ method: HTTPMethod, path: Path, callback: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
    {
        do {
            let url = try generator.url(path: path)
            let session = generateURLSession(for: path, method: method)
            let request = generateURLRequestWithHeaderFields(for: url, method: method)
            session.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    callback(data, response as? HTTPURLResponse, error)
                }
            }.resume()
        } catch {
            callback(nil, nil, error)
        }
    }
    
    /// Stubs the response for a request directed at provided path and method.
    public func stub(_ path: Path, _ method: HTTPMethod, statusCode: Int, body: Any?, headers: [String: String]?) throws
    {
        guard let urlResponse = HTTPURLResponse(
            url: try generator.url(path: path), statusCode: statusCode, httpVersion: nil, headerFields: headers
        ) else {
            throw URLResponseGenerationError()
        }
        let bodyData: Data?
        if let body = body {
            bodyData = try? JSONSerialization.data(withJSONObject: body as Any, options: .prettyPrinted)
        } else {
            bodyData = nil
        }
        let stub = HTTPResponseStub(urlResponse: urlResponse, statusCode: statusCode, body: bodyData)
        if var responsesForMethods = stubbedResponses[path] {
            responsesForMethods[method] = stub
            stubbedResponses[path] = responsesForMethods
        } else {
            stubbedResponses[path] = [method: stub]
        }
    }

    private func generateURLSession(for path: Path, method: HTTPMethod) -> URLSession
    {
        if let stub = stubbedResponses[path]?[method] {
            return StubbedURLSession(body: stub.body, response: stub.urlResponse)
        } else {
            return URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: nil)
        }
    }
    
    private func generateURLRequestWithHeaderFields(for url: URL, method: HTTPMethod) -> URLRequest
    {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue
        headerFields.forEach {
            request.addValue($1, forHTTPHeaderField: $0)
        }
        return request
    }
}
