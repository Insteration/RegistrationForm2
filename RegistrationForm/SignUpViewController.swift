//
//  SignUpViewController.swift
//  RegistrationForm
//
//  Created by Art Karma on 5/2/19.
//  Copyright © 2019 Art Karma. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordConformField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    
    private let picker = UIImagePickerController()
    private var userStorage: StorageReference!
    private var reference: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.isHidden = true
        picker.delegate = self
        
        let storage = Storage.storage().reference(forURL: "gs://registartionform-a4b06.appspot.com")
        reference = Database.database().reference()
        userStorage = storage.child("users")
    }
    
    @IBAction func selectImageButtonAction(_ sender: UIButton) {
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
        
        guard nameField.text != "", emailField.text != "", passwordField.text != "", passwordConformField.text != "" else {
            return
        }
        if passwordField.text == passwordConformField.text {
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                
                if let user = user {
                    
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = self.nameField.text!
                    changeRequest?.commitChanges(completion: nil)
                    
                    let imageRef = self.userStorage.child("\(user.user.uid).jpg")
                    let data = self.imageView.image?.jpegData(compressionQuality: 0.5)
                    let uploadTask = imageRef.putData(data!, metadata: nil, completion: { (metaData, error) in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        
                        imageRef.downloadURL(completion: { (url, error) in
                            if error != nil {
                                print(error!.localizedDescription)
                            }
                            
                            if let url = url {
                                let userInfo: [String: Any] = [
                                    "uid": user.user.uid,
                                    "full name": self.nameField.text!,
                                    "urlToImage": url.absoluteString
                                ]
                                
                                self.reference.child("users").child(user.user.uid).setValue(userInfo)
                                
                                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "userVC")
                                self.present(vc, animated: true, completion: nil)
                            }
                        })
                    })
                    
                    uploadTask.resume()
                    
                }
            }
        } else {
            print("Password not match")
        }
        
        
    }
    
}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.imageView.image = image
            nextButton.isHidden = false
        }
        self.dismiss(animated: true, completion: nil)
    }
}
