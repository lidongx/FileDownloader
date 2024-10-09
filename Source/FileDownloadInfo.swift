//
//  FileInfo.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/26.
//

import Foundation

public class FileDownloadInfo {
    public var url: URL
    public var fileName: String
    public var folderConfig: FileDownloadFolderConfiguration
    var config: FileDownloadConfiguration
    init(
        urlString: String,
        fileName: String? = nil,
        folderConfig: FileDownloadFolderConfiguration = .init(),
        config: FileDownloadConfiguration = FileDownloadConfiguration.defaultConfiguration) {
        self.url = FileDownloaderUtils.stringToURL(urlString: urlString)
        self.fileName = fileName ?? self.url.lastPathComponent
        assert(!self.fileName.isEmpty, "Invalid fileName: \(self.fileName)")
        self.folderConfig = folderConfig
        self.config = config
    }
    init(
        url: URL,
        fileName: String? = nil,
        folderConfig: FileDownloadFolderConfiguration = .init(),
        config: FileDownloadConfiguration = FileDownloadConfiguration.serverDefaultConfiguration) {
        self.url = url
        self.fileName = fileName ?? self.url.lastPathComponent
        assert(!self.fileName.isEmpty, "Invalid fileName: \(self.fileName)")
        self.folderConfig = folderConfig
        self.config = config
    }
    public var filePath: String {
        let fileURL = folderConfig.distinctFolderURL.appendingPathComponent(fileName)
        return fileURL.path
    }
}

public extension FileDownloadInfo {
    @discardableResult
    func fileName(fileName: String?) -> Self {
        self.fileName = fileName ?? self.url.lastPathComponent
        assert(!self.fileName.isEmpty, "Invalid fileName: \(self.fileName)")
        return self
    }
    @discardableResult
    func folderName(_ folderName: String) -> Self {
        self.folderConfig.distinctFolderName = folderName
        return self
    }
    @discardableResult
    func maxRetries(_ retry: Int) -> Self {
        self.config.maxRetries = retry
        return self
    }
    @discardableResult
    func folderConfig(folderConfig: FileDownloadFolderConfiguration) -> Self {
        self.folderConfig = folderConfig
        return self
    }
    @discardableResult
    func config(config: FileDownloadConfiguration) -> Self {
        self.config = config
        return self
    }
}
