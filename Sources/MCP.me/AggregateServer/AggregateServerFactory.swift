//
//  AggregateServerFactory.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-20.
//

import Foundation

enum AggregateServerFactory {
    static func make() async throws-> AggregateMCPServer {
        let emailConfig = try EmailHandler.Configuration.load()
        let emailHandler = try await EmailHandler(configuration: emailConfig)
        
        return .init(
            pingHandler: PingHandler(),
            emailHandler: emailHandler
        )
    }
}
