//
//  ViewController.swift
//  ReCaptchaPOC
//
//  Created by Thanh.NguyenTien on 16/08/2023.
//

import UIKit
import RecaptchaEnterprise

class ViewController: UIViewController {
    var recaptchaClient: RecaptchaClient?
    private let siteKey = "YOUR_SITE_KEY"
    private let apiKey = "YOUR_API_KEY"
    private let projectId = "YOUR_PROJECT_ID"

    @IBOutlet private var tokenTextview: UITextView!
    @IBOutlet private var assessmentTextview: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            do {
                let client = try await Recaptcha.getClient(withSiteKey: siteKey)
                self.recaptchaClient = client
            } catch let error as RecaptchaError {
                print("RecaptchaClient creation error: \(String(describing: error.errorMessage)).")
            }
        }
    }
    
    @IBAction func makeAction(_ sender: Any) {
        guard let recaptchaClient = recaptchaClient else {
            print("RecaptchaClient creation failed.")
            return
        }
        Task {
            do {
                let token = try await recaptchaClient.execute(withAction: RecaptchaAction.login)
                self.tokenTextview.text = token
            } catch let error as RecaptchaError {
                self.tokenTextview.text = "ERROR: \(error.errorMessage)"
            }
        }
    }
    
    @IBAction func getAssessment(_ sender: Any) {
        guard !self.tokenTextview.text.isEmpty else {
            return
        }
        tryGetAssessment(token: self.tokenTextview.text ?? "", userAction: .login)
    }
    
    @IBAction func resetContent(_ sender: Any) {
        tokenTextview.text = nil
        assessmentTextview.text = nil
    }
    
    private func tryGetAssessment(token: String, userAction: RecaptchaAction) {
        
        guard let url = URL(string: "https://recaptchaenterprise.googleapis.com/v1/projects/\(projectId)/assessments"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        let json: [String: Any] = ["event": ["token": token,
                                             "siteKey": siteKey,
                                             "expectedAction": userAction.action]] as [String : Any]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        Task {
            let (data, _) = try await URLSession.shared.data(for: request)
            self.assessmentTextview.text = String(decoding: data, as: UTF8.self)
//            print("ASSESSMENT: \(String(decoding: data, as: UTF8.self))")
        }

    }
}

