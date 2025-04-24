//
//  EmailHandler.swift
//  MCP.me
//
//  Created by Steven Prichard on 2025-04-20.
//

import SwiftMCP
import SwiftMail
import Foundation
import SwiftDotenv

@MCPServer(name: "Email", version: "0.0.1")
package actor EmailHandler {
    private let server: IMAPServer
    
    package init(configuration: Configuration) async throws {
        server = IMAPServer(
            host: configuration.host,
            port: configuration.port
        )
        
        try await connect(to: server, with: configuration)
    }
    
    private func connect(to server: IMAPServer, with configuration: Configuration) async throws {
        try await server.connect()
        
        try await server.login(
            username: configuration.username,
            password: configuration.password
        )
    }
    
    @MCPTool(description: "Lists all mailboxes on the server")
    func listMailboxes() async throws -> [Mailbox] {
        let specialMailboxes = try await server.listSpecialUseMailboxes()
            .map { Mailbox(info: $0) }
        
        let normalMailboxes = try await server.listMailboxes()
            .map { Mailbox(info: $0) }
            .filter { mailbox in
                !specialMailboxes.contains(where: { $0.name == mailbox.name })
            }
        
        return (specialMailboxes + normalMailboxes).sorted { $0.name < $1.name }
    }
    
    /**
     Fetches email headers containing information about each messages structure  from a specific mailbox
        - Parameter mailbox: The name of the mailbox
        - Parameter limit: The maximum amount of message headers to fetch (default: 100)
        - Returns: A collection of message headers
        - Throws: An error if unable to access the specified mailbox
     */
    @MCPTool(isConsequential: false)
    func fetchEmailHeaders(from mailbox: String, limit: Int = 100) async throws -> [MessageInfo] {
        let status = try await server.selectMailbox(mailbox)
        if let latestMessageIDs = status.latest(limit) {
            return try await server.fetchMessageInfo(using: latestMessageIDs)
        } else {
            throw MailError.generic(message: "No messages found in \(mailbox)")
        }
    }
    
    /**
    Fetches a specific part of a email, providing the mailbox & uID of the messaage
    Example: Mailbox: Receipts - uID: 252 - section: "2" -> URI: "mail://Receipts/252/2/STRIVEFitnessandTherapy-Receipt-2025-03-03.pdf"
     - Parameter mailbox: The name of the mailbox (required)
     - Parameter uID: The Identifier to the message in which you want the part from (required)
     - Parameter section: The section identifier of the part of the email. If not provided, all parts are returned(optional)
     - Returns: A  collection of the parts of the email requiest, represented as an MCP Resource
     - Throws: An error if message could not be found
     */
    @MCPTool(isConsequential: false)
    func fetchMessageParts(from mailbox: String, uID: Int, section: String? = nil) async throws -> [EmailPartContent] {
        let _ = try await server.selectMailbox(mailbox)
        let id = MessageIdentifierSet<UID>(uID)
        guard let messageInfo = try await server.fetchMessageInfo(using: id).first else {
             throw MailError.generic(message: "Message \(uID) not found in \(mailbox)")
        }
        
        guard let message = try await server.fetchMessages(using: id).first  else {
            throw MailError.generic(message: "Message \(uID) not found in \(mailbox)")
        }
    

        if let section {
            let sectionID = Section(section)
//            guard let part = messageInfo.parts.first(where: { $0.section == sectionID }) else {
//                throw MailError.generic(message: "No part with section \(section) found in message with uID \(uID)")
//            }
            guard let part = message.parts.first(where: { $0.section == sectionID }) else {
                throw MailError.generic(message: "No part with section \(section) found in message with uID \(uID)")
            }
            
            print("@@ DATA: \(String(data: part.data!, encoding: .utf8) ?? "NONE")")
            
            return try await process(
                mailbox: mailbox,
                info: messageInfo,
                uID: uID,
                part: part
            )
        }
        
        var results: [EmailPartContent] = []
        for part in messageInfo.parts {
            results.append(contentsOf:
                try await process(
                    mailbox: mailbox,
                    info: messageInfo,
                    uID: uID,
                    part: part
                )
            )
        }
        
        return results
    }
    
    @MCPTool(description: "Test Decoding PDF")
    func testDecodingPDF() async throws {
        let specialFolders = try await server.listSpecialUseMailboxes()
        guard let inbox = specialFolders.inbox else {
            print("❌ INBOX mailbox not found")
            exit(1)
        }
        let mailboxStatus = try await server.selectMailbox(inbox.name)
        print("Selected mailbox: \(inbox.name) with \(mailboxStatus.messageCount) messages")

        print("\nSearching for invoices with PDF ...")
        let messagesSet: MessageIdentifierSet<UID> = try await server.search(criteria: [.subject("invoice"), .text(".pdf")])
        print("Found \(messagesSet.count) messages")
        
        if !messagesSet.isEmpty {
            let messageInfos = try await server.fetchMessageInfo(using: messagesSet)
            print("\n📧 Invoice Emails (\(messageInfos.count)) 📧")
            for (index, messageInfo) in messageInfos.enumerated() {
                print("\n[\(index + 1)/\(messageInfos.count)]\n\(messageInfo)")
                print("---")
                
                // here we can get and decode specific parts
                for part in messageInfo.parts {

                    // find an part that's an attached PDF
                    guard part.contentType == "application/pdf" else
                    {
                        continue
                    }

                    // get the body data for the part
                    let data = try await server.fetchAndDecodeMessagePartData(messageInfo: messageInfo, part: part)
                    print("PART - encoding: \(part.encoding)")
                    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                    let url = desktopURL.appendingPathComponent(part.suggestedFilename)
                    try data.write(to: url)
                    let message =  String(data: data, encoding: .utf8) ?? "FAILED"
                    print(message)
                }
            }
        } else {
            print("No messages found matching the search criteria.")
            exit(1)
        }
    }
    
    /**
     Decodes the provided email content.
     Currenlty only supports PDF attachements
     - Parameter mailbox: The name of the mailbox (required)
     - Parameter uID: The Identifier to the message in which you want the part from (required)
     - Parameter section: The section identifier of the part of the email. If not provided, all parts are returned(optional)
     - Returns: A string of the decoded content
     - Throws: An error if there was a failure decoding the attachment
     */
    @MCPTool(isConsequential: false)
    func decodeAttachment(from mailbox: String, uID: Int, section: String? = nil) async throws -> String? {
        let parts = try await fetchMessageParts(from: mailbox, uID: uID, section: section)
        guard let attachment = parts.first else {
            throw MailError.generic(message: "Failed to find attachment")
        }

        guard attachment.mimeType == "application/pdf" else {
            throw MailError.generic(message: "Unsupported content type: \(attachment.mimeType ?? "UNKNOWN")")
        }
        
        guard let encodedData = attachment.blob else {
            throw MailError.generic(message: "Attachment is missing data")
        }
        
        guard let decodedData = Data(
            base64Encoded: encodedData,
            options: [.ignoreUnknownCharacters]
        ) else {
            throw MailError.generic(message: "Failed to decode attachment data")
        }
        
        return String(data: decodedData, encoding: .utf8)
    }
    
    /*
     Mailbox: Receipts
     UID: 184
     Section: 2
     */
    func fetchResource(from uri: URL) async throws -> EmailPartContent? {
        guard uri.scheme == "mail" else {
            throw MailError.resourceTemplate(.unsupportedScheme(privided: "\(uri.scheme ?? "NONE")"))
        }
        
        do {
            let variables = try uri.extractTemplateVariables(from: EmailResourceTemplate.template)
            
            guard let mailbox = variables["mailbox"],
                  let uIDString = variables["uid"],
                  let uID = Int(uIDString),
                  let sectionString = variables["section"]
            else {
                throw MailError.resourceTemplate(.missingRequiredVariables)
            }
            
            guard let resource = try await fetchMessageParts(
                from: mailbox,
                uID: uID,
                section: sectionString
            ).first else {
                //throw MailError.resourceTemplate(.invalidResource(provided: uri))
                return nil
            }
            
            return resource
            
        } catch let error {
            throw MailError.resourceTemplate(.failedVariableExtraction(reason: error))
        }
    }
    
    private func process(mailbox: String, info: MessageInfo, uID: Int, part: MessagePart) async throws -> [EmailPartContent] {
        let data = try await server.fetchAndDecodeMessagePartData(messageInfo: info, part: part)
        let uri = URL(string: "mail://\(mailbox)/\(uID)/\(part.section)/\(part.suggestedFilename)")!
        
        if part.contentType.hasPrefix("text/") {
            let text = String(data: data, encoding: .utf8)
            return [EmailPartContent(
                uri: uri,
                mimeType: part.contentType,
                text: text,
                blob: data
            )]
        }
        
        return [EmailPartContent(
            uri: uri,
            mimeType: part.contentType,
            blob: data
        )]
    }
}



