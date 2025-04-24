import Logging
import SwiftMCP
import Foundation
import ArgumentParser

@main
struct App: AsyncParsableCommand, AppArguments {
    private static let appLabel = "com.MCP.me"
    private static let signalQueueLabel = "com.MCP.me.signalQueue"
    
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080
    
    func run() async throws {
        let server = try await AggregateServerFactory.make()
        
        let transport = HTTPSSETransport(
            server: server,
            host: hostname,
            port: port
        )
        transport.serveOpenAPI = true
        transport.logger = Logger(label: App.appLabel)
                
        let signalHandler = SignalHandler(transport: transport)
        await signalHandler.setup(label: App.signalQueueLabel)
        // Blocking
        try await transport.run()
    }
}

public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
}
