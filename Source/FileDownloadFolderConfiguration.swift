//
//  FileDownloadResource.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/29.
//

import Foundation

public struct FileDownloadFolderConfiguration {
    var rootFolderURL: URL = FileDownloaderUtils.documentURL
    public var isChanged = false
    public var distinctFolderName = "FileDownloader" {
        didSet {
            didDistinctFolderNameChanged()
        }
    }
    var distinctFolderURL: URL {
        return rootFolderURL.appendingPathComponent(distinctFolderName)
    }
    public init() {
        // 创建文件夹
        FileDownloaderUtils.createFolder(distinctFolderName)
    }
    public init(distinctFolderName: String) {
        self.distinctFolderName = distinctFolderName
        didDistinctFolderNameChanged()
    }
    private mutating func didDistinctFolderNameChanged() {
        if distinctFolderName != "FileDownloader" {
            self.isChanged = true
        }
        FileDownloaderUtils.createFolder(distinctFolderName)
    }
}
