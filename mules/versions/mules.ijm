/*
*=									   =*
*   Filename:	    mules.ijm
*   Version:	    2.0
*=									   =*
*   Description:    Multiple Leaf Separation (mules)
*		    > separate & binarize multiple leaves from a single image
*		    > calculate Feret's diameter & breadth for leaf aspect ratio (LAR)
*   
*   Usage:	    Must be loaded & run through ImageJ frontend
*
*=  Author:	    0cb - Christian Bowman				   =*
*   Creation:	    2021-03-25
*   Updated:	    
*
*   Project:	    "itwasme-DIA"; Digital image analysis
*=									   =*
*/


//multiple leaf separation and LAR macro
//must run through IJ GUI!!


/* #--------------- Dependencies ---------------#
 * Plugins: Morphology (Particles8), BioVoxxel(Watershed Irregular Features)
 *
 */


#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".JPG") suffix

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
			processFile(input, output, list[i]);
			processFB(input, output, list[i]);    // COMMENT THIS LINE OUT IF YOU DON'T NEED LAR MEASUREMENTS
	}
}

function processFile(input, output, file) {

	open(input + File.separator + file);

	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);

//#--------------- img processing ---------------#

	run("Gaussian Blur...", "sigma=4");
	run("Make Binary");
	//run("Fill Holes");    //sometimes fills entire image
	run("Erode");
	run("Dilate");
	run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");

	//run("8-bit");    //Thesholding not always optimal
	//run("Auto Threshold", "method=Huang");

	
// particle analysis and ROI splitting
	run("Analyze Particles...", "size=10000-Infinity circularity=0.40-1.00 show=Outlines display exclude clear summarize add");
	
	selectWindow(title);

	count=roiManager("count");
	
	for (u=0; u<count; ++u) {
            
            run("Duplicate...", "title=crop");
            roiManager("Select", u);
            run("Crop");
            saveAs("PNG", output + File.separator + basename + "_no" + (u+1) + ".png");
            close();
             //Next round!
             selectWindow(title);

        }
		
    close();
        
	//selectWindow("particles");
        //close();
	
//#--------------- closing time ---------------#

	saveAs("PNG", output + File.separator + file);

	saveAs("Results", output + File.separator + basename + ".csv");
	run("Clear Results");

    print("Saving to: " + output);
	close();

	cleanUp();
}

//#--------------- Second run for LAR ---------------#
// feel free to comment out 'processFB' function at beginning of file if you don't need LAR


function processFB(input, output, file) {

	open(input + File.separator + file);

	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);

//#--------------- img processing ---------------#

	run("Gaussian Blur...", "sigma=4");
	run("Make Binary");
	//run("Fill Holes");
	run("Erode");
	run("Dilate");
	run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");

	//run("8-bit");
	//run("Auto Threshold", "method=Huang");

	
// particle analysis and ROI splitting
	run("Analyze Particles...", "size=10000-Infinity circularity=0.40-1.00 show=Outlines display exclude clear summarize add");
	
	selectWindow(title);

	count=roiManager("count");
	array=newArray(count);
	for(u=0; u<count; ++u) {
		array[u] = u;
	}

	roiManager("Select", array); 
	roiManager("Combine");
	run("Clear Outside");
	roiManager("Deselect");

	selectWindow(title);

	run("Particles8 ", "white morphology show=Particles minimum=0 maximum=9999999 display redirect=None");
		
    close();
        
	//selectWindow("particles");
        //close();
	
//#--------------- closing time ---------------#

	saveAs("PNG", output + File.separator + file);

	saveAs("Results", output + File.separator + basename + ".csv");
	run("Clear Results");

    print("Saving to: " + output);
	close();

	cleanUp();

}



//#-Closes the "Results" and "Log" windows and all image windows-#
function cleanUp() {
    requires("1.30e");
    if (isOpen("Results")) {
         selectWindow("Results"); 
         run("Close" );
    }
    if (isOpen("Log")) {
         selectWindow("Log");
         run("Close" );
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

