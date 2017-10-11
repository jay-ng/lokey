//
//  UserViewController.swift
//  LoKey
//
//  Created by Will Steiner on 1/7/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//

import UIKit

class UserViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, ConnectionSelectedDelegate {
    
    @IBOutlet var editToggle: UIBarButtonItem!
    
    @IBOutlet var nameLabel: UILabel!
    
    
    
    @IBOutlet var editUserName: UITextField!
    @IBOutlet var editNameField: UIView!
    @IBOutlet var userProfileImage: UIImageView!
    @IBOutlet var carIconImage: UIImageView!
    @IBOutlet var btDetailLabel: UILabel!
    @IBOutlet var imageEditLink: UIView!
    @IBOutlet var btEditView: UIView!
    
    private var activeUser : User!
    private var state : State!
    
    var imageSelectTap : UIGestureRecognizer!
    var carConnectionSelectorTap : UIGestureRecognizer!
    var imagePicker : UIImagePickerController!
    var editMode = false
    var needsSave = false
    var popCtrl : UIViewController?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        self.hideKeyboardWhenTappedAround()
        self.state = self.getState()
        self.activeUser = self.state.user
        
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        imageSelectTap = UITapGestureRecognizer(target: self, action: #selector(self.promptImageSelect))
        imageSelectTap.delegate = self
        imageEditLink.addGestureRecognizer(imageSelectTap)
        
        userProfileImage.layer.cornerRadius = userProfileImage.frame.size.width / 2
        userProfileImage.clipsToBounds = true
        userProfileImage.layer.borderWidth = 3
        userProfileImage.layer.borderColor = Utils.primaryColor.cgColor
        
        imageEditLink.layer.cornerRadius = imageEditLink.frame.size.width / 2
        
        carConnectionSelectorTap = UITapGestureRecognizer(target: self, action: #selector(self.promptConnectionSelect))
        carConnectionSelectorTap.delegate = self
        
        btEditView.addGestureRecognizer(carConnectionSelectorTap)
        
        carIconImage.layer.cornerRadius = carIconImage.frame.size.width / 2
        carIconImage.clipsToBounds = true
        carIconImage.layer.borderWidth = 3
        carIconImage.layer.borderColor = Utils.primaryColor.cgColor
        
        imageEditLink.isHidden = true
        editNameField.isHidden = true
        
        if(nameLabel.text == ""){
            toggleEdit(Any.self)
        }
        
        self.updateUserInfo()
        self.updateUserDeviceInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func selectConnection(connectionId: Int) {
        popCtrl?.dismiss(animated: true, completion: nil)
        var confirmMessage : String!
        
        var userCar : Device!
        
        // Get user's car
        if let carId : String = self.activeUser.car {
            if let car : Device = self.state.getDevice(carId) {
                userCar = car
            }
        } else {
            // No device.. create a car 'device'
            userCar = Device(
                id: "\(self.state.generateId())",
                connection: -1,
                currentPosition: nil,
                currentLocation: nil,
                currentAltitude: 0)
            self.state.addDevice(userCar)
            self.activeUser.car = userCar.id
            self.state.updateUser(self.activeUser)
        }
        
        // If no change, return
        if(connectionId == userCar.connection){
            return;
        }
        if(connectionId != -1){
            if let connection : Connection = self.state.getConnection(connectionId){
                confirmMessage = "Are you sure you want to update your car connection to \(connection.name)? This will overwrite the previous setting."
            } else {
                confirmMessage = "Are you sure you want to update your car connection? This will overwrite the previous setting."
            }
        } else {
            // User is reseting their car connection to none
            confirmMessage = "Are you sure you want to reset your car connection? Your car will no longer be tracked."
        }
        // Present confirmation dialog
        let confirmSelectionAlert = UIAlertController(title: "Confirm Connection", message: confirmMessage, preferredStyle: UIAlertControllerStyle.alert)
        confirmSelectionAlert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action: UIAlertAction!) in
            self.log("User updated car connection setting")
            
            userCar.connection = connectionId
            self.state.updateDevice(userCar.id, userCar)
            self.updateUserDeviceInfo()
            self.getInstance().syncWithPlatform()
        }))
        confirmSelectionAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.log("User cancled car connection modification")
        }))
        present(confirmSelectionAlert, animated: true, completion: nil)
    }
    
    func updateUserDeviceInfo(){
        var carSet = false;
        if let userCarId : String = self.activeUser.car {
            if let userCar : Device = self.state.getDevice(userCarId) {
                if let connectionId : Int = userCar.connection{
                    if let carConnection : Connection = self.state.getConnection(connectionId){
                        btDetailLabel.text = carConnection.name
                        carSet = true
                        carIconImage.layer.opacity = 1.0
                    }
                }
            }
        }
        if(!carSet){
            btDetailLabel.text = "Select Car Connection"
            carIconImage.layer.opacity = 0.25
        }
    }
    
    func updateUserInfo(){
        nameLabel.text = self.activeUser.username
        editUserName.text = self.activeUser.username
        if let img : UIImage = self.state.getUserImage(){
            userProfileImage.image = img
        }
    }
    
    @IBAction func toggleEdit(_ sender: Any) {
        
        if(editMode){
            
            //let parsedUsername = editFirstName.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            //let parsedLast = editLastName.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            self.activeUser.username = (editUserName.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!
            self.state.setUserImage(image: userProfileImage.image!)
            self.state.updateUser(self.activeUser)
            self.updateUserInfo()
            /*
             if(needsSave || self.state.user.first != parsedFirst || self.state.user.last != parsedLast){
             self.state.user.first = parsedFirst!
             self.state.user.last = parsedLast!
             self.state.setUserImage(image: userProfileImage.image!)
             self.updateUserInfo()
             self.saveState()
             needsSave = false
             } else {
             log("No changes to user, do not update.")
             }
             */
            
            // Update UI: Hide edit views
            self.dismissKeyboard()
            self.navigationItem.rightBarButtonItem?.title = "Edit"
            nameLabel.isHidden = false
            editNameField.isHidden = true
            imageEditLink.isHidden = true
            editMode = false
        } else {
            // Update UI: Display edit views
            self.navigationItem.rightBarButtonItem?.title = "Save"
            nameLabel.isHidden = true
            editNameField.isHidden = false
            imageEditLink.isHidden = false
            editMode = true
        }
        
    }
    
    func promptImageSelect(){
        let refreshAlert = UIAlertController(title: "Profile Image", message: "Would you like to take a new image or select from your photo library?", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action: UIAlertAction!) in
            self.toggleCamera()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Library", style: .cancel, handler: { (action: UIAlertAction!) in
            self.toggleImagePicker()
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    func toggleCamera(){
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func toggleImagePicker(){
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            userProfileImage.contentMode = .scaleAspectFill
            userProfileImage.image = pickedImage
            needsSave = true;
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //do som stuff from the popover
        log("User dismissed connection popover, no settings change")
    }
    
    func promptConnectionSelect() {
        
        let connectionCount = self.state.activeConnections.count
        
        if(connectionCount == 0){
            notifyUser("No Connections Detected", "Connect to your car stereo through bluetooth or wifi and try again.")
        } else {
            // Display popover selector of available connections
            let vc = (self.storyboard?.instantiateViewController(withIdentifier: "ConnectionPopover"))! as! ConnectionPopoverSelector
            vc.modalPresentationStyle = .popover
            
            let frameWidth = self.view.frame.width;
            
            let h = min(44.0 + Float(connectionCount) * 44.0, Float(self.view.frame.height/2))
            
            vc.preferredContentSize = CGSize(width: (frameWidth*0.66),height: CGFloat(h))
            vc.delegate = self
            
            
            if let presentationController = vc.popoverPresentationController {
                presentationController.delegate = self
                presentationController.permittedArrowDirections = .down
                presentationController.sourceView = self.view
                presentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: (self.view.bounds.midY + self.view.frame.height/4 - 20), width:0,height:0)
                
                self.present(vc, animated: true, completion: nil)
                self.popCtrl = vc;
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //segue for the popover configuration window
    }
}

