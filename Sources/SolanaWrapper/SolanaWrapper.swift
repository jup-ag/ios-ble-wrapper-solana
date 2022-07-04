//
//  SolanaWrapper.swift
//  SolanaWrapper
//
//  Created by Dante Puglisi on 7/4/22.
//

import Foundation
import JavaScriptCore

public class SolanaWrapper {
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
    
    public init() {
        injectTransportJS()
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
    
    public func getAppConfiguration(success: @escaping ((AppConfig)->()), failure: @escaping ((String)->())) {
        guard let module = jsContext.objectForKeyedSubscript("TransportModule") else { return }
        guard let transportModule = module.objectForKeyedSubscript("TransportBLEiOS") else { return }
        guard let transportInstance = transportModule.construct(withArguments: []) else { return }
        guard let solanaModule = module.objectForKeyedSubscript("Solana") else { return }
        guard let solanaInstance = solanaModule.construct(withArguments: [transportInstance]) else { return }
        solanaInstance.invokeMethodAsync("getAppConfiguration", withArguments: [], completionHandler: { resolve, reject in
            if let resolve = resolve {
                if let dict = resolve.toDictionary() {
                    guard let blindSigningEnabled = dict["blindSigningEnabled"] as? Bool else { print("Unexpected type returned"); return }
                    guard let pubKeyDisplayModeInt = dict["pubKeyDisplayMode"] as? Int else { print("Unexpected type returned"); return }
                    guard let version = dict["version"] as? String else { print("Unexpected type returned"); return }
                    guard let pubKeyDisplayMode = PubKeyDisplayMode(rawValue: pubKeyDisplayModeInt) else { print("Unexpected type returned"); return }
                    let appConfig = AppConfig(blindSigningEnabled: blindSigningEnabled, pubKeyDisplayMode: pubKeyDisplayMode, version: version)
                    
                    success(appConfig)
                }
            } else if let reject = reject {
                failure("REJECTED. Value: \(reject)")
            }
        })
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
