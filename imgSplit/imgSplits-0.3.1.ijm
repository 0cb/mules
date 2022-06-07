/* Image Split (imgSplit)

    ImageJ macro used to split images into equal cells.
    Image is divided by "n", where n=2 means 4 total cells
    Can be applied to entire image directories

    Filename:	imgSplits.ijm
    Version:	0.3.0
    
    Author:	0cb - Christian Bowman
    Creation:	2021-03-26
    Updated:	2021-07-23 16:27
    Project:	"itwasme-DIA"; Digital image analysis

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


//#--------------- Opening parameters ---------------#

#@ File	    (label = "Input directory", style = "directory") input
#@ File	    (label = "Output directory", style = "directory") output
#@ String   (label = "Input file suffix", value = ".jpg") suffixin
#@ String   (label = "Output file suffix", choices=(".jpg", ".png"), style="radioButtonHorizontal") suffixout

n = getNumber("How many divisions (e.g., 2 means quarters)?", 2);
//n = 3

//#--------------- Batch function ---------------#

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	
	for (i = 0; i < list.length; i++) {
	    if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffixin))
			processFile(input, output, list[i]);
	}
}

//#--------------- Split image cells ---------------#

function processFile(input, output, file) {
    print("Processing: " + input + File.separator + file);

	open(input + File.separator + file);
	id = getImageID();
	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);
	
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
		//selectWindow(title);
		
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
	ids=newArray(nImages);

	for (i = 0; i < nImages; i++) {
        selectImage(i+1);
        title = getTitle();
        print(title);
        //ids[i]=getImageID();

        idx = (i+1);
		if (suffixout == ".jpg"){
			saveAs("jpeg", output + File.separator + basename + "_no" + idx + ".jpg");
		} else if (suffixout == ".png"){
			saveAs("png", output + File.separator + basename + "_no" + idx + ".png");
		}
        
	} 

	//cleanUp();
	run("Close All");
	print("Completed: " + input + File.separator + file);
}

//#--------------- Close open windows ---------------# 
function cleanUp() {
    requires("1.30e");
    if (isOpen("Results")) {
         selectWindow("Results"); 
         run("Close");
    }
    if (isOpen("Log")) {
         selectWindow("Log");
         run("Close");
    }
    if (isOpen("ROI Manager")) {
    	selectWindow("ROI Manager");
    	run("Close");
    }
    while (nImages()>0) {
          selectImage(nImages());  
          run("Close");
    }
}


/*
 * Sauce: 
 * http://imagej.1557.x6.nabble.com/split-image-td5001409.html
 * http://imagej.1557.x6.nabble.com/How-to-save-all-opened-images-td3686986.html
 *
 */
