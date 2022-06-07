/*  Multiple Leaf Shapes (mules)
 *   
 *  ImageJ macro used to separate & calculate the leaf aspect ratio (LAR)
 *   for multiple leaves in multple images.
 *   Workflow includes separating & binarizing leaves
 *
 *   Filename:	mules.ijm
 *   Version:	0.3.4
 *
 *   Author:	0cb - Christian Bowman
 *   Creation:	2021-03-25
 *   Updated:	2021-09-05 17:41
 *   Project:	"itwasme-DIA"; Digital image analysis
 *
 *   Usage: Must be run through IJ GUI
 *   0. For analyzing images with multiple plant accessions,
 *	please use "imgSplit" prior to running "mules"
 *   1. Open ImageJ
 *   2. Plugins > Macros > Edit...
 *   3. Run (WITHOUT any images open)
 *   ** Make sure to backup your images prior to running mules.ijm!
 *   4. Select image input/ output directories and what format the images are in
 *   5. After pressing "OK", the screen will flash as IJ processes the images
 *
 *  #--------------- Dependencies ---------------#
 *	ImageJ/ FIJI Plugins: 
 *	'Particles8 ' (Morphology) https://blog.bham.ac.uk/intellimic/g-landini-software/
 *	'Watershed Irregular Features' (BioVoxxel) https://imagej.net/plugins/biovoxxel-toolbox
 */


/* #--------------- Changes ---------------#
 * added    2021-07-03	parameter for single vs multiple leaf analysis
 * removed  2021-07-03	redundant measurments from default "Analyze particles..."
 * added    2021-07-04	dependencies check
 * changed  2021-07-05	how single vs multiple leaves are handled during the LAR measurement step
 * added    2021-07-05	cleaned up step to eliminate background noise in 'single leaf' images
 * fixed    2021-08-04	small leaves were not picked up; reduced surface area requirement for detection 
 * fixed    2021-08-04	no measurements in output when "Measurements" or "Both" selected
 * fixed    2021-08-04	irregular watershed was not being applied to images containing multiple leaves
 * fixed    2021-08-06	full image for detected leaves came out too dim to use
 * fixed    2021-08-06	"Labels" in Results should now be named after their respective leaves
 * added	2021-09-05	red & blue lines for F.diam and breadth
 * 
 * #--------------- Issues ---------------#
 * Non-leaf objects being recognized based on surface area
 *	> adds additional measurements to the output
 *
 * #--------------- Planned ---------------#
 * Toggle for mask output: (object/ background) black/ white or white/ black
 * Renaming for output (user-specs, leading zeros, ...)
 * Petiole Isolation/ crop
 * R workflow integration
 * Filtering based on standard deviation
 *
 * Play around with "Analyze Particles..." settings (circularity and size)
 * Look into "Particles8" settings
 * Functions should be applied ONLY to ROIs to eliminate background noise
 * Reduce conservative nature of parameters to allow for smaller leaves
 *	> requires post-analysis filter
 * 
 */


//#--------------- Opening parameters ---------------#

// Dependencies check
List.setCommands;
//List.getList;    //lists all available plugins
if (List.get("Particles8 ")!="") {
	//plugin is installed
	} else {
		exit("Error: Missing 'Particles8 (Morphology)' plugin");
	} if (List.get("Watershed Irregular Features")!="") {
		//plugin is installed
	} else {
		exit ("Error: Missing 'Watershed Irregular Features (BioVoxxel)' plugin");
	}

#@ File	    (label = "Input directory", style = "directory") input
#@ File	    (label = "Output directory", style = "directory") output
#@ String   (label = "File suffix", value = ".jpg") suffix
#@ String   (label = "Number of leaves per image?", choices=("Single", "Multiple"), style="radioButtonHorizontal") leafchoice
#@ String   (label = "Desired outputs?", choices=("Masks only", "Measurements only", "Both"), style="radioButtonHorizontal") outchoice


//#--------------- Batch function ---------------#

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	
	for (i = 0; i < list.length; i++) {
	    if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			if (outchoice == "Masks only"){
				processMASK(input, output, list[i]);
			} else if (outchoice == "Measurements only") {
				processLAR(input, output, list[i]);
			} else if (outchoice == "Both") {
				// running the same processing twice: 1) save the individual masks, 2) take the measurements
				processMASK(input, output, list[i]);
				processLAR(input, output, list[i]);
			}
	}
}


//#--------------- First Run: Output separate leaf masking ---------------#

function processMASK(input, output, file) {

	open(input + File.separator + file);
	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);

// image processing

	processIMG();
	if (outchoice != "Masks only"){
		run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");
	}

// particle analysis and ROI splitting

	run("Analyze Particles...", "size=5000-Infinity circularity=0.15-1.00 show=Outlines display exclude clear summarize add");
	//run("Analyze Particles...", "size=10000-Infinity circularity=0.40-1.00 show=Outlines display exclude clear summarize add");
	
	selectWindow(title);

	
	//saveAs("PNG", output + File.separator + basename + "_full" + ".png");
    close();
        
	//selectWindow("particles");
        //close();
	
//#--------------- closing time ---------------#

	saveAs("PNG", output + File.separator + file);
	//saveAs("Results", output + File.separator + basename + ".csv");
	run("Clear Results");

    print("Saving to: " + output);
	close();
	cleanUp();
}

