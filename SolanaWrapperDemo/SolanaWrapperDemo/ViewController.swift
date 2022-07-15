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
    
    let DERIVATION_PATH_SOL = "44'/501'/0'"
    
    let solana = SolanaWrapper()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        connectionLabel.text = "Connecting..."
        
        func connect() {
            self.getAppConfigurationButton.isEnabled = false
            self.getAddressButton.isEnabled = false
            
            BleTransport.shared.create {
                print("Device disconnected")
                connect()
                self.connectionLabel.text = "Reconnecting..."
            } success: { connectedPeripheral in
                self.connectionLabel.text = "Connected to \(connectedPeripheral.name)"
                print("Connected to peripheral with name: \(connectedPeripheral.name)")
                self.getAppConfigurationButton.isEnabled = true
                self.getAddressButton.isEnabled = true
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
        solana.getAppConfiguration { response in
            self.waitingForResponseLabel.text = "Version: \(response.version)\nBlind Signing Enabled: \(response.blindSigningEnabled)\nPublic Key Display Mode: \(response.pubKeyDisplayMode)"
        } failure: { error in
            self.waitingForResponseLabel.text = "ERROR: \(error)"
        }
    }
    
    @IBAction func getAddressButtonTapped(_ sender: Any) {
        waitingForResponseLabel.text = "Getting Address..."
        solana.getAddress(path: DERIVATION_PATH_SOL) { response in
            self.waitingForResponseLabel.text = "Address received: \(response)"
        } failure: { error in
            self.waitingForResponseLabel.text = "ERROR: \(error)"
        }
    }
}

