//
//  Engagement.swift
//  Engage
//
//  Created by Nathan Tannar on 1/11/17.
//  Copyright © 2017 Nathan Tannar. All rights reserved.
//

import Parse
import NTComponents

public class Engagement: Group {
    
    private static var _current: Engagement?
    
    public var queryName: String? {
        get {
            guard let name = self.name?.replacingOccurrences(of: " ", with: "_") else {
                return String()
            }
            return name
        }
    }
    public var altTeamName: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_TEAM_NAME) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_TEAM_NAME] = newValue
        }
    }
    public var color: UIColor? {
        get {
            guard let colorHex = self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String else {
                return Color.Default.Tint.View
            }
            return UIColor(hexString: colorHex)
        }
    }
    public var colorHex: String? {
        get {
            return self.object.value(forKey: PF_ENGAGEMENTS_COLOR) as? String
        }
        set {
            self.object[PF_ENGAGEMENTS_COLOR] = newValue
        }
    }
    
    // MARK: - Initialization
    
    convenience init() {
        self.init(PFObject(className: PF_ENGAGEMENTS_CLASS_NAME))
        self.members.add(User.current()!.object)
        self.admins.add(User.current()!.object)
        self.positions = []
        self.profileFields = []
    }

    // MARK: - Public Functions
    
    public static func current() -> Engagement? {
        guard let engagement = self._current else {
            Log.write(.error, "The current engagement was nil")
            return nil
        }
        return engagement
    }
    
    public func create(completion: ((_ success: Bool) -> Void)?) {
        upload(image: coverImage, forKey: PF_ENGAGEMENTS_COVER_PHOTO) { 
            self.upload(image: self.image, forKey: PF_ENGAGEMENTS_LOGO, completion: {
                self.members.add(User.current()!.object)
                self.admins.add(User.current()!.object)
                self.memberCount = 1
                self.save { (success) in
                    if success {
                        User.current()?.engagements?.add(self.object)
                        User.current()?.save(completion: { (success) in
                            completion?(success)
                        })
                    }
                }
            })
        }
    }
    
    public class func select(_ engagement: Engagement) {
        
        var navContainer = UIViewController.topController() as? NTDrawerController
        if navContainer == nil {
            navContainer = NTDrawerController()
            navContainer?.makeKeyAndVisible(animated: true)
        }
        
        Engagement._current = engagement
        User.current()?.loadExtension(completion: {
            let feedVC = FeedViewController().withTitle("Feed")
            let messagesVC = MessagesViewController().withTitle("Messages")
            let userVC = UserViewController().withTitle("Profile")
            let groupVC = GroupViewController(forGroup: engagement)
            let eventsVC = CalendarViewController().withTitle("Events")
            let tabVC = NTScrollableTabBarController(viewControllers: [feedVC, messagesVC, userVC, groupVC, eventsVC])
            tabVC.tabBarPosition = .top
            tabVC.tabBarHeight = 30
            tabVC.currentTabBarHeight = 3
            tabVC.title = engagement.name
            let menuNav = NTNavigationController(rootViewController: SideBarMenuViewController())
            
            navContainer?.setViewController(NTNavigationController(rootViewController: tabVC), forSide: .center, completion: {
                navContainer?.setViewController(menuNav, forSide: .left)
                navContainer.statusBar.alpha = 1
            })
            
        })
        
        
    }
}
