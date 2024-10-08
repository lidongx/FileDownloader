//
//  FileDownloaderExtension.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/30.
//

import Foundation

public extension String{
    func startDownload(fileName:String? = nil,folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration,delegate:FileDownloadGroupDelegate? = nil){
        let url = FileDownloaderUtils.stringToURL(urlString: self)
        url.startDownload(fileName: fileName,folderConfig: folderConfig,delegate: delegate)
    }
}

public extension URL{
    func startDownload(fileName:String? = nil,folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration,delegate:FileDownloadGroupDelegate? = nil){
        let fileInfo = FileDownloadInfo(url: self, fileName:fileName, folderConfig: folderConfig, config: config)
        fileInfo.startDownload(delegate: delegate)
    }
}

public extension FileDownloadInfo{
    func startDownload(delegate:FileDownloadGroupDelegate? = nil){
        let group = FileDownloadGroup(fileInfos: [self],delegate: delegate)
        group.startDownload()
    }
}


public extension Array where Element == String{
    func startDownload(folderConfig:FileDownloadFolderConfiguration = .init(),delegate:FileDownloadGroupDelegate? = nil){
        let urls = FileDownloaderUtils.stringsToURLs(urlStrings: self)
        urls.startDownload(folderConfig: folderConfig,delegate: delegate)
    }
}

public extension Array where Element == URL{
    func startDownload(folderConfig:FileDownloadFolderConfiguration = .init(),delegate:FileDownloadGroupDelegate? = nil){
        let group = FileDownloadGroup(urls: self, folderConfig: folderConfig,delegate: delegate)
        group.startDownload()
    }
    
    func startQueueDownload(folderConfig:FileDownloadFolderConfiguration = .init(),delegate:FileDownloadQueueDelegate? = nil){
        let queue = FileDownloadQueue(urls: self, folderConfig: folderConfig,delegate: delegate)
        queue.startDownload()
    }
}

public extension Array where Element == FileDownloadInfo{
    func startDownload(folderConfig:FileDownloadFolderConfiguration = .init(),delegate:FileDownloadGroupDelegate? = nil){
        if(folderConfig.isChanged){
            for info in self {
                if(!info.folderConfig.isChanged){
                    info.folderConfig(folderConfig: folderConfig)
                }
            }
        }
        let group = FileDownloadGroup(fileInfos: self,delegate: delegate)
        group.startDownload()
    }
    
    func startQueueDownload(folderConfig:FileDownloadFolderConfiguration = .init(),delegate:FileDownloadQueueDelegate? = nil){
        if(folderConfig.isChanged){
            for info in self {
                if(!info.folderConfig.isChanged){
                    info.folderConfig(folderConfig: folderConfig)
                }
            }
        }
        let queue = FileDownloadQueue(fileInfos: self,delegate: delegate)
        queue.startDownload()
    }
}


public extension String{
    @discardableResult
    func savedFileName(_ savedFileName:String?)->FileDownloadInfo{
        let info = FileDownloadInfo(urlString: self, fileName: savedFileName)
        return info
    }
    
    @discardableResult
    func fileInfo()->FileDownloadInfo{
        let info = FileDownloadInfo(urlString: self)
        return info
    }
    
}
