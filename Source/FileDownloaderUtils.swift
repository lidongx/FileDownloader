//
//  FileDownloaderUtils.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/27.
//

import Foundation

public class FileDownloaderUtils{
    static var documentURL: URL {
        return FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    @discardableResult
    public static func createFolder(_ name:String)->Bool{
        let path = name.contains("Documents") ? name : FileDownloaderUtils.documentURL.path+"/"+name
        if  FileManager.default.fileExists(atPath: path){
            return true
        }
        do {
            try FileManager.default.createDirectory(atPath:path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch let error as NSError {
            print(error.localizedDescription)
            return false
        }
    }
    
    public static func stringToURL(urlString:String)->URL{
        guard let url = URL(string: urlString) else{
            fatalError("FileDownloaderUtils: Invalid URL \(urlString)")
        }
        return url
    }
    
    public static func stringsToURLs(urlStrings:[String])->[URL]{
        var urls:[URL] = []
        for urlString in urlStrings {
            urls.append(FileDownloaderUtils.stringToURL(urlString:urlString))
        }
        return urls
    }
}






