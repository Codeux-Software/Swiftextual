
import Foundation
import IOKit
import os.log

/// The `SystemInfo` class provides insight into the machine and
/// operating system that the library is currently operating on.
///
/// This library targets macOS 13.0 or later so many of the
/// properties within this class are tailored for that version
/// and those to follow. Information such as the name of the
/// operating system will not resolve prior to that release.
public final class SystemInfo
{
	/// Ethernet interface iterator.
	fileprivate static var ethernetInterfaces: io_iterator_t?
	{
		guard let interfaceMatchCF = IOServiceMatching("IOEthernetInterface") else {
			os_log("Failed to find matching ethernet interface.", log: .frameworkLog, type: .fault)

			return nil
		}

		let interfaceMatch = interfaceMatchCF as NSMutableDictionary
		interfaceMatch["IOPropertyMatch"] = ["IOPrimaryInterface" : true]

		var matchingServices: io_iterator_t = 0

		let matchResult = IOServiceGetMatchingServices(kIOMainPortDefault, interfaceMatch, &matchingServices)

		guard matchResult == KERN_SUCCESS else {
			os_log("IOServiceGetMatchingServices() returned unexpected result: '%@'", log: .frameworkLog, type: .fault, String(describing: matchResult))

			return nil
		}

		return matchingServices
	}

	/// MAC address of Ethernet interface formatted as a string.
	public static var ethernetMacAddress: String?
	{
		guard let services = ethernetInterfaces else {
			return nil
		}

		var macAddress: [UInt8]?

		var service = IOIteratorNext(services)

		while service > 0 {
			defer {
				service = IOIteratorNext(services)
			}

			var parentService: io_object_t = 0

			let parentResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService)

			guard parentResult == KERN_SUCCESS else {
				os_log("IORegistryEntryGetParentEntry() returned unexpected result: '%@'", log: .frameworkLog, type: .fault, String(describing: parentResult))

				continue
			}

			guard let dataCF = IORegistryEntryCreateCFProperty(parentService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0) else {
				os_log("Failed to read value of 'IOMACAddress' property.", log: .frameworkLog, type: .fault)

				continue
			}

			let data = (dataCF.takeUnretainedValue() as! CFData) as Data

			macAddress = [0, 0, 0, 0, 0, 0]

			data.copyBytes(to: &macAddress!, count: macAddress!.count)
		}

		if let macAddress {
			return macAddress.map { String(format: "%02x", $0) }.joined(separator: ":")
		}

		return nil
	}
}
