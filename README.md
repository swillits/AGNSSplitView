
AGNSSplitViewDelegate
=============

AGNSSplitViewDelegate is designed to be generic splitview delegate. The problem with 
splitviews is that some things which should be simple require implementing unintuitive
delegate methods, which gets to be pretty annoying.

For example, even setting a minimum and maximum width for a subview is not trivial. 
After coming across Matt Gallagher's blog post for priority-based resizing in 
splitviews, I knew I could use it as is, but took it to the next level. 

AGNSSplitViewDelegate lets you:

- Specificy uniform, proportional, or priority-based resizing
- Specify min/max sizes for subviews.
- Specify whether a subview can collapse
- Specify which subview is collapsed by a double-click on a divider

Normally to do any of these things you'd have to implement delegate methods yourself 
(over and over), but now you can just create a generic delegate, call some setters, 
and you're done.

Note: This code hasn't been proven bulletproof, but it's working great so far for me.



AGNSSplitView
=============

AGNSSplitView is a light NSSplitView subclass. All it does is give some control over 
divider thickness and style with a couple of writable properties. 

- dividerThickness;
- drawsDivider;
- dividerColor;
- dividerLineEdge;
- drawsDividerHandle;

Nothing major, but here if you want it.



Requirements
=============

There are no OS requirements for this code. It'll work in the old and new
runtimes, does not use garbage collection, and is not ARC-ified yet.



License
=============

Copyright (c) 2012, Seth Willits — Araelium Group

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies 
or substantial portions of the Software.

The Software is provided "as is", without warranty of any kind, express or implied, 
including but not limited to the warranties of merchantability, fitness for a 
particular purpose and noninfringement. In no event shall the authors or copyright 
holders be liable for any claim, damages or other liability, whether in an action of 
contract, tort or otherwise, arising from, out of or in connection with the Software 
or the use or other dealings in the Software.

--

In plain English: do whatever you want with it, and no you do not need to give me
credit in your application/documentation. 


