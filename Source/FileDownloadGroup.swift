//
//  FileDownloadGroup.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/26.
//

import Foundation

public class FileDownloadGroupDelegate {
    public var onFinished: ((FileDownloadGroup,[FileDownloadInfo]) -> Void)
    public var onFailed: ((FileDownloadGroup, String) -> Void)
    public var onProgress: ((FileDownloadGroup, Double) -> Void)

    public init(onFinished: @escaping (FileDownloadGroup,[FileDownloadInfo]) -> Void,
         onFailed: @escaping (FileDownloadGroup, String) -> Void,
         onProgress: @escaping (FileDownloadGroup, Double) -> Void) {
        self.onFinished = onFinished
        self.onFailed = onFailed
        self.onProgress = onProgress
    }
}

public class FileDownloadGroup{
    private var delegate:FileDownloadGroupDelegate?
    private var downloadItems:[FileDownloadItem] = []

    public var state:FileDownloadState = .none
    
    public var progress:Double = 0
    
    @discardableResult
    public convenience init(urlStrings:[String],
                            folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration,delegate:FileDownloadGroupDelegate? = nil
    ) {
        let urls = FileDownloaderUtils.stringsToURLs(urlStrings: urlStrings)
        self.init(urls: urls, folderConfig: folderConfig,delegate: delegate)
    }
    
    @discardableResult
    public convenience init(urls: [URL], folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration,delegate:FileDownloadGroupDelegate? = nil) {
        let fileInfos = urls.map { FileDownloadInfo(url: $0, folderConfig: folderConfig) }
        self.init(fileInfos: fileInfos, delegate: delegate)
    }
    
    @discardableResult
    public init(fileInfos:[FileDownloadInfo],delegate:FileDownloadGroupDelegate? = nil){
        FileDownloader.shared.add(group: self)
        self.delegate = delegate
        for fileInfo in fileInfos {
            let fileDownload = fileDownload(for: fileInfo)
            add(fileDownload: fileDownload,fileInfo: fileInfo)
        }
    }
    
    public var isValid:Bool{
        return FileDownloader.shared.groupExists(group: self)
    }
    
    deinit{
        debugPrint("FileDownloader:FileDownloadGroup release")
    }
}


extension FileDownloadGroup{
    public func add(urlString:String,fileName:String? = nil,
                    folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration){
        let url = FileDownloaderUtils.stringToURL(urlString: urlString)
        add(url: url,fileName:fileName,folderConfig: folderConfig,config: config)
    }
    
    public func add(url:URL,fileName:String?,folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration){
        let fileInfo = FileDownloadInfo(url: url, fileName: fileName, folderConfig: folderConfig, config: config)
        let fileDownload:FileDownload = fileDownload(for: fileInfo)
        add(fileDownload: fileDownload,fileInfo: fileInfo)
    }
    
    func add(fileDownload:FileDownload,fileInfo:FileDownloadInfo){
        if(!isValid){
            return
        }
        let callback = createFileDownloadCallback(fileInfo: fileInfo)
        fileDownload.add(callback: callback)
        downloadItems.append(.init(fileDownload: fileDownload, callback: callback))
    }
    
    private func fileDownload(for fileInfo:FileDownloadInfo)->FileDownload{
        if let fileDownload = FileDownloader.shared.fileDownload(for: fileInfo.url.path){
            return fileDownload
        }
        return FileDownload(fileInfo: fileInfo)
    }
    
    private func createFileDownloadCallback(fileInfo:FileDownloadInfo)->FileDownloadCallback{
        let callback = FileDownloadCallback(fileInfo: fileInfo) { [weak self] download in
            guard let self = self else{
                return
            }
            if(self.checkDownloadQueueFinished()){
                state = .finished
                
                let fileInfos = self.downloadItems.map({ $0.callback.fileInfo })
                self.delegate?.onFinished(self,fileInfos)
                FileDownloader.shared.remove(group: self)
            }
        } onDownloadFailed: { [weak self] (download, errorDescription) in
            guard let self = self else{
                return
            }
            state = .failed
            self.delegate?.onFailed(self,errorDescription)
            FileDownloader.shared.remove(group: self)
        } onDownloadProgress: { [weak self] (download, progress) in
            guard let self = self else{
                return
            }
            self.updateProgress()
        }
        return callback
    }
    
    private func checkDownloadQueueFinished()->Bool{
        if(downloadItems.count == 0){
            return false
        }
        
        for downloadItem in self.downloadItems {
            if(downloadItem.fileDownload.progress < 1){
                return false
            }
        }
        return true
    }
    
    private func updateProgress(){
        if(downloadItems.count > 0){
            var progress:Double = 0
            for downloadItem in self.downloadItems {
                progress += downloadItem.fileDownload.progress
            }
            progress = progress / Double(downloadItems.count)
            self.progress = progress
            self.delegate?.onProgress(self,progress)
        }
    }
    
    public func startDownload(){
        if(!isValid){
            return
        }
        state = .downloading
        for downloadItem in self.downloadItems {
            downloadItem.fileDownload.start()
        }
    }

    public func cancel(){
        if(!isValid){
            return
        }
        for downloadItem in self.downloadItems {
            downloadItem.fileDownload.cancel(callback: downloadItem.callback)
        }
        FileDownloader.shared.remove(group: self)
    }
    
    @MainActor
    public func pause(){
        if(!isValid){
            return
        }
        if(state == .downloading){
            for downloadItem in self.downloadItems {
                downloadItem.fileDownload.pause()
            }
            state = .suspend
        }
    }
    
    @MainActor
    public func resume(){
        if(!isValid){
            return
        }
        if(state == .suspend){
            for downloadItem in self.downloadItems {
                downloadItem.fileDownload.resume()
            }
        }
    }
    
}

