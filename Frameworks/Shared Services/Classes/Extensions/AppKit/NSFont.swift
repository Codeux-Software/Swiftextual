
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
