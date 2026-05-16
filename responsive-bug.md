# Responsive Bug

## Description

There are two examples with conflicting bugs - fix one -> create the other, fix the other -> create the first. Both relate to when the page is resized by the user.

## Examples

WAAPI/Animate3D
WAAPI/ResponsiveAnimations/Responsive

## Animate3D Bug

When the user resizes the page the spinning cube animation would restart. This was fixed, leading to another bug whereby there would be a visible 'flash/flicker' when the first Sides animation completed, and the next animation (rotate cube) begins. The 'flicker' is a single frame error, where the cube reduces in size for the one frame.

### Status

Fixed -
