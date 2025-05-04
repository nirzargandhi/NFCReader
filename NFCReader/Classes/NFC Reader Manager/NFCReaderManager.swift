//
//  NFCReaderManager.swift
//  NFCReader
//
//  Created by Nirzar Gandhi on 04/04/25.
//

import Foundation
import CoreNFC

protocol NFCReaderManagerDelegate: AnyObject {
    func didDetectNFCMessage(_ message: String)
}

class NFCReaderManager: NSObject {
    
    // MARK: - Properties
    static let shared: NFCReaderManager = {
        let instance = NFCReaderManager()
        return instance
    }()
    
    fileprivate lazy var detectedMessages = [NFCNDEFMessage]()
    internal var nfcReaderManagerDelegate: NFCReaderManagerDelegate?
    internal lazy var writeMessageToTagStr = ""
    internal lazy var isClearNFCTag = false
    
    
    // MARK: - Init
    override init() {
        super.init()
    }
}


// MARK: - Call Back
extension NFCReaderManager {
    
    internal func isNFCSupported() -> Bool {
        
        if #available(iOS 13.0, *) {
            return NFCTagReaderSession.readingAvailable
        } else {
            return NFCReaderSession.readingAvailable
        }
    }
    
    internal func startSession(message: String = "") {
        
        self.writeMessageToTagStr = message
        
        if #available(iOS 13.0, *) {
            
            // iso18092 - Using this we need extra permission from Apple
            
            var pollingOptions: NFCTagReaderSession.PollingOption = [.iso14443, .iso15693]
            
            if #available(iOS 16.0, *) {
                pollingOptions.insert(.pace)
            }
            
            let nfcTagSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self, queue: nil)
            nfcTagSession?.alertMessage = Constants.Generic.TAG_SESSION_MESSAGE
            nfcTagSession?.begin()
            
        } else {
            
            let nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            nfcSession.alertMessage = Constants.Generic.TAG_SESSION_MESSAGE
            nfcSession.begin()
        }
    }
    
    @available(iOS 13.0, *)
    fileprivate func readTag(session: NFCNDEFReaderSession , tags: [NFCNDEFTag] ) {
        
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            
            if nil != error {
                session.alertMessage = "Unable to connect to tag"
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                
                if .notSupported == ndefStatus {
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    return
                } else if nil != error {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    return
                }
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage: String
                    
                    if nil != error || nil == message {
                        statusMessage = "Fail to read NDEF from tag"
                    } else {
                        statusMessage = "Found 1 NDEF message"
                        DispatchQueue.main.async {
                            // Process detected NFCNDEFMessage objects.
                            self.detectedMessages.append(message!)
                            //self.tableView.reloadData()
                        }
                    }
                    
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
            })
        })
        
    }
    
    @available(iOS 13.0, *)
    fileprivate func writeTag(session: NFCNDEFReaderSession , tags: [NFCNDEFTag] ) {
        
        if tags.count > 1 {
            
            // Restart polling in 500 milliseconds.
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected. Please remove all tags and try again"
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            
            return
        }
        
        // Connect to the found tag and write an NDEF message to it.
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            
            if nil != error {
                session.alertMessage = "Unable to connect to tag"
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                
                guard error == nil else {
                    session.alertMessage = "Unable to query the NDEF status of tag"
                    session.invalidate()
                    return
                }
                
                switch ndefStatus {
                    
                case .notSupported:
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    
                case .readOnly:
                    session.alertMessage = "Tag is read only"
                    session.invalidate()
                    
                case .readWrite:
                    if let message = self.detectedMessages.first {
                        
                        tag.writeNDEF(message, completionHandler: { (error: Error?) in
                            
                            if error != nil {
                                session.alertMessage = "Write NDEF message fail: \(error!)"
                            } else {
                                session.alertMessage = "Write NDEF message successful"
                            }
                            
                            session.invalidate()
                        })
                    }
                    
                @unknown default:
                    session.alertMessage = "Unknown NDEF tag status"
                    session.invalidate()
                }
            })
        })
    }
    
    @available(iOS 13.0, *)
    fileprivate func readNFCTagMessage(session: NFCTagReaderSession, miFareTag: NFCMiFareTag) {
        
        // Let's say we want to write "ABCD" into Page 4
        let pageNumber: UInt8 = 4
        
        var command = Data()
        command.append(0x30) // READ command
        command.append(pageNumber)
        
        miFareTag.sendMiFareCommand(commandPacket: command) { (response: Data, error: Error?) in
            
            if let error = error {
                
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Read failed: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Read failed.")
                return
            }
            
            self.nfcReaderManagerDelegate?.didDetectNFCMessage("Read success, response: \(response as NSData)")
            
            let responseStr: String
            
            if let firstNullIndex = response.firstIndex(of: 0x00) {
                
                // Cut the data up to first 0x00 (null terminator)
                let cleanData = response.prefix(upTo: firstNullIndex)
                responseStr = String(data: cleanData, encoding: .utf8) ?? "Invalid text"
                
            } else {
                
                // No null byte found, decode all
                responseStr = String(data: response, encoding: .utf8) ?? "Invalid text"
            }
            
            // response is 16 bytes (4 pages × 4 bytes)
            if !responseStr.isEmpty {
                
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Read Text: \(responseStr)")
                session.alertMessage = "Read text: \(responseStr)"
                
                if responseStr != self.writeMessageToTagStr {
                    
                    self.writeNFCTagMessage(session: session, miFareTag: miFareTag)
                    return
                    
                } else {
                    
                    self.nfcReaderManagerDelegate?.didDetectNFCMessage("Previous message is the same, so I cannot write it. Please change the message and try again")
                    session.alertMessage = "Cannot write the same message twice"
                }
                
            } else {
                
                self.writeNFCTagMessage(session: session, miFareTag: miFareTag)
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Could not decode text")
                
                session.alertMessage = "Could not decode text"
                
                return
            }
            
            session.invalidate()
        }
    }
    
    @available(iOS 13.0, *)
    fileprivate func writeNFCTagMessage(session: NFCTagReaderSession, miFareTag: NFCMiFareTag) {
        
        let dataToWrite = Data(self.writeMessageToTagStr.asciiValues) // ASCII for A, B, C, D
        let pageNumber: UInt8 = 4
        
        var command = Data()
        command.append(0xA2) // WRITE command
        command.append(pageNumber)
        command.append(dataToWrite)
        
        miFareTag.sendMiFareCommand(commandPacket: command) { (response: Data, error: Error?) in
            
            if let error = error {
                
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Write failed: \(error.localizedDescription)")
                session.invalidate(errorMessage: "Write failed")
                
                return
            }
            
            self.nfcReaderManagerDelegate?.didDetectNFCMessage("Write successful, response: \(response as NSData)")
            
            session.alertMessage = "Write completed"
            session.invalidate()
        }
    }
    
    @available(iOS 13.0, *)
    fileprivate func clearNFCTag(session: NFCTagReaderSession, miFareTag: NFCMiFareTag) {
        
        var currentPage: UInt8 = 4
        let lastUserPage: UInt8 = 39 // NTAG213 memory ends at page 39
        let zeroBlock = Data([0x00, 0x00, 0x00, 0x00])
        
        func writeNext() {
            
            guard currentPage <= lastUserPage else {
                
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Tag cleared successfully")
                session.alertMessage = "Tag cleared successfully"
                session.invalidate()
                return
            }
            
            var command = Data()
            command.append(0xA2) // WRITE command
            command.append(currentPage)
            command.append(zeroBlock)
            
            miFareTag.sendMiFareCommand(commandPacket: command) { (response, error) in
                
                if let error = error {
                    
                    self.nfcReaderManagerDelegate?.didDetectNFCMessage("Failed to clear page \(currentPage): \(error.localizedDescription)")
                    session.invalidate(errorMessage: "Clear failed.")
                    return
                }
                
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Cleared page \(currentPage)")
                currentPage += 1
                writeNext()
            }
        }
        
        writeNext()
    }
}


