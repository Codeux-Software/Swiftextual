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
import CommonCrypto

public extension Data
{
	/// LF = Line Feed (`\n` , `0x0A` in hexadecimal, `10` in decimal)
	/// moves the cursor down to the next line without returning to the
	/// beginning of the line.
	static let lineFeed = { Data( [0x0a] ) }()

	/// CR = Carriage Return (`\r`, `0x0D` in hexadecimal, `13` in decimal)
	/// moves the cursor to the beginning of the line without advancing to
	/// the next line.
	static let carriageReturn = { Data( [0x0d] ) }()

	/// A CR immediately followed by a LF (CRLF, \r\n, or 0x0D0A) moves the
	/// cursor down to the next line and then to the beginning of the line.
	static let newline = { Data( [0x0d, 0x0a] ) }()

	/// Compute MD5 hash for data and return as string.
	///
	/// - Warning: MD5 is not cryptographically secure.
	/// Use it only in places where security is not a factor.
	var md5: String
	{
		var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

		withUnsafeBytes {
			_ = CC_MD5($0.baseAddress, CC_LONG(count), &digest)
		}

		return digest.map { String(format: "%02x", $0) }.joined()
	}

	/// Compute SHA-1 hash for data and return as string.
	var sha1: String
	{
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))

		withUnsafeBytes {
			_ = CC_SHA1($0.baseAddress, CC_LONG(count), &digest)
		}

		return digest.map { String(format: "%02x", $0) }.joined()
	}

	/// Compute SHA-256 hash for data and return as string.
	var sha256: String
	{
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

		withUnsafeBytes {
			_ = CC_SHA256($0.baseAddress, CC_LONG(count), &digest)
		}

		return digest.map { String(format: "%02x", $0) }.joined()
	}
	/// Interpret data bytes as an IPv4 address using
	/// `inet_ntop()` or return `nil` otherwise.
	var IPv4Address: String?
	{
		if isEmpty {
			return nil
		}

		let bufferLength = INET_ADDRSTRLEN

		var buffer = [CChar](repeating: 0, count: Int(bufferLength))

		if (inet_ntop(AF_INET, [UInt8](self), &buffer, socklen_t(bufferLength)) == nil) {
			return nil
		}

		return String(cString: buffer)
	}

	/// Interpret data bytes as an IPv6 address using
	/// `inet_ntop()` or return `nil` otherwise.
	var IPv6Address: String?
	{
		if isEmpty {
			return nil
		}

		let bufferLength = INET6_ADDRSTRLEN

		var buffer = [CChar](repeating: 0, count: Int(bufferLength))

		if (inet_ntop(AF_INET6, [UInt8](self), &buffer, socklen_t(bufferLength)) == nil) {
			return nil
		}

		return String(cString: buffer)
	}

	/// Removes `\r` and `\n` from end of data until
	/// a byte is found that is neither of those.
	var withoutNewlinesAtEnd: Data
	{
		var offsetAmount = 0

		for index in (startIndex ..< endIndex).reversed() {
			let byte = self[index]

			if (byte == 0x0d || byte == 0x0a) {
				offsetAmount += 1
			} else {
				break
			}
		}

		if offsetAmount > 0 {
			return Data(dropLast(offsetAmount))
		}

		return self
	}

	///
	/// Split data into lines using \n or \r\n
	///
	/// For example, `1\n2\n3\n` will produce `["1", "2", "3"]`
	///
	/// After splitting newlines, if there is any data left
	/// over that did not end in a newline, then that data
	/// is returned in the "remainder" argument of the tuple.
	///
	/// For example, `1\n2\n3\n4` will produce `["1", "2", "3"]`
	/// with a remainder of `4`
	///
	/// • The function returns nil when the data is empty.
	///
	/// • The function returns the data as the remainder when
	///   there are no newlines to split.
	///
	/// This function assumes data is presented without error.
	/// `\r\n\r` will produce a line which contains `\r` because
	/// the logic of the function assumes that only `\r\n` or
	/// `\n` will be used as a separator. Not `\r` by itself.
	///
	func splitNetworkLines() -> (lines: [Data], remainder: Data?)?
	{
		if isEmpty {
			return (lines: [], remainder: self)
		}

		let newlineChar: UInt8 = 0x0a // LF

		var lines = split(separator: newlineChar, maxSplits: .max, omittingEmptySubsequences: true)

		var remainingLine: Data?

		if last != newlineChar {
			remainingLine = lines.last

			lines.removeLast()
		}

		/* If data is only "\n", then lines will == 0 and
		remainingLine will == nil which means it's a good
		idea to keep this if statement planted here. */
		if lines.count == 0 {
			return (lines: [], remainder: remainingLine)
		}

		let linesTrimmed = lines.map { (line) in
			line.withoutNewlinesAtEnd
		}

		return (lines: linesTrimmed, remainder: remainingLine)
	}
}
