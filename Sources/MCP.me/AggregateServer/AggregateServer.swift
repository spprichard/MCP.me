//
//  Server.swift
//  API
//
//  Created by Steven Prichard on 2025-04-05.
//

import SwiftMCP

@MCPServer(name: "MCP.me", version: "0.0.1")
class AggregateMCPServer {
    internal let pingHandler: PingHandler
    internal let emailHander: EmailHandler
    
    internal var servers: [MCPServer]
    
    // TODO: Clean up the use of properties & array...do we need both?
    init(
        pingHandler: PingHandler,
        emailHandler: EmailHandler
    ) {
        self.pingHandler = pingHandler
        self.emailHander = emailHandler
        self.servers = [
            pingHandler,
            emailHandler
        ]
    }
}
