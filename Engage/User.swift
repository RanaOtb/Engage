//
//  User.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Foundation
import Parse
import NTUIKit

public class User {
    
    private static var _current: User?
    
    public var object: PFUser
    public var userExtension: UserExtension?
    public var id: String {
        get {
            guard let id = self.object.objectId else {
                Log.write(.error, "User ID was nil")
                fatalError()
            }
            return id
        }
    }
    public var createdAt: Date? {
        get {
            return self.object.createdAt
        }
    }
    public var updatedAt: Date? {
        get {
            return self.object.updatedAt
        }
    }
    public var image: UIImage?
    public var coverImage: UIImage?
    public var fullname: String? {
        get {
            return self.object.value(forKey: PF_USER_FULLNAME) as? String
        }
        set {
            self.object[PF_USER_FULLNAME] = newValue?.lowercased().capitalized
            self.object[PF_USER_FULLNAME_LOWER] = newValue?.lowercased()
        }
    }
    public var email: String? {
        get {
            return self.object.email
        }
        set {
            if newValue!.isValidEmail() {
                self.object.email = newValue
            }
        }
    }
    public var phone: String? {
        get {
            return self.object.value(forKey: PF_USER_PHONE) as? String
        }
        set {
            self.object[PF_USER_PHONE] = newValue
        }
    }
    public var blockedUsers: [String]? {
        get {
            return self.object.value(forKey: PF_USER_BLOCKED) as? [String]
        }
        set {
            self.object[PF_USER_BLOCKED] = newValue
        }
    }
    public var engagementsIds: [String] {
        get {
            var ids = [String]()
            guard let engagements = self.engagements else {
                return ids
            }
            for engagement in engagements {
                ids.append(engagement.objectId!)
            }
            return ids
        }
    }
    public var engagements: [PFObject]? {
        get {
            guard let engagements = self.object.value(forKey: PF_USER_ENGAGEMENTS) as? [PFObject] else {
                return [PFObject]()
            }
            return engagements
        }
        set {
            self.object[PF_USER_ENGAGEMENTS] = newValue
        }
    }
    
    // MARK: Initialization
    
    public init(fromObject object: PFUser) {
        self.object = object
        self.image = UIImage(named: "profile_blank")
            
        Log.write(.status, "Downloading images for user with id \(self.id)")
        let logoFile = self.object.value(forKey: PF_USER_PICTURE) as? PFFile
        logoFile?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.image = UIImage(data: imageData)
        }
        
