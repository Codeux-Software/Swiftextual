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

public extension FileManager
{
	/// Type information for a specific item at a destination.
	enum FileType {
		/// Destination is a regular file.
		case file

		/// Destination is a directory.
		case directory

		/// Destination is other type not recognized by this library.
		case other

		/// Destination does not exist.
		case none
	}

	/// Does item at path exist as a directory?
	///
	/// Use of this function is discouraged because the return value is not
	/// contextually complete. It will only tell you if a directory exists
	/// at the path. If a regular file exists there, then this function will
	/// return `false`. That can cause problems if you then try to create
	/// a directory at the path. See `destinationOccupied(atURL:)` instead.
	///
	/// This function will resolve symbolic links and alias files prior to
	/// determining whether the item at path is a directory.
	///
	/// - Parameter url: File URL of destination.
	/// - Returns: `true` if item at path is a directory. `false` otherwise.
	@inlinable func directoryExists(atURL url: URL) throws -> Bool
	{
		try fileType(atURL: url) == .directory
	}

	/// Does item at path exist as a regular file?
	///
	/// Use of this function is discouraged because the return value is not
	/// contextually complete. It will only tell you if a regular file exists
	/// at the path. If a directory exists there, then this function will
	/// return `false`. That can cause problems if you then try to create
	/// a regular file at the path. See `destinationOccupied(atURL:)` instead.
	///
	/// This function will resolve symbolic links and alias files prior to
	/// determining whether the item at path is a regular files.
	///
	/// - Parameter url: File URL of destination.
	/// - Returns: `true` if item at path is a regular file. `false` otherwise.
	@inlinable func fileExists(atURL url: URL) throws -> Bool
	{
		try fileType(atURL: url) == .file
	}

	/// Is the destination path occupied by something?
	///
	/// Any type of file, directory, package, application, volume, etc.
	///
	/// This function will resolve symbolic links and alias files prior
	/// to determining whether the destination path is occupied.
	///
	/// - Parameter path: File path of destination.
	/// - Returns: `true` if destination is occupied. `false` otherwise.
	@inlinable func destinationOccupied(atPath path: String) throws -> Bool
	{
		try fileType(atPath: path) != .none
	}

	/// Is the destination path occupied by something?
	///
	/// Any type of file, directory, package, application, volume, etc.
	///
	/// This function will resolve symbolic links and alias files prior
	/// to determining whether the destination path is occupied.
	///
	/// - Parameter url: File URL of destination.
	/// - Returns: `true` if destination is occupied. `false` otherwise.
	@inlinable func destinationOccupied(atURL url: URL) throws -> Bool
	{
		try fileType(atURL: url) != .none
	}

	/// Type of item at destination.
	///
	/// This function will resolve symbolic links and alias files prior
	/// to determining the type of item at destination.
	///
	/// - Parameter path: File URL of destination.
	/// - Returns: See `FileType` enum.
	@inlinable func fileType(atPath path: String) throws -> FileType
	{
		try resolveItem(atPath: path).type
	}

	/// Type of item at destination.
	///
	/// This function will resolve symbolic links and alias files prior
	/// to determining the type of item at destination.
	///
	/// - Parameter url: File URL of destination.
	/// - Returns: See `FileType` enum.
	@inlinable func fileType(atURL url: URL) throws -> FileType
	{
		try resolveItem(atURL: url).type
	}

	/// Resolve symbolic links and alias files to find the true destination.
	///
	/// - Parameter path: A file path
	/// - Returns: A tuple that contains the destination of the path and
	/// file type of the destination.
	@inlinable func resolveItem(atPath path: String) throws -> (location: String, type: FileType)
	{
		let r = try resolveItem(atURL: path.fileURL)

		return (r.location.path, r.type)
	}

