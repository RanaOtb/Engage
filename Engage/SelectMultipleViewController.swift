//
//  SelectSingleViewController.swift
//  Engage
//
//  Created by Tannar, Nathan on 2016-07-10.
//  Copyright © 2016 NathanTannar. All rights reserved.
//

import UIKit
import Parse
import SVProgressHUD

protocol SelectMultipleViewControllerDelegate {
    func didSelectMultipleUsers(selectedUsers: [PFUser]!)
}

class SelectMultipleViewController: UITableViewController {

    var users = [PFUser]()
    var selection = [String]()
    var delegate: SelectMultipleViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneButtonPressed))
        
        self.loadUsers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Backend methods
    
    func loadUsers() {
        let memberQuery = PFUser.query()
        print(Engagement.sharedInstance.members)
        memberQuery!.whereKey(PF_USER_OBJECTID, containedIn: Engagement.sharedInstance.members)
        memberQuery!.whereKey(PF_USER_OBJECTID, notEqualTo: PFUser.current()!.objectId!)
        memberQuery!.addAscendingOrder(PF_USER_FULLNAME)
        memberQuery!.findObjectsInBackground(block: { (users: [PFObject]?, error: Error?) in
            if error == nil {
                if users != nil {
                    self.users.removeAll(keepingCapacity: false)
                    for user in users! {
                        self.users.append(user as! PFUser)
                    }
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    // MARK: - User actions
    
    func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonPressed(_ sender: AnyObject) {
        if self.selection.count == 0 {
            print("No recipient selected")
            SVProgressHUD.showError(withStatus: "No Users Selected")
        } else {
            self.dismiss(animated: true, completion: { () -> Void in
                var selectedUsers = [PFUser]()
                for user in self.users {
                    if self.selection.contains(user.objectId!) {
                        selectedUsers.append(user)
                    }
                }
                selectedUsers.append(PFUser.current()!)
                self.delegate.didSelectMultipleUsers(selectedUsers: selectedUsers)
            })
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        SVProgressHUD.dismiss()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        let user = self.users[indexPath.row]
        cell.textLabel?.text = user[PF_USER_FULLNAME] as? String
        
        let selected = self.selection.contains(user.objectId!)
        cell.accessoryType = selected ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = self.users[indexPath.row]
        let selected = self.selection.contains(user.objectId!)
        if selected {
            if let index = self.selection.index(of: user.objectId!) {
                self.selection.remove(at: index)
            }
        } else {
            self.selection.append(user.objectId!)
        }
        
        self.tableView.reloadData()
    }

    
}
