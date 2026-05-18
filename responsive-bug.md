# Responsive Bug

## Description

There are two examples with conflicting bugs - fix one -> create the other, fix the other -> create the first. Both relate to when the page is resized by the user.

## Examples

WAAPI/ResponsiveAnimations/Responsive
WAAPI/Animate3D

**The bugs are listed in chronological order of discovery and fix.**


## Responsive Example Bug 1

When the user resized the page with the animations playing, the animations would restart. There may have been other visual bugs but this is a historical bug, and I can't remember all the symptoms. There may be useful information in commit messages.

### Status

Fixed.

Commit: (need to find this)


## Animate3D Example Bug

When the user resizes the page the spinning cube animation would restart. This was fixed, leading to another bug whereby there would be a visible 'flash/flicker' when the first Sides animation completed, and the next animation (rotate cube) begins. The 'flicker' is a single frame error, where the cube reduces in size for the one frame.

### Status

Fixed.

Commit: c014cee938c9f2df00017e2e80876c001936b051



## Responsive Example Bug 2

This regression bug appeared after the fix to the Animate3D bug.

Version 1 of this bug affected both tracks. Currently, for this version of the bug:

- The box on the Clamp track runs fine.
- The following relates to the Proportional Track only.

The animation restarts when the page is resized. If I drag resize the box flickers between start and end points.

### Reproduction Steps

Load page
Start animation
Stop animation
Resize

Result: Pass. Boxes remain at correct position.

Load page
Start animation
Allow to run to x=maxValue and begin it's return journey back to x=0
Stop animation
Resize

Result: Fail. Box jumps to x=0
Fixed.


Load page
Start animation
Allow to run to x=maxValue and begin it's return journey back to x=0
Resize multiple times

Result: Fail. Each resize cause the box to toggle between x=0 and x=maxValue.

Partially fixed, see Bug 3
Commit: 3080dd2ede14dd818a551feb189309a63065b008


## Responsive Example Bug 3

Resizing causes the box to jump to an endpoint, x=0 or x=maxValue, alternately.

Start in landscape
Load Page
Start animation
Stop animation at 50%
Switch orienation

Result: Fail. Box jumps to x=maxValue then to x=50%

Start in portrait
Load Page
Start animation
Stop animation at 50%
Switch orienation

Result: Fail. Box jumps to x=0 then to x=50%

When drag resizing, the above results in a constant flicker between x=0 and x=maxValue until dragging stops.

Partially fixed, see Bug 4
Commit: 0a7f29186c2432dd91962523f41484a2721d8fbd


## Responsive Example Bug 4

After a resize, the box isn't positioned accurately. If the box is at 50% and the orientation is changed, the
box should return to 50% no matter how many orientation changes there are - but it's not. You will need some debugging to verify and fix.

In portrait
Load the page
Widen the track
Start animation
Stop animation as the box passes the half way stage.
Switch to landscape

Result: Pass. Visually it looks correct.


In portrait
Load the page
Widen the track
Start animation
Stop animation as the box passes the half way stage.
Switch to landscape
Switch to portrait

Result: Fail. The box is too far left of where it should be.


In portrait
Load the page
Widen the track
Start animation
Stop animation on the return leg as the box passes the half way stage.
Switch to landscape
Switch to portrait

Result: Fail. The box is too far right of where it should be.

### Status

Fixed.

Commit: 825055aa1a6f235bf6418f928cae1304fd9e4c69

## Responsive Example Bug 5

Similar to Bug 4 but for the Clamp (bottom) track box.

In portrait
Load the page
Widen the track
Start animation
Stop animation before it completes it's first leg
Switch to landscape
Switch to portrait

Result: Pass. Box returns to it's exact same position.

In Landscape
Load the page
Widen the track
Start animation
Stop animation as it approaches the end of it's first leg
Switch to portrait

Result: Pass. The box's actual pixel position was out of bounds for the portrait width,
so was clamped as required.


In Landscape
Load the page
Widen the track
Start animation
Stop animation as it approaches the end of it's first leg
Switch to portrait
Switch to Landscape
Switch to portrait

Expected: Box should return to the right edge clamped position. Switching from portrait to landscape
should result in the box remaining at the same pixel position, so should the following switch back to portrait.

Result: Fail. The box is now moved left and is no longer up against the right edge of the track.

### Status

Not a library bug. Reproduces only when Chrome DevTools is open and the
device-toolbar orientation toggle is used: DevTools emits a spurious extra
`onResize` event with a stale viewport width on the second toggle, which
re-clamps the box against the wrong bounds. Cannot be reproduced in any of:

- The same browser with DevTools closed (drag-resize the window edge instead).
- An iOS simulator rotating between portrait and landscape.

The Proportional track masks the symptom because its position is rescaled
relative to the (also-spurious) bounds and lands at the visually-expected
spot anyway. The Clamp track has no such forgiveness.

