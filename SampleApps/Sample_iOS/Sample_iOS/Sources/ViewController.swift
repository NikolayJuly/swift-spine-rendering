import FoundationExtension
import Logging
import SpineSharedStructs
import SpineSwift
import UIKit

final class ViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let metalStack = try! SpineMetalStack()
        ObjectStorage.shared.setupSkeletonSwiftRuntime(with: metalStack.generalMetalStack)

        let cameraRect = CGRect(origin: CGPoint(x: -350, y: -250),
                                size: CGSize(width: 700, height: 1000))
        self.view = SpineView(metalStack: metalStack,
                              currentMediaTimeProvider: ObjectStorage.shared.currentMediaTimeProvider,
                              cameraFrame: ScreenFrame(rect: cameraRect),
                              logger: logger)

        logger.info("Loading sekeltons...")

        let skeletonsLoader = ObjectStorage.shared.skeletonsLoader
        let skeletonsFodler = Bundle.main.resourceURL!.appending(path: "Skeletons", directoryHint: .isDirectory)
        let skeletons = try! skeletonsLoader.load(from: skeletonsFodler)

        logger.info("Found \(skeletons.count) skeletons: \(skeletons.map { $0.name })")

        for skeleton in skeletons {
            spineView.add(skeleton: skeleton)
            try! skeleton.setAnimation(named: "death", loop: true, completion: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spineView.play()
    }

    // MARK: Private

    private let logger: Logger = ObjectStorage.shared.logger

    private var spineView: SpineView { view as! SpineView }
}

