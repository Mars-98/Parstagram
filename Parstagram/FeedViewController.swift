//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Mariam Adams on 10/23/20.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    let commentBar = MessageInputBar()
    var showsCommentBar = false
    
    var posts = [PFObject]()
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        // let refreshControl = UIRefreshControl()
        
        tableView.keyboardDismissMode = .interactive
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //create the comment
        let comment = PFObject(className: "comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()
        
        selectedPost.add(comment, forKey: "comments")
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved")
            }else{
                print("Error saving comment")
            }
        }
        tableView.reloadData()
            //clear and dismiss the input bar
            commentBar.inputTextView.text = nil
            showsCommentBar = false
            becomeFirstResponder()
            commentBar.inputTextView.resignFirstResponder()
        
    }
        
        @objc func keyboardWillBeHidden(note: Notification){
            commentBar.inputTextView.text = nil
            showsCommentBar = false
            becomeFirstResponder()
        }
        
        override var inputAccessoryView: UIView? {
            return commentBar
        }
        
        override var canBecomeFirstResponder: Bool {
            return showsCommentBar
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            let query = PFQuery(className:"Posts")
            query.includeKeys(["author", "comments", "comments.author"])
            query.limit = 20
            query.findObjectsInBackground { (posts, error) in
                if posts != nil {
                    self.posts = posts!
                    self.tableView.reloadData()
                }
            }
            
        }
        
        // Makes a network request to get updated data
        // Updates the tableView with the new data
        // Hides the RefreshControl
        //      func refreshControlAction(_ refreshControl: UIRefreshControl) {
        //          // ... Create the URLRequest `myRequest` ...
        //          // Configure session so that completion handler is executed on main UI thread
        //          let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        //          let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
        //              // ... Use the new data to update the data source ...
        //              // Reload the tableView now that there is new data
        //              myTableView.reloadData()
        //              // Tell the refreshControl to stop spinning
        //              refreshControl.endRefreshing()
        //          }
        //          task.resume()
        //      }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let post = posts[section]
            let comments = (post["comments"] as? [PFObject]) ?? []
            return comments.count + 2
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return posts.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let post = posts[indexPath.section]
            let comments = (post["comments"] as? [PFObject]) ?? []
            
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
                
                let user = post["author"] as! PFUser
                cell.authorLabel.text = user.username
                cell.commentLabel.text = post["caption"] as! String
                
                let imageFile = post["image"] as! PFFileObject
                let urlString = imageFile.url!
                let url = URL(string: urlString)!
                cell.photoView.af.setImage(withURL: url)
                
                return cell
            }else if indexPath.row <= comments.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
                let comment = comments[indexPath.row - 1]
                cell.commentLabel.text = comment["text"] as! String
                
                let user = comment["author"] as! PFUser
                cell.nameLabel.text = user.username
                
                
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
                return cell
            }
        }
        
        @IBAction func logout(_ sender: Any) {
            PFUser.logOut()
            let main = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
            let delegate = self.view.window?.windowScene?.delegate as! SceneDelegate
            delegate.window?.rootViewController = loginViewController
            
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let post = posts[indexPath.section]
            let comments = (post["comments"] as? [PFObject]) ?? []
            
            if indexPath.row == comments.count + 1 {
                showsCommentBar = true
                becomeFirstResponder()
                commentBar.inputTextView.becomeFirstResponder()
            }
            selectedPost = post
            
        }
    }

/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */


