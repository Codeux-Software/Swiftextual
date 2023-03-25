/* *********************************************************************
*
*            Copyright (c) 2023 Codeux Software, LLC
*     Please see ACKNOWLEDGEMENT for additional information.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
*  * Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
*  * Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
*  * Neither the name of "Codeux Software, LLC", nor the names of its
*    contributors may be used to endorse or promote products derived
*    from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
* OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
* LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
* SUCH DAMAGE.
*
*********************************************************************** */

import os.log
import Contacts

/// Assortment of services for Contacts.
public class AddressBook
{
	/// Contact card for the current user.
	///
	/// - Parameter keys: Array of descriptors for information to fetch.
	/// - Returns: Contact card or `nil` otherwise.
	fileprivate static func myCardWithKeys(toFetch keys: [CNKeyDescriptor]) -> CNContact?
	{
		let store = CNContactStore()

		do {
			let myCard = try store.unifiedMeContactWithKeys(toFetch: keys)

			return myCard
		} catch {
			/* A contact card can fail to be returned for an assortment of reasons.
			 From something as simple as not having a contact card, to the the user
			 denying the app access to their contact information.
			 Do not consider this a fatal error. */
			os_log("Failed to read contact card for self", log: .frameworkLog, type: .fault)
			os_log("Contact read error: %@", log: .frameworkLog, type: .debug, String(describing: error))
		}

		return nil
	}

	/// Nickname of the current user from their contact card,
	/// their first name if that is not configured, or `nil` otherwise.
	static var myName: String?
	{
		let keys = [CNContactGivenNameKey as CNKeyDescriptor,
					CNContactFamilyNameKey as CNKeyDescriptor]

		guard let myCard = myCardWithKeys(toFetch: keys) else {
			return nil
		}

		let nickname = myCard.nickname

		if nickname.isEmpty == false {
			return nickname
		}

		let	name = myCard.givenName

		if name.isEmpty == false {
			return name
		}

		return nil
	}

	/// First e-mail address configured in the contact card
	/// of the current user or `nil` otherwise.
	static var myEmailAddress: String?
	{
		let keys: [CNKeyDescriptor] = [CNContactEmailAddressesKey as CNKeyDescriptor]

		guard let myCard = myCardWithKeys(toFetch: keys) else {
			return nil
		}

		let address = myCard.emailAddresses

		return address.first?.value as? String
	}
}
