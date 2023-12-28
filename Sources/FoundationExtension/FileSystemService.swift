import Foundation

@usableFromInline
enum FileSystemServiceError: Error {

    case fileDoesntExists(URL)
    case unableToCreateWriteFileStream(URL)
}

public protocol FileSystemService: AnyObject, Sendable {
    /// Check that folder at URL exists and it is folder, not a file

    /// - returns: files and subfolder names
    func categorizedFolderContent(at folderUrl: URL) throws -> (files: [URL], folders: [URL])

    /// - Throws: FileSystemServiceError
    func fileContent(at url: URL) throws -> Data
}

public extension ObjectStorage {
    var fileSystemService: FileSystemService {
        get {
            if let existedOne = self[FileSystemServiceKey.self] {
                return existedOne
            }
            return FileManager.default
        }
        set {
            self[FileSystemServiceKey.self] = newValue
        }
    }
}

public extension FileSystemService {

    /// - Parameter validate: block to validate file. Return true to include file in result
    func findAllFiles(in folderUrl: URL, recusrsively: Bool, validate: (URL) -> Bool) throws -> [URL] {
        var fodlersToCheck = [folderUrl]
        var resFiles = [URL]()

        while fodlersToCheck.isEmpty == false {
            let folderUrl = fodlersToCheck.removeLast()

            let (files, folders) = try categorizedFolderContent(at: folderUrl)

            if recusrsively {
                fodlersToCheck.append(contentsOf: folders)
            }

            for fileUrl in files {
                let filename = fileUrl.lastPathComponent
                guard filename != ".DS_Store" else {
                    continue
                }

                guard validate(fileUrl) else {
                    continue
                }

                resFiles.append(fileUrl)
            }
        }

        return resFiles
    }
}

// Documentation says that ``FileManager`` is thread-safe in general, so mark as ``Sendable``
extension FileManager: FileSystemService, @unchecked Sendable {
    public func folderExists(at folderUrl: URL) -> Bool {
        var isDir: ObjCBool = false
        let folderExists = fileExists(atPath: folderUrl.path, isDirectory: &isDir)

        return folderExists && isDir.boolValue
    }

    public func categorizedFolderContent(at folderUrl: URL) throws -> (files: [URL], folders: [URL]) {
        let urls = try contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: [.isDirectoryKey])

        var files = [URL]()
        var folders = [URL]()
        folders.reserveCapacity(urls.count)
        files.reserveCapacity(urls.count)

        for url in urls {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])

            let isFolder: Bool
            if let isDirectory = values.isDirectory {
                isFolder = isDirectory
            } else {
                assert(false, "We request this resource value, when created urls, so info should exists")
                isFolder = folderExists(at: url)
            }
            if isFolder {
                folders.append(url)
            } else {
                guard url.lastPathComponent != ".DS_Store" else {
                    continue
                }
                files.append(url)
            }
        }
        return (files, folders)
    }

    public func fileContent(at url: URL) throws -> Data {
        guard let existedFileData = contents(atPath: url.path) else {
            throw FileSystemServiceError.fileDoesntExists(url)
        }

        return existedFileData
    }
}

private struct FileSystemServiceKey: ObjectStorageKey, ObjectStorageLockKey {
    typealias Value = FileSystemService
}
