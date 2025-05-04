//
//  Constants.swift
//  NFCReader
//
//  Created by Nirzar Gandhi on 04/04/25.
//

import Foundation
import UIKit

let BASEWIDTH = 375.0
let SCREENSIZE: CGRect      = UIScreen.main.bounds
let SCREENWIDTH             = UIScreen.main.bounds.width
let SCREENHEIGHT            = UIScreen.main.bounds.height
let STATUSBARHEIGHT         = UIApplication.shared.statusBarFrame.size.height
var NAVBARHEIGHT            = 44.0

let APPDELEOBJ              = UIApplication.shared.delegate as! AppDelegate

struct Constants {
    
    struct Generic {
        
        // Tag Session Message
        static let TAG_SESSION_MESSAGE = "Hold your iPhone near the tag"
    }
}
