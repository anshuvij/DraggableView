//
//  ViewController.swift
//  Card Items Movement
//
//  Created by Anshu Vij on 11/05/21.
//  Copyright © 2021 Anshu Vij. All rights reserved.
//

import UIKit
import ContactsUI
import EventKit


class RangeWithTag {
    var start: CGFloat = 0
    var end: CGFloat = 0
    var center: CGPoint = .zero
    
    init(start: CGFloat, end: CGFloat) {
        self.start = start
        self.end = end
    }
    
}

class ViewController: UIViewController {
    
    //MARK: - Properties
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!
    @IBOutlet weak var view3: UIView!
    @IBOutlet weak var view4: UIView!
    @IBOutlet weak var tableViewContact: UITableView!
    @IBOutlet weak var tableViewToDo: UITableView!
    @IBOutlet weak var tableViewShopping: UITableView!
    @IBOutlet weak var tableViewCalendar: UITableView!
    
    private var todoListItems = [String]()
    private var shoppingListItem = [String]()
    private let eventStore = EKEventStore()
    private var initialPosition: CGPoint = .zero
    private var views: [UIView] = []
    private var initialCenters: [CGPoint] = []
    private var concreteInitialCenters: [CGPoint] = []
    private var ranges: [RangeWithTag] = []
    private var contacts = [CNContact]()
    private var eventTitle = [String]()
    private let contactStore = CNContactStore()
    private var bounds: CGRect {
        return UIScreen.main.bounds
    }
    
    private var screenWidth: CGFloat {
        return bounds.width
    }
    
    private var screenHeight: CGFloat {
        return bounds.height
    }
    
    private var spaceBetweenCard: CGFloat {
        return 0
    }
    
    private var cardWidth: CGFloat {
        return (screenWidth - spaceBetweenCard) / 4
    }
    
    private var cardBounds: CGRect {
        return CGRect(x: 0, y: 0, width: cardWidth, height: screenHeight)
    }
    
