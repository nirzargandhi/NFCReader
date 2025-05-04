//
//  Common.swift
//  NFCReader
//
//  Created by Nirzar Gandhi on 04/04/25.
//

import Foundation
import UIKit

// MARK: - Multi Attributed String
func multiattributedString(strings : [String], fonts : [UIFont], colors : [UIColor], alignments : [NSTextAlignment] = [.left], lineSpace: CGFloat = 0.0)-> NSMutableAttributedString {
    
    var finalstr = ""
    for str in strings{
        finalstr = finalstr + str
    }
    let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: finalstr)
    
    var i = 0
    var j = 0
    
    for font in fonts{
        if (j < strings.count){
            attributeString.addAttribute(NSAttributedString.Key.font,
                                         value: font ,
                                         range: NSRange(
                                            location: i,
                                            length: strings[j].count))
            i = i + strings[j].count
            j = j + 1
        }
    }
    j = 0
    i = 0
    for color in colors{
        if (j < strings.count){
            attributeString.addAttribute(NSAttributedString.Key.foregroundColor,
                                         value: color ,
                                         range: NSRange(
                                            location: i,
                                            length: strings[j].count))
            i = i + strings[j].count
            j = j + 1
        }
    }
    
    j = 0
    i = 0
    for align in alignments {
        if (j < strings.count) {
            
            let style = NSMutableParagraphStyle()
            style.alignment = align
            style.lineSpacing = lineSpace
            
            attributeString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                         value:style,
                                         range : NSRange(
                                            location: i,
                                            length: strings[j].count))
            
            
            i = i + strings[j].count
            j = j + 1
        }
    }
    
    return attributeString
}
