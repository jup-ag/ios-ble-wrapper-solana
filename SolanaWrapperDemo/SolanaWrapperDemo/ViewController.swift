//
//  ViewController.swift
//  SolanaWrapperDemo
//
//  Created by Dante Puglisi on 7/4/22.
//

import UIKit
import SolanaWrapper
import BleTransport
import BleWrapper

class ViewController: UIViewController {
    
    @IBOutlet weak var waitingForResponseLabel: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var getAppConfigurationButton: UIButton!
    @IBOutlet weak var getAddressButton: UIButton!
    @IBOutlet weak var openAppButton: UIButton!
    
    let DERIVATION_PATH_SOL = "44'/501'/0'"
    
    let solana = SolanaWrapper()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        connectionLabel.text = "Connecting..."
        
        create(success: nil, failure: nil)
    }
    
    func create(success: EmptyResponse?, failure: ErrorResponse?) {
        self.getAppConfigurationButton.isEnabled = false
        self.getAddressButton.isEnabled = false
        self.openAppButton.isEnabled = false
        
        BleTransport.shared.create(timeout: .seconds(10)) {
            print("Device disconnected")
        } success: { connectedPeripheral in
            self.connectionLabel.text = "Connected to \(connectedPeripheral.name)"
            print("Connected to peripheral with name: \(connectedPeripheral.name)")
            self.getAppConfigurationButton.isEnabled = true
            self.getAddressButton.isEnabled = true
            self.openAppButton.isEnabled = true
            success?()
        } failure: { error in
            failure?(error)
        }
    }

    @IBAction func getAppConfigurationButtonTapped(_ sender: Any) {
        waitingForResponseLabel.text = "Getting App Configuration..."
        Task() {
            do {
                let appConfig = try await solana.getAppConfiguration()
                self.waitingForResponseLabel.text = "Version: \(appConfig.version)\nBlind Signing Enabled: \(appConfig.blindSigningEnabled)\nPublic Key Display Mode: \(appConfig.pubKeyDisplayMode)"
            } catch {
                if let error = error as? WrapperError {
                    self.waitingForResponseLabel.text = error.description()
                }
            }
        }
    }
    
    @IBAction func getAddressButtonTapped(_ sender: Any) {
        waitingForResponseLabel.text = "Getting Address..."
        Task() {
            do {
                let address = try await solana.getAddress(path: DERIVATION_PATH_SOL)
                self.waitingForResponseLabel.text = "Address received: \(address)"
            } catch {
                if let error = error as? WrapperError {
                    self.waitingForResponseLabel.text = error.description()
                }
            }
        }
    }
    
    @IBAction func openAppButtonTapped(_ sender: Any) {
        Task() {
            print("Will try opening Solana")
            do {
                try await solana.openAppIfNeeded()
                print("Opened Solana!")
            } catch {
                if let error = error as? BleStatusError {
                    if error == .userRejected {
                        let alert = UIAlertController(title: "User Rejected", message: "User rejected opening the app", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

