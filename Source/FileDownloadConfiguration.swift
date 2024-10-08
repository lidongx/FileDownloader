//
//  FileDownloadConfiguration.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/30.
//

import Foundation

public struct FileDownloadConfiguration{
    var maxRetries:Int
    var timeoutIntervalForRequest:TimeInterval
    var requestCachePolicy:NSURLRequest.CachePolicy
    var intervals:[Int] = []
 
    public init(maxRetries: Int, timeoutIntervalForRequest: TimeInterval, requestCachePolicy: NSURLRequest.CachePolicy) {
        self.maxRetries = maxRetries
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.requestCachePolicy = requestCachePolicy
        intervals = countIntervals()
    }
    
    public func toURLSessionConfiguration()->URLSessionConfiguration{
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeoutIntervalForRequest
        config.requestCachePolicy = requestCachePolicy
        return config
    }
    
    
    public static var defaultConfiguration:FileDownloadConfiguration = .init(maxRetries: 0,timeoutIntervalForRequest: 30, requestCachePolicy: .returnCacheDataElseLoad)
    
    public static var serverDefaultConfiguration:FileDownloadConfiguration = .init(maxRetries: 0,timeoutIntervalForRequest: 30, requestCachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

}

extension FileDownloadConfiguration{
    func countIntervals()->[Int]{
        guard maxRetries > 0 else { return [] }
        return (0..<maxRetries).map { 5 * (1 << $0) }.reversed()
    }
    
    public var interval:Int{
        return intervals[maxRetries]
    }
}
