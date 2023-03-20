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

public extension Dictionary where Key == String
{
	/// Case insensitive subscript
	subscript(caseInsensitive key: Key) -> Value?
	{
		if let keyOut = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
			return self[keyOut]
		}

		return nil
	}
}

public extension Dictionary where Key == String, Value == String
{
	/// Encoder/Decoder used when translating dictionary to String value.
	typealias FormEncoderDecoder = (_ value: Value) -> Value

	/// Combine key and values into string.
	///
	/// This function takes an optional encoder of type `FormEncoderDecoder`
	/// The key and value of the dictionary will be passed to the encoder
	/// to give it an opportunity to format the string however it'd like.
	/// Percent encoding is used when an encoder is not specified.
	///
	/// - Example:
	///
	/// The dictionary:
	/// ```
	/// ["Name" : "Taylor Swift", "Location" : "USA"]
	/// ```
	///
	/// Will produce:
	/// ```
	/// Name=Taylor+Swift&Location=USA
	/// ```
	/// 
	/// - Parameters:
	///   - separator: Separator used for each object. Defaults to and sign (`&`).
	///   - encoder: A closure of type `FormEncodeDecoder` whose purpose is to
	///   encode the value of each object.
	/// - Returns: String representation of dictionary.
	func encodedFormString(withSeparator separator: String = "&", encoder: FormEncoderDecoder? = nil) -> String
	{
		map {
			var key = $0
			var value = $1

			if let encoder {
				key = encoder(key)
				value = encoder(value)
			} else {
				value = key.percentEncoded!
				value = value.percentEncoded!
			}

			return "\(key)=\(value)"
		}.joined(separator: separator)
	}

	/// Chunk form data into key and value.
	///
	/// This function takes an optional decoder of type `FormEncoderDecoder`
	/// The key and value of the dictionary will be passed to the decoder
	/// to give it an opportunity to format the string however it'd like.
	/// Percent encoding is used when an encoder is not specified.
	///
	/// - Example:
	///
	/// The form data:
	/// ```
	/// Name=Taylor+Swift&Location=USA
	/// ```
	///
	/// Will produce:
	/// ```
	/// ["Name" : "Taylor Swift", "Location" : "USA"]
	/// ```
	///
	/// - Parameters:
	///   - separator: Separator used for each object. Defaults to and sign (`&`).
	///   - decoder: A closure of type `FormEncodeDecoder` whose purpose is to
	///   decode the value of each object.
	/// - Returns: Dictionary representation of string.
	init(decodedFromString string: String, withSeparator separator: String = "&", decoder: FormEncoderDecoder? = nil)
	{
		let formData: [Key : Value] =
		string.split(separator: separator, omittingEmptySubsequences: true).reduce(into: [:]) { (chunks, chunk) in
			let hunk = chunk.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)

			var key = String(hunk[0])

			if key.isEmpty {
				os_log("Nonsense key skipped over.", log: .frameworkLog, type: .fault)

				return
			}

			var value = (hunk.count > 1) ? String(hunk[1]) : ""

			if let decoder {
				key = decoder(key)
				value = decoder(value)
			} else {
				key = key.percentDecoded!
				value = value.percentDecoded!
			}

			chunks[key] = value
		}

		self = formData
	}
}

public extension Dictionary where Value == AnyObject
{
	/// Cast value of object at `key` as `Bool`
	///
	/// - Parameter key: Key of object
	/// - Returns: Value of object as `Bool` or `false` otherwise.
	@inlinable func bool(for key: Key) -> Bool
	{
		self[key] as? Bool ?? false
	}

	/// Cast value of object at `key` as `Array` of type.
	///
	/// - Parameter key: Key of object
	/// - Returns: Value of object as `<Array>` of type or `nil` otherwise.
	@inlinable func array<Value>(for key: Key) -> Array<Value>?
	{
		self[key] as? Array<Value> ?? nil
	}

	/// Cast value of object at `key` as `Dictionary` of type.
	///
	/// - Parameter key: Key of object
	/// - Returns: Value of object as `Dictionary` of type or `nil` otherwise.
	@inlinable func dictionary(for key: Key) -> Dictionary<Key, Value>?
	{
		self[key] as? Dictionary<Key, Value> ?? nil
	}

	/// Cast value of object at `key` as `String`
	///
	/// - Parameter key: Key of object
	/// - Returns: Value of object as `String` or `nil` otherwise.
	@inlinable func string(for key: Key) -> String?
	{
		self[key] as? String ?? nil
	}

	/// Cast value of object at `key` to `Int`
	///
	/// - Parameter key: Key of object
	/// - Returns: Value of object as `Int` or `0` otherwise.
	@inlinable func integer(for key: Key) -> Int
	{
		self[key] as? Int ?? 0
	}

	/// Cast value of object at `key` to `Double`
	///
	/// - Parameter key: Key of object
	/// - Returns: Value of object as `Double` or `0.0` otherwise.
	@inlinable func double(for key: Key) -> Double
	{
		self[key] as? Double ?? 0.0
	}
}
