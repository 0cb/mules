/* Multiple Leaf Shapes (mules)
 *   
 *  ImageJ macro used to separate & calculate the leaf aspect ratio (LAR)
 *   for multiple leaves in multple images.
 *   Workflow includes separating & binarizing leaves
 *
 *   Filename:	mules.ijm
 *   Version:	0.4.3
 *
 *   Author:	0cb - Christian Bowman
 *   Creation:	2021-03-25
 *   Updated:	2021-12-03 09:31
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
 *	ImageJ/ FIJI ver:
 *	2.3.0/1.53f51; Java 1.8.0_172
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
 * added    2021-08-09	option for .jpg or .png output images
 * added    2021-10-15	"advanced options" section; red & blue lines for F.diam & breadth
 * added    2021-10-16	"advanced options" section; pick up small leaves (area = 1000px)
 * changed  2021-11-15	method for drawing breadth; clarification for how breadth is actually measured
 * fixed    2021-11-16	colors should be fixed now for line drawing
 * added    2021-11-16	"advanced options" section; swap between white/black and black/white 
 * added    2021-11-16	leading zeros for output files
 * added    2021-11-19	"advanced options" section; small or detailed results option
 * added    2021-12-03	single line measurement between breadth points (for offset)
 *
 * #--------------- Issues ---------------#
 * Non-leaf objects being recognized based on surface area
 *	> adds additional measurements to the output
 *
 * #--------------- Planned ---------------#
 * Renaming for output (user-specs, leading zeros, ...)
 * Petiole Isolation/ crop
 * R workflow integration
 * Elliptic Fourier Descriptors
 * Filter based on standard deviation (post-processing)
 * PCA, Umap(?)
 * degree of offset for 'FBrdth'
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
#@ String   (label = "Input file suffix", value = ".jpg") suffixin
#@ String   (label = "Output file suffix", choices=(".jpg", ".png"), style="radioButtonHorizontal") suffixout
#@ String   (label = "Number of leaves per image?", choices=("Single", "Multiple"), style="radioButtonHorizontal") leafchoice
#@ String   (label = "Desired outputs?", choices=("Masks only", "Measurements only", "Both"), style="radioButtonHorizontal") outchoice

#@ String   (value = "<html>Advanced options<br/>(Optional)", visibility="MESSAGE") advanced
#@ String   (label = "Colored Feret's diameter and breadth lines?", choices=("yes", "no"), style="radioButtonHorizontal") redblue
#@ String   (label = "Small leaves? (May pick up more non-leaf objects)", choices=("yes", "no"), value="no", persist=false, style="radioButtonHorizontal") smleaf
#@ String   (label = "Black leaves on white background?", choices=("yes", "no"), style="radioButtonHorizontal") bwbg
#@ String 	(label = "Detailed measurements file?", choices=("yes", "no"), style="radioButtonHorizontal") rsmall

//value="no", persist=false,

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

	if (smleaf == "yes"){
		run("Analyze Particles...", "size=1000-Infinity circularity=0.15-1.00 show=Outlines display exclude clear summarize add");
	} else if (smleaf == "no"){
		run("Analyze Particles...", "size=5000-Infinity circularity=0.15-1.00 show=Outlines display exclude clear summarize add");
	}
	//run("Analyze Particles...", "size=5000-Infinity circularity=0.15-1.00 show=Outlines display exclude clear summarize add");
	//run("Analyze Particles...", "size=10000-Infinity circularity=0.40-1.00 show=Outlines display exclude clear summarize add");
	
	selectWindow(title);

	if (bwbg == "yes") {
			run("Invert LUT");
		}

	if (redblue == "no"){

	    count = roiManager("count");
	
	    for (u = 0; u < count; ++u) {
		run("Duplicate...", "title=crop");
		roiManager("Select", u);
		run("Crop");

		idx = u + 1;
		
		if (suffixout == ".jpg"){
			saveAs("jpeg", output + File.separator + basename + "_" + IJ.pad(idx, 3) + ".jpg");
		} else if (suffixout == ".png"){
			saveAs("png", output + File.separator + basename + "_" + IJ.pad(idx, 3) + ".png");
		}
		
		close();
		//Next round!
		selectWindow(title);
	    }
	}
	
	//saveAs("PNG", output + File.separator + basename + "_full" + ".png");
    close();
        
	//selectWindow("particles");
        //close();
	
//#--------------- closing time ---------------#

	if (suffixout == ".jpg"){
			saveAs("jpeg", output + File.separator + file);
		} else if (suffixout == ".png"){
			saveAs("png", output + File.separator + file);
	}
	//saveAs("PNG", output + File.separator + file);
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

	if (smleaf == "yes"){
		run("Analyze Particles...", "size=1000-Infinity circularity=0.15-1.00 show=Nothing exclude clear add");
	} else if (smleaf == "no"){
		run("Analyze Particles...", "size=5000-Infinity circularity=0.15-1.00 show=Nothing exclude clear add");
	}
		
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
	
	if (suffixout == ".jpg"){
			saveAs("jpeg", output + File.separator + file);
		} else if (suffixout == ".png"){
			saveAs("png", output + File.separator + file);
	}
		
	close();
	selectWindow(title);
	
	roiManager("Deselect");
	run("Clear Results");    //remove default measurements
	selectWindow(title);

	if (smleaf == "yes"){
		run("Particles8 ", "white morphology show=Particles filter minimum=1000 maximum=9999999 display redirect=None");
	} else if (smleaf == "no"){
		run("Particles8 ", "white morphology show=Particles filter minimum=5000 maximum=9999999 display redirect=None");
	}
	    
	//run("Particles8 ", "white label morphology show=Particles filter minimum=5000 maximum=9999999 display redirect=None");

// table building
	numberOfRows = nResults;
	    for (row = 0; row < numberOfRows; row++) {

		Fer = getResult("Feret", row);
		Fx1 = getResult("FeretX1", row);
		Fy1 = getResult("FeretY1", row);
		Fx2 = getResult("FeretX2", row);
		Fy2 = getResult("FeretY2", row);
	    
		Bx1 = getResult("BrdthX1", row);
		By1 = getResult("BrdthY1", row);
		Bx2 = getResult("BrdthX2", row);
		By2 = getResult("BrdthY2", row);

		rd1 = ((Bx1-Fx1)*(Fx2-Fx1)+(By1-Fy1)*(Fy2-Fy1))/(Fer*Fer);
      	Px1 = Fx1+rd1*(Fx2-Fx1);
      	Py1 = Fy1+rd1*(Fy2-Fy1);
      	Ln1 = sqrt((Bx1-Px1)*(Bx1-Px1)+(By1-Py1)*(By1-Py1));
      	
      	rd2 = ((Bx2-Fx1)*(Fx2-Fx1)+(By2-Fy1)*(Fy2-Fy1))/(Fer*Fer);
      	Px2 = Fx1+rd2*(Fx2-Fx1);
      	Py2 = Fy1+rd2*(Fy2-Fy1);
      	Ln2 = sqrt((Bx2-Px2)*(Bx2-Px2)+(By2-Py2)*(By2-Py2));
      	PLn = Ln1+Ln2;

      	Ln3 = sqrt((Bx1-Fx1)*(Bx1-Fx1)+(By1-Fy1)*(By1-Fy1));
      	
	setResult("PrLen1", row, Ln1);
      	setResult("PrLen2", row, Ln2);
      	setResult("PBrdth", row, PLn);
	setResult("FBrdth", row, Ln3);
      	updateResults();
	
   
// red and blue lines
	if (redblue == "yes"){
	    
		//Feret's
		makeLine(Fx1, Fy1, Fx2, Fy2);
		run("Colors...", "foreground=white background=black selection=red");
		run("Add Selection...");
		//Roi.setStrokeColor("red"); //adding lines to ROI puts them in queue for cropping & causes error
      	//roiManager("add & draw");

		//Breadth - perpendicular to Feret's
      	
      	makeLine(Bx1, By1, Px1, Py1);
		run("Colors...", "foreground=white background=black selection=blue");
		run("Add Selection...");

      	makeLine(Bx2, By2, Px2, Py2);
		run("Colors...", "foreground=white background=black selection=blue");
		run("Add Selection...");
	    }
	}

    //close();
        
	//selectWindow("particles");
        //close();
		
     for (i = 0; i < nResults; i++) {
     	idx = i + 1;
     	setResult("Label", i, basename + "_leaf" + IJ.pad(idx, 3));
     }

	if (bwbg == "yes") {
			run("Invert LUT");
		}

	if (redblue == "yes"){

	    count = roiManager("count");
		
	    for (u = 0; u < count; ++u){
		run("Duplicate...", "title=crop");
		roiManager("Select", u);
		run("Crop");

		idx = u + 1;
		
		if (suffixout == ".jpg"){
			saveAs("jpeg", output + File.separator + basename + "_" + IJ.pad(idx, 3) + ".jpg");
		} else if (suffixout == ".png"){
			saveAs("png", output + File.separator + basename + "_" + IJ.pad(idx, 3) + ".png");
		}
		close();
		//Next round!
		selectWindow(title);
	    }
	}

	if (rsmall == "yes") {
		saveAs("Results", output + File.separator + basename + "_detailed" + ".csv");
	}

// Small table
// sauce: https://gist.github.com/lacan/6b40bba1f878f332b7dbb7468be2fbc8
	nR = nResults;
	Lab = newArray(nR);
	Are = newArray(nR);
	Fer = newArray(nR);
	Fx1 = newArray(nR);
	Fy1 = newArray(nR);
	Fx2 = newArray(nR);
	Fy2 = newArray(nR);
	Brd = newArray(nR);
	Bx1 = newArray(nR);
	By1 = newArray(nR);
	Bx2 = newArray(nR);
	By2 = newArray(nR);
	Asp = newArray(nR);
	Ln1 = newArray(nR);
	Ln2 = newArray(nR);


	// Grab the old results
	for (i=0; i<nR;i++) {
		Lab[i] = getResultLabel(i);
		Are[i] = getResult("Area", i);
		Fer[i] = getResult("Feret", i);
		Fx1[i] = getResult("FeretX1", i);
		Fy1[i] = getResult("FeretY1", i);
		Fx2[i] = getResult("FeretX2", i);
		Fy2[i] = getResult("FeretY2", i);
	    Brd[i] = getResult("Breadth", i);
		Bx1[i] = getResult("BrdthX1", i);
		By1[i] = getResult("BrdthY1", i);
		Bx2[i] = getResult("BrdthX2", i);
		By2[i] = getResult("BrdthY2", i);
		Asp[i] = getResult("AspRatio", i);
		Ln1[i] = getResult("PrLen1", i);
		Ln2[i] = getResult("PrLen2", i);
		Ln3[i] = getResult("FBrdth", i);
	}
	
	// Rename the old table
	IJ.renameResults("Raw Results");

	// Make the new table
	for (i=0; i<nR;i++) {
		setResult("Label", i, Lab[i]);
		setResult("Area", i, Are[i]);
      	setResult("Feret", i, Fer[i]);
      	setResult("FeretX1", i, Fx1[i]);
		setResult("FeretY1", i, Fy1[i]);
      	setResult("FeretX2", i, Fx2[i]);
      	setResult("FeretY2", i, Fy2[i]);
      	setResult("Breadth", i, Brd[i]);
      	setResult("BrdthX1", i, Bx1[i]);
      	setResult("BrdthY1", i, By1[i]);
      	setResult("BrdthX2", i, Bx2[i]);
      	setResult("BrdthY2", i, By2[i]);
      	setResult("AspRatio", i, Asp[i]);
	setResult("PrLen1", i, Ln1[i]);
      	setResult("PrLen2", i, Ln2[i]);
	setResult("FBrdth", i, Ln3[i]);
	}
	updateResults();
	
//#--------------- closing time ---------------#

	//saveAs("PNG", output + File.separator + file);    //redundant full image (L204-206)

	saveAs("Results", output + File.separator + basename + "_simple" + ".csv");
	run("Clear Results");

    print("Saving to: " + output);
	close();
	cleanUp();

}

//#--------------- Image processing & masking---------------#
function processIMG() {
    run("Gaussian Blur...", "sigma=4");
    setOption("BlackBackground", true); //defaults to white background for first run only...
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
    if (isOpen("Raw Results")) {
         selectWindow("Raw Results"); 
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
    if (isOpen("Summary")) {
    	selectWindow("Summary");
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

