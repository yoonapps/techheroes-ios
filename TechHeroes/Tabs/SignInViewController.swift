//
//  SignInViewController.swift
//  TechHeroes
//
//  Created by Kyle Yoon on 11/13/16.
//  Copyright © 2016 Kyle Yoon. All rights reserved.
//

import UIKit
import WebKit

protocol SignInViewControllerDelegate: class {
    
    func viewController(viewController: SignInViewController, didSignInFor user: User)
    func didTapCancel(for viewController: SignInViewController)
    
}

class SignInViewController: UIViewController, WKUIDelegate {
    
    weak var delegate: SignInViewControllerDelegate?
    
    override func viewDidLayoutSubviews() {
        addAuthLoadedWebView()
    }
    
    func addAuthLoadedWebView() {
        let baseURL = "https://www.linkedin.com/oauth/v2/authorization"
        let redirectURL = "https://" + redirect + "/oauth"
        let state = "apps.yoon.techheroes-ios"
        let scope = "r_basicprofile&r_emailaddress"
        
        var authorizationURL = "\(baseURL)?"
        authorizationURL += "response_type=code&"
        authorizationURL += "client_id=\(linkedInID)&"
        authorizationURL += "redirect_uri=\(redirectURL)&"
        authorizationURL += "state=\(state)&"
        authorizationURL += "scope=\(scope)"
        
        guard let URL = URL(string: authorizationURL) else { return }
        let request = URLRequest(url: URL)
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.load(request)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func didTapCancel() {
        delegate?.didTapCancel(for: self)
    }

}

extension SignInViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,
            url.host == redirect,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let items = components.queryItems,
            let codeItem = items.filter({ $0.name == "code" }).first,
            let code = codeItem.value {
            APIUtility.requestAccessToken(for: code,
                                          success: { token, expiration in
                                            // Get user info
                                            APIUtility.requestUserInfo(for: token,
                                                                       success: {
                                                                        [weak self]
                                                                        user in
                                                                        // TODO: local persistence
                                                                        if let strongSelf = self {
                                                                            strongSelf.delegate?.viewController(viewController: strongSelf, didSignInFor: user)
                                                                        }
                                                                        
                                            },
                                                                       failure: { error in
                                                                        
                                            })
            },
                                          failure: { error in
            })
//            delegate?.viewController(viewController: self, didReceiveAuthCode: code)
        }

        decisionHandler(.allow)
    }
    
}
