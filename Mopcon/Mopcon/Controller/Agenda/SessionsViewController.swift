//
//  SessionsViewController.swift
//  Mopcon
//
//  Created by WU CHIH WEI on 2019/9/20.
//  Copyright © 2019 EthanLin. All rights reserved.
//

import UIKit

class SessionsViewController: MPBaseSessionViewController {

    private var sessions: [Session] = []
    
    var observer: NSKeyValueObservation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        observer = FavoriteManager.shared.observe(
            \.sessionIds,
            changeHandler: { [weak self] _, _ in
            
                self?.tableView.reloadData()
        })
    }
    
    func updateData(sessions: [Session]) {
        
        self.sessions = sessions
        
        tableView.reloadData()
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // MARK: Private Method
    
    func tableViewRowHeight(indexPath:IndexPath) -> CGFloat{
        
        let room = sessions[indexPath.section].room[indexPath.row]
        var tags: [Tag] = []
        
        
        if room.isKeynote {
            
            tags.append(TagFactory.keynoteTag())
        }
        
        if room.isOnline {
            
            tags.append(TagFactory.onlineTag())
        }
        
        if !room.recordable {
            
            tags.append(TagFactory.unrecordableTag())
        }
        
        if room.sponsorId != 0 {
            
            tags.append(TagFactory.partnerTag())
        }
        
        for category in room.tags {
            
            tags.append(category)
        }
        
        /**
         計算高度  layoutConstraint Label FontSize = 13
         */
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        
        var totalString = String()
        for tag in tags {
            totalString.append(tag.name)
        }
        
        label.numberOfLines = 0
        label.text = totalString
        
        var constraintRect = label.sizeThatFits(CGSize(width: tableView.bounds.size.width - 40 - CGFloat(16 * room.tags.count) - CGFloat(10 * room.tags.count), height: CGFloat.greatestFiniteMagnitude))
      
        var boundingBox = totalString.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], context: nil)
        
        let tagHeight = ConferenceTableViewCellBasisHeight + (ceil(boundingBox.size.height / 20) * (20 + 13) - 20)
        
        label.font = UIFont.systemFont(ofSize: 18)

        totalString = String()
        for speaker in room.speakers {
            
            totalString.append(speaker.name+" ")
        }
        
        constraintRect = label.sizeThatFits(CGSize(width: self.tableView.bounds.size.width - 113, height: CGFloat.greatestFiniteMagnitude))
      
        boundingBox = totalString.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], context: nil)
        
        let speakerNameHeight = max(boundingBox.size.height,21.5)
        

        return tagHeight + speakerNameHeight
    }

    // MARK : Tableview Datasource & Tableview Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {

        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sessions[section].room.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return sessions[section].event == "" ? 0 : 64
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let breakCell = tableView.dequeueReusableCell(
            withIdentifier: BreakTableViewCell.identifier
        ) as? BreakTableViewCell else {
            
            return nil
        }
        
        let sessionObject = sessions[section]
        
        breakCell.updateUI(
            startDate: DateFormatter.string(for: sessionObject.startedAt, formatter: "HH:mm"),
            endDate: DateFormatter.string(for: sessionObject.endedAt, formatter: "HH:mm"),
            event: sessionObject.event
        )
        
        return breakCell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let conferenceCell = tableView.dequeueReusableCell(
            withIdentifier: ConferenceTableViewCell.identifier,
            for: indexPath
        )
        
        
        return conferenceCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(
            at: indexPath,
            animated: false
        )
        
        let agendaStoryboard = UIStoryboard(
            name: "Agenda",
            bundle: nil
        )
        
        if #available(iOS 13.0, *) {
            
            guard let detailVC = agendaStoryboard.instantiateViewController(
                identifier: ConferenceDetailViewController.identifier
            ) as? ConferenceDetailViewController else {
                
                return
            }
            
            detailVC.conferenceType = .session(sessions[indexPath.section].room[indexPath.row].sessionId)
            
            show(detailVC, sender: nil)
            
        } else {
            
            guard let detailVC = agendaStoryboard.instantiateViewController(
                withIdentifier: ConferenceDetailViewController.identifier
            ) as? ConferenceDetailViewController else {
                    
                    return
            }
            
            detailVC.conferenceType = .session(sessions[indexPath.section].room[indexPath.row].sessionId)
            
            show(detailVC, sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        let sessionIds = FavoriteManager.shared.fetchSessionIds()
        
        let id = sessions[indexPath.section].room[indexPath.row].sessionId
        
        if sessionIds.contains(id) {
            
            sessions[indexPath.section].room[indexPath.row].isLiked = true
            
        } else {
            
            sessions[indexPath.section].room[indexPath.row].isLiked = false
        }
        
        guard let conferenceCell = cell as? ConferenceTableViewCell else {
            
            return
        }
        
        conferenceCell.updateUI(room: sessions[indexPath.section].room[indexPath.row])
       
        conferenceCell.delegate = self
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableViewRowHeight(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableViewRowHeight(indexPath: indexPath)
    }
}

extension SessionsViewController: ConferenceTableViewCellDelegate {
    
    func likeButtonDidTouched(_ cell: ConferenceTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        sessions[indexPath.section].room[indexPath.row].isLiked = !sessions[indexPath.section].room[indexPath.row].isLiked
        

        let room = sessions[indexPath.section].room[indexPath.row]
        
        if room.isLiked {
            
            FavoriteManager.shared.addSession(room: room)
            
        } else {
            
  
            FavoriteManager.shared.removeSession(room: room)
        }
    }
}
