//@ File (label = "Input directory", style = "directory") chosenDir

inputDir = chosenDir + File.separator;
setBatchMode(false);
var acceptedNonBioFormatsFiles = "jpg, jpeg, tif, png, bmp, gif, avi, ijm, txt";

run("Bio-Formats Macro Extensions");

processBioFormatFiles(inputDir);

function processBioFormatFiles(currentDirectory) {
    fileList = getFileList(currentDirectory);
    
    for (file = 0; file < fileList.length; file++) {
        Ext.isThisType(currentDirectory + fileList[file], supportedFileFormat);
        
        if (supportedFileFormat == "true" && 
            !matches(acceptedNonBioFormatsFiles, ".*" + substring(fileList[file], lengthOf(fileList[file]) - 3) + ".*")) {
            
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

function runMyMacro() {
    // Set measurement parameters
    run("Set Measurements...", "area mean min limit display redirect=None decimal=3");
    setBackgroundColor(0, 0, 0);
    name = getTitle();
    getDimensions(width, height, channels, slices, frames);
    print(slices);

    // Define the region of interest (ROI)
    makeOval(-38, 150, 1100, 926);
    waitForUser("Please define the region of interest");
    run("Clear Outside");
    run("Select None");

    // Define total tissue region within the image
    run("Duplicate...", "duplicate channels=3");
    setAutoThreshold("Triangle dark");
    run("Convert to Mask", "method=Triangle background=Default calculate black");
    rename("maskALL");
    run("Despeckle", "stack");
    setOption("BlackBackground", true);
    run("Erode", "stack");    
    run("Erode", "stack");    
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");

    // Define total positive region of Channel 1 within the image
    selectWindow(name);
    run("Duplicate...", "duplicate channels=1");
    setAutoThreshold("IJ_IsoData dark");
    waitForUser("Please choose threshold value");
    run("Convert to Mask", "method=Default background=Default black");
    run("Despeckle", "stack");
    run("Erode", "stack");    
    run("Erode", "stack");
    run("Dilate", "stack");
    run("Dilate", "stack");
    rename("mask");
    selectWindow(name);
    run("Split Channels");

    // Masks and Measurements

    // Measure negative region of Channel 1
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
    
    // Measure positive region of Channel 1
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
