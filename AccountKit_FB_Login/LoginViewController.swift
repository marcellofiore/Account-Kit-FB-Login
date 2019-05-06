//
//  LoginViewController.swift
//  AccountKit_FB_Login
//
//  Created by WP Developer on 06.05.19.
//  Copyright © 2019 WP Developer. All rights reserved.
//

/*
 * IMPORTATNT !!!!!!
 * PLEASE CONFIGURE Info.plist FACEBOOK DATA TO TEST CORRECTLY => overwrite {YOUR-FACEBOOK-APP-ID} with your facebook App ID
 */

import UIKit

import AccountKit
// If I exclude these two frameworks then the problem is solved...
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    private let accountKit = AccountKit(responseType: .accessToken)
    private var pendingLoginViewController: (UIViewController & AKFViewController)? = nil
    private var showAccountOnAppear = false

    override func viewDidLoad() {
        super.viewDidLoad()

        showAccountOnAppear = accountKit.currentAccessToken != nil
        pendingLoginViewController = accountKit.viewControllerForLoginResume()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if showAccountOnAppear {
            showAccountOnAppear = false
            presentWithSegueIdentifier("segueToDetail", animated: animated)
        } else if let viewController = pendingLoginViewController {
            prepareLoginViewController(viewController)
            present(viewController, animated: animated, completion: nil)
            pendingLoginViewController = nil
        }
    }
    
    // SMS Login - Account Kit
    @IBAction func ActionSMSLogin(_ sender: UIButton) {
        
        let viewController = accountKit.viewControllerForPhoneLogin(with: nil, state: nil)
        self.prepareDataEntryViewController(viewController)
        present(viewController, animated: true, completion: nil)
        
    }
    
    // Facebook Login Button
    @IBAction func ActionFBLogin(_ sender: UIButton) {
        // bottone custom login facebook
        let readPermissions = ["public_profile"] // imposta cosa si vuole del profilo facebook
        let loginManager = LoginManager()
        loginManager.logIn(permissions: readPermissions, from: self) { (result, error) in
            if ((error) != nil){
                print("login failed with error: \(String(describing: error))")
            } else if (result?.isCancelled)! {
                print("login cancelled")
            } else {
                guard result != nil else { return }
                self.requestGraph(tokenFB: result!.token!.tokenString, completion: { (data_user) in
                    if(data_user != nil) {
                        print("RETURN API-GRAPH FaceBook DATA-USER: ", data_user!)
                    }
                })
            }
        }
        
    }
    
    // Helpers - Login / Account Kit
    
    func prepareLoginViewController(_ loginViewController: AKFViewController) {
        loginViewController.delegate = self
    }
    func presentWithSegueIdentifier(_ segueIdentifier: String, animated: Bool) {
        if animated {
            performSegue(withIdentifier: segueIdentifier, sender: nil)
        } else {
            UIView.performWithoutAnimation {
                self.performSegue(withIdentifier: segueIdentifier, sender: nil)
            }
        }
    }
    func requestGraph(tokenFB : String, completion: @escaping ([String: Any]?) -> Void) {
        let reqFB = GraphRequest.init(graphPath: "me", parameters: ["fields":"first_name, last_name, email"], tokenString: tokenFB , version: "v2.8", httpMethod: .get)
        // execute
        reqFB.start(completionHandler: { (connection, data_user_return, error) in
            if(error == nil) {
                guard let data_user = data_user_return as? [String : Any] else {
                    print("No Data FB Graph")
                    DispatchQueue.main.async(execute: {
                        completion(nil)
                    })
                    return
                }
                print("API FB - GRAPH: \(data_user)")
                DispatchQueue.main.async(execute: {
                    completion(data_user)
                })
                
            } else {
                print("error Graph FB: \(String(describing: error))")
                DispatchQueue.main.async(execute: {
                    completion(nil)
                })
                return
            }
        })
        
    }
    func prepareDataEntryViewController(_ viewController: AKFViewController) {
        viewController.delegate = self
        // set color controller Account Kit
        viewController.uiManager = SkinManager.init(skinType: SkinType.classic, primaryColor: UIColor.red)
    }
    
    // END HELPERS
    
}

extension LoginViewController: AKFViewControllerDelegate {
    
    // The problem with the SDK 5.0.0.... => AccessToken is Ambiguouses
    func viewController(_ viewController: UIViewController & AKFViewController, didCompleteLoginWith accessToken: AccessToken, state: String) {
        self.presentWithSegueIdentifier("segueToDetail", animated: false)
    }

    func viewController(_ viewController: UIViewController & AKFViewController, didFailWithError error: Error) {
        print("\(viewController) did fail with error: \(error)")
    }
    
    func viewControllerDidCancel(_ viewController: UIViewController & AKFViewController) {
        print("AccountKit VC Cancelled")
    }
}
