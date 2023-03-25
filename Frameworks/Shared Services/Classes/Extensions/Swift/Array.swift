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

import Foundation

public extension Array
{
	/// Chunk array into equally sized portions.
	/// 
	/// - Parameter size: Size of chunks. Must be greater than zero.
	/// - Returns: Array of array chunks
	@inlinable func chunked(into size: Int) -> [[Element]]
	{
		precondition(size > 0)

		return stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}

	/// Chunk array into equally sized portions and perform closure on each chunk.
	///
	/// - Parameters:
	///   - size: Size of chunks. Must be greater than zero.
	///   - closure: Closure to perform on each chunk.
	@inlinable func walkChunks(of size: Int, with closure: ([Element]) -> Void)
	{
		chunked(into: size).forEach(closure)
	}

	/// Moved an object from one index to another.
	///
	/// - Warning: This function is not out-of-bounds safe.
	///
	/// - Parameters:
	///   - fromIndex: Index to move from
	///   - toIndex: Index to move to
	mutating func move(from fromIndex: Int, to toIndex: Int)
	{
		let object = self[fromIndex]

		remove(at: fromIndex)

		if fromIndex < toIndex {
			insert(object, at: (toIndex - 1))
		} else {
			insert(object, at: toIndex)
		}
	}
}

public extension Array where Element == URL
{
	/// For each file URL in an array: resolve symbolic links
	/// or alias files, checks if the destination exists, then
	/// returns an array of string paths.
	///
	/// If a path is a symbolic link or alias file, then the
	/// path in the array returned is the resolved destination.
	var resolvingPaths: [String]
	{
		compactMap {
			let r = try? FileManager.default.resolveItem(atURL: $0)

			if let r, r.type == .none {
				return r.location.path
			}

			return nil
		}
	}
}

public extension Array where Element == String
{
	/// For each path in an array: resolve symbolic links or
	/// alias files, then checks if the path is a directory.
	/// Only paths that are directories are returned.
	///
	/// If a path is a symbolic link or alias file, then the
	/// path in the array returned is the resolved destination.
	var resolvingDirectories: Self
	{
		compactMap {
			let d = try? FileManager.default.resolveItem(atPath: $0)

			if let d, d.type == .directory {
				return d.location
			}

			return nil
		}
	}

	/// Append string to array only if it does not already appear in it.
	///
	/// - Parameter string: String to append
	@inlinable mutating func append(withoutDuplicating string: String)
	{
		if contains(where: { $0 == string}) {
			return
		}

		append(string)
	}

	/// Does array contain string ignoring case?
	///
	/// - Parameter caseInsensitive: String to search for
	/// - Returns: `true` if array contains string ignoring case.
	func contains(caseInsensitive value: String) -> Bool
	{
		contains { $0.caseInsensitiveCompare(value) == .orderedSame }
	}

	/// Constructor for a string only array controller.
	///
	/// - Example:
	/// ```
	/// [
	/// 	["string" : "Puppy"],
	/// 	["string" : "Corn"],
	/// 	["string" : "Taylor Swift"]
	/// ]
	/// ```
	///
	/// - Returns: An array of dictionaries whose key is
	/// `string` and value is object in original array.
	@inlinable var arrayControllerObjects: [[String : String]]
	{
		map { ["string" : $0] }
	}

	/// Options for configuring the function `cleanup(withOptions:trimSet:)`
	struct CleanupOptions: OptionSet {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		/// Remove strings that have zero length.
		public static let removeEmpty 	= CleanupOptions(rawValue: 1 << 0)

		/// Trim whitespaces and new lines on both ends of strings.
		public static let trim			= CleanupOptions(rawValue: 1 << 1)

		/// Do not allow a string to appear more than once.
		public static let unique		= CleanupOptions(rawValue: 1 << 2)

		/// Trim strings, remove those that are empty, and unique them.
		public static let all: CleanupOptions	= [.removeEmpty, trim, unique]
	}

	/// Clean array by removing strings with zero length.
	@inlinable mutating func cleanupEmptyValues()
	{
		cleanup(withOptions: .removeEmpty)
	}

	/// Clean array by removing duplicate strings
	/// and those with zero length.
	@inlinable mutating func cleanupEmptyValuesAndUnique()
	{
		/* I could specify `.all` but it is better to be explicit
		 here so there is no doubt what is being cleaned..  */
		cleanup(withOptions: [.trim, .removeEmpty, .unique])
	}

	/// Clean array by removing duplicate strings.
	@inlinable mutating func cleanupByUniquing()
	{
		cleanup(withOptions: .unique)
	}

	/// Clean array by performing certain actions.
	///
	/// - Parameter withOptions: Action to perform when cleaning array.
	/// - Parameter trimSet: Character set used when trimming contents. Defaults to spaces and new lines.
	mutating func cleanup(withOptions options: CleanupOptions = .all, trimSet: CharacterSet = .whitespacesAndNewlines)
	{
		var uniqueSet: Set<Element>? = options.contains(.unique) ? [] : nil

		let arrayOut: Self =

		compactMap {
			var object = $0

			if options.contains(.trim) {
				object = object.trimmingCharacters(in: trimSet)
			}

			if (options.contains(.removeEmpty) && object.isEmpty) {
				return nil
			}

			if uniqueSet?.insert(object).inserted == false {
				return nil
			}

			return object
		}

		self = arrayOut
	}
}

