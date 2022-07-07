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
    
    let DERIVATION_PATH_SOL = "44'/501'/0'"
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// `create` connects automatically to the first discovered device so have your device ready before launching this demo
        BleTransport.shared.create {
            print("Device disconnected")
        } success: { connectedPeripheral in
            print("Connected to peripheral with name: \(connectedPeripheral.name)")
            let solana = SolanaWrapper()
            /*solana.getAppConfiguration { response in
                print("Response received: \(response)")
            } failure: { error in
                print(error)
            }*/
            solana.getAddress(path: self.DERIVATION_PATH_SOL) { response in
                print("Response received: \(response)")
            } failure: { error in
                print(error)
            }

        } failure: { error in
            if let error = error {
                print(error.description())
            } else {
                print("No error")
            }
        }
    }

}

