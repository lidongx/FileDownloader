//
//  FileDownloadItem.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/30.
//

import Foundation

class FileDownloadItem{
    var fileDownload:FileDownload
    var callback:FileDownloadCallback
    
    init(fileDownload: FileDownload, callback: FileDownloadCallback) {
        self.fileDownload = fileDownload
        self.callback = callback
    }
    
}
