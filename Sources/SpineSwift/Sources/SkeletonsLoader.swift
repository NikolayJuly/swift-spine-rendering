import Foundation
import FoundationExtension
import Logging
import MetalExtension

public protocol SkeletonsLoader {
    /// Read files in provided folder and looking for `.json` files, which we assume will be result of export
    /// After that uses spine runtime to load skeletons
    func load(from folder: URL) throws -> [SpineSkeleton]
}

public extension ObjectStorage {
    var skeletonsLoader: SkeletonsLoader {
        let key = SkeletonsLoaderKey.self
        guard let existed = self[key] else {
            fatalError("Call `setupSkeletonSwiftRuntime(with:)` before using `skeletonsLoader` property")
        }
        return existed
    }

    func setupSkeletonSwiftRuntime(with generalMetalStack: GeneralMetalStack) {
        TextureSpineImplementation.setup(with: generalMetalStack,
                                         using: fileSystemService)
        let key = SkeletonsLoaderKey.self
        self[key] = SkeletonsLoaderImpl(fileSystemService: fileSystemService,
                                        logger: logger)
    }
}

final class SkeletonsLoaderImpl: SkeletonsLoader {
    init(fileSystemService: FileSystemService,
         logger: Logger) {
        self.fileSystemService = fileSystemService
        self.logger = logger
    }

    func load(from folder: URL) throws -> [SpineSkeleton] {
        let jsonFiles = try fileSystemService.findAllFiles(in: folder, recusrsively: false) { url in
            let filename = url.lastPathComponent
            return url.pathExtension == "json"
        }
        let names = jsonFiles.map { $0.lastPathComponent }
                             .map { $0.fileNameByRemovingExtension }

        return try names.map { name in
            try SpineSkeleton(name: name,
                              animationFolderUrl: folder,
                              logger: logger)
        }
    }

    // MARK: Private

    private let fileSystemService: FileSystemService
    private let logger: Logger
}

private struct SkeletonsLoaderKey: ObjectStorageKey {
    typealias Value = SkeletonsLoader
}
