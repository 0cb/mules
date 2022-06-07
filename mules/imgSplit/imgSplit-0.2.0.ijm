/* Image Split (imgSplit)
 
    ImageJ macro used to split images into equal cells.
    Requires total cells to be in perfect squares (eg. 4, 9, 16, etc.)

    Filename:	imgSplit.ijm
    Version:	0.2.0

    Author:	0cb - Christian Bowman
    Creation:	2021-03-26
    Updated:	2021-06-21 16:24
    Project:	"itwasme-DIA"; Digital image analysis

    Usage: Must be run through IJ GUI
    1. Open ImageJ
    2. Plugins > Macros > Edit...

	(If single image)
    3a. Open image to split
    4a. "Run" macro
    5a. Screen will flash and separate images will be saved

	(If multiple images)
	** Please refer to "imgSplits" for multiple images
    3b. Do NOT open any images
    4b. "Run" macro (WITHOUT any images open)
    5b. Select image input/ output directories and what format the images are in
    6b. After pressing "OK", the screen will flash as IJ processes the images
*/


//
//removed dialog for repeated measures; n -> nxn grid of the image
//n = getNumber("How many divisions (e.g., 2 means quarters)?", 2);
n = 2
id = getImageID();
title = getTitle();
getLocationAndSize(locX, locY, sizeW, sizeH);
width = getWidth();
height = getHeight();
tileWidth = width / n;
tileHeight = height / n;

for (y = 0; y < n; y++) {
    offsetY = y * height / n;
    for (x = 0; x < n; x++) {
	offsetX = x * width / n;
	selectImage(id);
	call("ij.gui.ImageWindow.setNextLocation", locX + offsetX, locY + offsetY);
	tileTitle = title + " [" + x + "," + y + "]";
	run("Duplicate...", "title=" + tileTitle);
	makeRectangle(offsetX, offsetY, tileWidth, tileHeight);
	run("Crop");
    }
}

selectImage(id);
close();

// get image IDs of all open images
//dir = getDirectory("Choose a Directory");
dir = getDirectory("file");
ids=newArray(nImages);
for (i=0;i<nImages;i++) {
        selectImage(i+1);
        title = getTitle;
        print(title);
        ids[i]=getImageID;

        saveAs("Jpeg", dir+title+ids[i] + ".jpg");
} 

run("Close All");


/*
 * Sauce: 
 * http://imagej.1557.x6.nabble.com/split-image-td5001409.html
 * http://imagej.1557.x6.nabble.com/How-to-save-all-opened-images-td3686986.html
 *
 */
