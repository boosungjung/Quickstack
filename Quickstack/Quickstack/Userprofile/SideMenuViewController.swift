//
//  SideMenuViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 2/5/2023.
//

import Foundation
import UIKit
import FirebaseAuth

class SideMenuViewController: UIViewController{
    var appDelegate: AppDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let authenticationViewController = storyboard.instantiateViewController(withIdentifier: "AuthenticationViewController") as! AuthenticationViewController
            
            
            let navigationController = UINavigationController(rootViewController: authenticationViewController)
            navigationController.modalPresentationStyle = .fullScreen
            
//            let appDelegate = UIApplication.shared.delegate as? AppDelegate
//            
//            appDelegate!.resetDatabaseController()
            self.present(navigationController, animated: true, completion: nil)
                    
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
        
    }
}
