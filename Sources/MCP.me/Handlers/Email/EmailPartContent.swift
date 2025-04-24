//
//  EmailPartContent.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-20.
//

import SwiftMCP
import Foundation

/// A resource content implementation for email body parts
@Schema
public struct EmailPartContent: MCPResourceContent {
    /// The URI of the resource
    public let uri: URL
    
    /// The MIME type of the resource
    public let mimeType: String?
    
    /// The text content of the resource (if it's a text resource)
    public let text: String?
    
    /// The binary content of the resource (if it's a binary resource)
    public let blob: Data?
    
    /// Creates a new FileResourceContent
    /// - Parameters:
    ///   - uri: The URI of the file
    ///   - mimeType: The MIME type of the resource (optional)
    ///   - text: The text content of the resource (if it's a text resource)
    ///   - blob: The binary content of the resource (if it's a binary resource)
    public init(uri: URL, mimeType: String? = nil, text: String? = nil, blob: Data? = nil) {
        self.uri = uri
        self.mimeType = mimeType
        self.text = text
        self.blob = blob
    }
}
