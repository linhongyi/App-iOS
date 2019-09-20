//
//  AgendaViewController.swift
//  Mopcon
//
//  Created by EthanLin on 2018/7/4.
//  Copyright © 2018 EthanLin. All rights reserved.
//

import UIKit

class AgendaViewController: MPBaseViewController {
    
    @IBOutlet weak var dateSelectionView: SelectionView!
    
    @IBOutlet weak var scheduleSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var agendaTableView: UITableView!
    
    var sessionLists: [SessionList] = []
    
    private var selectedSchedule = [Schedule.Payload.Agenda.Item]()
    
    private var selectedUnconf = [Schedule_unconf.Payload.Item]()
    
    private var selectedAgenda:Schedule.Payload.Agenda.Item.AgendaContent?
    
    private var mySchedule = MySchedules.get(forKey: UserDefaultsKeys.dayOneSchedule)
    
    private var schedule_day1 = [Schedule.Payload.Agenda.Item]()
    
    private var schedule_day2 = [Schedule.Payload.Agenda.Item]()
    
    private var unconf_day1 = [Schedule_unconf.Payload.Item]()
    
    private var unconf_day2 = [Schedule_unconf.Payload.Item]()
    
    private var isAgenda: Bool = true
    
    private let spinner = LoadingTool.setActivityindicator()
    
    @IBAction func chooseScheduleAction(_ sender: UISegmentedControl) {
        
        isAgenda = (sender.selectedSegmentIndex == 0)
        
        agendaTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        agendaTableView.delegate = self
        
        agendaTableView.dataSource = self
        
        agendaTableView.separatorStyle = .none
        
        scheduleSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], for: .selected)
        
        setupTableViewCell()
        
        fetchSessions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if CurrentLanguage.getLanguage() == Language.english.rawValue {
            
            self.navigationItem.title = "Agenda"
            
            scheduleSegmentedControl.setTitle("Schedule", forSegmentAt: 0)
            
            scheduleSegmentedControl.setTitle("Favorite", forSegmentAt: 1)
            
            scheduleSegmentedControl.setTitle("Communication", forSegmentAt: 2)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == SegueIDManager.performConferenceDetail {
            
//            if let vc = segue.destination as? ConferenceDetailViewController {
//
//                vc.key = key
//
//                vc.agenda = selectedAgenda
//            }
        }
    }
    
    private func setupTableViewCell() {
        
        let conferenceTableViewCell = UINib(nibName: ConferenceTableViewCell.identifier, bundle: nil)
        
        agendaTableView.register(
            conferenceTableViewCell,
            forCellReuseIdentifier: ConferenceTableViewCell.identifier
        )
    }
    
    func fetchSessions() {
        
        SessionProvider.fetchAllSession(completion: { [weak self] result in
            
            switch result {
                
            case .success(let sessionLists):
                
                self?.sessionLists = sessionLists
                
                self?.throwToMainThreadAsync {
                    
                    self?.dateSelectionView.dataSource = self
                    
                    self?.agendaTableView.reloadData()
                }
                
            case .failure(let error):
                
                print(error)
            }
        })
    }
}

// MARK : Tableview Datasource & Tableview Delegate
extension AgendaViewController: UITableViewDelegate, UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
    
        guard let seletedIndex = dateSelectionView.seletedIndex else { return 0 }
        
        return sessionLists[seletedIndex].period.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let seletedIndex = dateSelectionView.seletedIndex else { return 0 }
        
        return sessionLists[seletedIndex].period[section].room.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard let seletedIndex = dateSelectionView.seletedIndex else { return 0 }
        
        return sessionLists[seletedIndex].period[section].event == "" ? 0 : 72
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let breakCell = tableView.dequeueReusableCell(
            withIdentifier: BreakTableViewCell.identifier
        ) as? BreakTableViewCell else {
            
            return nil
        }
        
        let sessionObject = sessionLists[dateSelectionView.seletedIndex!].period[section]
        
        breakCell.updateUI(
            startDate: DateFormatter.string(for: sessionObject.startedAt, formatter: "HH:mm"),
            endDate: DateFormatter.string(for: sessionObject.endedAt, formatter: "HH:mm"),
            event: sessionObject.event
        )
        
        return breakCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let conferenceCell = tableView.dequeueReusableCell(
            withIdentifier: ConferenceTableViewCell.identifier,
            for: indexPath
        ) as? ConferenceTableViewCell else {
            
                return UITableViewCell()
        }
        
        let room = sessionLists[dateSelectionView.seletedIndex!]
            .period[indexPath.section]
            .room[indexPath.row]
        
        conferenceCell.updateUI(room: room)
        
        return conferenceCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard scheduleSegmentedControl.selectedSegmentIndex != 2 else { return }
        
        selectedAgenda = isAgenda ? selectedSchedule[indexPath.section].agendas[indexPath.row] : mySchedule[indexPath.row]
        
        performSegue(withIdentifier: SegueIDManager.performConferenceDetail, sender: nil)
    }
}

extension AgendaViewController: ConferenceTableViewCellDelegate {
    
    func whichCellButtonDidTapped(sender: UIButton, index: IndexPath) {
        
        let agenda = selectedSchedule[index.section].agendas[index.row]
   
        if sender.image(for: .normal) == #imageLiteral(resourceName: "like_24") {
            
            MySchedules.add(agenda: agenda, forKey: agenda.date!)
            
        } else if sender.image(for: .normal) == #imageLiteral(resourceName: "dislike_24"){
            
            MySchedules.remove(agenda: agenda, forKey: agenda.date!)
        }
        
        agendaTableView.reloadData()
    }
    
}

extension AgendaViewController: SelectionViewDataSource {
    
    func numberOfButton(_ selectionView: SelectionView) -> Int {
        
        return sessionLists.count
    }
    
    func titleOfButton(_ selectionView: SelectionView, at index: Int) -> String {
        
        return sessionLists[index].dateString
    }
    
    func didSelectedButton(_ selectionView: SelectionView, at index: Int) {
        
        agendaTableView.reloadData()
    }
}
