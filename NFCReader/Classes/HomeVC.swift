//
//  HomeVC.swift
//  NFCReader
//
//  Created by Nirzar Gandhi on 04/04/25.
//

import UIKit
import CoreNFC

class HomeVC: BaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var messageTF: UITextField!
    @IBOutlet weak var detectMessageTxtView: UITextView!
    
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var readBtn: UIButton!
    @IBOutlet weak var writeBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    
    
    // MARK: - Properties
    fileprivate lazy var messagesStr = ""
    
    
    // MARK: -
    // MARK: - View init Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Home"
        
        self.setControlsProperty()
        self.checkNFCSupported()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = .white
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.hidesBackButton = true
    }
    
    fileprivate func setControlsProperty() {
        
        self.view.backgroundColor = .white
        self.view.isOpaque = false
        
        // Message TextField
        self.messageTF.backgroundColor = .clear
        self.messageTF.textColor = .black
        self.messageTF.tintColor = .black
        self.messageTF.font = UIFont.systemFont(ofSize: 14)
        self.messageTF.keyboardType = .default
        self.messageTF.autocorrectionType = .no
        self.messageTF.delegate = self
        self.messageTF.attributedPlaceholder = NSAttributedString(string: "Enter message", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        self.messageTF.text = ""
        
        // Detect Message TextView
        self.detectMessageTxtView.backgroundColor = .clear
        self.detectMessageTxtView.textColor = .black
        self.detectMessageTxtView.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        self.detectMessageTxtView.textAlignment = .left
        self.detectMessageTxtView.isEditable = false
        self.detectMessageTxtView.isSelectable = false
        self.detectMessageTxtView.text = ""
        
        // Button StackView
        self.buttonStackView.axis = .horizontal
        self.buttonStackView.alignment = .fill
        self.buttonStackView.distribution = .fillEqually
        self.buttonStackView.spacing = 20.0
        
        // Read Buttton
        self.readBtn.setBackgroundColor(color: .black, forState: .normal)
        self.readBtn.setTitleColor(.white, for: .normal)
        self.readBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.readBtn.titleLabel?.lineBreakMode = .byClipping
        self.readBtn.layer.masksToBounds = true
        self.readBtn.addRadiusWithBorder(radius: 8.0)
        self.readBtn.showsTouchWhenHighlighted = false
        self.readBtn.adjustsImageWhenHighlighted = false
        self.readBtn.adjustsImageWhenDisabled = false
        self.readBtn.setTitle("Read", for: .normal)
        
        // Write Button
        self.writeBtn.setBackgroundColor(color: .black, forState: .normal)
        self.writeBtn.setTitleColor(.white, for: .normal)
        self.writeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.writeBtn.titleLabel?.lineBreakMode = .byClipping
        self.writeBtn.layer.masksToBounds = true
        self.writeBtn.addRadiusWithBorder(radius: 8.0)
        self.writeBtn.showsTouchWhenHighlighted = false
        self.writeBtn.adjustsImageWhenHighlighted = false
        self.writeBtn.adjustsImageWhenDisabled = false
        self.writeBtn.setTitle("Write", for: .normal)
        
        // Clear Button
        self.clearBtn.setBackgroundColor(color: .black, forState: .normal)
        self.clearBtn.setTitleColor(.white, for: .normal)
        self.clearBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        self.clearBtn.titleLabel?.lineBreakMode = .byClipping
        self.clearBtn.layer.masksToBounds = true
        self.clearBtn.addRadiusWithBorder(radius: 8.0)
        self.clearBtn.showsTouchWhenHighlighted = false
        self.clearBtn.adjustsImageWhenHighlighted = false
        self.clearBtn.adjustsImageWhenDisabled = false
        self.clearBtn.setTitle("Clear", for: .normal)
    }
}


// MARK: - Call Back
extension HomeVC {
    
    fileprivate func checkNFCSupported() {
        
        if NFCReaderManager.shared.isNFCSupported() {
            
            self.messagesStr += "\nNFC is supported"
            self.detectMessageTxtView.text = self.messagesStr
            
            NFCReaderManager.shared.nfcReaderManagerDelegate = self
            
            self.readBtn.isUserInteractionEnabled = true
            self.readBtn.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            
            self.writeBtn.isUserInteractionEnabled = true
            self.writeBtn.backgroundColor = UIColor.black.withAlphaComponent(1.0)
            
        } else {
            
            self.messagesStr += "\nNFC is not supported"
            self.detectMessageTxtView.text = self.messagesStr
            
            self.readBtn.isUserInteractionEnabled = false
            self.readBtn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            self.writeBtn.isUserInteractionEnabled = false
            self.writeBtn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
    
    fileprivate func clearMessageText() {
        
        self.messageTF.resignFirstResponder()
        
        self.messagesStr = ""
        self.detectMessageTxtView.text = ""
    }
}


// MARK: - NFCReaderManager Delegate
extension HomeVC: NFCReaderManagerDelegate {
    
    func didDetectNFCMessage(_ message: String) {
        
        DispatchQueue.main.async {
            
            self.messagesStr += "\n\(message)"
            self.detectMessageTxtView.text = self.messagesStr
        }
    }
}


// MARK: - Button Touch & Action
extension HomeVC {
    
    @IBAction func readBtnTouch(_ sender: Any) {
        
        self.clearMessageText()
        
        NFCReaderManager.shared.startSession()
    }
    
    @IBAction func writeBtnTouch(_ sender: Any) {
        
        self.clearMessageText()
        
        if let messageText = self.messageTF.text, !messageText.isEmpty {
            NFCReaderManager.shared.startSession(message: messageText)
        } else {
            self.detectMessageTxtView.text = "Enter a message"
        }
    }
    
    @IBAction func clearBtnTouch(_ sender: Any) {
        
        self.clearMessageText()
        
        NFCReaderManager.shared.startSession()
        NFCReaderManager.shared.isClearNFCTag = true
    }
}


// MARK: - UITextField Delegate
extension HomeVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}