//#--------------- Second Run: Measurements for LAR ---------------#
// feel free to comment out 'processFB' function at beginning of file if you don't need LAR

function processLAR(input, output, file) {

	open(input + File.separator + file);
	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);

// image processing

	processIMG();
	if (outchoice != "Masks only"){
		run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");
	}

// particle analysis and ROI splitting

	run("Analyze Particles...", "size=5000-Infinity circularity=0.15-1.00 show=Nothing exclude clear add");
	//run("Analyze Particles...", "size=10000-Infinity circularity=0.40-1.00 show=Outlines display exclude clear summarize add");

	//selectWindow(title);

	if (leafchoice == "Multiple"){
	    count=roiManager("count");
	    array=newArray(count);
	
	    for(u=0; u<count; ++u) {
			array[u] = u;
	    }

	    roiManager("Select", array); 
	    roiManager("Combine");
	    run("Clear Outside");
	    
	} else if (leafchoice == "Single"){
		roiManager("Select", 0);
		run("Clear Outside");
		
	}

	run("Duplicate...", "title=full");
	saveAs("PNG", output + File.separator + file);
	close();
	selectWindow(title);
	
	roiManager("Deselect");
	run("Clear Results");    //remove default measurements
	selectWindow(title);
	    
	run("Particles8 ", "white morphology show=Particles filter minimum=5000 maximum=9999999 display redirect=None");
    numberOfRows = nResults;
	for (row = 0; row < numberOfRows; row++) {

	    Fx1 = getResult("FeretX1", row);
	    Fy1 = getResult("FeretY1", row);
	    Fx2 = getResult("FeretX2", row);
	    Fy2 = getResult("FeretY2", row);

	    Bx1 = getResult("BrdthX1", row);
	    By1 = getResult("BrdthY1", row);
	    Bx2 = getResult("BrdthX2", row);
	    By2 = getResult("BrdthY2", row);

	    makeLine(Fx1, Fy1, Fx2, Fy2);
	    run("Properties... ", "stroke=red width=1");
		run("Add Selection...");

	    makeLine(Bx1, By1, Bx2, By2);
	    run("Properties... ", "stroke=blue width=1");
		run("Add Selection...");
	    
	}
    //close();
        
	//selectWindow("particles");
        //close();

     for (i = 0; i < nResults; i++) {
     	setResult("Label", i, basename + "_leaf" + i + 1);
     }

     
	count = roiManager("count");
	
	for (u = 0; u < count; ++u) {
		run("Duplicate...", "title=crop");
		roiManager("Select", u);
		run("Crop");
		saveAs("PNG", output + File.separator + basename + "_no" + (u+1) + ".png");
		close();
		//Next round!
		selectWindow(title);
	}

	
//#--------------- closing time ---------------#

	saveAs("PNG", output + File.separator + file);    //redundant full image (L204-206)
	saveAs("Results", output + File.separator + basename + ".csv");
	run("Clear Results");

    print("Saving to: " + output);
	close();
	cleanUp();

}

//#--------------- Image processing & masking---------------#
function processIMG() {
    run("Gaussian Blur...", "sigma=4");
    run("Make Binary");
    //run("Fill Holes");
    run("Erode");
    run("Dilate");
    //run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");
    
    //run("8-bit");
    //run("Auto Threshold", "method=Huang");
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
 * sauce:
 * https://forum.image.sc/t/results-table-to-macro/28190/12
 * https://www.youtube.com/watch?reload=9&v=AX4qt2NluAo
 * https://forum.image.sc/t/saving-each-roi-as-individual-images/3227
 * https://forum.image.sc/t/how-to-clear-outside-whith-multiple-rois-on-a-stack/27576/7
 * https://forum.image.sc/t/macro-clear-outside-with-multiple-drawn-shapes/4473/3
 * https://imagej.net/BioVoxxel_Toolbox#Watershed_Irregular_Features
 * http://imagej.1557.x6.nabble.com/Within-my-macro-how-do-I-test-if-a-plugin-is-installed-before-calling-it-td3691533.html
 *
 */

//#--------------- skeletons ---------------#
/*
* draw Feret's diameter and breadth for visualization
*	run("Particles8 ", "white morphology show=Particles minimum=0 maximum=9999999 display redirect=None");
*	numberOfRows = nResults;
*	for (row = 0; row < numberOfRows; row++) {
*
*	    Fx1 = getResult("FeretX1", row);
*	    Fy1 = getResult("FeretY1", row);
*	    Fx2 = getResult("FeretX2", row);
*	    Fy2 = getResult("FeretY2", row);
*
*	    Bx1 = getResult("BrdthX1", row);
*	    By1 = getResult("BrdthY1", row);
*	    Bx2 = getResult("BrdthX2", row);
*	    By2 = getResult("BrdthY2", row);
*
*	    makeLine(Fx1, Fy1, Fx2, Fy2);
*	    run("Properties... ", "stroke=red width=1");
*		run("Add Selection...");
*
*	    makeLine(Bx1, By1, Bx2, By2);
*	    run("Properties... ", "stroke=blue width=1");
*		run("Add Selection...");
*	    
*	}
*/

