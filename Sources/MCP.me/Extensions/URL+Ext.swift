//
//  URL+Ext.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-22.
//

import Foundation

extension URL {
    func extractTemplateVariables(from: String) throws -> [String: String] {
        let templateComponents = from.split(separator: "/")
        let urlComponents = self.absoluteString.split(separator: "/")
        
        guard templateComponents.count == urlComponents.count else {
            throw MCPResourceErrors.invalidTemplateStructure(message: "The provided template doesn't match expected structure")
        }
        
        var variables = [String: String]()
        
        for (template, actual) in zip(templateComponents, urlComponents) {
            if template.hasPrefix("{") && template.hasSuffix("}") {
                let name = String(template.dropFirst().dropLast())
                variables[name] = String(actual)
            } else if template != actual {
                throw MCPResourceErrors.invalidTemplateStructure(message: "The provided template doesn't match expected variable structure")
            }
        }
        
        return variables
    }
    
    enum MCPResourceErrors: Error {
        case invalidTemplateStructure(message: String)
    }
}