	/// Resolve symbolic links and alias files to find the true destination.
	///
	/// - Parameter url: A file URL
	/// - Returns: A tuple that contains the destination of the URL and
	/// file type of the destination.
	func resolveItem(atURL url: URL) throws -> (location: URL, type: FileType)
	{
		guard url.isFileURL else {
			throw URLAccessError.notFileURL
		}

		var location = url

		location.standardize()

		location.resolveSymlinksInPath()

		guard try location.checkResourceIsReachable() else {
			return (location, .none)
		}

		let properties = try location.resourceValues(forKeys: [.isAliasFileKey, .isRegularFileKey, .isDirectoryKey])

		if properties.isAliasFile ?? false {
			let d = try URL(resolvingAliasFileAt: url, options: [.withoutUI, .withoutMounting])

			return try resolveItem(atURL: d)
		}

		if properties.isDirectory ?? false {
			return (location, .directory)
		} else if properties.isRegularFile ?? false {
			return (location, .file)
		}

		return (location, .other)
	}

	/// Lock item at destination.
	///
	/// - Parameter path: File path to destination.
	/// - Returns: `true` on success. `false` otherwise.
	@inlinable func lockItem(atPath path: String) throws
	{
		try lockItem(atURL: path.fileURL)
	}

	/// Unlock item at destination.
	///
	/// - Parameter path: File path to destination.
	/// - Returns: `true` on success. `false` otherwise.
	@inlinable func unlockItem(atPath path: String) throws
	{
		try unlockItem(atURL: path.fileURL)
	}

	/// Lock item at destination.
	///
	/// - Parameter path: File URL to destination.
	/// - Returns: `true` on success. `false` otherwise.
	@inlinable func lockItem(atURL url: URL) throws
	{
		try toggleLock(atURL: url, on: true)
	}

	/// Unlock item at destination.
	///
	/// - Parameter path: File URL to destination.
	/// - Returns: `true` on success. `false` otherwise.
	@inlinable func unlockItem(atURL url: URL) throws
	{
		try toggleLock(atURL: url, on: false)
	}

	/// Toggle lock on item at destination.
	///
	/// - Parameter path: File URL to destination.
	/// - Parameter on: Lock state: `true` for on, `false` for off.
	/// - Returns: `true` on success. `false` otherwise.
	func toggleLock(atURL url: URL, on: Bool) throws
	{
		guard url.isFileURL else {
			throw URLAccessError.notFileURL
		}

		var properties = URLResourceValues()
		properties.isUserImmutable = on

		do {
			var destination = url // needs to be immutable

			try destination.setResourceValues(properties)
		} catch {
			os_log("Failed to set new properties on URL '%@': %@", log: .frameworkLog, type: .fault,
				   String(describing: url), String(describing: error))

			throw URLAccessError.otherError(error)
		}
	}

	/// Is cloud item at destination 100% downloaded?
	///
	/// If the destination being checked is a directory, then the
	/// directory will only be considered 100% downloaded if all
	/// files it contains are as well.
	///
	/// This function will return `true` for any non-cloud item.
	///
	/// - Parameter url: File path to destination.
	/// - Returns: `true` if item is 100% downloaded. `false` otherwise.
	@inlinable func isUbiquitousItemDownloaded(atPath path: String) throws -> Bool
	{
		try isUbiquitousItemDownloaded(atURL: path.fileURL)
	}

