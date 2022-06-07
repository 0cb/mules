/* Image Split (imgSplit)

    ImageJ macro used to split images into equal cells.
    Image is divided by "n", where n=2 means 4 total cells

    Filename:	imgSplits.ijm
    Version:	0.2.0
    
    Author:	0cb - Christian Bowman
    Creation:	2021-03-26
    Updated:	2021-06-21 16:36
    Project:	"itwasme_DIA"; Digital image analysis

	Usage: Must be run through IJ GUI
    1. Open ImageJ
    2. Plugins > Macros > Edit...

	(If single image)
	** Please refer to "imgSplit" for single images
    3a. Open image to split
    4a. "Run" macro
    5a. Screen will flash and separate images will be saved

	(If multiple images)
    3b. Do NOT open any images
    4b. "Run" macro (WITHOUT any images open)
    5b. Select image input/ output directories and what format the images are in
    6b. After pressing "OK", the screen will flash as IJ processes the images
*/


//#--------------- Batch function ---------------#

#@ File(label = "Input directory", style = "directory") input
#@ File(label = "Output directory", style = "directory") output
#@ String(label = "File suffix", value = ".JPG") suffix

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
	    if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

//#--------------- Split image cells ---------------#

function processFile(input, output, file) {
    print("Processing: " + input + File.separator + file);

	open(input + File.separator + file);

	n = getNumber("How many divisions (e.g., 2 means quarters)?", 2);
	//n = 3
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
	dir = getDirectory("Choose a Directory");
	ids=newArray(nImages);
	for (i=0;i<nImages;i++) {
        selectImage(i+1);
        title = getTitle;
        print(title);
        ids[i]=getImageID;

        saveAs("Jpeg", dir+title+ids[i] + ".jpg");
	} 

	run("Close All");
}


/*
 * Sauce: 
 * http://imagej.1557.x6.nabble.com/split-image-td5001409.html
 * http://imagej.1557.x6.nabble.com/How-to-save-all-opened-images-td3686986.html
 *
 */
