//
//  AggregateMCPServer+MCPResourceProviding.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-22.
//

import SwiftMCP
import Foundation

extension AggregateMCPServer: MCPRessourceProviding {
    var mcpResources: [any MCPResource] {
        get async {
            return []
        }
    }
    
    var mcpResourceTemplates: [any MCPResourceTemplate] {
        get async {
            [
                EmailResourceTemplate()
            ]
        }
    }
    
    func getResource(uri: URL) async throws -> (any MCPResourceContent)? {
        try await self.emailHander.fetchResource(from: uri)
    }
}

