//
//  EmailResourceTemplate.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-22.
//

import SwiftMCP

struct EmailResourceTemplate: MCPResourceTemplate {
    static let template = "mail://{mailbox}/{uid}/{section}"
    
    var uriTemplate: String = Self.template
    
    var name: String = "Contains a speciic part of an email"
    
    var description: String? = "Mailbox is the name of the mailbox that contains the email. UID is the unique identifier of the email. section is a string representing the part of the email i.e '1.2'."
    
    var mimeType: String? = nil
}
