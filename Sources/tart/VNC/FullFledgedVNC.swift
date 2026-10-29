import Foundation
import Dynamic
import Virtualization

class FullFledgedVNC: VNC {
  let password: String
  private let vnc: Dynamic

  init(virtualMachine: VZVirtualMachine) {
    password = Array(PassphraseGenerator().prefix(4)).joined(separator: "-")
    let securityConfiguration = Dynamic._VZVNCAuthenticationSecurityConfiguration(password: password)
    // Use the main queue rather than the concurrent DispatchQueue.global().
    // The server likely expects a serial queue, and the VZVirtualMachine it
    // attaches to is bound to the main queue (created via init(configuration:)),
    // so this keeps VNC callbacks on the same queue as the VM. Lume does the same.
    // See https://github.com/openai/tart/issues/1382
    vnc = Dynamic._VZVNCServer(port: 0, queue: DispatchQueue.main,
                               securityConfiguration: securityConfiguration)
    vnc.virtualMachine = virtualMachine
    vnc.start()
  }

  func waitForURL(netBridged: Bool) async throws -> URL {
    while true {
      // Port is 0 shortly after start(),
      // but will be initialized later
      if let port = vnc.port.asUInt16, port != 0 {
        return URL(string: "vnc://:\(password)@127.0.0.1:\(port)")!
      }

      // Wait 50 ms.
      try await Task.sleep(nanoseconds: 50_000_000)
    }
  }

  func stop() throws {
    vnc.stop()
  }

  deinit {
    try? stop()
  }
}
