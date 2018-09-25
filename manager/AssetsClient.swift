//
//  AssetsClient.swift
//  Test
//
//  Created by Claudio Vega on 9/13/18.
//  Copyright © 2018 Claudio Vega. All rights reserved.
//

import UIKit
import Foundation

public class AssetsClient {
    private struct statics {
        static let memoryCapacity = 4 * 1024 * 1024 // 4 Mb
        static let diskCapacity = 50 * 1024 * 1024 // 50 Mb
        static let diskPath = "thumbsCache"
        static let requestTimeout = TimeInterval(10.0)
    }

    private let operationQueue = OperationQueue()
    public static let shared = AssetsClient()
    private let sessionConfiguration = URLSessionConfiguration.default
    private let session: URLSession
    private let cache = URLCache(memoryCapacity: statics.memoryCapacity, diskCapacity: statics.diskCapacity, diskPath: statics.diskPath)
    private let calendar = Calendar.current

    public var assetsURL: URL?
    public var assetsIdentifier: String?

    public init() {
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        sessionConfiguration.urlCache = nil
        session = URLSession(configuration: sessionConfiguration)
        operationQueue.maxConcurrentOperationCount = 4
    }

    public func data(forPath path: String, rootURL: URL?) -> Data? {
        guard let rootURL = rootURL, let dataURL = URL(string: path.replacingOccurrences(of: "/", with: "", options: [.anchored], range: nil), relativeTo: rootURL) else {
            return nil
        }
        return data(forURL: dataURL)
    }

    public func data(forURL URL: URL) -> Data? {
        let request = URLRequest(url: URL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: statics.requestTimeout)
        return cache.cachedResponse(for: request)?.data
    }

    public func image(dataForURL URL: URL) -> UIImage? {
        guard let imageData = data(forURL: URL) else {
            return nil
        }
        return UIImage(data: imageData)
    }

    public func image(dataForPath path: String, rootURL: URL?) -> UIImage? {
        guard let rootURL = rootURL, let dataURL = URL(string: path.replacingOccurrences(of: "/", with: "", options: [.anchored], range: nil), relativeTo: rootURL) else {
            return nil
        }
        return image(dataForURL: dataURL)
    }

    public func fetch(path: String, rootURL: URL?, completionHandler: ((Data?) -> ())?) {
        guard let rootURL = rootURL, let dataURL = URL(string: path.replacingOccurrences(of: "/", with: "", options: [.anchored], range: nil), relativeTo: rootURL) else {
            completionHandler?(nil)
            return
        }
        fetch(URL: dataURL, completionHandler: completionHandler)
    }

    public func fetch(URL: URL, completionHandler: ((Data?) -> ())?) {
        let request = URLRequest(url: URL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: statics.requestTimeout)
        if let cachedResponse = cache.cachedResponse(for: request), let response = cachedResponse.response as? HTTPURLResponse, response.statusCode == 200, let data = cache.cachedResponse(for: request)?.data {
            // we return the cached data
            if let completionHandler = completionHandler {
                DispatchQueue.main.async(execute: {
                    completionHandler(data)
                })
            }
            return
        }

        let operation = FetchOperation(session: session, request: request)
        operation.completionHandler = {
            (data: Data?, response: HTTPURLResponse?, error: Error?) -> Void in
            DispatchQueue.main.async(execute: {
                if let data = data, let response = response, response.statusCode == 200, error == nil {
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    self.cache.storeCachedResponse(cachedResponse, for: request)
                    // we return the retrieved data
                    completionHandler?(data)
                } else {
                    completionHandler?(nil)
                }
            })
        }
        operationQueue.addOperation(operation)
    }
}
