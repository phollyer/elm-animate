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






