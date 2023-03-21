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

public extension NSColor
{
	/// Convenience initializer for `init(calibratedRed:green:blue:alpha:)`
	///
	/// Each parameter supplied to this initializer is divided by 255
	/// if it is greater than 1.0 to make it easier to cross between
	/// conventions when creating a color.
	///
	/// - Parameters:
	///   - red: Red
	///   - green: Green
	///   - blue: Blue
	///   - alpha: Alpha
	convenience init(compatCalibratedRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
	{
		let r = (red > 1.0) ? red / 0xff : red
		let g = (green > 1.0) ? green / 0xff : green
		let b = (blue > 1.0) ? blue / 0xff : blue
		let a = (alpha > 1.0) ? alpha / 0xff : alpha

		self.init(calibratedRed: r, green: g, blue: b, alpha: a)
	}

	/// Convenience initializer for `init(calibratedWhite:alpha:)`
	///
	/// Each parameter supplied to this initializer is divided by 255
	/// if it is greater than 1.0 to make it easier to cross between
	/// conventions when creating a color.
	///
	/// - Parameters:
	///   - white: White
	///   - alpha: Alpha
	convenience init(compatCalibratedWhite white: CGFloat, alpha: CGFloat)
	{
		let w = (white > 1.0) ? white / 0xff : white
		let a = (alpha > 1.0) ? alpha / 0xff : alpha

		self.init(calibratedWhite: w, alpha: a)
	}

	/// Is color in gray color space?
	@inlinable var isGrayColorSpace: Bool
	{
		colorSpace.colorSpaceModel == .gray
	}

	/// Is color in RGB color space?
	@inlinable var isInRGBColorSpace: Bool
	{
		colorSpace.colorSpaceModel == .rgb
	}

	fileprivate typealias ColorSpaceRGB = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
	fileprivate typealias ColorSpaceGray = (w: CGFloat, a: CGFloat)

	/// Is color a shade of gray?
	///
	/// This function only supports colors in the RGB or
	/// gray color spaces. It will return `nil` for any other.
	var isShadeOfGray: Bool
	{
		if isInRGBColorSpace {
			var c: ColorSpaceRGB = (0.0, 0.0, 0.0, 1.0)

			getRed(&c.r, green: &c.g, blue: &c.b, alpha: nil)

			return c.r == c.g && c.g == c.b && c.r == c.b
		} else if isGrayColorSpace {
			return true
		}

		os_log("Unsupported color space: %@", log: .frameworkLog, type: .fault, String(describing: colorSpace))

		return false
	}

	/// Inverted color
	var invertedColor: NSColor?
	{
		if isInRGBColorSpace {
			var c: ColorSpaceRGB = (0.0, 0.0, 0.0, 1.0)

			getRed(&c.r, green: &c.g, blue: &c.b, alpha: &c.a)

			return NSColor(compatCalibratedRed: (1.0 - c.r), green: (1.0 - c.g), blue: (1.0 - c.b), alpha: c.a)
		} else if isGrayColorSpace {
			var c: ColorSpaceGray = (0.0, 0.0)

			getWhite(&c.w, alpha: &c.a)

			return NSColor(compatCalibratedWhite: (1.0 - c.w), alpha: c.a)
		}

		os_log("Unsupported color space: %@", log: .frameworkLog, type: .fault, String(describing: colorSpace))

		return nil
	}

	/// Hexadecimal string representation of color in either
	/// an six character RGB color space or eight character
	/// RGBA color space format.
	///
	/// This function only supports colors in the RGB or
	/// gray color spaces. It will return `nil` for any other.
	///
	/// - Parameter withAlpha: Whether to include alpha in string
	/// - Returns: String representation of color proceeded by a
	/// pound sign (#).
	func hexadecimalString(withAlpha: Bool = false) -> String?
	{
		var c: ColorSpaceRGB = (0.0, 0.0, 0.0, 1.0)

		if isInRGBColorSpace {
			getRed(&c.r, green: &c.g, blue: &c.b, alpha: &c.a)
		} else if isGrayColorSpace {
			getWhite(&c.r, alpha: &c.a)

			c.g = c.r; c.b = c.r
		} else {
			os_log("Unsupported color space: %@", log: .frameworkLog, type: .fault, String(describing: colorSpace))

			return nil
		}

		let string: NSString

		if withAlpha {
			string = NSString(format: "#%02X%02X%02X%02X",
			Int(c.r * 0xff), Int(c.g * 0xff), Int(c.b * 0xff), Int(c.a * 0xff))
		} else {
			string = NSString(format: "#%02X%02X%02X",
			Int(c.r * 0xff), Int(c.g * 0xff), Int(c.b * 0xff))
		}

		return string as String
	}

	/// Initialize an instance of NSColor using a hexadecimal color string.
	///
	/// Strings with pounds signs (#) are supported, but not required.
	///
	/// Only six character RGB and eight character RGBA color strings are supported.
	/// When alpha is not specified, it defaults to (1.0). Opaque.
	///
	/// - Example:
	/// ```
	/// FFFFFF for red with alpha 1.0
	/// #FF0000 for red with alpha 1.0
	/// #FF0000FF for red with alpha 1.0
	/// ```
	///
	/// - Parameter hexadecimalString: Hexadecimal color string
	convenience init?(hexadecimalString: String)
	{
		var string = hexadecimalString

		if string.hasPrefix("#") {
			string.removeFirst()
		}

		if   string.isEmpty ||
				(string.count != 6 && string.count != 8) ||
				(string.count % 2) != 0 {
			os_log("Hexadecimal color is not properly formatted.", log: .frameworkLog, type: .error)
			os_log("Hexadecimal color string: '%@'", log: .frameworkLog, type: .debug, string)

			return nil
		}

		var colorTotal:UInt64 = 0

		guard Scanner(string: string).scanHexInt64(&colorTotal) else {
			os_log("Hexadecimal color is not hexadecimal", log: .frameworkLog, type: .error)
			os_log("Hexadecimal color string: '%@'", log: .frameworkLog, type: .debug, string)

			return nil
		}

		if (string.count < 8) {
			colorTotal <<= 8

			colorTotal |= 0xff
		}

		let r = CGFloat((colorTotal & 0xff000000) >> 24)
		let g = CGFloat((colorTotal & 0x00ff0000) >> 16)
		let b = CGFloat((colorTotal & 0x0000ff00) >> 8)
		let a = CGFloat (colorTotal & 0x000000ff)

		self.init(compatCalibratedRed: r, green: g, blue: b, alpha: a)
	}
}
