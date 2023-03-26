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
import os.log

public extension URL
{
	/// Errors that may be be thrown when accessing a URL
	/// from various components of this library.
	enum AccessError: Error
	{
		/// URL is not a file URL.
		case notFileURL

		/// Error returned from an Apple API that works on a URL.
		case otherError(Error)
	}

	/// Shorthand for single key lookup with `resourceValues(forKeys:)`.
	/// Please see the documentation for that function for additional information.
	/// - Parameter key: Resource key to query.
	/// - Returns: Value of resource key. `nil` otherwise.
	func resourceValue(forKey key: URLResourceKey) -> URLResourceValues?
	{
		do {
			return try resourceValues(forKeys: [key])
		} catch {
			os_log("Failed to read resource value '%@' for URL '%@': %@", log: .frameworkLog, type: .error,
				   String(describing: key), String(describing: self), String(describing: error))
		}

		return nil
	}

	/// Filesystem representation string for file URL.
	var filesystemRepresentationString: String
	{
		get throws {
			guard isFileURL else {
				throw AccessError.notFileURL
			}

			var string: String = ""

			withUnsafeFileSystemRepresentation { (rep: (UnsafePointer<Int8>?)) in
				if let rep {
					string = FileManager.default.string(withFileSystemRepresentation:rep, length:strlen(rep))
				}
			}

			return string
		}
	}

	/// Use the value of `filesystemRepresentationString` to perform
	/// comparison between two file URLs.
	///
	/// - Parameter url: URL to compare self to.
	/// - Returns: `true` if equal. `false` otherwise.
	func filesystemRepresentation(isEqualToURL url: URL) -> Bool
	{
		/// Guard is necessary because otherwise if both calls to
		/// `filesystemRepresentationString` result in a `nil` value,
		/// then the result will be `true` which is not desired.
		guard let left = try?      filesystemRepresentationString,
			  let right = try? url.filesystemRepresentationString else {
			return false
		}

		return left == right
	}
}

/// Convenience declaration for URL access errors.
///
/// See `URL.AccessError`
public typealias URLAccessError = URL.AccessError
