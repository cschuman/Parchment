import Foundation

class FileWatcher {
    private let url: URL
    private let callback: () -> Void
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    
    init(url: URL, callback: @escaping () -> Void) {
        self.url = url
        self.callback = callback
    }
    
    func start() {
        guard fileDescriptor == -1 else { return }
        
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        let queue = DispatchQueue(label: "file.watcher", qos: .background)
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename],
            queue: queue
        )
        
        source?.setEventHandler { [weak self] in
            self?.callback()
        }
        
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }
        
        source?.resume()
    }
    
    func stop() {
        source?.cancel()
        source = nil
    }
    
    deinit {
        stop()
    }
}