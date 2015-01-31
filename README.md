## Bouncing-Heart
Valentine's day HTML5 toy - draw a heart and then throw it around! 

[Try it out in your browser now][1].

Calculates the relative mass and moment of the drawn heart, then animates it with Euler's method. Deals with rigid body collisions between the heart and the wall realistically.

[1]: http://rawgit.com/harpocrates/Bouncing-Heart/master/Bouncing%20Heart.html "Bouncing Heart"

## Instructions
Draw a heart (or really any shape) by holding your mouse down as you trace the outline of the desired heart. Once done, the heart should be filled. Then, click and drag to throw it around and watch it bounce and spin off the walls. To catch it/throw it again, click on it and drag.

## Pending developments
Make the heart shatter into pieces (pieces won't interact with each other, just with walls and floor) after a threshold of total impulse transferred. Challenges to face:
  * drawing cracks on the heart (variable stroke width for moving cracks - Maybe like [this](http://stackoverflow.com/questions/12844491/drawing-lines-with-continuously-varying-line-width-on-html-canvas))
  * implementing some polygon clipping algorithm to calculate the shape of pieces. Sticking to convex pieces will allow use of the relatively simpler Sutherland–Hodgman algorithm.
