//
//  APIClient.swift
//  Client
//
//  Created by Claudio Vega on 9/11/18.
//  Copyright © 2018 Claudio Vega. All rights reserved.
//

import Foundation
import Unbox
import CoreLocation

public typealias APIClientParameters = [String: Any]
private typealias APIClientResponseJSON = [String: Any]
private typealias APIClientCompletionHandler = (_ success: Bool, _ response: HTTPURLResponse?, _ json: Any?) -> ()

fileprivate enum APIHTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
}

public enum APIHTTPContentType {
    case json
    case formURLEncoded
    case plainText

    var headerValue: String {
        switch self {
        case .json: return "application/json"
        case .formURLEncoded: return "application/x-www-form-urlencoded"
        case .plainText: return "text/plain"
        }
    }

    func HTTPBodyForParameters(_ parameters: APIClientParameters) -> Data? {
        switch self {
        case .json:
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
                return data
            } catch {
                NSLog("JSON serialization error: \(error)")
                return nil
            }

        case .formURLEncoded, .plainText:
            var URLComponents = Foundation.URLComponents()
            URLComponents.queryItems = parameters.map {
                (key, value) in
                URLQueryItem(name: key, value: value as? String ?? String(describing: value))
            }
            let data = URLComponents.query?.data(using: String.Encoding.ascii)
            return data
        }
    }
}

public class APIClient {
    public static let shared = APIClient()
    private let rootURL = URL(string: "http://private-f0eea-mobilegllatam.apiary-mock.com")!

    fileprivate let sessionConfiguration = URLSessionConfiguration.ephemeral
    fileprivate let session: URLSession

    private var deviceIdentifier: String?
    private var userIdentifier: String?

    private let operationQueue = OperationQueue()

    fileprivate init() {
        sessionConfiguration.urlCache = nil
        // set additonal http headers (eg. app name and version)
        // sessionConfiguration.httpAdditionalHeaders
        sessionConfiguration.httpCookieAcceptPolicy = .always
        session = URLSession(configuration: sessionConfiguration)
        operationQueue.maxConcurrentOperationCount = 4
    }

    // MARK: - Private Helper Methods

    fileprivate func request(URL: Foundation.URL, method: APIHTTPMethod, contentType: APIHTTPContentType = .json, parameters: APIClientParameters? = nil, headers: [String: String]? = nil) -> URLRequest {
        var request = URLRequest(url: URL)
        request.httpMethod = method.rawValue
        if let parameters = parameters {
            switch method {
            case .GET:
                guard var URLComponents = URLComponents(url: URL, resolvingAgainstBaseURL: true) else {
                    break
                }
                URLComponents.queryItems = parameters.map {
                    (key, value) in
                    URLQueryItem(name: key, value: value as? String ?? String(describing: value))
                }
                if let actualURL = URLComponents.url {
                    request.url = actualURL
                }
                break

            case .POST, .DELETE, .HEAD:
                request.setValue(contentType.headerValue, forHTTPHeaderField: "Content-Type")
                request.httpBody = contentType.HTTPBodyForParameters(parameters)
                break
            }
        }
        if let headers = headers {
            for(field, value) in headers {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }

        return request
    }


    // MARK: - Generic Call Methods

    fileprivate func performCall(authenticated: Bool = false, URL: Foundation.URL, method: APIHTTPMethod, contentType: APIHTTPContentType = .json, parameters: APIClientParameters? = nil, headers: [String: String]? = nil, completionHandler: @escaping APIClientCompletionHandler) {
        let request = self.request(URL: URL, method: method, contentType: contentType, parameters: parameters, headers: headers)
        let operation = FetchOperation(session: session, request: request)
        operation.completionHandler = {
            (data: Data?, response: URLResponse?, error: Error?) in
            let httpResponse = response as? HTTPURLResponse
            DispatchQueue.main.async(execute: {
                if let data = data, error == nil {
                    if contentType == .json {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data, options: []) // as? APIClientResponseJSON
                            // we are either a JSON root object or an array
                            if json is APIClientResponseJSON || json is [APIClientResponseJSON] {
                                completionHandler(true, httpResponse, json)
                            } else {
                                completionHandler(false, httpResponse, nil)
                            }
                        } catch let error {
                            NSLog("JSON Deserialization error: \(error); URL: \(URL)")
                            completionHandler(false, httpResponse, nil)
                        }
                    } else {
                        let string = String(data: data, encoding: .utf8)
                        completionHandler(string != nil, httpResponse, string)
                    }
                } else {
                    NSLog("error: \(String(describing: error))")
                    completionHandler(false, httpResponse, nil)
                }
            })
        }
        operationQueue.addOperation(operation)
    }

    private func performCall(authenticated: Bool = false, method: APIHTTPMethod, path: String, contentType: APIHTTPContentType = .json, parameters: APIClientParameters? = nil, headers: [String: String]? = nil, completionHandler: @escaping APIClientCompletionHandler) {
        guard let someURL = endpointURL(forPath: path) else {
            completionHandler(false, nil, nil)
            return
        }
        NSLog("calling URL: \(someURL.absoluteString)")
        performCall(authenticated: authenticated, URL: someURL, method: method, contentType: contentType, parameters: parameters, headers: headers, completionHandler: completionHandler)
    }

    private func endpointURL(forPath path: String) -> URL? {
        return URL(string: path.replacingOccurrences(of: "/", with: "", options: [.anchored], range: nil), relativeTo: rootURL)
    }

    // MARK: - Public Methods

    public func getList(completionHandler: ((Bool, [LaptopModel]) -> ())?) {
        let path = "/list"
        performCall(authenticated: true,
                    method: .GET,
                    path: path,
                    completionHandler: {
                        (success: Bool, response: URLResponse?, json: Any?) in
                        if success, let json = json as? [APIClientResponseJSON] {
                            do {
                                let laptops: [LaptopModel] = try unbox(dictionaries: json)
                                completionHandler?(true, laptops)
                            } catch let error {
                                NSLog("getList API call failed; error: \(error)")
                                completionHandler?(false, [])
                            }
                        } else {
                            completionHandler?(false, [])
                        }
                        
        })
    }
}
