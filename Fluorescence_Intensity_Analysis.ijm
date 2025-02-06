directory=getDirectory("Tif Files Dir");
#@int(label="Choose DAPI channel", value=1) canaldapi
#@int(label="Choose quantification channel", value=3) canal

filelist = getFileList(directory);
for (j = 0; j < lengthOf(filelist); j++) {
    if (endsWith(filelist[j], ".tif")) { 
        open(directory + File.separator + filelist[j]);
        
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

        // Apply threshold
        setAutoThreshold("Otsu dark");
        waitForUser("Check Threshold");
        selectWindow(name);

        if (channels > 1) {
            // Split channels if the image has multiple channels
            run("Split Channels");
            rename("Positive Region Result of C" + canal + "-" + name);
            setThreshold(1, 255);
            for (i = 1; i < slices; i++) {
                setSlice(i);
                run("Measure");
                selectWindow("Positive Region Result of C" + canal + "-" + name);
            }
        } else {
            // Process single-channel images
            for (i = 1; i < slices; i++) {
                setSlice(i);
                run("Measure");
                selectWindow(name);
            }
        }
    }
    close("*");  
}