    private var panGesture: UIPanGestureRecognizer {
        return UIPanGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
    }
    
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        fetchEventsFromCalendar()
        fetchContact()
        todoListItems = UserDefaults.standard.stringArray(forKey: Constants.todoListItem) ?? []
        shoppingListItem = UserDefaults.standard.stringArray(forKey: Constants.shoppingListItem) ?? []
    }
    
    //MARK: - Helpers
    private func setupUI() {
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        
        var start: CGFloat = 0, end: CGFloat = cardWidth
        views = [view1,view2,view3,view4]
        
        for index in 0..<views.count {
            let customView = views[index]
            customView.tag = index
            customView.isUserInteractionEnabled = true
            customView.center.x = (cardWidth + spaceBetweenCard/2) * CGFloat(index) + cardWidth / 2
            concreteInitialCenters.append(customView.center)
            customView.addGestureRecognizer(panGesture)
            setViewProperties(for: index, customView: customView)
            views[index] = customView
            let range: RangeWithTag
            if index == 0 {
                range = RangeWithTag(start: -.infinity, end: end)
            }
            else if index < 3 {
                range = RangeWithTag(start: start, end: end)
            }
            else {
                range = RangeWithTag(start: start, end: .infinity)
            }
            
            range.center = customView.center
            ranges.append(range)
            start += cardWidth
            end += cardWidth
            tableViewShopping.delegate = self
            tableViewShopping.dataSource = self
            tableViewContact.delegate = self
            tableViewContact.dataSource = self
            tableViewToDo.delegate = self
            tableViewToDo.dataSource = self
            tableViewCalendar.delegate = self
            tableViewCalendar.dataSource = self
            tableViewContact.register(UINib(nibName: Constants.contactCell, bundle: nil), forCellReuseIdentifier: Constants.contactCell)
            tableViewCalendar.register(UINib(nibName: Constants.contactCell, bundle: nil), forCellReuseIdentifier: Constants.contactCell)
            tableViewToDo.register(UINib(nibName: Constants.contactCell, bundle: nil), forCellReuseIdentifier: Constants.contactCell)
            tableViewShopping.register(UINib(nibName: Constants.contactCell, bundle: nil), forCellReuseIdentifier: Constants.contactCell)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    private func setViewProperties(for index: Int, customView: UIView) {
        
        switch index {
        case 0:
            customView.backgroundColor = .systemRed
        case 1:
            customView.backgroundColor = .systemBlue
        case 2:
            customView.backgroundColor = .systemYellow
        default:
            customView.backgroundColor = .orange
        }
        initialCenters.append(customView.center)
    }
    
    private func fetchEventsFromCalendar() -> Void {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
        case .notDetermined:
            requestAccessToCalendar()
        case .authorized:
            self.fetchEventsFromCalendar(calendarTitle: "Calendar")
            break
        case .restricted, .denied: break
            
        }
    }
    
    private func fetchContact() ->Void {
        
        let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch (status) {
        case .notDetermined:
            requestAccessToContact()
        case .authorized:
            self.contacts = ContactStore.getContactDetails()
            DispatchQueue.main.async {
                self.tableViewContact.reloadData()
            }
            break
        case .restricted, .denied: break
            
        }
    }
    
    private func requestAccessToCalendar() {
        
        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
            
            self.fetchEventsFromCalendar(calendarTitle: "Calendar")
            
        }
        
    }
    
    private func requestAccessToContact() {
        
        contactStore.requestAccess(for: CNEntityType.contacts) { (access, error) in
            
            self.contacts = ContactStore.getContactDetails()
            
            DispatchQueue.main.async {
                self.tableViewContact.reloadData()
            }
        }
        
    }
    
    private func fetchEventsFromCalendar(calendarTitle: String) -> Void {
        
        let calendars = eventStore.calendars(for: .event)
        for calendar in calendars {
            let selectedCalendar = calendar
            let startDate = NSDate(timeIntervalSinceNow: -24*3600)
            let endDate = NSDate(timeIntervalSinceNow: 24*3600)
            let predicate = eventStore.predicateForEvents(withStart: startDate as Date, end: endDate as Date, calendars: [selectedCalendar])
            let events = eventStore.events(matching: predicate) as [EKEvent]
            
            for event in events {
                eventTitle.append(event.title)
                DispatchQueue.main.async {
                    self.tableViewCalendar.reloadData()
                }
            }
        }
        
    }
    
    private func swapLogic(current viewTag: Int, xPos: CGFloat, currentView: UIView) {
        
        for index in 0..<ranges.count {
            
            if xPos >= ranges[index].start && xPos < ranges[index].end {
                
                currentView.center.x = ranges[index].center.x
                
                for index in 0..<views.count {
                    if areViewsDifferentWithSameCenters(viewItem1: views[index], viewItem2: currentView) {
                        
                        //  UIView.animate(withDuration: 1) {
                        UIView.animate(withDuration: 1.0, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.9, options: [.curveEaseOut]) {
                            self.swapViewTagsAndUpdateCenters(view1: self.views[index], view2: currentView)
                        }
                        return
                    }
                }
            }
        }
        currentView.center.x = initialPosition.x
    }
    
    private func areViewsDifferentWithSameCenters(viewItem1: UIView, viewItem2: UIView) -> Bool {
        return viewItem1 != viewItem2 && viewItem1.center.x == viewItem2.center.x
    }
    
    private func swapViewTagsAndUpdateCenters(view1: UIView, view2: UIView) {
        let tag = view1.tag
        view1.tag = view2.tag
        view1.center.x = concreteInitialCenters[view2.tag].x
        view2.tag = tag
        let tempView = views[view1.tag]
        views[view1.tag] = views[view2.tag]
        views[view2.tag] = tempView
        
        for index in 0..<views.count {
            views[index].layer.zPosition = 0
        }
        views[view1.tag].layer.zPosition = 1
        views[view2.tag].layer.zPosition = 2
    }
    
    private func showAlert(fromToDoList : Bool) {
        
        var message = ""
        
        if fromToDoList {
            message = "Enter new to do list item"
        }else {
            message = "Enter new to shopping list item"
        }
        let alert = UIAlertController(title: "New item", message: message, preferredStyle: .alert)
        
        alert.addTextField { field in
            field.placeholder = "Enter item..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] (_) in
            if let field = alert.textFields?.first {
                if let text = field.text, !text.isEmpty {
                    DispatchQueue.main.async {
                        if fromToDoList {
                            var currentItem = UserDefaults.standard.stringArray(forKey: Constants.todoListItem) ?? []
                            currentItem.append(text)
                            UserDefaults.standard.setValue(currentItem, forKey: Constants.todoListItem)
                            self?.todoListItems.append(text)
                            self?.tableViewToDo.reloadData()
                        }
                        
                        else {
                            var currentItem = UserDefaults.standard.stringArray(forKey: Constants.shoppingListItem) ?? []
                            currentItem.append(text)
                            UserDefaults.standard.setValue(currentItem, forKey: Constants.shoppingListItem)
                            self?.shoppingListItem.append(text)
                            self?.tableViewShopping.reloadData()
                        }
                    }
                    
                }
            }
        }))
        
        present(alert,animated: true)
    }
    
    //MARK: - Actions
    @objc private func handleTap(_ gesture: UIPanGestureRecognizer) {
        guard let tag = gesture.view?.tag else {
            return
        }
        
        let currentView = views[tag]
        switch gesture.state {
        case .began:
            for index in 0..<views.count {
                views[index].layer.zPosition = 0
            }
            currentView.layer.zPosition = 1
            let translation = gesture.translation(in: currentView)
            let initialCenter = initialCenters[tag]
            initialPosition = CGPoint(x: initialCenter.x + translation.x, y: view.center.y)
        case .changed:
            let translation = gesture.translation(in: currentView)
            let initialCenter = initialCenters[tag]
            currentView.center = CGPoint(x: initialCenter.x + translation.x, y: view.center.y)
        default:
            swapLogic(current: tag, xPos: currentView.center.x, currentView: currentView)
        }
    }
    
    @IBAction func addListClicked(_ sender: UIButton) {
        showAlert(fromToDoList: true)
        
    }
    
    @IBAction func addShoppingListClicked(_ sender: Any) {
        showAlert(fromToDoList: false)
    }
    
    
}

