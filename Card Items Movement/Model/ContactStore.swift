//
//  ContactStore.swift
//  Card Items Movement
//
//  Created by Anshu Vij on 12/05/21.
//  Copyright © 2021 Anshu Vij. All rights reserved.
//

import Foundation
import ContactsUI

class ContactStore {
    
    class func getContactDetails()->[CNContact] {
        
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let keys = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                        CNContactPhoneNumbersKey,
                        CNContactEmailAddressesKey
                ] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            try contactStore.enumerateContacts(with: request){
                    (contact, stop) in
                // Array containing all unified contacts from everywhere
                contacts.append(contact)
//                for phoneNumber in contact.phoneNumbers {
//                    if let number = phoneNumber.value as? CNPhoneNumber, let label = phoneNumber.label {
//                        let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)
//                        print("\(contact.givenName) \(contact.familyName) tel:\(localizedLabel) --                                \(number.stringValue), email: \(contact.emailAddresses)")
//                    }
//                }
            }
            print(contacts)
        } catch {
            print("unable to fetch contacts")
        }
        return contacts
    }
    
    
    
}
