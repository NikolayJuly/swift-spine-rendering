import Foundation
import QuartzCore

/// We need way to change speed of single Skeleton or whole scene/view
/// So view will change speed of skeleton, so it will depends on view speed
public protocol SpineSkeletonClock: AnyObject {
    var speed: Double { get set }

    func delta() -> CFTimeInterval
}

protocol RestartableSpineClock: SpineSkeletonClock {

    /// Reset last time to now. Should be called when animation starts
    func start()

    /// Make sure watches return 0 from delta
    func pause()

    func cutCurrentFrameTime()
}

/// Will use separate watch for each skeleton, as they can play animations separately
/// SpineView should set ``SpineSkeleton/clock`` when skeleton added to scene
/// This way, Skeleton watch depends on View watch and we can slow down them all togeter
/// Also, because scene cut new time on its watch on each update, all skeletons will get the same `delta` in update
final class SpineSkeletonClockMediaTimeImpl: RestartableSpineClock {

    init(currentMediaTimeProvider: CurrentMediaTimeProvider) {
        self.currentMediaTimeProvider = currentMediaTimeProvider
        self.lastTime = currentMediaTimeProvider.now()
        self._delta = 0
    }

    // MARK: SpineSkeletonWatch

    var speed: Double = 1

    func delta() -> CFTimeInterval {
        return _delta
    }

    func start() {
        self.lastTime = currentMediaTimeProvider.now()
    }

    func pause() {
        self._delta = 0
    }

    func cutCurrentFrameTime() {
        let now = currentMediaTimeProvider.now()
        let delta = now - lastTime
        self.lastTime = now
        self._delta = speed * delta
    }

    // MARK: Private

    private let currentMediaTimeProvider: CurrentMediaTimeProvider

    private var lastTime: CFTimeInterval
    private var _delta: CFTimeInterval
}

final class SpineSkeletonClockWapper: SpineSkeletonClock {

    init(parentClock: SpineSkeletonClock) {
        self.parentClock = parentClock
    }

    // MARK: SpineSkeletonWatch

    var speed: Double = 1

    func delta() -> CFTimeInterval {
        let otherDelta = parentClock.delta()
        return speed * otherDelta
    }

    // MARK: Private

    private let parentClock: SpineSkeletonClock
}
