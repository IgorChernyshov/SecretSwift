//
//  ViewController.swift
//  SecretSwift
//
//  Created by Igor Chernyshov on 28.08.2021.
//

import UIKit
import LocalAuthentication

final class ViewController: UIViewController {

	// MARK: - Outlets
	@IBOutlet var secret: UITextView!

	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Nothing to see here"
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
	}

	// MARK: - Selectors
	@objc private func adjustForKeyboard(notification: Notification) {
		guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

		let keyboardScreenEndFrame = keyboardValue.cgRectValue
		let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

		if notification.name == UIResponder.keyboardWillHideNotification {
			secret.contentInset = .zero
		} else {
			secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
		}

		secret.scrollIndicatorInsets = secret.contentInset

		let selectedRange = secret.selectedRange
		secret.scrollRangeToVisible(selectedRange)
	}

	@objc private func saveSecretMessage() {
		guard secret.isHidden == false else { return }

		KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
		secret.resignFirstResponder()
		secret.isHidden = true
		title = "Nothing to see here"
	}

	@IBAction func authenticateDidTap(_ sender: Any) {
		let context = LAContext()
		var error: NSError?

		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			let reason = "Identify yourself!"

			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
				[weak self] success, authenticationError in

				DispatchQueue.main.async {
					if success {
						self?.unlockSecretMessage()
					} else {
						let alertController = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: "OK", style: .default))
						self?.present(alertController, animated: true)
					}
				}
			}
		} else {
			let alertController = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "OK", style: .default))
			self.present(alertController, animated: true)
		}
	}

	// MARK: - Working with text
	private func unlockSecretMessage() {
		secret.isHidden = false
		title = "Secret stuff!"

		secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
	}
}