// MARK: - NFCTagReaderSession Delegate
@available(iOS 13.0, *)
extension NFCReaderManager: NFCTagReaderSessionDelegate {
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        self.nfcReaderManagerDelegate?.didDetectNFCMessage("NFC tag session become active")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tags found")
            return
        }
        
        session.connect(to: tag) { error in
            
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }
            
            switch tag {
                
            case .miFare(let miFareTag):
                
                let uid = miFareTag.identifier.map { String(format: "%02x", $0) }.joined()
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("MiFare UID: \(uid)")
                
                if self.isClearNFCTag {
                    self.clearNFCTag(session: session, miFareTag: miFareTag)
                } else if !self.writeMessageToTagStr.isEmpty {
                    self.readNFCTagMessage(session: session, miFareTag: miFareTag)
                }
                
            case .iso7816(let iso7816Tag):
                
                let uid = iso7816Tag.identifier.map { String(format: "%02x", $0) }.joined()
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("ISO7816 UID: \(uid)")
                
                if let dt = iso7816Tag.applicationData {
                    self.nfcReaderManagerDelegate?.didDetectNFCMessage("Application Data: \(dt)")
                }
                
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("Historical Bytes: \(String(describing: iso7816Tag.historicalBytes))")
                
            case .iso15693(let iso15693Tag):
                
                let uid = iso15693Tag.identifier.map { String(format: "%02x", $0) }.joined()
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("ISO15693 UID: \(uid)")
                
            case .feliCa(let feliCaTag):
                
                let uid = feliCaTag.currentIDm.map { String(format: "%02x", $0) }.joined()
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("FeliCa IDm: \(uid)")
                self.nfcReaderManagerDelegate?.didDetectNFCMessage("System Code: \(feliCaTag.currentSystemCode.map { String(format: "%02x", $0) }.joined())")
                
            @unknown default:
                session.invalidate(errorMessage: "Unknown tag type")
                return
            }
            
            if self.writeMessageToTagStr.isEmpty && !self.isClearNFCTag {
                session.alertMessage =  "NFC tag scanned successfully"
                session.invalidate()
            }
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        self.nfcReaderManagerDelegate?.didDetectNFCMessage("NFC tag Session Invalidated: \(error.localizedDescription)")
    }
}


// MARK: - NFCNDEFReaderSession Delegate
extension NFCReaderManager: NFCNDEFReaderSessionDelegate {
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        self.nfcReaderManagerDelegate?.didDetectNFCMessage("NFC session become active")
    }
    
    // Called when an NFC tag is detected
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        for message in messages {
            
            for record in message.records {
                
                if let payloadStr = String(data: record.payload, encoding: .utf8) {
                    
                    self.nfcReaderManagerDelegate?.didDetectNFCMessage("NFC Data: \(payloadStr)")
                    break
                }
            }
        }
    }
    
    // Called when an error occurs
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        self.nfcReaderManagerDelegate?.didDetectNFCMessage("NFC Session Invalidated: \(error.localizedDescription)")
    }
    
    /// - Tag: processingNDEFTag
    /// if This method is not implement then only   func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) will call
    /// Tells the delegate that the session detected NFC tags with NDEF messages and enables read-write capability for the session.
    @available(iOS 13.0, *)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        self.readTag(session: session, tags: tags)
    }
}
