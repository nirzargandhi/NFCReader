//
//  NFCReaderExtensions.swift
//  NFCReader
//
//  Created by Nirzar Gandhi on 04/04/25.
//

import UIKit

// MARK: - UIViewController
extension UIViewController {
    
    // Add Navigation Bottom Shadow
    func hideNavigationBottomShadow() {
        self.navigationController?.navigationBar.layer.masksToBounds = true
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.clear.cgColor
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.0
    }
    
    // Get Top & Bottom bar height
    var getNavBarHeight: CGFloat {
        return (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    
    var getTabBarHeight: CGFloat {
        return (self.tabBarController?.tabBar.frame.size.height ?? 49.0)
    }
}


// MARK: - NSObject
extension NSObject {
    
    var ClassName: String {
        return String(describing: type(of: self))
    }
    
    class var ClassName: String {
        return String(describing: self)
    }
}


// MARK: - UIView
extension UIView {
    
    func addRadiusWithBorder(radius: CGFloat = 10, border: CGFloat = 0.0) {
        
        self.layer.cornerRadius = radius
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }
        self.layer.borderWidth = border
    }
}


// MARK: - UIButton
extension UIButton {
    
    // Set BackgroundColor
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()?.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}


// MARK: - String Protocol
extension StringProtocol {
    var asciiValues: [UInt8] { compactMap(\.asciiValue) }
}
