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
import os.log

public extension NSArrayController
{
	/// Remove all arranged objects.
	func removeAllArrangedObjects()
	{
		guard let count = (arrangedObjects as? Array<Any>)?.count else {
			os_log("Failed to determine count of `arrangedObjects`", log: .frameworkLog, type: .fault)

			return
		}

		remove(atArrangedObjectIndexes: IndexSet(integersIn: ..<count))
	}

	/// Replace an arranged object with another maintaining same index.
	///
	/// Objects passed to this function must conform to `Equatable` to
	/// allow the index of the original object to be found.
	///
	/// - Parameters:
	///   - arrangedObject: Original object
	///   - newObject: Object to replace original with
	func replace<T: Equatable>(arrangedObject: T, withObject newObject: T)
	{
		guard let content = arrangedObjects as? Array<T> else {
			os_log("`arrangedObjects` does not conform to Array<%@>", log: .frameworkLog, type: .fault, String(describing: T.self))

			return
		}

		guard let index = content.firstIndex(where: { $0 == arrangedObject }) else {
			/* Log nothing. Objects are allowed not to be present. */

			return
		}

		replace(atArrangedObjectIndex: index, withObject: newObject)
	}

	/// Replace an arranged object with another maintaining at `index`.
	///
	/// - Warning: This function is not out-of-bounds safe.
	///
	/// - Parameters:
	///   - index: Index of object
	///   - object: Object to replace object with
	func replace(atArrangedObjectIndex index: Int, withObject object: Any)
	{
		insert(object, atArrangedObjectIndex: (index + 2))

		remove(atArrangedObjectIndex: index)
	}

	/// Moved an arranged object from one index to another.
	///
	/// - Warning: This function is not out-of-bounds safe.
	///
	/// - Parameters:
	///   - fromIndex: Index to move from
	///   - toIndex: Index to move to
	func move(atArrangedObjectIndex fromIndex: Int, toIndex: Int)
	{
		guard let content = arrangedObjects as? Array<Any> else {
			os_log("`arrangedObjects` does not conform to Array<Any>", log: .frameworkLog, type: .fault)

			return
		}

		let object = content[fromIndex]

		remove(atArrangedObjectIndex: fromIndex)

		if fromIndex < toIndex {
			insert(object, atArrangedObjectIndex: (toIndex - 1))
		} else {
			insert(object, atArrangedObjectIndex: toIndex)
		}
	}
}
