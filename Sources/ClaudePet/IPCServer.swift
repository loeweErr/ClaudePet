import Foundation
import Darwin

/// Newline-delimited JSON over a Unix domain socket.
/// Lives inside the GUI process. The MCP-mode subprocess connects here.
enum IPC {
    /// Fixed path so both processes find each other. /tmp is fine for a local toy.
    static let socketPath = "/tmp/claude-pet.sock"
}

protocol IPCRequestHandler: AnyObject {
    /// Called on the main thread. Return a human-readable status string
    /// (becomes the MCP tool's text content).
    func handleIPC(method: String, params: [String: Any]) -> String
}

final class IPCServer {

    weak var handler: IPCRequestHandler?

    private var listenFd: Int32 = -1
    private var acceptThread: Thread?
    private var running: Bool = false

    func start() {
        unlink(IPC.socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            FileHandle.standardError.write(Data("[ipc] socket() failed\n".utf8))
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        IPC.socketPath.withCString { src in
            withUnsafeMutableBytes(of: &addr.sun_path) { dst in
                let dstPtr = dst.baseAddress!.assumingMemoryBound(to: CChar.self)
                _ = strncpy(dstPtr, src, dst.count - 1)
            }
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bindResult = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                bind(fd, sa, addrLen)
            }
        }
        guard bindResult == 0 else {
            FileHandle.standardError.write(Data("[ipc] bind() failed errno=\(errno)\n".utf8))
            close(fd)
            return
        }

        guard listen(fd, 5) == 0 else {
            FileHandle.standardError.write(Data("[ipc] listen() failed errno=\(errno)\n".utf8))
            close(fd)
            return
        }

        listenFd = fd
        running = true

        let t = Thread { [weak self] in self?.acceptLoop() }
        t.name = "claude-pet-ipc-accept"
        t.start()
        acceptThread = t
    }

    func stop() {
        running = false
        if listenFd >= 0 {
            close(listenFd)
            listenFd = -1
        }
        unlink(IPC.socketPath)
    }

    private func acceptLoop() {
        while running {
            let clientFd = accept(listenFd, nil, nil)
            if clientFd < 0 {
                if !running { return }
                continue
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.handleClient(fd: clientFd)
            }
        }
    }

    private func handleClient(fd: Int32) {
        defer { close(fd) }
        var buffer = Data()
        var chunk = [UInt8](repeating: 0, count: 4096)

        while running {
            let n = read(fd, &chunk, chunk.count)
            if n <= 0 { return }
            buffer.append(chunk, count: Int(n))

            while let nl = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer.subdata(in: 0..<nl)
                buffer.removeSubrange(0...nl)
                handleLine(lineData, fd: fd)
            }
        }
    }

    private func handleLine(_ data: Data, fd: Int32) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            writeJSON(["error": "invalid json"], fd: fd)
            return
        }
        let id = obj["id"]
        let method = (obj["method"] as? String) ?? ""
        let params = (obj["params"] as? [String: Any]) ?? [:]

        var result: String = ""
        let sema = DispatchSemaphore(value: 0)
        DispatchQueue.main.async { [weak self] in
            if let h = self?.handler {
                result = h.handleIPC(method: method, params: params)
            } else {
                result = "error: no handler"
            }
            sema.signal()
        }
        _ = sema.wait(timeout: .now() + 5)

        var response: [String: Any] = ["result": result]
        if let id = id { response["id"] = id }
        writeJSON(response, fd: fd)
    }

    private func writeJSON(_ obj: [String: Any], fd: Int32) {
        guard let data = try? JSONSerialization.data(withJSONObject: obj) else { return }
        var line = data
        line.append(0x0A)  // newline
        line.withUnsafeBytes { buf in
            var sent = 0
            while sent < buf.count {
                let n = write(fd, buf.baseAddress!.advanced(by: sent), buf.count - sent)
                if n <= 0 { return }
                sent += n
            }
        }
    }
}
