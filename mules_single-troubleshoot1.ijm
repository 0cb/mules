title = getTitle();
	
run("Gaussian Blur...", "sigma=4");
run("Make Binary");
	//run("Fill Holes");
	//run("Watershed");
run("Erode");
run("Dilate");
run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");

	//run("8-bit");
	//run("Auto Threshold", "method=Huang");

	
// particle analysis and ROI splitting
// make changes to the below function for troubleshooting at the "circularity" value
run("Analyze Particles...", "size=10000-Infinity circularity=0.00-1.00 show=Outlines display exclude clear summarize add");

selectWindow(title);

count=roiManager("count");
array=newArray(count);

for(i=0; i<count;i++) {
        array[i] = i;
}

roiManager("Select", array); 
roiManager("Combine");
//run("Clear Outside");
roiManager("Deselect");

selectWindow(title);

run("Particles8 ", "white morphology show=Particles minimum=0 maximum=9999999 display redirect=None");

