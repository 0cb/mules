//multiple leaf separation and LAR macro
//must run through IJ GUI!!

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
	}
}

function processFile(input, output, file) {

	open(input + File.separator + file);

	title = getTitle();
	dotIndex = indexOf(title, ".");
	basename = substring(title, 0, dotIndex);

//#--------------- img processing ---------------#

	run("8-bit");
	run("Auto Threshold", "method=Huang");

// particle analysis and ROI splitting
	run("Analyze Particles...", "  show=Outlines display exclude clear add summarize");
	
	selectWindow(title);

	for (u=0; u<roiManager("count"); ++u) {
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

}

cleanUp();

//#-Closes the "Results" and "Log" windows and all image windows-#
function cleanUp() {
    requires("1.30e");
    if (isOpen("Results")) {
         selectWindow("Results"); 
         run("Close" );
    {
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

