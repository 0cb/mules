title = getTitle();

// options

processIMG();
partROI();
morphoDraw();
resFilter();
//perpLine();
//cleanUp();
testingblock();




function processIMG() {	
	run("Gaussian Blur...", "sigma=4");
	setOption("BlackBackground", true); //defaults to white background for first run only...
	run("Make Binary");
	//run("Fill Holes");
	//run("Watershed");
	run("Erode");
	run("Dilate");
	run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");

	//run("8-bit");
	//run("Auto Threshold", "method=Huang");
}

function partROI() {
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
	run("Clear Outside");
	roiManager("Deselect");
	run("Clear Results");
}

function morphoDraw() {
	selectWindow(title);

	run("Particles8 ", "white morphology show=Particles minimum=0 maximum=9999999 display redirect=None");

	numberOfRows = nResults;
	    for (row = 0; row < numberOfRows; row++) {

		Are = getResult("Area", row);
		Fer = getResult("Feret", row);
		Fx1 = getResult("FeretX1", row);
		Fy1 = getResult("FeretY1", row);
		Fx2 = getResult("FeretX2", row);
		Fy2 = getResult("FeretY2", row);

	    Brd = getResult("Breadth", row);
		Bx1 = getResult("BrdthX1", row);
		By1 = getResult("BrdthY1", row);
		Bx2 = getResult("BrdthX2", row);
		By2 = getResult("BrdthY2", row);

		Asp = getResult("AspRatio", row);

		//Feret's
		makeLine(Fx1, Fy1, Fx2, Fy2);
		run("Colors...", "foreground=white background=black selection=red");
		run("Add Selection...");
		//Roi.setStrokeColor("red"); //adding lines to ROI puts them in queue for cropping & causes error
      	//roiManager("add & draw");

		//Breadth - perpendicular to Feret's
      	rd1 = ((Bx1-Fx1)*(Fx2-Fx1)+(By1-Fy1)*(Fy2-Fy1))/(Fer*Fer);
      	Px1 = Fx1+rd1*(Fx2-Fx1);
      	Py1 = Fy1+rd1*(Fy2-Fy1);
      	Ln1 = sqrt((Bx1-Px1)*(Bx1-Px1)+(By1-Py1)*(By1-Py1));
      	makeLine(Bx1, By1, Px1, Py1);
		run("Colors...", "foreground=white background=black selection=blue");
		run("Add Selection...");

      	rd2 = ((Bx2-Fx1)*(Fx2-Fx1)+(By2-Fy1)*(Fy2-Fy1))/(Fer*Fer);
      	Px2 = Fx1+rd2*(Fx2-Fx1);
      	Py2 = Fy1+rd2*(Fy2-Fy1);
      	Ln2 = sqrt((Bx2-Px2)*(Bx2-Px2)+(By2-Py2)*(By2-Py2));
      	makeLine(Bx2, By2, Px2, Py2);
		run("Colors...", "foreground=white background=black selection=blue");
		run("Add Selection...");

		PLn = Ln1+Ln2;

      	setResult("PrLen1", row, Ln1);
      	setResult("PrLen2", row, Ln2);
      	setResult("PBrdth", row, PLn);
      	updateResults();

	    }	    
}

function perpLine() {
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

		lineEq(Fx1, Fy1, Fx2, Fy2, Bx1, By1, Bx2, By2, bound_y1, bound_y2);


		
	}
}

function lineEq( x_1, y_1, x_2, y_2, x_3, y_3, x_4, y_4, bound_y1, bound_y2 ) {
	// hot sauce: https://www.geeksforgeeks.org/program-for-point-of-intersection-of-two-lines/
	//return sqrt( pow( x_0 - x_1, 2 ) + pow( y_0 - y_1, 2 ) );
	m = (y_2 - y_1)/(x_2 - x_1);
	mperp = -(1/m);
	
	//lineAB: a1x + b1y = c1
	a1 = y_2 - y_1;
	b1 = x_1 - x_2;
	c1 = a1*(x_1) + b1*(y_1);

	//lineCD: a2x + b2y = c2
	a2 = y_4 - y_3;
	b2 = x_3 - x_4;
	c2 = a2*(x_3) + b2*(y_3);

	detrm = a1*b2 - a2*b1;

	x_0 = (b2*c1 - b1*c2)/detrm;
	y_0 = (a1*c2 - a2*c1)/detrm;

	makePoint(x_0, y_0);
	roiManager("add & draw");

	makeOval(x_0, y_0, 10, 10);
	run("Properties...", "stroke=blue width=1");
	run("Add Selection...");

	print("a1",a1);
	print("b1",b1);
	print("c1",c1);
	print("m",m);
	print("mperp",mperp);
	print("x_0",x_0);
	print("y_0",y_0);

	//attempt: https://stackoverflow.com/questions/62866298/how-to-draw-a-line-on-an-image-given-the-slope-and-the-intercept-coordinates-x
	q = y_0 - (mperp*x_0);
    new_x1 = x_0 + 50;
    new_y1 = (mperp*new_x1) + q;
    bound_x1 = (new_y1-q)/mperp;
    //bound_y1;
    new_x2 = x_0 - 50;
    new_y2 = (mperp*new_x2) + q;
    bound_x2 = (new_y2-q)/mperp;
    //bound_y2;

	makeLine(new_x1, new_y1, new_x2, new_y2);
	//makeLine(bound_x1, new_y1, bound_x2, new_y2);
	//makeLine(new_x1, bound_y1, new_x2, bound_y2);
	roiManager("add & draw");
	
	//other attempts: https://stackoverflow.com/questions/62866298/how-to-draw-a-line-on-an-image-given-the-slope-and-the-intercept-coordinates-x
	// https://stackoverflow.com/questions/7941226/how-to-add-line-based-on-slope-and-intercept-in-matplotlib/52951876#52951876
	// https://forum.image.sc/t/perpendicular-distance-between-2-lines-shortest-distance-between-2-lines/3862/5
	// https://forum.image.sc/t/line-tool-to-roi-manager-with-different-colors/8090
    
}

function resFilter() {
// Small table
	nR = nResults;
	//Lab = newArray(nR);
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
		//Lab[i] = getResultLabel(i);
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
	}

	// Rename the old table
	IJ.renameResults("Raw Results");

	// Make the new table
	for (i=0; i<nR;i++) {
		//setResult("Label", i, Lab[i]);
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
	}
	updateResults();
}

//-testing block-//
function testingblock() {

	nAR = nResults;
	rats = newArray(nAR);

	
	for (i=0; i<nAR;i++) {
		rats[i] = getResult("AspRatio", i);
		getStatistics(area, mean);
		//rats[i-1] = mean;
	}
	Array.getStatistics(rats, min, max, mean, stdDev);
	print("");
   	print("n: "+nAR);
   	print("mean: "+mean);
  	print("stdDev: "+stdDev);
   	print("min: "+min);
   	print("max: "+max);

//next steps: 
//	- add numeric labels to images
//	- add "_potOL" to label for potential outliers

}




//---------------//

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
