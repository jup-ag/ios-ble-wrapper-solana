//
//  SolanaWrapper.swift
//
//  Created by Dante Puglisi on 7/4/22.
//

import Foundation
import JavaScriptCore
import BleWrapper
import Base58Swift

public class SolanaWrapper: BleWrapper {
    lazy var jsContext: JSContext = {
        let jsContext = JSContext()
        guard let jsContext = jsContext else { fatalError() }
        
        guard let
                commonJSPath = Bundle.module.path(forResource: "bundle", ofType: "js") else {
            print("Unable to read resource files.")
            fatalError()
        }
        
        do {
            let common = try String(contentsOfFile: commonJSPath, encoding: String.Encoding.utf8)
            _ = jsContext.evaluateScript(common)
        } catch (let error) {
            print("Error while processing script file: \(error)")
            fatalError()
        }
        
        return jsContext
    }()
    
    var transportInstance: JSValue?
    var solanaInstance: JSValue?
    
    public override init() {
        super.init()
        injectTransportJS()
        loadInstance()
    }
    
    fileprivate func injectTransportJS() {
        jsContext.setObject(TransportJS.self, forKeyedSubscript: "SwiftTransport" as (NSCopying & NSObjectProtocol))
        
        jsContext.exceptionHandler = { _, error in
            print("Caught exception:", error as Any)
        }
        
        jsContext.setObject(
            {()->@convention(block) (JSValue)->Void in { print($0) }}(),
            forKeyedSubscript: "print" as NSString
        )
    }
    
    fileprivate func loadInstance() {
        guard let module = jsContext.objectForKeyedSubscript("TransportModule") else { return }
        guard let transportModule = module.objectForKeyedSubscript("TransportBLEiOS") else { return }
        transportInstance = transportModule.construct(withArguments: [])
        guard let transportInstance = transportInstance else { return }
        guard let solanaModule = module.objectForKeyedSubscript("Solana") else { return }
        solanaInstance = solanaModule.construct(withArguments: [transportInstance])
    }
    
    public func getAppConfiguration(success: @escaping ((AppConfig)->()), failure: @escaping ((String)->())) {
        guard let solanaInstance = solanaInstance else { failure("Instance not initialized"); return }
        solanaInstance.invokeMethodAsync("getAppConfiguration", withArguments: [], completionHandler: { resolve, reject in
            if let resolve = resolve {
                if let dict = resolve.toDictionary() {
                    guard let blindSigningEnabled = dict["blindSigningEnabled"] as? Bool else { failure("Resolved but couldn't parse"); return }
                    guard let pubKeyDisplayModeInt = dict["pubKeyDisplayMode"] as? Int else { failure("Resolved but couldn't parse"); return }
                    guard let version = dict["version"] as? String else { failure("Resolved but couldn't parse"); return }
                    guard let pubKeyDisplayMode = PubKeyDisplayMode(rawValue: pubKeyDisplayModeInt) else { failure("Resolved but couldn't parse"); return }
                    let appConfig = AppConfig(blindSigningEnabled: blindSigningEnabled, pubKeyDisplayMode: pubKeyDisplayMode, version: version)
                    
                    success(appConfig)
                } else {
                    failure("Resolved but couldn't parse")
                }
            } else if let reject = reject {
                failure("REJECTED. Value: \(reject)")
            }
        })
    }
    
    public func getAddress(path: String, success: @escaping ((String)->()), failure: @escaping ((String)->())) {
        guard let solanaInstance = solanaInstance else { return }
        solanaInstance.invokeMethodAsync("getAddress", withArguments: [path]) { resolve, reject in
            if let resolve = resolve {
                if let dict = resolve.toDictionary() as? [String: Any], let addressDict = dict["address"] as? [String: AnyObject] {
                    let data = self.parseBuffer(dict: addressDict)
                    let base58 = Base58.base58Encode(data)
                    success(base58)
                } else {
                    failure("Resolved but couldn't parse")
                }
            } else if let reject = reject {
                failure("REJECTED. Value: \(reject)")
            }
        }
    }
    
    public func signTransaction(path: String, txBuffer: [UInt8], success: @escaping ((String)->()), failure: @escaping ((String)->())) {
        guard let solanaInstance = solanaInstance else { return }
        guard let transportInstance = transportInstance else { return }
        guard let buffer = transportInstance.invokeMethod("arrayToBuffer", withArguments: [txBuffer]) else { failure("Couldn't create buffer"); return }
        solanaInstance.invokeMethodAsync("signTransaction", withArguments: [path, buffer]) { resolve, reject in
            if let resolve = resolve {
                if let dict = resolve.toDictionary() as? [String: Any], let addressDict = dict["signature"] as? [String: AnyObject] {
                    let data = self.parseBuffer(dict: addressDict)
                    let base58 = Base58.base58Encode(data)
                    success(base58)
                } else {
                    failure("Resolved but couldn't parse")
                }
            } else if let reject = reject {
                failure("REJECTED. Value: \(reject)")
            }
        }
    }
}

enum PubKeyDisplayMode: Int {
    case long = 0
    case short = 1
}

public struct AppConfig {
    let blindSigningEnabled: Bool
    let pubKeyDisplayMode: PubKeyDisplayMode
    let version: String
}
