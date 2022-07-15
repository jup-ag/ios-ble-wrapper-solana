//
//  ViewController.swift
//  SolanaWrapperDemo
//
//  Created by Dante Puglisi on 7/4/22.
//

import UIKit
import SolanaWrapper
import BleTransport

class ViewController: UIViewController {
    
    @IBOutlet weak var waitingForResponseLabel: UILabel!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var getAppConfigurationButton: UIButton!
    @IBOutlet weak var getAddressButton: UIButton!
    @IBOutlet weak var openAppButton: UIButton!
    @IBOutlet weak var closeAppButton: UIButton!
    
    let DERIVATION_PATH_SOL = "44'/501'/0'"
    
    let solana = SolanaWrapper()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        connectionLabel.text = "Connecting..."
        
        func connect() {
            self.getAppConfigurationButton.isEnabled = false
            self.getAddressButton.isEnabled = false
            self.openAppButton.isEnabled = false
            self.closeAppButton.isEnabled = false
            
            BleTransport.shared.create {
                print("Device disconnected")
                connect()
                self.connectionLabel.text = "Reconnecting..."
            } success: { connectedPeripheral in
                self.connectionLabel.text = "Connected to \(connectedPeripheral.name)"
                print("Connected to peripheral with name: \(connectedPeripheral.name)")
                self.getAppConfigurationButton.isEnabled = true
                self.getAddressButton.isEnabled = true
                self.openAppButton.isEnabled = true
                self.closeAppButton.isEnabled = true
            } failure: { error in
                if let error = error {
                    print(error.description())
                } else {
                    print("No error")
                }
            }
        }
        
        connect()
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
            do {
                try await solana.openApp()
                print("Opened app!")
            } catch {
                print("\((error as? BleTransportError)?.description() ?? "Failed with no error")")
            }
        }
    }
    
    @IBAction func closeAppButtonTapped(_ sender: Any) {
        Task() {
            do {
                try await solana.closeApp()
                print("Closed app!")
            } catch {
                print("\((error as? BleTransportError)?.description() ?? "Failed with no error")")
            }
        }
    }
}

