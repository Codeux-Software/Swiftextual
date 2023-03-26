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

import AppKit

public extension NSLayoutConstraint
{
	fileprivate static let archivedConstantsLock = NSLock()
	fileprivate static var archivedConstants: [NSLayoutConstraint : CGFloat] = [:]

	/// Value of archived constant.
	fileprivate var archivedConstant: CGFloat?
	{
		set {
			Self.archivedConstantsLock.lock()

			/* Swift will warn that access to this property is not thread
			 safe because its mutable. In most cases, this would be true.
			 Not in this one. This property is the only time that this
			 dictionary is accessed. And at all times we lock it. */
			Self.archivedConstants[self] = newValue

			Self.archivedConstantsLock.unlock()
		}
		get {
			Self.archivedConstantsLock.lock()

			let value = Self.archivedConstants[self]

			Self.archivedConstantsLock.unlock()

			return value
		}
	}

	/// Archive current value of `constant` so that changes can
	/// be made to the layout without losing the original value.
	func archiveConstant()
	{
		archivedConstant = constant
	}

	/// Set value of `constant` to archived constant if it exists.
	///
	/// The archived constant is destroyed after restore.
	func restoreConstant()
	{
		if let archivedConstant {
			constant = archivedConstant

			self.archivedConstant = nil
		}
	}

	/// Zero out value of `constant`.
	///
	/// - Parameter archiveConstant: `true` to archive the value
	/// of `constant` prior to zeroing it. Defaults to `false`.
	func zeroOut(archiveConstant: Bool = false)
	{
		if archiveConstant {
			self.archiveConstant()
		}

		constant = 0.0
	}
}