While investigating, a related real bug was found and fixed: after a
resize-driven WAAPI animation recreate, the rAF tick inside
`setupAnimationEvents` was hardcoding `isAnimating: true` in the
`propertyUpdate` it sent back to Elm, which flipped `AnimGroup.Paused`
back to `Running` and caused subsequent resizes to take the wrong
(mid-flight) code path.


## Responsive Bug 6

Bounds are not respected on resize when sequencing translate animations with events.

In Lndscape
Load the page
Switch to portrait before the dot gets half way across

Result: Pass. The dot respects the new bounds and animates down correctly when it reaches it's new target endpoint.

In Landscape
Load the page
Switch to portrait after the dot gets half way across

Result: Fail. The dot waits at the endpoint - presumably until the animation time completes for the previous x endpoint prior to switching to portrait - it then respects all bounds.

In Portrait
Load the page
Switch to landscape at any point

Result: Fail. The dot continues to the previous portrait end point, not the new landscape end point, and travels down to the correct y endpoint - it then respects all the bounds.

Fixed


## Responsive Bug 7

In the Perspective3D example, the dot is stopping at an end point until the animation time completes after a resize that reduces the target end position, when the dot is past the new bounds and gets clamped. The animation continue to runs, so the dot waits in it's clamped position until it completes. Then the next animation runs correctly.

In Landscape
Load the page
Let the animation run until the dot has gone past the max y position if in portrait
Switch to portrait

Result: Fail. The dot gets clamped to the top right corner, but the animation still runs, causing the dot to wait at its clamped position until the next animation begins.

Fixed.

## Responsive Bug 8 - WAAPI, Perspective3D example

Load the page
Allow the dot to travel to top right, and begin downward journey
Drag resize the width so that the anim area reduces in size

Result: Fail. Dot appears to slow down as the width changes. Does not happen when the dot is on the left edge travelling up.

### Discoveries

1. When the dot is travelling up the left edge, and the width is drag resized, the animation runs nearly perfectly. Only known issue - the dot can pause when it gets to (0,0). This suggests the animation clock has been updated incorrectly - hence the dot remaining in it's max boundary position until the clock completes. The dots speed doesn't appear to change, so it must be the clock.

2. When the dot is travelling down the right edge, and the anim area width is reduced by drag resizing, the dot remains at it's y position until the the drag is over, then it carries on it's way correctly.

3. When the dot is travelling along the top edge to the top right corner, if the height is drag resized, the behaviour is the same as 1 only for the x axis not the y.

4. When the dot is travelling along the bottom edge heading towards x = 0, if the height is drag resized the behaviour is the same 2 only for it's x position not y.

5. When the dot pauses in 1 and 3, the box continues to move down:

    - the box only moves in response to the perspective-origin moving
    - the dot and the perspective-origin are supposed to be in-sync
    - if the dot stops at (0,0) in response to resizing, and the box keeps moving correctly, this means the perspective-origin is moving correctly - therefore the dot must have speeded up or moved forward more than it should have during resize.

6. If I just let the animations play without resizing, the only Ended event I get is from 'perspectiveContainerAnim', nothing for the 'vanishingPointDotAnim'. If I resize the anim area, then at the end of the leg, both Ended events fire, then it goes back to just the Ended event for 'perspectiveContainerAnim' until I resize again.

7. Diagnostic logging in the JS resize handlers (gated on `globalThis.__ELM_MOTION_RESIZE_DEBUG__`) showed that for every single resize command during a drag, the four key values — `commandData.currentY` (Elm physics), `oldVisualPosition.y` (live `getComputedStyle` snapshot), `targetPosition.y` (new keyframe target), and `newCurrentTime` (seek time for the recreated animation) — were in **perfect lockstep** for both `vanishingPointDotAnim` and `perspectiveContainerAnim`. The state pipeline was correct end-to-end; the bug was not a stale-state bug.

   The plateaus in the log (e.g. 30+ consecutive lines all at `currentTime=1665.8`) revealed the root cause: drag-resize events fire at native input cadence, ~30 per displayed frame. `document.timeline.currentTime` only ticks at rAF boundaries, so every same-frame resize sees the same WAAPI clock. Each one was doing a full `animation.cancel()` + recreate, which leaves a brief gap where the element snaps back to its base style. For the dot's `transform: translate3d(...)` — a **compositor-accelerated** property — the GPU layer spent most of each displayed frame at the base position, producing the visible freeze. The container's `perspective-origin` is main-thread painted, so the same churn collapsed into one paint per frame and looked smooth.

### Resolution

Added rAF-coalescing in [js/src/animations.js](js/src/animations.js): incoming resize commands are buffered in a per-`${animGroup}:${property}` pending map and drained by a single `requestAnimationFrame` callback. Each unique key now performs at most one cancel+recreate per displayed frame. The original synchronous worker is preserved as `_resizeTransformAnimationImmediate` for the existing test suite. Regression coverage in [js/tests/resizeCoalescing.test.js](js/tests/resizeCoalescing.test.js).

Fixed.
