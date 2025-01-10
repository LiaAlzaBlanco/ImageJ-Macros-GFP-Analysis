# ImageJ-Macros-GFP-Analysis
ImageJ macros for analyzing GFP fluorescence in multi-channel images. Supplementary material.
// Macro for analyzing mean pixel intensity of GFP channel over the red channel across each layer
// Supplementary Table 1
// Author: [Lía Alza Blanco]
// Date: [10/01/2025]

// Define input directory
//@ File (label="Input directory", style="directory") chosenDir;
inputDir = chosenDir + File.separator;
setBatchMode(false);

// Supported file formats
var acceptedNonBioFormatsFiles = "jpg,jpeg,tif,png,bmp,gif,avi,ijm,txt";

// Load Bio-Formats plugin
run("Bio-Formats Macro Extensions");
processBioFormatFiles(inputDir);

// Function to process Bio-Format compatible files recursively
function processBioFormatFiles(currentDirectory) {
    fileList = getFileList(currentDirectory);
    for (file = 0; file < fileList.length; file++) {
        Ext.isThisType(currentDirectory + fileList[file], supportedFileFormat);
        if (supportedFileFormat == "true" && !matches(acceptedNonBioFormatsFiles, ".*" + substring(fileList[file], lengthOf(fileList[file]) - 3) + ".*")) {
            Ext.setId(currentDirectory + fileList[file]);
            Ext.getSeriesCount(seriesCount);
            for (series = 1; series <= seriesCount; series++) {
                run("Bio-Formats Importer", "open=[" + currentDirectory + fileList[file] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + series);
                runMyMacro();
            }
        } else if (matches(acceptedNonBioFormatsFiles, ".*" + substring(fileList[file], lengthOf(fileList[file]) - 3) + ".*")) {
            open(currentDirectory + fileList[file]);
            runMyMacro();
        } else if (endsWith(fileList[file], "/")) {
            processBioFormatFiles(currentDirectory + fileList[file]);
        }
    }
}

// Function to analyze the current file
function runMyMacro() {
    // Set measurement parameters
    run("Set Measurements...", "area mean min limit display redirect=None decimal=3");
    setBackgroundColor(0, 0, 0);

    // Get image details
    name = getTitle();
    getDimensions(width, height, channels, slices, frames);

    // Define region of interest (ROI)
    makeOval(-38, 150, 1100, 926);
    waitForUser("Please define region of interest");
    run("Clear Outside");
    run("Select None");

    // Analyze GFP channel
    run("Duplicate...", "duplicate channels=3");
    setAutoThreshold("Triangle dark");
    run("Convert to Mask", "method=Triangle background=Default calculate black");
    rename("maskALL");
    run("Despeckle", "stack");
    setOption("BlackBackground", true);

    // Morphological operations
    run("Erode", "stack");
    for (i = 0; i < 8; i++) {
        run("Dilate", "stack");
    }

    // Process mask
    selectWindow(name);
    run("Duplicate...", "duplicate channels=1");
    setAutoThreshold("IJ_IsoData dark");
    waitForUser("Please choose threshold value");
    run("Convert to Mask", "method=Default background=Default black");
    run("Despeckle", "stack");
    run("Erode", "stack");
    run("Erode", "stack");

    // Measure positive and negative regions
    rename("mask");
    selectWindow(name);
    run("Split Channels");
    imageCalculator("Subtract create stack", "maskALL", "mask");
    selectWindow("Result of maskALL");
    imageCalculator("AND create stack", "C2-" + name, "Result of maskALL");
    rename("Channel1 Neg Region Result of C2-" + name);
    setThreshold(1, 255);
    for (i = 1; i < slices; i++) {
        setSlice(i);
        run("Measure");
        selectWindow("Channel1 Neg Region Result of C2-" + name);
    }
    close();
    imageCalculator("AND create stack", "C2-" + name, "mask");
    rename("Channel1 Pos Region Result of C2-" + name);
    setThreshold(1, 255);
    for (i = 1; i < slices; i++) {
        setSlice(i);
        run("Measure");
        selectWindow("Channel1 Pos Region Result of C2-" + name);
    }
    close("*");
}
