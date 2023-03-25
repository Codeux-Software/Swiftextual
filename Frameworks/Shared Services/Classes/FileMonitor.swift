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

import Combine
import CoreServices
import os.log

/// `FileMonitor` can be used of monitoring for changes to a specific
/// set of file URLs. It can associate an optional context with each
/// to make it easier to work with events that dispatch from it.
public class FileMonitor
{
	/// Each event dispatched by a file monitor is a copy of `Event`
	/// containing the file URL targeted by the event, flags that
	/// were acted upon, an identifier, and an optional context that
	/// was defined at the point the monitor was initialized.
	struct Event
	{
		let url: URL
		let flags: Flags
		let identifier: FSEventStreamEventId
		let context: Any?

		fileprivate init(url: URL, flags: FSEventStreamCreateFlags, identifier: FSEventStreamEventId, context: Any?) {
			self.url = url
			self.flags = .init(rawValue: flags)
			self.identifier = identifier
			self.context = context
		}

		/// Flags of event.
		struct Flags: OptionSet {
			public let rawValue: UInt32

			public init(rawValue: UInt32) {
				self.rawValue = rawValue
			}

			/// See `kFSEventStreamEventFlagItemChangeOwner` for more information.
			static let changeOwner = Flags(rawValue: 0x00004000)

			/// See `kFSEventStreamEventFlagItemCloned` for more information.
			static let cloned = Flags(rawValue: 0x00400000)

			/// See `kFSEventStreamEventFlagItemCreated` for more information.
			static let created = Flags(rawValue: 0x00000100)

			/// See `kFSEventStreamEventFlagEventIdsWrapped` for more information.
			static let eventIdsWrapped = Flags(rawValue: 0x00000008)

			/// See `kFSEventStreamEventFlagItemXattrMod` for more information.
			static let extendedAttributes = Flags(rawValue: 0x00008000)

			/// See `kFSEventStreamEventFlagItemFinderInfoMod` for more information.
			static let finder = Flags(rawValue: 0x00002000)

			/// See `kFSEventStreamEventFlagHistoryDone` for more information.
			static let historyDone = Flags(rawValue: 0x00000010)

			/// See `kFSEventStreamEventFlagItemInodeMetaMod` for more information.
			static let indexNodeMetadata = Flags(rawValue: 0x00000400)

			/// See `kFSEventStreamEventFlagItemIsDir` for more information.
			static let isDirectory = Flags(rawValue: 0x00020000)

			/// See `kFSEventStreamEventFlagItemIsFile` for more information.
			static let isFile = Flags(rawValue: 0x00010000)

			/// See `kFSEventStreamEventFlagItemIsHardlink` for more information.
			static let isHardlink = Flags(rawValue: 0x00100000)

			/// See `kFSEventStreamEventFlagItemIsLastHardlink` for more information.
			static let isLastHardlink = Flags(rawValue: 0x00200000)

			/// See `kFSEventStreamEventFlagItemIsSymlink` for more information.
			static let isSymlink = Flags(rawValue: 0x00040000)

			/// See `kFSEventStreamEventFlagKernelDropped` for more information.
			static let kernelDropped = Flags(rawValue: 0x00000004)

			/// See `kFSEventStreamEventFlagItemModified` for more information.
			static let modified = Flags(rawValue: 0x00001000)

			/// See `kFSEventStreamEventFlagMount` for more information.
			static let mount = Flags(rawValue: 0x00000040)

			/// See `kFSEventStreamEventFlagOwnEvent` for more information.
			static let ownEvent = Flags(rawValue: 0x00080000)

			/// See `kFSEventStreamEventFlagItemRemoved` for more information.
			static let removed = Flags(rawValue: 0x00000200)

			/// See `kFSEventStreamEventFlagItemRenamed` for more information.
			static let renamed = Flags(rawValue: 0x00000800)

			/// See `kFSEventStreamEventFlagRootChanged` for more information.
			static let rootChanged = Flags(rawValue: 0x00000020)

			/// See `kFSEventStreamEventFlagMustScanSubDirs` for more information.
			static let subdirectoryChanged = Flags(rawValue: 0x00000001)

			/// See `kFSEventStreamEventFlagUnmount` for more information.
			static let unmount = Flags(rawValue: 0x00000080)

			/// See `kFSEventStreamEventFlagUserDropped` for more information.
			static let userDropped = Flags(rawValue: 0x00000002)

			/// No flags for event.
			static let none = Flags([])
		}
	}

