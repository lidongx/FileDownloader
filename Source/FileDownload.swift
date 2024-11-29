//
//  FileDownload.swift
//  FileDownloader
//
//  Created by lidong on 2024/9/26.
//

import Foundation
import Alamofire
class FileDownloadCallback {
    var onDownloadFinished: ((FileDownload) -> Void)
    var onDownloadFailed: ((FileDownload, String) -> Void)
    var onDownloadProgress: ((FileDownload, Double) -> Void)
    var fileInfo: FileDownloadInfo
    init(fileInfo: FileDownloadInfo,
         onDownloadFinished: @escaping (FileDownload) -> Void,
         onDownloadFailed: @escaping (FileDownload, String) -> Void,
         onDownloadProgress: @escaping (FileDownload, Double) -> Void) {
        self.fileInfo = fileInfo
        self.onDownloadFinished = onDownloadFinished
        self.onDownloadFailed = onDownloadFailed
        self.onDownloadProgress = onDownloadProgress
    }
}
public enum FileDownloadState {
    case none
    case downloading
    case finished
    case failed
    case suspend
}
class FileDownload: NSObject {
    var fileInfo: FileDownloadInfo
    private var session: Session!
    private var downloadRequest: DownloadRequest?
    private var callbacks: [FileDownloadCallback] = []
    var progress: Double = 0
    private(set) var state: FileDownloadState = .none
    private var timer: Timer?
    public var isValid: Bool {
        return FileDownloader.shared.fileDownloadExists(fileDownload: self)
    }
    init(fileInfo: FileDownloadInfo) {
        self.fileInfo = fileInfo
        super.init()
        self.setupSession()
        FileDownloader.shared.add(fileDownload: self)
    }
    private func setupSession() {
        let config = fileInfo.config.toURLSessionConfiguration()
        self.session = Session(configuration: config)
    }
    func add(callback: FileDownloadCallback) {
        if !isValid {
            return
        }
        callbacks.append(callback)
    }
    func remove(callback: FileDownloadCallback) {
        if !isValid {
            return
        }
        callbacks.removeAll { $0 === callback }
    }
    private var destination: DownloadRequest.Destination {
        let fileName = fileInfo.fileName
        let fileURL = fileInfo.folderConfig.distinctFolderURL.appendingPathComponent(fileName)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        return destination
    }
    func start() {
        if !isValid {
            return
        }
        if state == .downloading {
            return
        }
        executeDownload()
    }
    func restart() {
        if !isValid {
            return
        }
        progress = 0
        reset()
        start()
    }
    func reset() {
        if !isValid {
            return
        }
        downloadRequest?.cancel()
        downloadRequest = nil
        cancelTimer()
    }
    func cancel(callback: FileDownloadCallback) {
        if !isValid {
            return
        }
        callbacks.removeAll { $0 === callback  }
        if callbacks.count == 0 {
            reset()
            FileDownloader.shared.remove(fileDownload: self)
        }
    }
    func pause() {
        if !isValid {
            return
        }
        if state == .downloading && downloadRequest != nil {
            downloadRequest?.suspend()
            state = .suspend
        }
    }
    func resume() {
        if !isValid {
            return
        }
        if state == .suspend && downloadRequest != nil {
            downloadRequest?.resume()
            state = .downloading
        }
    }
    private func executeDownload() {
        state = .downloading
        downloadRequest = session.download(fileInfo.url, to: destination)
            .downloadProgress { [weak self] progress in
                guard let self = self else {
                    return
                }
                if FileDownloader.shared.enableLog {
                    debugPrint("FileDownloader: url: \(self.fileInfo.url)")
                    debugPrint("FileDownloader: 进度: \(progress.fractionCompleted * 100)%")
                    debugPrint("FileDownloader: 已下载: \(progress.completedUnitCount) / 总大小: \(progress.totalUnitCount)")
                }
                DispatchQueue.main.async {
                    self.progress = progress.fractionCompleted
                    for callback in self.callbacks {
                        callback.onDownloadProgress(self, progress.fractionCompleted)
                    }
                }
            }
            .response { [weak self] response in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    switch response.result {
                    case .success:
                        self.state = .finished
                        if let filePath = response.fileURL?.absoluteString {
                            self.handleFinished(filePath: filePath)
                        }
                    case .failure(let error):
                        self.state = .failed
                        self.handerException(error: error)
                    }
                }
            }
    }
    private func handleFinished(filePath: String) {
        self.state = .finished
        for callback in self.callbacks {
            callback.onDownloadProgress(self, self.progress)
        }
        for callback in self.callbacks {
            do {
                try self.copyFileIfNeeded(filePath: filePath, callback: callback)
            } catch {
                self.handerException(error: error)
                return
            }
            callback.onDownloadFinished(self)
        }
        if FileDownloader.shared.enableLog {
            debugPrint("FileDownloader: 下载成功 文件移动到 \(filePath)")
        }
        FileDownloader.shared.remove(fileDownload: self)
    }
    private func copyFileIfNeeded(filePath: String, callback: FileDownloadCallback) throws {
        let orginURL = URL(string: filePath)!
        let fileName = callback.fileInfo.fileName
        let fileURL = callback.fileInfo.folderConfig.distinctFolderURL.appendingPathComponent(fileName)
        if orginURL != fileURL {
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                try FileManager.default.copyItem(at: orginURL, to: fileURL)
                debugPrint("FileDownloader: 复制文件到:\(fileURL.path)")
            } catch {
                throw error
            }
        }
    }
    private func handerException(error: Error) {
        self.state = .failed
        if FileDownloader.shared.enableLog {
            debugPrint("FileDownloader:失败(url:\(self.fileInfo.url)  错误:\(error.localizedDescription)")
        }
        self.handleDownloadFailure(errorDescription: error.localizedDescription)
    }
    func handleDownloadFailure(errorDescription: String) {
        if fileInfo.config.maxRetries > 0 {
            fileInfo.config.maxRetries -= 1
            performAfterDelay(interval: fileInfo.config.interval)
        } else {
            notifyDownloadFailure(errorDescription: errorDescription)
            FileDownloader.shared.remove(fileDownload: self)
        }
    }
    func performAfterDelay(interval: Int) {
        cancelTimer()
        if FileDownloader.shared.enableLog {
            debugPrint("FileDownloader:延迟执行中,延迟时间：\(interval)")
        }
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.cancelTimer()
                self?.restart()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    func notifyDownloadFailure(errorDescription: String) {
        for callback in self.callbacks {
            callback.onDownloadFailed(self, errorDescription)
        }
    }
    deinit{
        debugPrint("FileDownloader:FileDownload release")
    }
}
