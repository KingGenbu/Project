//
//  ILSocketManager.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 28/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.



import Foundation
import SocketIO

enum SocketEventConsts {
    
    enum Emit: String {
        case onFeedJoin = "onFeedJoin"
        case onFeedUnjoin = "onFeedUnjoin"
    }
    
    enum On: String {
        case liveFeedCount = "liveFeedCount"
        
    }
}
protocol ILSocketManagerDelegate {
    func updateViewerUpdate(liveFeedCount: String)
    func updateMyLiveViewerCount(feedID:String,liveFeedCount: String)
}

enum ILSocketStatus: String {
    case connected
    case disconnected
    case error
    case reconnect
    case reconnectAttempt
}

class ILSocketManager: NSObject {
    
    static let shared = ILSocketManager()
    var socket: SocketIOClient!
    var manager: SocketManager!
    var connectParams: [String : Any]!
    var delegate: ILSocketManagerDelegate!
    var canResumeConnection: Bool = false
    
    override init() {
        super.init()
    }
    
    func establishConnection(withParams: [String : Any]) {
        connectParams = withParams
        manager = SocketManager(socketURL: URL(string: ApiManager.socketURL)!, config: [.log(false), .compress])
        socket = manager.defaultSocket
        socket.connect()
        observeClientEvenets()
        canResumeConnection = true
    }
    
    func resumeConnection() {
        if connectParams != nil {
            socket = manager.defaultSocket
            socket.connect()
            observeClientEvenets()
        }
    }
    
    func pauseConnection() {
        if canResumeConnection {
            if socket != nil {
                socket.disconnect()
            }
        }
    }
    
    func closeConnection() {
        if socket != nil {
            connectParams = nil
            canResumeConnection = false
            socket.disconnect()
        }
    }
    
    func observeClientEvenets() {
        socket.on(clientEvent: .connect) { (data, ack) in
            print("connect")
            self.observeEvents()
            if self.connectParams != nil {
                if let feedId = self.connectParams?[WebserviceRequestParmeterKey.feedId] as? String, feedId.count > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                        self.emitEvent(.onFeedJoin, items: self.connectParams)
                    })
                }
            }
        }
        socket.on(clientEvent: .disconnect) { (data, ack) in
            print("disconnect")
        }
        socket.on(clientEvent: .error) { (data, ack) in
            print("error")
        }
        socket.on(clientEvent: .reconnect) { (data, ack) in
            print("reconnect")
        }
        socket.on(clientEvent: .reconnectAttempt) { (data, ack) in
            print("reconnectAttempt")
        }
    }
    
    func observeEvents() {
        socket.on(SocketEventConsts.On.liveFeedCount.rawValue) { (data, ack) in
            if let message = data.first {
                
                print("Live stream data",data)
                self.delegate.updateViewerUpdate(liveFeedCount: "\((message as! [String:Any])["count"]!)")
                if let feedId = (message as! [String:Any])["feedId"] as? String, let count = (message as! [String:Any])["count"] as? Int {
                    self.delegate.updateMyLiveViewerCount(feedID: "\(feedId)", liveFeedCount: "\(count)")
                }
            }
        }
    }
    
    func emitEvent(_ event: SocketEventConsts.Emit, items: SocketData) {
        if socket != nil {
            socket.emit(event.rawValue, items)
        }
    }
    
    func observeEventsMyLive() {
        socket.on(SocketEventConsts.On.liveFeedCount.rawValue) { (data, ack) in
            if let message = data.first {
               // print("Live stream count",message)
                self.delegate.updateMyLiveViewerCount(feedID: "\((message as! [String:Any])["feedId"]!)", liveFeedCount: "\((message as! [String:Any])["count"]!)")
            }
        }
    }
    
    func joinLiveStream(withParams dicParams: [String: Any]) {
        print("Connection Parametes: \(dicParams)")
        if socket.status == .connected {
            connectParams = dicParams
            self.emitEvent(.onFeedJoin, items: dicParams)
        }
    }
}

