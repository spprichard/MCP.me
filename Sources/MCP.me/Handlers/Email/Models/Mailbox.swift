//
//  File.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-20.
//

import SwiftMCP
import SwiftMail
import Foundation

/**
 Name and special use properties of a mailbox
 */
@Schema
struct Mailbox: Codable
{
    /**
     The name of the mailbox
     */
    let name: String
    
    /**
     If there's a special use for this mailbox
     */
    let specialUse: String?
    
    init(info: SwiftMail.Mailbox.Info) {
        self.name = info.name
        
        // Map special-use attributes to their string representation
        if info.attributes.contains(.inbox) {
            self.specialUse = "Inbox"
        } else if info.attributes.contains(.sent) {
            self.specialUse = "Sent"
        } else if info.attributes.contains(.trash) {
            self.specialUse = "Trash"
        } else if info.attributes.contains(.drafts) {
            self.specialUse = "Drafts"
        } else if info.attributes.contains(.junk) {
            self.specialUse = "Junk"
        } else if info.attributes.contains(.archive) {
            self.specialUse = "Archive"
        } else if info.attributes.contains(.flagged) {
            self.specialUse = "Flagged"
        } else {
            self.specialUse = nil
        }
    }
}

