macro "traj macro [h]" {
	
// This macro is suited to complexes data gathered with 3 separate imaging channels. 

// This script uses a transformation file with the AF647-labelled protein (sHsp in my case) as the reference
// So it aligns the other channels to this one so that colocalisation analysis can be performed

// So firstly the cropping, background correction and transformations (where necessary) are performed. The transformed 
// files are saved. Then the peak-finding step is performed and peaks are saved.

// This is followed by the colocalisation section where the coordinates of the peaks that are found in the three channels
// are compared to identify those that are colocalised with one another. These colocalisations are saved as well

// Then we move to the photobleaching trajectory sections. Here, we open the movies again and the peaks are imported
// into the ROI manager. Then the fluorescence intensity of the peaks over the course of the movie is measured
// and saved into a file

// After this I want to get an estimate of the degree of random colocalisation that occurs when two spots on the 
// coverslip are overlapping because of random binding to the same spot on the coverslip, rather than actually being
// in complex with one another. To do this, I use a little script that randomised the coordinates of the sHsp and 
// Hsp70 peaks - randomises within the maximum and minimum x and y coordinates of the real peaks. Then these randomised
// coordinates are checked for colocalisation with the real coordinates of the other components.

// ---------------------------------------IMPORTANT NOTE:------------------------------------------------------

// This script requires the extra files
// "count_colocalized_peaks_Andrew.js"
// "s_m_b.jar" plugin called "Single Molecule Biophysics"
// "Filter_for_colocal.ijm"
// "results_to_ROI.txt"
// "peak_intensity.txt"
// "scramble_xy.js"

// Some of these files will live in the "plugins" folder" : "count_colocalised_peaks_Andrew.js", "scramble_xy.js"

//-------------------------------------------------------------------------------------------------------------
// Client setup (aligned channel, 555-labelled
//-------------------------------------------------------------------------------------------------------------

var client_path = File.openDialog("Please Select RAW image Client (555)");
var dir = File.getParent(client_path);
var name = File.getName(client_path);

splitter = split(dir, File.separator)
len = splitter.length
trimm = len - 1
ROIpatharr = Array.slice(splitter, 0, trimm)
str = "";
filesep = File.separator;
for (i = 0; i < ROIpatharr.length-1; i++) 
    str = str + ROIpatharr[i] + filesep; 
str = str + ROIpatharr[ROIpatharr.length-1] + filesep; 
ROIpath = filesep + str + "ROI_cropped.zip";

print("Client Raw Image path= " + client_path)

run("Set Measurements...", "centroid stack redirect=None decimal=3");

//-------------------------------------------------------------------------------------------------------------
// Hsp70 setup (aligned channel, 488-labelled)
//-------------------------------------------------------------------------------------------------------------

var Hsp70_path = File.openDialog("Please Select RAW image Hsp70 (488)");
var dir = File.getParent(Hsp70_path);
var name = File.getName(Hsp70_path);

print("Hsp70 Raw Image path= " + Hsp70_path)

//-------------------------------------------------------------------------------------------------------------
// sHsp setup (non-aligned reference channel, 647-labelled)
//-------------------------------------------------------------------------------------------------------------

var sHsp_path = File.openDialog("Please Select RAW image sHsp (647)");
var dir = File.getParent(sHsp_path);
var name = File.getName(sHsp_path);

splitter = split(dir, File.separator)
len = splitter.length
trimm = len -1
ROIpatharr = Array.slice(splitter,0,trimm)
str = "";
filesep = File.separator;
for (i=0; i<ROIpatharr.length-1; i++) 
    str = str + ROIpatharr[i] + filesep; 
str = str + ROIpatharr[ROIpatharr.length-1] + filesep; 
ROIpath = filesep + str + "ROI_cropped.zip";

print("Raw Image path= " + sHsp_path)
print("ROI path= " + ROIpath);
output = dir + filesep
print("Output path= " + output)

transformationfile_555_to_647 = filesep + str + "TransformationMatrices_552_to_647.txt";
transformationfile_488_to_647 = filesep + str + "TransformationMatrices_488_to_647.txt";


// Create output folder for all Trajectories
trajectories_output = filesep + str + "/Trajectories/"
print(trajectories_output);
File.makeDirectory(trajectories_output);

run("Set Measurements...", "centroid stack redirect=None decimal=3");

client_results   = output + "Client_results.csv" 
sHsp_results      = output + "sHsp_results.csv"
Hsp70_results = output + "Hsp70_results.csv"
Client_colocalisation_results = output + "Client_colocalisation.csv"
Hsp70_colocalisation_results = output + "Hsp70_colocalisation.csv"

Client_MAX       = output + "MAX_Client peaks.tif"
client_image     = output + "Client.tif"
sHsp_image        = output + "sHsp background corrected.tif"
Hsp70_image = output + "Hsp70.tif"

Client_background_image = filesep + str + "555_background.tif"
sHsp_background_image    = filesep + str + "647_background.tif"
Hsp70_background_image = filesep + str + "488_background.tif"


FRET_background_image_555 = filesep + str + "555_FRET_background.tif"
FRET_background_image_488_647 = filesep + str + "488_647_FRET_background.tif"
FRET_background_image_488_555 = filesep + str + "488_555_FRET_background.tif"

// going to make some folders that contain client results and sHsp results

client_output_folder = filesep + str + "/client_results/"
print(client_output_folder);
File.makeDirectory(client_output_folder);

sHsp_output_folder = filesep + str + "/sHsp_results/"
print(sHsp_output_folder);
File.makeDirectory(sHsp_output_folder);

Hsp70_output_folder = filesep + str + "/Hsp70_results/"
print(Hsp70_output_folder);
File.makeDirectory(Hsp70_output_folder);


//create folders within trajectories folder, for client and sHsp

/// they are called coloc in this script but will actually get ALL trajectories

colocalised_output_folder = trajectories_output + "/ALL/"
print(colocalised_output_folder);
File.makeDirectory(colocalised_output_folder);

//make subfolders for sHsp, client, Hsp70
client_coloc_trajectories = colocalised_output_folder + "/Client/"
print(client_coloc_trajectories);
File.makeDirectory(client_coloc_trajectories);

sHsp_coloc_trajectories = colocalised_output_folder + "/sHsp/"
print(sHsp_coloc_trajectories);
File.makeDirectory(sHsp_coloc_trajectories);

Hsp70_coloc_trajectories = colocalised_output_folder + "/Hsp70/"
print(Hsp70_coloc_trajectories);
File.makeDirectory(Hsp70_coloc_trajectories);

// not sure if we will have this so just leaving it out for now
FRET_output_folder = filesep + str + "/FRET_results/"
print(FRET_output_folder);
File.makeDirectory(FRET_output_folder);

// make subfolders for individual FRET types
FRET_555_to_647_folder = FRET_output_folder + "/555_to_647/"
print(FRET_555_to_647_folder);
File.makeDirectory(FRET_555_to_647_folder);

FRET_488_to_647_folder = FRET_output_folder + "/488_to_647/"
print(FRET_488_to_647_folder);
File.makeDirectory(FRET_488_to_647_folder);


FRET_488_to_555_folder = FRET_output_folder + "/488_to_555/"
print(FRET_488_to_555_folder);
File.makeDirectory(FRET_488_to_555_folder);

//-------------------------------------------------------------------------------------------------------------
// Process Client channel (555)
//-------------------------------------------------------------------------------------------------------------

Imagetitle = File.getNameWithoutExtension(client_path);

// Check if Client.tif already exists
if (File.exists(client_image)) {
    print("Client.tif already exists — skipping transformation.");
} else {
    print("Client.tif not found — running transformation.");

    // ----- TRANSFORMATION BLOCK (ONLY RUNS IF NEEDED) -----

    open(client_path);	// open original raw image
    Imagetitle = getTitle();
    rename("Raw");

    roiManager("Open", ROIpath);
    roiManager("Select", 1);
    run("Duplicate...", "title=Client duplicate");

    // Background correction 
    open(Client_background_image);
    rename("background_Client");
    selectWindow("Client");
    run("32-bit");
    run("Beam Profile Correction", "electronic_offset=500 background_image=background_Client");
    setMinAndMax(0, 65536);
    run("16-bit");

    // Alignment block…
    splitDir = dir + "/Client/";
    File.makeDirectory(splitDir);
    selectWindow("Client");
    run("Image Sequence... ", "format=TIFF use save=[" + splitDir + "]");
    selectWindow("Client");
    close();;

    outputFolder = splitDir;

    function action(outputFolder, outputFolder, filename) {
        open(outputFolder + filename);
        run("MultiStackReg", "stack_1="+filename+" action_1=[Load Transformation File] file_1=["+ transformationfile_555_to_647 +"] stack_2=None action_2=Ignore file_2=[] transformation=[Rigid Body]");
        roiManager("Select", 3);
        run("Duplicate...", "duplicate");
        saveAs("tif", outputFolder + filesep + filename);
        close();;
        close();;
    }

    list = getFileList(outputFolder);
    for (i = 0; i < list.length; i++)
        action(outputFolder, outputFolder, list[i]);

    output = dir + filesep;
    run("Image Sequence...", "open=[" + outputFolder + "] sort");
    rename("Client");
    run("Z Project...", "projection=[Max Intensity]");
    selectWindow("MAX_Client");
    saveAs("tiff", output+getTitle()); 
    close();
    selectWindow("Client");
    saveAs("tiff", output+getTitle()); 
    
    selectWindow("Raw");
    run("Close");
}

// ----- ALWAYS-RUN BLOCK (HAPPENS EVEN IF TRANSFORMATION IS SKIPPED) -----

// At this point, Client.tif 100% exists
open(client_image);
rename("Client");

// Create a max projection and save it
run("Z Project...", "stop=20 projection=[Max Intensity]");
saveAs("tiff", output+getTitle());
selectWindow("MAX_Client.tif");
run("Enhance Contrast", "saturated=0.35");

// Measure peaks
roiManager("reset");
run("Peak Finder");
waitForUser("Have you selected your peaks? \n\nPress OK to continue");
roiManager("Measure");

// Save analysis output
saveAs("Results", output + "Client_results.csv");
close();;

// Extra image exports
saveAs("jpeg", output + "AVG_Client.jpeg");
selectWindow("Client");
saveAs("jpeg", output + "background_corrected_Client.jpeg");
selectWindow("Results");
run("Close");

run("Close All");

roiManager("reset");

//-------------------------------------------------------------------------------------------------------------
// Process Hsp70 channel (488)
//-------------------------------------------------------------------------------------------------------------

// Check if Hsp70.tif already exists
if (File.exists(Hsp70_image)) {
    print("Hsp70.tif already exists — skipping transformation.");
} else {
    print("Hsp70.tif not found — running transformation.");

    // ----- TRANSFORMATION BLOCK (ONLY RUNS IF NEEDED) -----

    open(Hsp70_path);	// open original raw image
    Imagetitle = getTitle();
    rename("Raw");

    roiManager("Open", ROIpath);
    roiManager("Select", 0);
    run("Duplicate...", "title=Hsp70 duplicate");

    // Background correction 
    open(Hsp70_background_image);
    rename("background_Hsp70");
    selectWindow("Hsp70");
    run("32-bit");
    run("Beam Profile Correction", "electronic_offset=500 background_image=background_Hsp70");
    setMinAndMax(0, 65536);
    run("16-bit");


    // Alignment of Hsp70 channel to sHsp reference
    splitDir = dir + "/Hsp70/";
    File.makeDirectory(splitDir);
    selectWindow("Hsp70");
    run("Image Sequence... ", "format=TIFF use save=[" + splitDir + "]");
    selectWindow("Hsp70");
    close();;

    outputFolder = splitDir;

    function actionHsp70(outputFolder, outputFolder, filename) {
        open(outputFolder + filename);
        run("MultiStackReg", 
            "stack_1=" + filename +
            " action_1=[Load Transformation File]" +
            " file_1=[" + transformationfile_488_to_647 + "]" +
            " stack_2=None action_2=Ignore file_2=[]" +
            " transformation=[Rigid Body]");
        roiManager("Select", 3);
        run("Duplicate...", "duplicate");
        saveAs("tif", outputFolder + filesep + filename);
        close();;
        close();;
    }

    list = getFileList(outputFolder);
    for (i = 0; i < list.length; i++)
        actionHsp70(outputFolder, outputFolder, list[i]);

    output = dir + filesep;
    run("Image Sequence...", "open=[" + outputFolder + "] sort");
    rename("Hsp70");
    run("Z Project...", "projection=[Max Intensity]");
    selectWindow("MAX_Hsp70");
    saveAs("tiff", output+getTitle()); 
    close();
    selectWindow("Hsp70");
    saveAs("tiff", output+getTitle());
    
    selectWindow("background_Hsp70");
    close();
}


// ----- ALWAYS-RUN BLOCK (HAPPENS EVEN IF TRANSFORMATION IS SKIPPED) -----

// At this point, Hsp70.tif is guaranteed to exist
open(Hsp70_image);
rename("Hsp70");

run("Z Project...", "stop=20 projection=[Max Intensity]");
saveAs("tiff", output+getTitle());

selectWindow("MAX_Hsp70.tif");
run("Enhance Contrast", "saturated=0.35");

// Measure peaks
roiManager("reset");
run("Peak Finder");
waitForUser("Have you selected your peaks? \n\nPress OK to continue");
roiManager("Measure");

// Save results
saveAs("Results", output + "Hsp70_results.csv");
close();;

// Save JPEGs and cleanup
saveAs("jpeg", output + "AVG_Hsp70.jpeg");

selectWindow("Hsp70");
saveAs("jpeg", output + "background_corrected_Hsp70.jpeg");
close();;
selectWindow("Results");
run("Close");

run("Close All");

roiManager("reset");

//-------------------------------------------------------------------------------------------------------------
// Process sHsp channel (this one does not gets aligned, 647)
//-------------------------------------------------------------------------------------------------------------

open(sHsp_path);	
rename("Raw sHsp");
selectWindow("Raw sHsp");

roiManager("Open", ROIpath);
roiManager("Select", 2);	// this will be the sHsp (647) channel
run("Duplicate...", "title=sHsp duplicate");

// Background correction 
open(sHsp_background_image);
rename("Background_sHsp");
selectWindow("sHsp");
run("32-bit");
//run("Beam Profile Correction", "electronic_offset=350 background_image=Background_AF647");
run("Beam Profile Correction", "electronic_offset=500 background_image=Background_sHsp");
setMinAndMax(0, 65536);
run("16-bit");

// crop second time in order to remove black edges in channel
roiManager("Select", 3);
run("Duplicate...", "title=[sHsp background corrected] duplicate");
saveAs("tiff", output + "sHsp background corrected.tif");	
run("Z Project...", "stop=20 projection=[Max Intensity]");
saveAs("tiff", output + "MAX_sHsp.tif");

roiManager("reset");
selectWindow("MAX_sHsp.tif");
run("Enhance Contrast", "saturated=0.35");

// Find the peaks within the sHsp image
run("Peak Finder");
waitForUser("Have you selected your peaks? \n \nPress OK to continue");
roiManager("Measure");	//this will allow for a table to be produced
selectWindow("sHsp background corrected.tif");
saveAs("jpeg", output + "background_corrected_sHsp.jpeg");
run("Close");
selectWindow("Results"); 
saveAs("Results", output + "sHsp_results.csv"); 
close();;
selectWindow("sHsp");
close();;
selectWindow("Results"); 
run("Close"); 
selectWindow("Background_sHsp");
close();
selectWindow("Raw sHsp");
close();;
roiManager("reset");

//selectWindow("Raw");
//run("Close");

//-------------------------------------------------------------------------------------------------------------
// COLOCALISATION SECTION
//-------------------------------------------------------------------------------------------------------------

Imagetitle = File.getNameWithoutExtension(client_path) + ".tif";

//---------------- First section is going to be colocalisation between client and sHsp ------------------------


// colocalisation analysis- we look for colocalised spots between the channels (complexes)
//we also save which spots are colocalised and which are not, so we can filter and examine them later
open(client_results);	
//selectWindow("client_results.csv");
IJ.renameResults("client");
open(sHsp_results);	
//selectWindow("sHsp_results.csv");
IJ.renameResults("sHsp");
run("count colocalized peaks Andrew", "table_1=client table_2=sHsp maximum_distance=3");
selectWindow("client");
IJ.renameResults("Results");
selectWindow("sHsp");
		run("Close");
		// this needs to be the local path of this macro
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm");
selectWindow("Colocalization");
saveAs("tiff", output + "Colocalization_sHsp.tiff");
close();
IJ.renameResults("client_colocalisation_sHsp");
selectWindow("client_colocalisation_sHsp");
saveAs("Results", output + "client_colocalisation_sHsp.csv"); 
selectWindow("client_colocalisation_sHsp.csv");
     run("Close"); 
          
//------------------- Now we are going to do colocalisation between clients and Hsp70 ----------------------------

open(client_results);	
//selectWindow("client_results.csv");
IJ.renameResults("client");

open(Hsp70_results);
IJ.renameResults("Hsp70");

run("count colocalized peaks Andrew", "table_1=client table_2=Hsp70 maximum_distance=3");
selectWindow("client");
IJ.renameResults("Results");
selectWindow("Hsp70");
		run("Close");
		// this needs to be the local path of this macro
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm");
selectWindow("Colocalization");
saveAs("tiff", output + "Colocalization_Hsp70.tiff");
close();
IJ.renameResults("client_colocalisation_Hsp70");
selectWindow("client_colocalisation_Hsp70");
saveAs("Results", output + "client_colocalisation_Hsp70.csv"); 
selectWindow("client_colocalisation_Hsp70.csv");
     run("Close"); 

//------------------- Lastly we are going to do colocalisation between sHsp and Hsp70 ----------------------------

open(sHsp_results);	
//selectWindow("client_results.csv");
IJ.renameResults("sHsp");

open(Hsp70_results);
IJ.renameResults("Hsp70");

run("count colocalized peaks Andrew", "table_1=sHsp table_2=Hsp70 maximum_distance=3");
selectWindow("sHsp");
IJ.renameResults("Results");
selectWindow("Hsp70");
		run("Close");
		// this needs to be the local path of this macro
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm");
selectWindow("Colocalization");
saveAs("tiff", output + "Colocalization_sHsp_Hsp70.tiff");
close();
IJ.renameResults("sHsp_colocalisation_Hsp70");
selectWindow("sHsp_colocalisation_Hsp70");
saveAs("Results", output + "sHsp_colocalisation_Hsp70.csv"); 
selectWindow("sHsp_colocalisation_Hsp70.csv");
     run("Close"); 

//-------------------------------------------------------------------------------------------------------------
// PHOTOBLEACHING TRAJECTORY SECTION
//-------------------------------------------------------------------------------------------------------------

roiManager("reset");

// ----------------------------------------- Client first -----------------------------------------------------

open(client_results);	
//selectWindow("client_results.csv");
IJ.renameResults("Results");

open(client_image);

runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/results_to_ROI.txt");
selectWindow("Results");
        run("Close");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
selectWindow("Results");
saveAs("Results", output + "client_ALL_traj.csv");
selectWindow("Results");
saveAs("Results", client_coloc_trajectories + Imagetitle  +"_Client_traj.csv");
//saveAs("Results", client_coloc_trajectories + Imagetitle +"_Client_traj.csv");  
run("Close");
selectWindow("Client.tif");
run("Close");
roiManager("reset");

// ------------------------------------------------- sHsps -----------------------------------------------------

open(sHsp_results);	
//selectWindow("client_results.csv");
IJ.renameResults("Results");

open(sHsp_image);

runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/results_to_ROI.txt"); // you need to put the location of your script
selectWindow("Results");
        run("Close");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
selectWindow("Results");
saveAs("Results", output + "sHsp_ALL_traj.csv");
selectWindow("Results");
saveAs("Results", sHsp_coloc_trajectories + Imagetitle  +"_sHsp_traj.csv");
//saveAs("Results", sHsp_coloc_trajectories + Imagetitle + "_sHsp_traj.csv");
run("Close");
selectWindow("sHsp background corrected.tif");
run("Close");
roiManager("reset");

// -------------------------------------------------- Hsp70s ----------------------------------------------------

open(Hsp70_results);
IJ.renameResults("Results");

open(Hsp70_image);

runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/results_to_ROI.txt"); // you need to put the location of your script
selectWindow("Results");
        run("Close");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
selectWindow("Results");
saveAs("Results", output + "Hsp70_ALL_traj.csv");
selectWindow("Results");
saveAs("Results", Hsp70_coloc_trajectories + Imagetitle  +"_Hsp70_traj.csv");
//saveAs("Results", Hsp70_coloc_trajectories + Imagetitle + "_Hsp70_traj.csv");
run("Close");
selectWindow("Hsp70.tif");
run("Close");
roiManager("reset");

//-------------------------------------------------------------------------------------------------------------
// RANDOMISING ("SCRAMBLING") COORDINATES AND THEN COLOCALISATION WITH THESE COORDINATES SECTION
//-------------------------------------------------------------------------------------------------------------

// ------------------------- Scrambling sHsp coordinates and colocalising with client -------------------------

open("sHsp_results.csv");
// needs to be called "Hsp" to go into scramble_xy.js
IJ.renameResults("Hsp");
open("Client_results.csv");
IJ.renameResults("Client");

runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/scramble_xy.js");
selectWindow("Hsp");
saveAs("Results", sHsp_output_folder + Imagetitle + "_sHsp_scrambled_results.csv");
name_of_scrambled_csv = Imagetitle + "_sHsp_scrambled_results.csv";
IJ.renameResults("sHsp");

//now running the colocalisation macro plugin thing
run("count colocalized peaks Andrew", "table_1=Client table_2=sHsp maximum_distance=3");
selectWindow("Colocalization");
close();
selectWindow("Client");
//saveAs("Results", output + "Fibril_colocalisation.csv"); 
saveAs("Results", client_output_folder + Imagetitle + "_client_scramble_sHsp_results.csv");
IJ.renameResults("Results");
selectWindow("sHsp");
		run("Close");
		
//now filter these data for only those colocalised not all the spots combined.
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm");
IJ.renameResults("Client_sHsp_scramble_colocalisation_only");
selectWindow("Client_sHsp_scramble_colocalisation_only");
//saveAs("Results", output + "Fibril_colocalisation_only.csv"); 
saveAs("Results", client_output_folder + Imagetitle + "_client_sHsp_scramble_colocalized.csv");
run("Close");
//name_of_scrambled_csv = Imagetitle + "_sHsp_scrambled_results.csv";
//selectWindow(name_of_scrambled_csv);
//run("Close");
roiManager("reset");

// ------------------------ Scrambling Hsp70 coordinates and colocalising with client ----------------------

open("Hsp70_results.csv");
// needs to be called "Hsp" to go into scramble_xy.js
IJ.renameResults("Hsp");
open("Client_results.csv");
IJ.renameResults("Client");

runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/scramble_xy.js");
selectWindow("Hsp");
saveAs("Results", Hsp70_output_folder + Imagetitle + "_Hsp70_scrambled_results.csv");
name_of_scrambled_csv = Imagetitle + "_Hsp70_scrambled_results.csv";
IJ.renameResults("Hsp70");

//now running the colocalisation macro plugin thing
run("count colocalized peaks Andrew", "table_1=Client table_2=Hsp70 maximum_distance=3");
selectWindow("Colocalization");
close();
selectWindow("Client");
//saveAs("Results", output + "Fibril_colocalisation.csv"); 
saveAs("Results", client_output_folder + Imagetitle + "_client_scramble_Hsp70_results.csv");
IJ.renameResults("Results");
selectWindow("Hsp70");
		run("Close");
		
//now filter these data for only those colocalised not all the spots combined.
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm");
IJ.renameResults("Client_Hsp70_scramble_colocalisation_only");
selectWindow("Client_Hsp70_scramble_colocalisation_only");
//saveAs("Results", output + "Fibril_colocalisation_only.csv"); 
saveAs("Results", client_output_folder + Imagetitle + "_client_Hsp70_scramble_colocalized.csv");
run("Close");
//name_of_scrambled_csv = Imagetitle + "_sHsp_scrambled_results.csv";
//selectWindow(name_of_scrambled_csv);
//run("Close");
roiManager("reset");

// ------------------------ Scrambling sHsp coordinates and colocalising with Hsp70 ---------------------

sHsp_scrambled_results = sHsp_output_folder + Imagetitle + "_sHsp_scrambled_results.csv";
print(sHsp_scrambled_results);

open(sHsp_scrambled_results);
IJ.renameResults("sHsp");
open("Hsp70_results.csv");
IJ.renameResults("Hsp70");

//now running the colocalisation macro plugin thing
run("count colocalized peaks Andrew", "table_1=sHsp table_2=Hsp70 maximum_distance=3");
selectWindow("Colocalization");
close();
selectWindow("sHsp");
//saveAs("Results", output + "Fibril_colocalisation.csv"); 
saveAs("Results", sHsp_output_folder + Imagetitle + "_sHsp_scramble_Hsp70_results.csv");
IJ.renameResults("Results");
selectWindow("Hsp70");
		run("Close");
		
//now filter these data for only those colocalised not all the spots combined.
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm");
IJ.renameResults("sHsp_Hsp70_scramble_colocalisation_only");
selectWindow("sHsp_Hsp70_scramble_colocalisation_only");
//saveAs("Results", output + "Fibril_colocalisation_only.csv"); 
saveAs("Results", sHsp_output_folder + Imagetitle + "_Hsp70_scramble_colocalized.csv");
run("Close");
//name_of_scrambled_csv = Imagetitle + "_sHsp_scrambled_results.csv";
//selectWindow(name_of_scrambled_csv);
//run("Close");
roiManager("reset");

// ---------------------------- Saving some of the files in a different folder --------------------------

open("Client_results.csv");
IJ.renameResults("Results");
saveAs("Results", client_output_folder + Imagetitle + "_client_results.csv");
run("Close");

open("client_colocalisation_sHsp.csv");
IJ.renameResults("Results");
saveAs("Results", client_output_folder + Imagetitle + "_client_colocalisation_sHsp.csv");
run("Close");

open("client_colocalisation_Hsp70.csv");
IJ.renameResults("Results");
saveAs("Results", client_output_folder + Imagetitle + "_client_colocalisation_Hsp70.csv");
run("Close");

open("sHsp_results.csv");
IJ.renameResults("Results");
saveAs("Results", sHsp_output_folder + Imagetitle + "_sHsp_results.csv");
run("Close");

open("sHsp_colocalisation_Hsp70.csv");
IJ.renameResults("Results");
saveAs("Results", sHsp_output_folder + Imagetitle + "_sHsp_colocalisation_Hsp70_results.csv");
run("Close");

open("Hsp70_results.csv");
IJ.renameResults("Results");
saveAs("Results", Hsp70_output_folder + Imagetitle + "_Hsp70_results.csv");
run("Close");


//-------------------------------------------------------------------------------------------------------------
// FINISHING UP
//-------------------------------------------------------------------------------------------------------------

// ----------------- End -----------------

run("Close All", "non-images");

roiManager("reset");

close("*");
waitForUser("All done! :) \n \nPress OK to continue. Close ROI manager before running script again :)");

}
