//
//  AuthenticationViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 25/4/2023.
//

import UIKit
import FirebaseAuth

class AuthenticationViewController: UIViewController {
    
    @IBOutlet weak var loginEmail: UITextField!
    
    @IBOutlet weak var loginPassword: UITextField!
    
    @IBOutlet weak var signupName: UITextField!
    
    @IBOutlet weak var signupEmail: UITextField!
    
    @IBOutlet weak var signupPassword: UITextField!
    
    weak var databaseController: DatabaseProtocol?
    
    // Flags to check for segue
    var islogin = false
    var issignup = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateUser()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        if signupName != nil{
            guard let username = signupName.text else{
                databaseController?.loadUser(userName: "NULL")
                return
            }
            databaseController?.loadUser(userName: username)
            
        }
        
    }
    func authenticateUser(){
        
        if Auth.auth().currentUser != nil{
            DispatchQueue.main.async {
                self.islogin = true
                self.performSegue(withIdentifier: "loginCompleteSegue", sender: nil)
            }
        }else{
            print("pass")
        }
    }
        
        
    @IBAction func login(_ sender: Any) {
        guard let loginPassword = loginPassword.text else{
            print("missing password")
            return
        }
        guard let loginEmail = loginEmail.text else{
            print("missing email")
            return
        }
        Auth.auth().signIn(withEmail: loginEmail, password: loginPassword) { [weak self] authResult, error in
            guard error == nil else{
                print("login failed")
                self?.displayMessage(title: "Login Failed", message: "Password/Email incorrect")
                return
            }
            print("successful")
            
            self?.islogin = true
            self?.performSegue(withIdentifier: "loginCompleteSegue", sender: nil)
        }
    }
    
    @IBAction func signup(_ sender: Any) {
        
        if signupEmail.text!.isEmpty{
            self.displayMessage(title: "Signup Failed", message: "Missing email")
            return
        }
        else if signupPassword.text!.isEmpty{
            self.displayMessage(title: "Signup Failed", message: "Missing password")
            return
        }
        
        Auth.auth().createUser(withEmail: signupEmail.text!, password: signupPassword.text!, completion: {authResult, error in
            // ...
            guard error == nil else{
                self.displayMessage(title: "Signup Failed", message: "Try stronger password/Different email")
                return
            }
            self.issignup = true
            self.performSegue(withIdentifier: "signupCompleteSegue", sender: nil)
        })
        
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // makes sure we dont segue if user hasnt logged in
        if identifier == "loginCompleteSegue"{
            if !self.islogin{
                return false
            }
            self.islogin = false
        }
        if identifier == "signupCompleteSegue"{
            if !self.issignup{
                return false
            }
            self.issignup = false
        }
        
        
        return true
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

