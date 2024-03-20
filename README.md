## Overview

This package provide sample code for spine API usage + Metal rendering.

## How to run sample app

Navigate to `./SampleApps/Sample_iOS`. Run `Sample_iOS.xcodeproj` to run sample app with alien death animation in a loop.
Atm it works with Xcode 15.3 and swift 5.10.

Here is sample app rendering:

![SampleiOSAppRecoding 2](https://github.com/NikolayJuly/swift-spine-rendering/assets/699116/023e1cd3-2d5d-487b-a54e-2712276b7906)

## How to use package to render your skeletons

- You need to call `setupSkeletonSwiftRuntime`, it will setup some functions needed by Spine runtime. Should be called before any other package usage.
- Identify camera rect and create `SpineView`. For now we use static camera frame. Check position of skeleton in global coordinates, to choose right camera frame.
- Use skeleton loader from `ObjectStorage.shared.skeletonsLoader` to load skeleton from exported folder.
- After loading skeletong add them to spine view with desired animation like this:
```
for skeleton in skeletons {
    spineView.add(skeleton: skeleton)
    try! skeleton.setAnimation(named: "death", loop: true, completion: nil)
}
```
- Call `spineView.play()` to play animations, when spine view appeared.
 
## Skeleton export requirements to use with this package

- One export per sekeleton
- Json format, runtime version 4.1
- Texture atlas: Pack - checked
- Check "Premultiplied alpha" in "Pack settings"

## Side note about rendering

Since this was a side projet I did play with [triple buffering technique](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/TripleBuffering.html). 
It should make rendering async, which improve performance, but it also will have severe punishment, if there is no buffer available for rendering.
