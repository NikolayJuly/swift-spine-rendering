import Foundation
import FoundationExtension
import SpineC

public extension String {
    static let spineAtlasExtension = ".atlas.txt"
}

public final class SpineAtlas {

    public let name: String

    public let pAtlas: UnsafeMutablePointer<spAtlas>

    /// - parameter name: name of atlas to load in this folder
    /// - parameter animationFolderUrl: URL to folder with atlas.txt, skeleton and atlas png
    public convenience init(name: String, animationFolderUrl: URL) throws {
        let fileSystemService: FileSystemService = FileManager.default

        let matchingAtlas: (URL) -> Bool = { url in
            let filename = url.lastPathComponent
            return filename == name + .spineAtlasExtension
        }

        let files = try fileSystemService.findAllFiles(in: animationFolderUrl,
                                                       recusrsively: false,
                                                       validate: matchingAtlas)

        guard files.count == 1 else {
            throw SpineAtlasError.failedToFindAtlas(name, animationFolderUrl)
        }

        let atlasUrl = files.first!

        try self.init(fileurl: atlasUrl)
    }

    /// - parameter fileurl: url of `atlas.txt` file
    public init(fileurl: URL) throws {
        let cAtlasPath = fileurl.path.cString(using: .utf8)

        // UnsafeMutablePointer<spAtlas>
        let spAtlasPointer = spAtlas_createFromFile(cAtlasPath, nil)

        guard let pointer = spAtlasPointer else {
            throw SpineAtlasError.failedToCreateAtlas(fileurl)
        }

        self.pAtlas = pointer
        self.name = fileurl.lastPathComponent.fileNameByRemovingExtension
    }

    deinit {
        spAtlas_dispose(pAtlas)
    }

    /// Provided value should not overlive closure context
    public func withPages<R>(_ closure: ([UnsafeMutablePointer<spAtlasPage>]) throws -> R) rethrows -> R  {
        var array = [UnsafeMutablePointer<spAtlasPage>]()
        var next = pAtlas.pages
        while let current = next {
            array.append(current)
            next = current.next
        }
        return try closure(array)
    }

    /// Provided value should not overlive closure context
    public func withRegions<R>(_ closure: ([UnsafeMutablePointer<spAtlasRegion>]) throws -> R) rethrows -> R  {
        var array = [UnsafeMutablePointer<spAtlasRegion>]()
        var next = pAtlas.regions
        while let current = next {
            array.append(current)
            next = current.next
        }
        return try closure(array)
    }
}

public enum SpineAtlasError: Error {
    case failedToFindAtlas(String, URL)
    case failedToCreateAtlas(URL)
}
