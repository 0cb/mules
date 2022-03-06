title = getTitle();

// options

//processIMG();
processIMG2();
partROI();
morphoDraw();
resFilter();
//perpLine();
//cleanUp();
testingblock();



function processIMG() {	
	run("Gaussian Blur...", "sigma=4");
	setOption("BlackBackground", false); //defaults to white background for first run only...
	run("Make Binary");
	//run("Fill Holes");
	//run("Watershed");
	run("Erode");
	run("Dilate");
	run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-100");    //100(norm); 250(overlap)
	//run("Watershed Irregular Features", "erosion=1 convexity_threshold=0 separator_size=0-250");    //100(norm); 250(overlap)

	//run("8-bit");
	//run("Auto Threshold", "method=Huang");
}

function processIMG2() {
	run("8-bit");
	setThreshold(15, 255);
	run("Convert to Mask");
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
	}
	updateResults();
}

//-testing block-//

function testingblock() {

// stdDev filter only works with leaves in current image; need to be able to apply over extended set
	cutoff = 0.375;  // stdDev cutoff for filtering
	nAR = nResults;
	labs = newArray(nAR);
	rats = newArray(nAR);

	for (i = 0; i < nAR; i++) {
     	idx = i + 1;
     	setResult("Label", i, "leaf" + IJ.pad(idx, 3));
     }

	//-populate array-
	for (i=0; i<nAR;i++) {
		labs[i] = getResultLabel(i);
		rats[i] = getResult("AspRatio", i);
		getStatistics(area, mean);
		//rats[i-1] = mean;
	}
   	//----------------

	//-initial stats-
		Array.getStatistics(rats, min, max, mean, stdDev);
		print("");
		print("rats");
   		print("n: "+rats.length);
   		print("mean: "+mean);
  		print("stdDev: "+stdDev);
   		print("min: "+min);
   		print("max: "+max);
   		Array.show(rats);
   	//----------------

   	//-filter-
   		if(stdDev > cutoff){
   			cutFilter();
   		}
   	//--------
}

function cutFilter() {
	print("stdDev is larger than "+cutoff+". Running filter");
	labsF = Array.copy(labs);
	ratsF = Array.copy(rats);
	Array.show(ratsF);
			////
	Array.getStatistics(ratsF, min, max, mean, stdDev);
	upperBound = mean + stdDev;
	lowerBound = mean - stdDev;
	
	print("");
	print("ratsF");
	print("n: "+ratsF.length);
   	print("mean: "+mean);
  	print("stdDev: "+stdDev);
   	print("min: "+max);
   	print("max: "+min);
   	print("max cutoff: "+upperBound);
	print("min cutoff: "+lowerBound);

	labsOut = newArray(ratsF.length);
	ratsOut = newArray(ratsF.length);

   	for (j=0; j<ratsF.length; j++) {
   		if(ratsF[j] > upperBound) {
   			print("max outlier ID: "+labsF[j]);
   			// if outlier ID, then setResult("Label", i, basename + "outlier" + IJ.pad(idx, 3));
   			labsOut[j] = labsF[j];
   			ratsOut[j] = ratsF[j];
   		} else {
   			if(ratsF[j] < lowerBound) {
   				print("min outlier ID: "+labsF[j]);
   				labsOut[j] = labsF[j];
   				ratsOut[j] = ratsF[j];
   			}
   		}
   	}
	//Array.deleteIndex() does not work here for some reason
	labsOut = Array.deleteValue(labsOut, 0);
	ratsOut = Array.deleteValue(ratsOut, 0.000);
	Array.show(ratsOut);

	//-array magic-
	labsDiff = ArrayDiff(labsF, labsOut);
	ratsDiff = ArrayDiff(ratsF, ratsOut);
	Array.show(ratsDiff);

	Array.getStatistics(ratsDiff, min, max, mean, stdDev);
	print("");
	print("ratsDiff");
	print("n: "+ratsDiff.length);
   	print("mean: "+mean);
  	print("stdDev: "+stdDev);
   	print("max: "+max);
   	print("min: "+min);

	labs = Array.copy(labsDiff);
	rats = Array.copy(ratsDiff);

	if(stdDev > cutoff) {
		cutFilter();
	}
} ///make array at bottom of function and before function call
	

	//function index(a, value) {
		///https://stackoverflow.com/questions/48206332/printing-array-items-by-index-number-in-imagej-fiji
		///i = index(rats, stdDev);
		///print("indicies: "+i); 
		//for (i=0; i<a.length; i++) 
      	//if (a[i] > value) return i; 
    //return -1; 
 	//} 

//next steps: 
//	- add numeric labels to images
//	- add "_potOL" to label for potential outliers

//}




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


//graveyard
// -- used for stdDev filtering
//table_name = "Outliers"
//	table_cols = newArray("Max", "Min");
//	newTable(table_name, table_cols);

//	function newTable(table_name, table_cols) {
//		Table.create(table_name);
//		for (i=0; i<table_cols.length; i++) {
//			selectWindow(table_name);
//			Table.set(table_cols[i], 0, 0);
//		}
//	Table.deleteRows(0, 0, table_name);
//	}


// F U N C T I O N S .....................................................
function ArrayUnion(array1, array2) {
	unionA = newArray();
	for (i=0; i<array1.length; i++) {
		for (j=0; j<array2.length; j++) {
			if (array1[i] == array2[j]){
				unionA = Array.concat(unionA, array1[i]);
			}
		}
	}
	return unionA;
}
// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
function ArrayDiff(array1, array2) {
	diffA	= newArray();
	unionA 	= newArray();	
	for (i=0; i<array1.length; i++) {
		for (j=0; j<array2.length; j++) {
			if (array1[i] == array2[j]){
				unionA = Array.concat(unionA, array1[i]);
			}
		}
	}
	c = 0;
	for (i=0; i<array1.length; i++) {
		for (j=0; j<unionA.length; j++) {
			if (array1[i] == unionA[j]){
				c++;
			}
		}
		if (c == 0) {
			diffA = Array.concat(diffA, array1[i]);
		}
		c = 0;
	}
	for (i=0; i<array2.length; i++) {
		for (j=0; j<unionA.length; j++) {
			if (array2[i] == unionA[j]){
				c++;
			}
		}
		if (c == 0) {
			diffA = Array.concat(diffA, array2[i]);
		}
		c = 0;
	}	
	return diffA;
}
// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {
			//print("found: "+array[i]);			
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
}
// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
function ArrayOccur(array, n) {
	array1 	= Array.sort(array);
	array2 	= Array.concat(array1, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array2.length)-1) {
		if (array2[i] == array2[(i)+1]) {
			//print("found: "+array[i]);			
		} else {
			uniqueA = Array.concat(uniqueA, array2[i]);
		}
   		i++;
   	}
   	c = 0;
   	occurA	= newArray();
   	//compare unique with input array
   	for (i=0; i<uniqueA.length; i++) {
   		for (j=0; j<array.length; j++) {
   			if (uniqueA[i] == array[j]) {
   				c++;
   			}
   		}
   		if (c == n) {
   			occurA = Array.concat(occurA, uniqueA[i]);
   		}
   		c = 0;
   	}
	return occurA;
}
// . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .