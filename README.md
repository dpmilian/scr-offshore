# scr-offshore
Repository for projects made while at sea

<h2>winch-numbers</h2>

Simple python project that recognizes digits off selected regions from the LCD control screen of a 50 ton winch. 
Uses opencv to preprocess and threshold the image, recognize the contours, compare them through a trained K-Nearest Neighbour algorithm and select the best match. 

Training can also be performed with the correct cli parameter <i>learn</i>. Does not process false positives, so will try to match any contour to one of the digits 0 - 9, "-" or ".". Since only the numeric values are required, all expected unrequired contours are trained to be recognized as a "," character, afterwards these values are filtered out.

Minimal Tk gui included to select video source, and the TCP/ serial port to output detected string if required.

Most of the code pulls from open source obtained from The Internet, if it looks like yours, it probably is. 


<h2>fancy-hud</h2>

HUD with 3d like elements and graphing integrated into HD video feed. 

Work in Progress, very early stages!