extension EmailHandler {
    package struct Configuration {
        let host: String
        let port: Int
        let username: String
        let password: String
        
        static func load() throws -> Configuration {
            // Get IMAP credentials
            guard case let .string(host) = Dotenv["IMAP_HOST"],
                  case let .integer(port) = Dotenv["IMAP_PORT"],
                  case let .string(username) = Dotenv["IMAP_USERNAME"],
                  case let .string(password) = Dotenv["IMAP_PASSWORD"] else {
                throw Errors.failedToLoadConfiguration
            }
            
            return .init(
                host: host,
                port: port,
                username: username,
                password: password
            )
        }
        
        enum Errors: Error {
            case failedToLoadConfiguration
        }
    }
}

extension EmailHandler {
    enum MailError: Error {
        case generic(message: String)
        case resourceTemplate(ResourceTemplateError)
        
        var localizedDescription: String {
            switch self {
            case .generic(message: let message):
                return message
            case .resourceTemplate(let error):
                return error.localizedDescription
            }
        }
    }
    
    enum ResourceTemplateError: Error {
        case missingRequiredVariables
        case invalidResource(provided: URL)
        case unsupportedScheme(privided: String)
        case failedVariableExtraction(reason: Error)
        
        var localizedDescription: String {
            switch self {
            case .unsupportedScheme(privided: let scheme):
                return "Unsupported scheme: \(scheme)"
            case .invalidResource(provided: let url):
                return "Invalid resource URL: \(url)"
            case .failedVariableExtraction(let error):
                return "Failed to extract variables from resource template - reason: \(error)"
            case .missingRequiredVariables:
                return "Missing required variables in resource template"
            }
        }
    }
}
