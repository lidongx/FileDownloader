//
//  FileDownloader.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/26.
//

import Foundation

public class FileDownloader{
    public static let shared:FileDownloader = FileDownloader();
    var groups:[FileDownloadGroup] = []
    var queues:[FileDownloadQueue] = []
    var downloadMap:[String:FileDownload] = [:]
    public var enableLog:Bool = false
}

extension FileDownloader{
    
    @MainActor
    public func cancelAll(){
        for group in self.groups {
            group.cancel()
        }
        self.groups.removeAll()
        
        for queue in self.queues {
            queue.cancel()
        }
        self.queues.removeAll()
    }
}


extension FileDownloader{
    func add(group:FileDownloadGroup){
        groups.append(group)
    }
    
    func remove(group:FileDownloadGroup){
        groups.removeAll { $0 === group  }
    }
    
    func groupExists(group:FileDownloadGroup)->Bool{
        return groups.filter { $0 === group }.count > 0
    }
    
    func add(queue:FileDownloadQueue){
        queues.append(queue)
    }
    
    func remove(queue:FileDownloadQueue){
        queues.removeAll { $0 === queue  }
    }
    
    func queueExists(queue:FileDownloadQueue)->Bool{
        return queues.filter { $0 === queue }.count > 0
    }
    
    func add(fileDownload:FileDownload){
        downloadMap[fileDownload.fileInfo.url.path] = fileDownload
    }

    func remove(fileDownload:FileDownload){
        downloadMap.removeValue(forKey: fileDownload.fileInfo.url.path)
    }
    
    func fileDownloadExists(fileDownload:FileDownload) -> Bool{
        return downloadMap.keys.contains(fileDownload.fileInfo.url.path)
    }
    
    func fileDownload(for urlString:String)->FileDownload?{
        return downloadMap[urlString]
    }
    
}
