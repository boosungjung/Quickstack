//
//  UIViewController+DisplayMessage.swift
//  Quickstack
//
//  Created by BooSung Jung on 26/4/2023.
//

import UIKit
extension UIViewController {
    
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        
        self.present(alertController, animated: true)
    }
}
