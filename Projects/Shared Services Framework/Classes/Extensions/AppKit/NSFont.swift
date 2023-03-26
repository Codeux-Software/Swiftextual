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

public extension NSFont
{
	@inlinable static func fontExists(named name: String) -> Bool
	{
		NSFontManager.shared.availableFonts.contains(where: { $0 == name} )
	}

	@inlinable var traits: NSFontTraitMask
	{
		NSFontManager.shared.traits(of: self)
	}

	var italicized: NSFont
	{
		#warning("The validity of this code has not yet been tested.")

		let theFont = NSFontManager.shared.convert(self, toHaveTrait: .italicFontMask)

		if theFont.traits.contains(.italicFontMask) {
			return theFont
		}

		var italicTransform = AffineTransform(
			m11: 1.0,
			m12: 0.0,
			m21: -tan(-14.0 * (acos(0) / 90)),
			m22: 1.0,
			tX: 0.0,
			tY: 0.0)

		italicTransform.scale(pointSize)

		if let fontOut = NSFont(descriptor: theFont.fontDescriptor, textTransform: italicTransform) {
			return fontOut
		}

		return self
	}
}
