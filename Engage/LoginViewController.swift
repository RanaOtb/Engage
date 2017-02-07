//
//  ViewController.swift
//  Engage
//
//  Created by Nathan Tannar on 1/9/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import UIKit
import NTUIKit
import Parse
import ParseFacebookUtilsV4

class LoginViewController: NTLoginViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginOptions = [.facebook, .email]
        self.logo = UIImage(named: "Engage_Logo")
        
        if PFUser.current() != nil {
            let query = PFQuery(className: "Engagements")
            query.whereKey("name", equalTo: "Test")
            query.findObjectsInBackground(block: { (objects, error) in
                if let object = objects?.first {
                    User.didLogin(with: PFUser.current()!)
                    Engagement.didSelect(with: object)
                }
            })
        }
    }
    
    override func registerButtonPressed() {
        let vc = UINavigationController(rootViewController: RegisterViewController())
        self.present(vc, animated: true, completion: nil)
    }
    
    override func emailLoginLogic(email: String, password: String) {
        
        // Freeze user interaction
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // Send login data to server to request session token
        PFUser.logInWithUsername(inBackground: email, password: password) { (object, error) -> Void in
            UIApplication.shared.endIgnoringInteractionEvents()
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                return
            }
            Log.write(.status, "Email Login Successful")
            User.didLogin(with: user)
            let query = PFQuery(className: "Engagements")
            query.whereKey("name", equalTo: "Test")
            query.findObjectsInBackground(block: { (objects, error) in
                if let object = objects?.first {
                    Engagement.didSelect(with: object)
                }
            })
        }
    }
    
    override func facebookLoginLogic() {
        PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email", "user_friends"]) { (object, error) in
            guard let user = object else {
                Log.write(.error, error.debugDescription)
                Toast.genericErrorMessage()
                return
            }
            Log.write(.status, "Facebook Login Successful")
            User.didLogin(with: user)
            
            
            let request = FBSDKGraphRequest(graphPath:"me", parameters: ["fields": "id, email, first_name, last_name"])
            request!.start(completionHandler: { (connection, result, error) in
                guard let userData = result as? NSDictionary else {
                    Log.write(.error, "Could not request user data from Facebook")
                    Toast.genericErrorMessage()
                    return
                }
                User.current().email = userData["email"] as? String
                let firstName = userData["first_name"] as! String
                let lastName = userData["last_name"] as! String
                User.current().fullname = firstName + " " + lastName
                User.current().save(completion: nil)
                
                let query = PFQuery(className: "Engagements")
                query.whereKey("name", equalTo: "Test")
                query.findObjectsInBackground(block: { (objects, error) in
                    if let object = objects?.first {
                        Engagement.didSelect(with: object)
                    }
                })
            })
        }
    }
}

