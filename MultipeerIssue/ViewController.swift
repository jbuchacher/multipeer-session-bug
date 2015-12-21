//
//  ViewController.swift
//  MultipeerIssue
//
//  Created by Josh Buchacher on 12/21/15.
//  Copyright © 2015 jbuchacher. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    private let MPC = MultipeerDelegate()
    private let reuseIdentifier = "ConnectedPeerCell"
    
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var browseButton: UIButton?
    @IBOutlet weak var advertiseButton: UIButton?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startBrowsing() {
        advertiseButton?.enabled = false
        browseButton?.enabled = false
        
        MPC.startBrowsing(peerChangedState)
    }
    
    @IBAction func startAdvertsiing() {
        advertiseButton?.enabled = false
        browseButton?.enabled = false
        
        MPC.startAdvertising(peerChangedState)
    }
    
    @IBAction func reset() {
        MPC.reset()
        
        advertiseButton?.enabled = true
        browseButton?.enabled = true
        collectionView?.reloadData()
    }
    
    func peerChangedState(peerID: MCPeerID, state: MCSessionState) {
        dispatch_async(dispatch_get_main_queue(),{
            self.collectionView?.reloadData()
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MPC.connectedPeers.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    }
}

class MultipeerDelegate: NSObject, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    
    static let peerId = MCPeerID(displayName: UIDevice.currentDevice().name)
    static let serviceType = "mpc-svc"
    
    let advertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: serviceType)
    let browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
    let session = MCSession(peer: peerId)
    
    typealias PeerConnectionEvent = (peerID: MCPeerID, state: MCSessionState) -> Void
    
    private(set) var connectedPeers = [MCPeerID]()
    private var connectionHandler: PeerConnectionEvent?
    
    override init() {
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
        session.delegate = self
    }
    
    func startBrowsing(peerConnectedHandler: PeerConnectionEvent) {
        connectionHandler = peerConnectedHandler
        
        browser.startBrowsingForPeers()
        print("started browsing")
    }
    
    func startAdvertising(peerConnectedHandler: PeerConnectionEvent) {
        connectionHandler = peerConnectedHandler
        
        advertiser.startAdvertisingPeer()
        print("started advertising")
    }
    
    func reset() {
        advertiser.stopAdvertisingPeer()
        print("stopped advertising")
        
        browser.stopBrowsingForPeers()
        print("stopped browsing")
        
        connectedPeers.removeAll()
    }
    
// Advertising Delegate
    @objc func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        invitationHandler(true, session)
    }

// Browsing Delegate

    @objc func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer: \(peerID.displayName)")
        
        print("inviting peer: \(peerID.displayName)")
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10.0)
    }
    
    @objc func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost peer: \(peerID.displayName)")
    }

// Session Delegate
    
    @objc func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print("state changed: \(peerID.displayName) is \(state.rawValue)")
        
        switch state {
        case .NotConnected:
            if connectedPeers.contains(peerID) {
                connectedPeers.removeAtIndex(connectedPeers.indexOf(peerID)!)
            }
        case .Connected:
            if connectedPeers.contains(peerID) { return }
            
            connectedPeers.append(peerID)
        default: break
        }
        
        connectionHandler?(peerID: peerID, state: state)
    }
    
    @objc func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        // unused
    }
    
    @objc func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // unused
    }
    
    @objc func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        // unused
    }

    @objc func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        // unused
    }
}
    