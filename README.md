
AGNSSplitViewDelegate
=============

AGNSSplitViewDelegate is designed to be generic splitview delegate. The problem with splitviews is that some things which should be simple require implementing delegate methods and doing that over and over gets to be really annoying.

For example, even setting a minimum and maximum width for a subview is not trivial. After coming across Matt Gallagher's blog post for priority-based resizing in splitviews, I knew I could use it, but took it to the next level. 

AGNSSplitViewDelegate lets you:

- Specificy uniform, proportional, or priority-based resizing
- Specify min/max sizes for subviews.
- Specify whether a subview can collapse
- Specify which subview is collapsed by a double-click on a divider

Normally to do any of these things you'd have to implement delegate methods yourself (over and over), but now you can just create a generic delegate, call some setters, and you're done.

Note: This code hasn't been bulletproofed, but it's working great so far for me.



AGNSSplitView
=============

AGNSSplitView is a light NSSplitView subclass. All it does is give some control over divider thickness and style with a couple of writable properties. 

- dividerThickness;
- drawsDivider;
- dividerColor;
- dividerLineEdge;
- drawsDividerHandle;

Nothing major, but here if you want it.
