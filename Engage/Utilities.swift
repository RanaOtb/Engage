//
//  Utilities.swift
//  Engage
//
//  Created by Nathan Tannar on 9/30/16.
//  Copyright © 2016 Nathan Tannar. All rights reserved.
//

import Foundation
import UIKit
import Former
import BRYXBanner

class Utilities {
    
    class func userLoggedIn(_ target: AnyObject) {
        PushNotication.parsePushUserAssign()
        let navVC = UINavigationController(rootViewController: EngagementsViewController())
        target.present(navVC, animated: false, completion: nil)
    }
    
    class func showEngagement(_ target: AnyObject) {
        PushNotication.parsePushUserAssign()
        appToolbarController = AppToolbarController(rootViewController: FeedViewController())
        appMenuController = AppMenuController(rootViewController: appToolbarController)
        let rootViewController = AppNavigationDrawerController(rootViewController: appMenuController, leftViewController: LeftMenuController(), rightViewController: RightAnnouncementsViewController())
        target.present(rootViewController, animated: true, completion: nil)
    }
    
    class func showBanner(title: String, subtitle: String, duration: Double) {
        let banner = Banner(title: title, subtitle: subtitle, image: nil, backgroundColor: MAIN_COLOR!)
        banner.dismissesOnTap = true
        banner.show(duration: duration)
    }
    
    class func postNotification(_ notification: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    class func timeElapsed(seconds: TimeInterval) -> String {
        var elapsed: String
        if seconds < 60 {
            elapsed = "Just now"
        }
        else if seconds < 60 * 60 {
            let minutes = Int(seconds / 60)
            let suffix = (minutes > 1) ? "mins" : "min"
            elapsed = "\(minutes) \(suffix) ago"
        }
        else if seconds < 24 * 60 * 60 {
            let hours = Int(seconds / (60 * 60))
            let suffix = (hours > 1) ? "hours" : "hour"
            elapsed = "\(hours) \(suffix) ago"
        }
        else {
            let days = Int(seconds / (24 * 60 * 60))
            let suffix = (days > 1) ? "days" : "day"
            elapsed = "\(days) \(suffix) ago"
        }
        return elapsed
    }
    
    class func dateToString(time: NSDate) -> String {
        var interval = NSDate().minutes(after: time as Date!)
        if interval < 60 {
            if interval <= 1 {
                return "Just Now"
            }
            else {
                return "\(interval) minutes ago"
            }
        }
        else {
            interval = NSDate().hours(after: time as Date!)
            if interval < 24 {
                if interval <= 1 {
                    return "1 hour ago"
                }
                else {
                    return "\(interval) hours ago"
                }
            }
            else {
                interval = NSDate().days(after: time as Date!)
                if interval <= 1 {
                    return "1 day ago"
                }
                else {
                    return "\(interval) days ago"
                }
            }
        }
    }
}