//MARK: - UITableViewDelegate
extension ViewController : UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
}

//MARK: - UITableViewDataSource
extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == tableViewContact {
            return contacts.count
        }
        if tableView == tableViewCalendar {
            return eventTitle.count
        }
        if tableView == tableViewToDo {
            return todoListItems.count
        }
        if tableView == tableViewShopping {
            return shoppingListItem.count
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if tableView == tableViewContact {
            let phoneNumber = contacts[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.contactCell, for: indexPath) as! ContactTableViewCell
            cell.numberLabel.isHidden = false
            cell.nameLabel.text = phoneNumber.givenName
            cell.numberLabel.text =  phoneNumber.phoneNumbers.first?.value.stringValue
            return cell
        }
        
        if tableView == tableViewCalendar {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.contactCell, for: indexPath) as! ContactTableViewCell
            cell.nameLabel.text = eventTitle[indexPath.row]
            cell.numberLabel.isHidden = true
            return cell
        }
        if tableView == tableViewToDo {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.contactCell, for: indexPath) as! ContactTableViewCell
            cell.nameLabel.text = todoListItems[indexPath.row]
            cell.numberLabel.isHidden = true
            return cell
        }
        
        if tableView == tableViewShopping {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.contactCell, for: indexPath) as! ContactTableViewCell
            cell.nameLabel.text = shoppingListItem[indexPath.row]
            cell.numberLabel.isHidden = true
            return cell
        }
        
        else {
            return UITableViewCell()
        }
        
    }
    
    
    
}
