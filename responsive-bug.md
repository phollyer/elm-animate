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



