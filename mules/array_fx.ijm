/* Some functions for arrays (ImageJ Macro Language)
 * Rainer M. Engel, 2012
 * 
 * Union, Diff, Unique, Occur
 * (execute macro to see them in action ..)
 */
 
print("\\Clear");

print("a1 and a2:");
a1 = newArray(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15);
a2 = newArray(11,12,13,14,15,16,17,18,19,20);
Array.print(a1);
Array.print(a2);

print("");
print("union of both arrays:");
union = ArrayUnion(a1, a2);
Array.print(union);

print("");
print("diff between both arrays:");
diff = ArrayDiff(a1, a2);
Array.print(diff);

print("");
print("unique filter on concatenated arrays:");
joined = Array.concat(a1,a2,0,0,5,5,20,20);
unique = ArrayUnique(joined);
Array.print(unique);

print("");
print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
print("joined array: .. ");
Array.print(joined);
print("");
print("filter for occurrance (3 times):");
appear = ArrayOccur(joined, 3); 
Array.print(appear);
print("filter for occurrance (2 times):");
appear = ArrayOccur(joined, 2); 
Array.print(appear);
print("filter for occurrance (1 times):");
appear = ArrayOccur(joined, 1); 
Array.print(appear);



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