	/// Is cloud item at destination 100% downloaded?
	///
	/// If the destination being checked is a directory, then the
	/// directory will only be considered 100% downloaded if all
	/// files it contains are as well.
	///
	/// This function will return `true` for any non-cloud item.
	///
	/// - Parameter url: File URL to destination.
	/// - Returns: `true` if item is 100% downloaded. `false` otherwise.
	func isUbiquitousItemDownloaded(atURL url: URL) throws -> Bool
	{
		guard url.isFileURL else {
			throw URLAccessError.notFileURL
		}

		let properties: URLResourceValues

		do {
			properties = try url.resourceValues(forKeys: [.isDirectoryKey, .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
		} catch {
			os_log("Failed to read resource values for URL '%@': %@", log: .frameworkLog, type: .error,
				   String(describing: url), String(describing: error))

			throw URLAccessError.otherError(error)
		}

		/* If item is not in the cloud, then we can assume it is
		 downloaded because it already exists on the hard drive. */
		guard properties.isUbiquitousItem ?? false else {
			return true
		}

		if let isDirectory = properties.isDirectory, isDirectory {
			/* Recursively traverse the hierarchy of the directory
			 until we find at least one item that is downloading. */
			/* `contentsOfDirectory()` gives us the option to preload keys.
			 This can probably be optimized so we preload properties here
			 and use a nested function for validation instead of recursively
			 calling self. That probably has negligible gain. */
			let files: [URL]

			do {
				files = try contentsOfDirectory(at: url, includingPropertiesForKeys: [])
			} catch {
				os_log("Failed to read directory contents of URL '%@': %@", log: .frameworkLog, type: .error,
					   String(describing: url), String(describing: error))

				return false
			}

			if try files.contains(where: { try isUbiquitousItemDownloaded(atURL: $0) == false } ) {
				return false /* Something in the directory is downloading. */
			}

			return true /* Nothing in directory is downloading. */
		} // isDirectory

		return 	properties.ubiquitousItemDownloadingStatus == .current ||
				properties.ubiquitousItemDownloadingStatus == .downloaded
	}

	/// Perform a file copy or move operation from one path to another.
	///
	/// - Warning: **This function is destructive.**
	/// Any file that exists at the destination file path
	/// will be removed completely or moved to Trash.
	///
	/// - Parameters:
	///   - sourcePath: The original file path
	///   - destinationPath: The destination file path
	///   - copyInsteadOfMove: `true` to perform a copy operation instead of move. Defualts to `false`.
	///   - trashDestination: `true` to move destination file to Trash instead of outright vanishing. Defaults to `false`.
	/// - Returns: No error on success. Error describing problem otherwise.
	func relocateItem(atPath sourcePath: String, toPath destinationPath: String, copyInsteadOfMove: Bool = false, trashDestination: Bool = false) throws
	{
		try relocateItem(atURL: sourcePath.fileURL, toURL: destinationPath.fileURL, copyInsteadOfMove: copyInsteadOfMove, trashDestination: trashDestination)
	}

	/// Perform a file copy or move operation from one path to another.
	///
	/// - Warning: **This function is destructive.**
	/// Any file that exists at the destination file path
	/// will be removed completely or moved to Trash.
	///
	/// - Parameters:
	///   - sourcePath: The original file path
	///   - destinationPath: The destination file path
	///   - copyInsteadOfMove: `true` to perform a copy operation instead of move. Defaults to `false`.
	///   - trashDestination: `true` to move destination file to Trash instead of outright vanishing. Defaults to `false`.
	/// - Returns: `true` on success. `false` otherwise.
	func relocateItem(atURL sourceURL: URL, toURL destinationURL: URL, copyInsteadOfMove: Bool = false, trashDestination: Bool = false) throws
	{
		guard sourceURL.isFileURL && destinationURL.isFileURL else {
			throw URLAccessError.notFileURL
		}

		if let exists = try? destinationOccupied(atURL: destinationURL), exists {
			do {
				if (trashDestination) {
					try trashItem(at: destinationURL, resultingItemURL: nil)
				} else {
					try removeItem(at: destinationURL)
				}
			} catch {
				os_log("Failed to remove file at destination: '%@': '%@'", log: .frameworkLog, type: .error,
					   String(describing: destinationURL), String(describing: error))

				throw URLAccessError.otherError(error)
			}
		}

		do {
			if (copyInsteadOfMove) {
				try copyItem(at: sourceURL, to: destinationURL)
			} else {
				try moveItem(at: sourceURL, to: destinationURL)
			}
		} catch {
			os_log("Failed to copy/move file '%@' -> '%@': '%@'", log: .frameworkLog, type: .error,
				   String(describing: sourceURL), String(describing: destinationURL), String(describing: error))

			throw URLAccessError.otherError(error)
		}
	}
}
