import Foundation

final class FileWatcher {
    private let url: URL
    private let callback: () -> Void
    private let debounceInterval: TimeInterval
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private let callbackQueue: DispatchQueue

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
        guard fileDescriptor == -1 else { return }

        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            Logger.warning("Failed to open file for watching: \(url.path)")
            return
        }

        let queue = DispatchQueue(label: "file.watcher", qos: .background)
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.handleFileChange()
        }

        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        source?.resume()
    }

    private func handleFileChange() {
        // Cancel any pending debounced callback
        debounceWorkItem?.cancel()

        // Create new debounced callback
        let workItem = DispatchWorkItem { [weak self] in
            self?.callback()
        }
        debounceWorkItem = workItem

        // Schedule callback after debounce interval
        callbackQueue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }
}
