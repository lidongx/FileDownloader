//
//  FileDownloaderExtension.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/30.
//

import Foundation

public extension String {
    @discardableResult
    func startDownload(fileName: String? = nil,
                       folderConfig: FileDownloadFolderConfiguration = .init(),
                       config: FileDownloadConfiguration = .defaultConfiguration,
                       delegate: FileDownloadGroupDelegate? = nil) -> FileDownloadGroup {
        let url = FileDownloaderUtils.stringToURL(urlString: self)
        return url.startDownload(fileName: fileName, folderConfig: folderConfig, delegate: delegate)
    }
}

public extension URL {
    @discardableResult
    func startDownload(fileName: String? = nil,
                       folderConfig: FileDownloadFolderConfiguration = .init(),
                       config: FileDownloadConfiguration = .defaultConfiguration,
                       delegate: FileDownloadGroupDelegate? = nil) -> FileDownloadGroup {
        let fileInfo = FileDownloadInfo(url: self, fileName: fileName, folderConfig: folderConfig, config: config)
        return fileInfo.startDownload(delegate: delegate)
    }
}

public extension FileDownloadInfo {
    @discardableResult
    func startDownload(delegate: FileDownloadGroupDelegate? = nil) -> FileDownloadGroup {
        let group = FileDownloadGroup(fileInfos: [self], delegate: delegate)
        group.startDownload()
        return group
    }
}
public extension Array where Element == String {
    @discardableResult
    func startDownload(folderConfig: FileDownloadFolderConfiguration = .init(),
                       delegate: FileDownloadGroupDelegate? = nil) -> FileDownloadGroup {
        let urls = FileDownloaderUtils.stringsToURLs(urlStrings: self)
        return urls.startDownload(folderConfig: folderConfig, delegate: delegate)
    }
    
    func startQueueDownload(
        folderConfig: FileDownloadFolderConfiguration = .init(), delegate: FileDownloadQueueDelegate? = nil) {
        let urls = FileDownloaderUtils.stringsToURLs(urlStrings: self)
        urls.startQueueDownload(folderConfig: folderConfig, delegate: delegate)
    }
}
public extension Array where Element == URL {
    func startDownload(folderConfig: FileDownloadFolderConfiguration = .init(),
                       delegate: FileDownloadGroupDelegate? = nil) -> FileDownloadGroup {
        let group = FileDownloadGroup(urls: self, folderConfig: folderConfig, delegate: delegate)
        group.startDownload()
        return group
    }
    @discardableResult
    func startQueueDownload(
        folderConfig: FileDownloadFolderConfiguration = .init(), delegate: FileDownloadQueueDelegate? = nil) -> FileDownloadQueue {
        let queue = FileDownloadQueue(urls: self, folderConfig: folderConfig, delegate: delegate)
        queue.startDownload()
            return queue
    }
}
public extension Array where Element == FileDownloadInfo {
    @discardableResult
    func startDownload(
        folderConfig: FileDownloadFolderConfiguration = .init(),
        delegate: FileDownloadGroupDelegate? = nil) -> FileDownloadGroup {
        if folderConfig.isChanged {
            for info in self where !info.folderConfig.isChanged {
                info.folderConfig(folderConfig: folderConfig)
            }
        }
        let group = FileDownloadGroup(fileInfos: self, delegate: delegate)
        group.startDownload()
        return group
    }
    @discardableResult
    func startQueueDownload(
        folderConfig: FileDownloadFolderConfiguration = .init(),
        delegate: FileDownloadQueueDelegate? = nil) -> FileDownloadQueue {
        if folderConfig.isChanged {
            for info in self where !info.folderConfig.isChanged {
                info.folderConfig(folderConfig: folderConfig)
            }
        }
        let queue = FileDownloadQueue(fileInfos: self, delegate: delegate)
        queue.startDownload()
        return queue
    }
}
public extension String {
    @discardableResult
    func savedFileName(_ savedFileName: String?) -> FileDownloadInfo {
        let info = FileDownloadInfo(urlString: self, fileName: savedFileName)
        return info
    }
    @discardableResult
    func fileInfo() -> FileDownloadInfo {
        let info = FileDownloadInfo(urlString: self)
        return info
    }
}
