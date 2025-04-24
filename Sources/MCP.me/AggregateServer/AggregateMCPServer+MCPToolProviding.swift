//
//  AggregateMCPServer+Ext.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-19.
//

import SwiftMCP

extension AggregateMCPServer: MCPToolProviding {
    var mcpToolMetadata: [MCPToolMetadata] {
        servers
            .compactMap { $0 as? MCPToolProviding }
            .flatMap { $0.mcpToolMetadata }
    }
    
    func callTool(_ name: String, arguments: [String : any Sendable]) async throws -> any Encodable & Sendable {
        for server in servers {
            guard let toolProvider = server as? MCPToolProviding,
                 toolProvider.mcpToolMetadata.contains(where: { $0.name == name })
            else { continue }
            
            return try await toolProvider.callTool(name, arguments: arguments)
        }
        
        throw MCPToolError.unknownTool(name: name)
    }
}
