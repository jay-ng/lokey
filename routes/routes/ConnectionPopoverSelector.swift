//
//  ConnectionPopoverSelector.swift
//  LoKey
//
//  Created by Will Steiner on 1/29/17.
//  Copyright © 2017 Will Steiner. All rights reserved.
//


import UIKit

class ConnectionPopoverSelector: UITableViewController {

    
    var selectedConnection: Int?
    var connections : [Connection]!
    var connectionCount : Int!
    var delegate: ConnectionSelectedDelegate?
    var hasConnections = false
    
    var state : State!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = self.getState()
        self.connections = self.state.getActiveConnections()
        self.connectionCount = self.connections.count
        self.hasConnections = (self.connectionCount > 0)
        tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(hasConnections){
            return connectionCount + 1
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "connectionOption", for: indexPath)
        
        let bgColorView = UITableViewCell()
        bgColorView.backgroundColor = Utils.primaryColor.withAlphaComponent(0.5)
        cell.selectedBackgroundView = bgColorView
        
        if(!hasConnections){
            if(indexPath.row == 0){
                cell.textLabel?.text = "No Active Connections"
            } else {
                cell.textLabel?.text = "Reset - None"
            }
            return cell
        }
        
        if(indexPath.row != connectionCount){
            let conn = connections[indexPath.row]
            cell.textLabel?.text = conn.name
        } else {
            cell.textLabel?.text = "Reset - None"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row != connectionCount){
            delegate?.selectConnection(connectionId: self.connections[indexPath.row].id)
        } else {
            delegate?.selectConnection(connectionId: -1)
        }
    }

}
