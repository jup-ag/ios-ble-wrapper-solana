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
                commonJSPath = Bundle.main.path(forResource: "bundle", ofType: "js") else {
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
    
    public func getAppConfiguration(completion: @escaping ((String)->())) {
        guard let module = jsContext.objectForKeyedSubscript("TransportModule") else { return }
        guard let transportModule = module.objectForKeyedSubscript("TransportBLEiOS") else { return }
        guard let transportInstance = transportModule.construct(withArguments: []) else { return }
        guard let solanaModule = module.objectForKeyedSubscript("Solana") else { return }
        guard let solanaInstance = solanaModule.construct(withArguments: [transportInstance]) else { return }
        solanaInstance.invokeMethodAsync("getAppConfiguration", withArguments: [], completionHandler: { resolve, reject in
            if let resolve = resolve {
                let resolvedString = "RESOLVED. Value: \(String(describing: resolve.toObject()))"
                print(resolvedString)
                completion(resolvedString)
            } else if let reject = reject {
                let rejectedString = "REJECTED. Value: \(reject)"
                print(rejectedString)
                completion(rejectedString)
            }
        })
    }
}