        let coverFile = self.object.value(forKey: PF_USER_COVER) as? PFFile
        coverFile?.getDataInBackground { (data, error) in
            guard let imageData = data else {
                Log.write(.error, error.debugDescription)
                return
            }
            self.coverImage = UIImage(data: imageData)
        }
        if Engagement.current() != nil {
            self.loadExtension(completion: nil)
        }
    }
    
    // MARK: Public Functions
    
    public static func current() -> User! {
        guard let user = self._current else {
            Log.write(.error, "The current user was nil")
            return nil
        }
        return user
    }
    
    public func save(completion: ((_ success: Bool) -> Void)?) {
        self.object.saveInBackground { (success, error) in
            if success && self.userExtension != nil {
                self.userExtension?.save(completion: { (success) in
                    Cache.update(self)
                    completion?(success)
                })
            }
            if error != nil {
                Log.write(.error, "Could not save user")
                Log.write(.error, error.debugDescription)
                let toast = Toast(text: error?.localizedDescription, button: nil, color: Color.darkGray, height: 44)
                toast.dismissOnTap = true
                toast.show(duration: 1.0)
                completion?(success)
            }
        }
    }
    
    public func undoModifications() {
        User._current = Cache.retrieveUser(User.current().id)
    }
    
    public func loadExtension(completion: (() -> Void)?) {
        let userExtenionQuery = PFQuery(className: Engagement.current().queryName! + PF_USER_CLASS_NAME)
        userExtenionQuery.includeKey(PF_USER_TEAM)
        userExtenionQuery.whereKey(PF_USER_EXTENSION, equalTo: User.current().object)
        userExtenionQuery.findObjectsInBackground { (objects, error) in
            guard let userExtensions = objects else {
                Log.write(.error, error.debugDescription)
                completion?()
                return
            }
            if userExtensions.count == 0 {
                // Extension does not exist yet
                let newExtension = PFObject(className: Engagement.current().queryName! + PF_USER_CLASS_NAME)
                newExtension[PF_USER_EXTENSION] = User.current().object
                newExtension.saveInBackground()
                Log.write(.status, "Created extension for user \(self.id)")
                self.userExtension = UserExtension(fromObject: newExtension)
                
            } else if userExtensions.count == 1 {
                self.userExtension = UserExtension(fromObject: userExtensions[0])
                Log.write(.status, "Loaded extension for user \(self.id)")
                
            } else {
                self.userExtension = UserExtension(fromObject: userExtensions[0])
                Log.write(.status, "Loaded extension for user \(self.id)")
                
                // Extra extensions exist
                for index in 1...userExtensions.count {
                    Log.write(.warning, "An extra extension for user \(self.id) was deleted")
                    userExtensions[index].deleteInBackground()
                }
            }
            completion?()
        }
    }
    
    public class func didLogin(with user: PFUser) {
        User._current = User(fromObject: user)
        PushNotication.parsePushUserAssign()
        if let id = UserDefaults.standard.value(forKey: "currentEngagement") as? String {
            let engagmentQuery = PFQuery(className: PF_ENGAGEMENTS_CLASS_NAME)
            engagmentQuery.whereKey(PF_ENGAGEMENTS_OBJECT_ID, equalTo: id)
            engagmentQuery.getFirstObjectInBackground(block: { (object, error) in
                guard let engagement = object else {
                    let navContainer = NTNavigationContainer(centerView: NTPageViewController(viewControllers: [UINavigationController(rootViewController: EngageInfoViewController()),UINavigationController(rootViewController: EngagementHomeViewController()), UINavigationController(rootViewController: DiscoverEngagementsViewController())], initialIndex: 1))
                    UIApplication.shared.keyWindow?.rootViewController = navContainer
                    return
                }
                Engagement.didSelect(with: engagement)
            })
        } else {
            let navContainer = NTNavigationContainer(centerView: NTPageViewController(viewControllers: [UINavigationController(rootViewController: EngageInfoViewController()),UINavigationController(rootViewController: EngagementHomeViewController()), UINavigationController(rootViewController: DiscoverEngagementsViewController())], initialIndex: 1))
            UIApplication.shared.keyWindow?.rootViewController = navContainer
        }
    }
    
    public func logout(_ target: UIViewController) {
        if self.id == User.current().id {
            
            let actionSheetController: UIAlertController = UIAlertController(title: "Are you sure?", message: "", preferredStyle: .alert)
            actionSheetController.view.tintColor = Color.defaultNavbarTint
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheetController.addAction(cancelAction)
            
            let logoutAction: UIAlertAction = UIAlertAction(title: "Logout", style: .destructive) { action -> Void in
                PFUser.logOut()
                PushNotication.parsePushUserResign()
                UserDefaults.standard.set("", forKey: "currentEngagement")
                let navContainer = NTNavigationContainer(centerView: LoginViewController())
                UIApplication.shared.keyWindow?.rootViewController = navContainer
            }
            actionSheetController.addAction(logoutAction)
            
            actionSheetController.popoverPresentationController?.sourceView = target.view
            target.present(actionSheetController, animated: true, completion: nil)
        } else {
            Log.write(.warning, "User is not logged in")
        }
    }
    
    // MARK: User Extension
    
    public class UserExtension {
        
        public var object: PFObject
        public var id: String {
            get {
                guard let id = self.object.objectId else {
                    Log.write(.error, "User ID was nil")
                    fatalError()
                }
                return id
            }
        }
        public var bio: String? {
            get {
                return self.object.value(forKey: PF_USER_BIO) as? String
            }
            set {
                self.object[PF_USER_BIO] = newValue
            }
        }
        public var team: Team?
        
        // MARK: Initialization
        
        public init(fromObject object: PFObject) {
            self.object = object
            
            guard let team = object.object(forKey: PF_USER_TEAM) as? PFObject else {
                Log.write(.status, "User is not associated with a team")
                return
            }
            self.team = Cache.retrieveTeam(team)
        }
        
        // MARK: Public Functions
        
        public func field(forIndex index: Int) -> String? {
            guard let profileFields = Engagement.current().profileFields else {
                Log.write(.warning, "Engagements profile fields was nil")
                return nil
            }
            if index >= profileFields.count {
                return nil
            }
            let indexString = profileFields[index].replacingOccurrences(of: " ", with: "_")
            return self.object.value(forKey: indexString) as? String
        }
        
        public func setValue(_ newValue: String, forField field: String) {
            self.object[field] = newValue
        }
        
        public func save(completion: ((_ success: Bool) -> Void)?) {
            self.object.saveInBackground { (success, error) in
                completion?(success)
                if error != nil {
                    Log.write(.error, "Could not save user extension")
                    Log.write(.error, error.debugDescription)
                    Toast.genericErrorMessage()
                }
            }
        }
    }
}
