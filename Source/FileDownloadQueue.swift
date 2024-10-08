//
//  FileDownloadQueue.swift
//  FileDownloader
//
//  Created by lidong on 2024/10/8.
//

import Foundation
//
//  FileDownloadQueue.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/26.
//

import Foundation

public class FileDownloadQueueDelegate {
    public var onFinished: ((FileDownloadQueue,[FileDownloadInfo]) -> Void)
    public var onFailed: ((FileDownloadQueue, String) -> Void)
    public var onProgress: ((FileDownloadQueue, Double) -> Void)

    init(onFinished: @escaping (FileDownloadQueue,[FileDownloadInfo]) -> Void,
         onFailed: @escaping (FileDownloadQueue, String) -> Void,
         onProgress: @escaping (FileDownloadQueue, Double) -> Void) {
        self.onFinished = onFinished
        self.onFailed = onFailed
        self.onProgress = onProgress
    }
}

public class FileDownloadQueue{
    private var delegate:FileDownloadQueueDelegate?
    private var downloadItems:[FileDownloadItem] = []

    public var state:FileDownloadState = .none
    
    var index:Int = 0
    
    public var progress:Double = 0
    
    @discardableResult
    public convenience init(urlStrings:[String],
                            folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration,delegate:FileDownloadQueueDelegate? = nil
    ) {
        let urls = FileDownloaderUtils.stringsToURLs(urlStrings: urlStrings)
        self.init(urls: urls, folderConfig: folderConfig,delegate: delegate)
    }
    
    @discardableResult
    public convenience init(urls: [URL], folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration,delegate:FileDownloadQueueDelegate? = nil) {
        let fileInfos = urls.map { FileDownloadInfo(url: $0, folderConfig: folderConfig) }
        self.init(fileInfos: fileInfos, delegate: delegate)
    }
    
    @discardableResult
    public init(fileInfos:[FileDownloadInfo],delegate:FileDownloadQueueDelegate? = nil){
        FileDownloader.shared.add(queue: self)
        self.delegate = delegate
        for fileInfo in fileInfos {
            let fileDownload = fileDownload(for: fileInfo)
            add(fileDownload: fileDownload)
        }
    }
    
    public var isValid:Bool{
        return FileDownloader.shared.queueExists(queue: self)
    }
    
    deinit{
        debugPrint("FileDownloader:FileDownloadQueue release")
    }
}


extension FileDownloadQueue{
    public func add(urlString:String,fileName:String? = nil,
                    folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration){
        let url = FileDownloaderUtils.stringToURL(urlString: urlString)
        add(url: url,fileName:fileName,folderConfig: folderConfig,config: config)
    }
    
    public func add(url:URL,fileName:String?,folderConfig:FileDownloadFolderConfiguration = .init(),config:FileDownloadConfiguration = .defaultConfiguration){
        let info = FileDownloadInfo(url: url, fileName: fileName, folderConfig: folderConfig, config: config)
        let fileDownload:FileDownload = fileDownload(for: info)
        add(fileDownload: fileDownload)
    }
    
    func add(fileDownload:FileDownload){
        if(!isValid){
            return
        }
        let callback = createFileDownloadCallback(fileInfo: fileDownload.fileInfo)
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
        let callback = FileDownloadCallback(fileInfo: fileInfo){ [weak self] download in
            guard let self = self else{
                return
            }
            if(self.checkDownloadQueueFinished()){
                self.state = .finished
                let fileInfos = self.downloadItems.map({ $0.callback.fileInfo })
                self.delegate?.onFinished(self,fileInfos)
                FileDownloader.shared.remove(queue: self)
            }else{
                self.next()
            }
        } onDownloadFailed: { [weak self] (download, errorDescription) in
            guard let self = self else{
                return
            }
            state = .failed
            self.delegate?.onFailed(self,errorDescription)
            FileDownloader.shared.remove(queue: self)
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
       
        for downloadItem in self.downloadItems {
            if(downloadItem.fileDownload.progress < 1){
                state = .downloading
                downloadItem.fileDownload.start()
                break
            }
        }
    }

    public func next(){
        startDownload()
    }
    
    public func cancel(){
        if(!isValid){
            return
        }
        for downloadItem in self.downloadItems {
            downloadItem.fileDownload.cancel(callback: downloadItem.callback)
        }
        FileDownloader.shared.remove(queue: self)
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

