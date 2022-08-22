# MuLES: Multiple Leaf Sample Extraction System

```MuLES``` (Multiple Leaf Shape Extraction System) is a workflow based in ImageJ for quickly analyzing traditional morphometric parameters of simple leaf type samples. The workflow utilizes plugins published for use in ImageJ to identify and measure different parameters relevant to object shape, such as object length, width, area, and aspect ratio. These measurements can be taken using raw input images and require no initial pre-processing steps (eg. thresholding).

A summary of the capabilities of ```MuLES``` is as follows:

* User-friendly workflow that features a graphical user interface (GUI) and does not require prior coding knowledge.
* Automated batch processing of multiple images containing one or several leaves per image, allowing for high-throughput measuring of large populations.
* Orientation-agnostic processing that can identify individual leaves in close proximity.
* Additional options for controlling how the results are output, allowing for users to incorporate the output from ```MuLES``` into other image analysis softwares (eg. Momocs).

&nbsp;

Video walkthroughs demonstrating the ```MuLES``` and ```imgSplit``` workflows can be found at:

* https://www.youtube.com/watch?v=vtj93rbDO28 (MuLES) 
* https://www.youtube.com/watch?v=9HVsNvAWPjE (imgSplit)


# ImageJ/ Fiji installation
To use ```MuLES```, it is recommended that users install Fiji, a pre-packaged distribution of the image analysis software ImageJ. This distribution comes pre-packaged with multiple plugins for use in scientific image analysis. Fiji is available for download at https://imagej.net/software/fiji/downloads. 

Additionally, ```MuLES``` requires two dependencies that can be installed through the Fiji interface.

```> Help > Update... > Manage update sites > (Select the following two plugins:)```

* Morphology (Landini, 2008)
* BioVoxxel (Brocher, 2022)


# MuLES installation
```MuLES``` can be downloaded for use with ImageJ/ Fiji in several ways:

##Direct download

* https://github.com/0cb/mules/archive/refs/heads/main.zip


##Installing via the commandline

```git clone https://github.com/0cb/mules```


# The MuLES workflow
A detailed document describing the ```MuLES``` workflow can be found in the /docs folder of this repository (https://github.com/0cb/mules/blob/main/docs/MuLES_introduction.pdf).

Additionally, video walkthroughs for both ```MuLES``` and ```imgSplit``` are available at https://www.youtube.com/watch?v=vtj93rbDO28 and https://www.youtube.com/watch?v=9HVsNvAWPjE, respectively.


# Questions
For any questions regarding MuLES, you may contact the author, Christian S. Bowman, at mules.software@gmail.com.

MuLES is licensed under the GNU General Public License v3.0 or later. For more information, please refer to the LICENSE file in this repository.