	/// Event monitor.
	let events$ = PassthroughSubject<Event, Never>()

	fileprivate let urls: [URL]
	fileprivate let context: [String : Any] /// Key = URL file system representation

	fileprivate var eventStream: FSEventStreamRef?

	typealias URLWithContext = (url: URL, context: Any?)

	/// Create new file monitor with a list of file URLs and
	/// an optional context that is associated with each.
	///
	/// - Parameter urls: List of file URLs to monitor.
	init(withURLs urls: [URLWithContext]) throws
	{
		var urlsOut: [URL] = []

		/// Context objects are mapped to a dictionary with the key equal
		/// to the file system representation string of the URL and the
		/// value the context. This is done versus keeping an array of
		/// tuples around so that for each event, there is not an
		/// overhead of filtering the array of tuples for each URL.
		self.context = try urls.reduce(into: [:]) { (previous, next) in
			let url = next.url

			/// This call will throw if URL is not a file URL so
			/// validation beyond it is not necessary in this scope.
			let key = try url.filesystemRepresentationString

			previous[key] = next.context

			urlsOut.append(url)
		}

		self.urls = urlsOut
	}

	convenience init(withURLs urls: [URL]) throws
	{
		let urlsOut = urls.map( { URLWithContext($0, nil) } )

		try self.init(withURLs: urlsOut)
	}

	convenience init(withURL url: URLWithContext) throws
	{
		try self.init(withURLs: [url])
	}

	convenience init(withURL url: URL) throws
	{
		try self.init(withURLs: [url])
	}

	/// Is monitoring of events occurring?
	var monitoring: Bool
	{
		eventStream != nil
	}

	/// Stop monitoring for events.
	func stopMonitoring()
	{
		guard let eventStream else {
			return
		}

		FSEventStreamStop(eventStream)
		FSEventStreamInvalidate(eventStream)
		FSEventStreamRelease(eventStream)

		self.eventStream = nil
	}

	deinit
	{
		stopMonitoring()
	}

	/// Begin monitoring for events as of now with a specific latency
	/// between each dispatch of events.
	///
	/// Events are dispatched on global queue with default QOS priority.
	///
	/// - Parameter latency: Latency between each dispatch of events. Defaults to `1.0`.
	/// - Parameter resolveDestination: For each file URL that this monitor was initialized
	/// with, any that are symbolic links or alias files will be resolved. The destination
	/// of the link is then monitored rather than the link file itself. Defaults to `false`.
	/// - Returns: `true` on success. `false` otherwise.
	func startMonitoring(withLatency latency: Double = 1.0, resolveDestination: Bool = true) -> Bool
	{
		if monitoring {
			os_log("Cannot start monitor because it is already active.", log: .frameworkLog, type: .fault)

			return false
		}

		let streamEventCallback: FSEventStreamCallback = {
			_, clientCallbackInfo, numEvents, eventPaths, eventFlags, eventIds in

			let target = unsafeBitCast(clientCallbackInfo, to: FileMonitor.self)

			/// When `kFSEventStreamCreateFlagUseCFTypes` flag is set on the stream,
			/// the events paths will be an array of strings which means we can safely
			/// force unwrap the value of this property safely.
			let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]

			for index in 0..<numEvents {
				let url = URL(fileURLWithPath: paths[index])

				var context: Any? = nil

				if let urlRep = try? url.filesystemRepresentationString {
					context = target.context[urlRep]
				}

				let eventOut = Event(url: url, flags: eventFlags[index], identifier: eventIds[index], context: context)

				target.events$.send(eventOut)
			}
		}

		let paths = (resolveDestination) ? urls.resolvingPaths : urls.map( { $0.path } )

		var context = FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)

		context.info = Unmanaged.passUnretained(self).toOpaque()

		eventStream = FSEventStreamCreate(kCFAllocatorDefault,
										  streamEventCallback,
										  &context,
										  paths as CFArray,
										  FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
										  latency,
										  UInt32(	kFSEventStreamCreateFlagFileEvents |
													kFSEventStreamCreateFlagNoDefer |
													kFSEventStreamCreateFlagUseCFTypes))

		guard let eventStream else {
			os_log("FSEventStreamCreate() returned nil result.", log: .frameworkLog, type: .fault)

			return false
		}

		FSEventStreamSetDispatchQueue(eventStream, .global(qos: .default))

		return FSEventStreamStart(eventStream)
	}
}
