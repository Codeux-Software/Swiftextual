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

import Security
import os.log

/// The `Keychain` class is responsible for the task of adding,
/// removing, and modifying passwords in the user's keychain.
public class Keychain
{
	/// `Item` is used to identify a specific entry in the keychain.
	struct KeychainItem
	{
		/// A label describing the contents of the item.
		let name: String

		/// A unique identifier for the item.
		let identifier: String

		/// Password associated with the item.
		///
		/// Stores are encoded and decoded using UTF-8.
		///
		/// - Warning: Password is not permitted to be `nil` when adding
		/// an item to the keychain or modifying it. Use an empty string
		/// instead to set no password. Assigning `nil` when performing
		/// these actions will throw a precondition failure.
		var password: String?
	}

	/// Errors that can occur when accessing the keychain.
	enum KeychainError: Error, Equatable
	{
		/// Item does not exist in the keychain.
		case itemNotFound

		/// Item already exists in the keychain.
		case duplicateItem

		/// Item cannot be retrieved.
		case itemNotAvailable

		/// Item cannot be modified.
		case itemNotModified

		/// The keychain returned an item in an unsupported format.
		case malformedData

		/// Catch-all case for all errors not covered above.
		case otherStatus(OSStatus)

		/// Convenience initializer.
		init?(_ status: OSStatus) {
			switch status {
				case errSecSuccess:
					return nil
				case errSecItemNotFound:
					self = .itemNotFound
				case errSecDuplicateItem:
					self = .duplicateItem
				case errSecDataNotAvailable:
					self = .itemNotAvailable
				case errSecDataNotModifiable:
					self = .itemNotModified
				default:
					self = .otherStatus(status)
			}
		}
	 }

	/// Internal constructor for item lookup.
	fileprivate func searchDictionary(forItem item: KeychainItem) -> [CFString : Any]
	{
		[
			kSecClass: kSecClassGenericPassword,
			kSecAttrLabel : item.name,
			kSecAttrDescription : "application password",
			kSecAttrService : item.identifier
		]
	}

	/// Add item to keychain.
	/// - Parameter item: The item to add.
	/// - Returns: `true` on success. `false` otherwise.
	func add(_ item: KeychainItem) throws
	{
		guard let password = item.password else {
			preconditionFailure("When adding a keychain item, a password must be specified.")
		}

		var changes = searchDictionary(forItem: item)

		changes[kSecValueData] = password.data(using: .utf8)

		let status = SecItemAdd(changes as CFDictionary, nil)

		if let error = KeychainError(status) {
			throw error
		}
	}

	/// Modify item in keychain.
	///
	/// Password is the only property of an item that can
	/// be changed after an entry is created in the keychain.
	/// To change any other property: delete the entry,
	/// then add it using the desired properties.
	///
	/// If an entry does not already exist in the keychain,
	/// then it will be added when performing this function.
	///
	/// - Parameter item: The item to modify.
	/// - Returns: `true` on success. `false` otherwise.
	func modify(_ item: KeychainItem) throws
	{
		guard let newPassword = item.password else {
			preconditionFailure("When modifying a keychain item, a password must be specified. That is the only attribute that can be modified.")
		}

		let changes = [
			kSecValueData : newPassword.data(using: .utf8)
		]

		let search = searchDictionary(forItem: item)

		let status = SecItemUpdate(search as CFDictionary, changes as CFDictionary)

		if status == errSecItemNotFound {
			try add(item)

			return
		}

		if let error = KeychainError(status) {
			throw error
		}
	}

	/// Remove item from keychain.
	/// - Parameter item: The item to delete.
	/// - Returns: `true` on success. `false` otherwise.
	func remove(_ item: KeychainItem) throws
	{
		let search = searchDictionary(forItem: item)

		let status = SecItemDelete(search as CFDictionary)

		if let error = KeychainError(status) {
			throw error
		}
	}

	/// Password for item in keychain.
	/// - Parameter item: The item to retrieve password for.
	/// - Returns: The password as a string. `nil` if item does not exist, or an error occurred.
	func password(forItem item: KeychainItem) throws -> String?
	{
		var search = searchDictionary(forItem: item)

		search[kSecMatchLimit] = kSecMatchLimitOne
		search[kSecReturnData] = kCFBooleanTrue

		var result: CFTypeRef?

		let status = SecItemCopyMatching(search as CFDictionary, &result)

		if let error = KeychainError(status) {
			if error == .itemNotFound {
				os_log("Failed to return password because item does not exist.", log: .frameworkLog, type: .debug)
			} else {
				os_log("Failed to return password: '%@'", log: .frameworkLog, type: .error, String(describing: status))
			}

			throw error
		}

		guard let data = result as? Data else {
			os_log("Failed to cast return value to Data type.", log: .frameworkLog, type: .fault)

			throw KeychainError.malformedData
		}

		return String(data: data, encoding: .utf8)
	}
}
