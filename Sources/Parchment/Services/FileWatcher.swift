import Foundation

final class FileWatcher {
    private let url: URL
    private let callback: () -> Void
    private let debounceInterval: TimeInterval
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private let callbackQueue: DispatchQueue
    private let lock = NSLock()  // Thread-safety for start/stop operations

    /// Creates a file watcher with debouncing
    /// - Parameters:
    ///   - url: The file URL to watch
    ///   - debounceInterval: Minimum time between callbacks (default 300ms)
    ///   - callback: Called when file changes (debounced)
    init(url: URL, debounceInterval: TimeInterval = 0.3, callback: @escaping () -> Void) {
        self.url = url
        self.debounceInterval = debounceInterval
        self.callback = callback
        self.callbackQueue = DispatchQueue.main
    }

    func start() {
        lock.lock()
        defer { lock.unlock() }

        guard fileDescriptor == -1 else { return }

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            Logger.warning("Failed to open file for watching: \(url.path)")
            return
        }

        let queue = DispatchQueue(label: "file.watcher", qos: .background)
        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )

        // Capture fileDescriptor by value for cancel handler to avoid race conditions
        let fd = fileDescriptor

        newSource.setEventHandler { [weak self] in
            self?.handleFileChange()
        }

        newSource.setCancelHandler {
            // Use captured fd value - no need for weak self
            if fd >= 0 {
                close(fd)
            }
        }

        source = newSource
        source?.resume()
    }

    private func handleFileChange() {
        lock.lock()

        // Cancel any pending debounced callback
        debounceWorkItem?.cancel()

        // Create new debounced callback
        let workItem = DispatchWorkItem { [weak self] in
            self?.callback()
        }
        debounceWorkItem = workItem

        lock.unlock()

        // Schedule callback after debounce interval
        callbackQueue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }

        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        source?.cancel()
        source = nil
        // Reset file descriptor (actual close happens in cancel handler)
        fileDescriptor = -1
    }

    deinit {
        stop()
    }
}
