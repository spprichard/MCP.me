//
//  PingHandler.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-19.
//

import SwiftMCP

@MCPServer(name: "PingMCP", version: "0.0.1")
class PingHandler {
    @MCPTool(description: "Ping is used to test the connection to the server")
    func ping() -> String {
        return "PONG"
    }
}
