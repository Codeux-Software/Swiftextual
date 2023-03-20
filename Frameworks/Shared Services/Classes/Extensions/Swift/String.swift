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

public extension String
{
	/// Substring string with an `NSRange`.
	///
	/// This function is out-of-bounds safe.
	///
	/// - Parameter nsrange: Range to produce substring
	/// - Returns: `Substring` constrained to `nsrange` parameter.
	func substring(with nsrange: NSRange) -> Substring?
	{
		guard let range = Range(nsrange, in: self) else {
			return nil
		}

		return self[range]
	}

	/// Interpret string as an IPv4 address using
	/// `inet_pton` or return `nil` otherwise.
	var IPv4AddressBytes: Data?
	{
		if isEmpty {
			return nil
		}

		var sa = sockaddr_in()

		if (inet_pton(AF_INET, self,  &(sa.sin_addr)) == 1) {
			return Data(bytes: &(sa.sin_addr.s_addr), count: 4)
		}

		return nil
	}

	/// Interpret string as an IPv6 address using
	/// `inet_pton` or return `nil` otherwise.
	var IPv6AddressBytes: Data?
	{
		if isEmpty {
			return nil
		}

		var sa = sockaddr_in6()

		if (inet_pton(AF_INET6, self, &(sa.sin6_addr)) == 1) {
			return Data(bytes: &(sa.sin6_addr), count: 16)
		}

		return nil
	}

	/// Is this string a valid IPv4 address?
	@inlinable var isIPv4Address: Bool
	{
		IPv4AddressBytes != nil
	}

	/// Is this string a valid IPv6 address?
	@inlinable var isIPv6Address: Bool
	{
		IPv6AddressBytes != nil
	}

	/// Is this string a valid IPv4 or IPv6 address?
	@inlinable var isIPAddress: Bool
	{
		isIPv4Address || isIPv6Address
	}

	/// File URL of string including tilde expansion
	@inlinable var fileURL: URL
	{
		URL(fileURLWithPath: (self as NSString).expandingTildeInPath)
	}

	/// Percent encode string using `CharacterSet.percentEncodedSet`
	/// as permitted list of characters.
	@inlinable var percentEncoded: String?
	{
		addingPercentEncoding(withAllowedCharacters: .percentEncodedSet)
	}

	/// Percent decoded string
	@inlinable var percentDecoded: String?
	{
		removingPercentEncoding
	}
}
