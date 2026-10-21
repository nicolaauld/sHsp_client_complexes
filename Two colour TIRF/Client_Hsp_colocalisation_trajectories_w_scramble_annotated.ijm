macro "traj macro [h]" {

// This macro is suited to complexes data gathered with 2 separate imaging channels. 

// This script uses a transformation file with the AF647-labelled protein (sHsp in my case) as the reference
// So it aligns the other channel to this one so that colocalisation analysis can be performed

// So firstly the cropping, background correction and transformations (where necessary) are performed. The transformed 
// files are saved. Then the peak-finding step is performed and peaks are saved.

// This is followed by the colocalisation section where the coordinates of the peaks that are found in the three channels
// are compared to identify those that are colocalised with one another. These colocalisations are saved as well

// Then we move to the photobleaching trajectory sections. Here, we open the movies again and the colocalised and non-colocalised
// peaks are imported into the ROI manager. Then the fluorescence intensity of the peaks over the course of the movie is measured
// and saved into a file

// After this I want to get an estimate of the degree of random colocalisation that occurs when two spots on the 
// coverslip are overlapping because of random binding to the same spot on the coverslip, rather than actually being
// in complex with one another. To do this, I use a little script that randomised the coordinates of the sHsp 
// within the maximum and minimum x and y coordinates of the real peaks. Then these randomised
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


// This macro is suited to complexes data gathered with separate imaging conditions. 
// That is, if molecules are FRETing, and you have to bleach them separately, but then look for colocalisation.
// This is opposed to dual imaging. 
// Setup: define the image to get data from.
// Select Client (488-labelled, reference) first, then Hsp (647-labelled, aligned) next.


//-------------------------------------------------------------------------------------------------------------
// Client setup (aligned channel, 488-labelled
//-------------------------------------------------------------------------------------------------------------
var client_path = File.openDialog("RAW image Client (488)");
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
ROIpath = filesep + str + "ROI.zip";

print("Client Raw Image path= " + client_path)
print("ROI path= " + ROIpath);
output = dir + filesep
print("Output path= " + output)
transformationfile = filesep + str + "TransformationMatrices.txt";

run("Set Measurements...", "centroid stack redirect=None decimal=3");

//-------------------------------------------------------------------------------------------------------------
// sHsp setup (non-aligned reference channel, 647-labelled)
//-------------------------------------------------------------------------------------------------------------
var hsp_path = File.openDialog("RAW image Hsp (647)");
var dir = File.getParent(hsp_path);
var name = File.getName(hsp_path);

splitter = split(dir, File.separator)
len = splitter.length
trimm = len -1
ROIpatharr = Array.slice(splitter,0,trimm)
str = "";
filesep = File.separator;
for (i=0; i<ROIpatharr.length-1; i++) 
    str = str + ROIpatharr[i] + filesep; 
str = str + ROIpatharr[ROIpatharr.length-1] + filesep; 
ROIpath = filesep + str + "ROI.zip";

print("Raw Image path= " + hsp_path)
print("ROI path= " + ROIpath);
output = dir + filesep
print("Output path= " + output)
// This is the file we generate to adjust for any misalignment between the emission channels, generated using optical beads image
transformationfile = filesep + str + "TransformationMatrices.txt";

// Create output folder for all Trajectories
trajectories_output = filesep + str + "/Trajectories/"
print(trajectories_output);
File.makeDirectory(trajectories_output);

run("Set Measurements...", "centroid stack redirect=None decimal=3");

client_results   = output + "Client_results.csv" 
Hsp_results      = output + "Hsp_results.csv"
Client_colocalisation_results = output + "Client_colocalisation.csv"

Client_MAX       = output + "MAX_Client peaks.tif"
client_image     = output + "Client.tif"
Hsp_image        = output + "Hsp background corrected.tif"

Client_background_image = filesep + str + "488_background.tif"
Hsp_background_image    = filesep + str + "647_background.tif"


// going to make some folders that contain client results and hsp results

client_output_folder = filesep + str + "/client_results/"
print(client_output_folder);
File.makeDirectory(client_output_folder);

hsp_output_folder = filesep + str + "/hsp_results/"
print(hsp_output_folder);
File.makeDirectory(hsp_output_folder);

//-------------------------------------------------------------------------------------------------------------
// Process client channel 
//-------------------------------------------------------------------------------------------------------------
open(client_path);	// open original raw image
Imagetitle = getTitle()
rename("Raw");

roiManager("Open", ROIpath);
roiManager("Select", 1);	// this will be the Client (488) channel
run("Duplicate...", "title=Client duplicate");

// Background correction 
open(Client_background_image);
rename("background_Client");
selectWindow("Client");
run("32-bit");
run("Beam Profile Correction", "electronic_offset=500 background_image=background_Client");
setMinAndMax(0, 65536);
run("16-bit");


// Alignment of Client channel using bead image (to Hsp 647 reference)
splitDir = dir + "/Client/"
File.makeDirectory(splitDir);
selectWindow("Client");
run("Image Sequence... ", "format=TIFF use save=[" + splitDir + "]");
//run("Image Sequence... ", "format=TIFF use save=splitDir");
selectWindow("Client");
close();

outputFolder = splitDir

function action(outputFolder, outputFolder, filename) {
    open(outputFolder + filename);
    run("MultiStackReg", "stack_1="+filename+" action_1=[Load Transformation File] file_1=["+ transformationfile +"] stack_2=None action_2=Ignore file_2=[] transformation=[Rigid Body]");
    roiManager("Select", 2);
    run("Duplicate...", "duplicate");
    saveAs("tif", outputFolder + filesep + filename);
    close();
    close();
}

list = getFileList(outputFolder);
for (i = 0; i < list.length; i++)
    action(outputFolder, outputFolder, list[i]);

output = dir + filesep
run("Image Sequence...", "open=[" + outputFolder + "] sort");
rename("Client");
run("Z Project...", "projection=[Max Intensity]");
selectWindow("MAX_Client");
saveAs("tiff", output+getTitle()); 
close()
selectWindow("Client");
saveAs("tiff", output+getTitle()); 

// this is generating a max image by sort of compressing all frames of the movie
run("Z Project...", "stop=20 projection=[Max Intensity]");
saveAs("tiff", output+getTitle()); 
selectWindow("MAX_Client.tif");
run("Enhance Contrast", "saturated=0.35");

roiManager("reset");
// Find the peaks within the Client image
run("Peak Finder");
waitForUser("Have you selected your peaks? \n \nPress OK to continue");
roiManager("Measure");	
saveAs("Results", output + "Client_results.csv"); 
close();
//selectWindow("AVG_Client");
saveAs("jpeg", output + "AVG_Client.jpeg");
//close();
selectWindow("background_Client");
close()
selectWindow("Client.tif");
saveAs("jpeg", output + "background_corrected_Client.jpeg");
close()
selectWindow("Results"); 
run("Close");
selectWindow("Raw");
run("Close");
roiManager("reset");


//-------------------------------------------------------------------------------------------------------------
// Process sHsp channel (non-aligned reference channel, 647-labelled)
//-------------------------------------------------------------------------------------------------------------


open(hsp_path);	
rename("Raw Hsp");
selectWindow("Raw Hsp")

roiManager("Open", ROIpath);
roiManager("Select", 0);	// this will be the Hsp (647) channel
run("Duplicate...", "title=Hsp duplicate");

// Background correction 
open(Hsp_background_image);
rename("Background_Hsp");
selectWindow("Hsp");
run("32-bit");
//run("Beam Profile Correction", "electronic_offset=350 background_image=Background_AF647");
run("Beam Profile Correction", "electronic_offset=500 background_image=Background_Hsp");
setMinAndMax(0, 65536);
run("16-bit");

// crop second time in order to remove black edges in channel
roiManager("Select", 2);
run("Duplicate...", "title=[Hsp background corrected] duplicate");
saveAs("tiff", output + "Hsp background corrected.tif");	
run("Z Project...", "stop=20 projection=[Max Intensity]");
saveAs("tiff", output + "MAX_Hsp.tif");

roiManager("reset");
selectWindow("MAX_Hsp.tif");
run("Enhance Contrast", "saturated=0.35");


// Find the peaks within the Hsp image
run("Peak Finder");
waitForUser("Have you selected your peaks? \n \nPress OK to continue");
roiManager("Measure");	//this will allow for a table to be produced
selectWindow("Hsp background corrected.tif");
saveAs("jpeg", output + "background_corrected_Hsp.jpeg");
run("Close");
selectWindow("Results"); 
saveAs("Results", output + "Hsp_results.csv"); 
close();
selectWindow("Hsp");
close()
selectWindow("Results"); 
run("Close"); 
selectWindow("Background_Hsp");
close()
selectWindow("Raw Hsp");
close()
roiManager("reset");

//-------------------------------------------------------------------------------------------------------------
// COLOCALISATION SECTION with trajectories for colocalised molecules
//-------------------------------------------------------------------------------------------------------------

//create colocalisation folders within trajectories folder, for client and hsp

colocalised_output_folder = trajectories_output + "/Coloc/"
print(colocalised_output_folder);
File.makeDirectory(colocalised_output_folder);

//make subfolders for hsp vs client
client_coloc_trajectories = colocalised_output_folder + "/Client/"
print(client_coloc_trajectories);
File.makeDirectory(client_coloc_trajectories);

hsp_coloc_trajectories = colocalised_output_folder + "/Hsp/"
print(hsp_coloc_trajectories);
File.makeDirectory(hsp_coloc_trajectories);

// colocalisation analysis- we look for colocalised spots between the channels (complexes)
//we also save which spots are colocalised and which are not, so we can filter and examine them later
open(client_results);	
//selectWindow("client_results.csv");
IJ.renameResults("client");
open(Hsp_results);	
//selectWindow("Hsp_results.csv");
IJ.renameResults("Hsp");
run("count colocalized peaks Andrew", "table_1=client table_2=Hsp maximum_distance=3");
selectWindow("client");
IJ.renameResults("Results");
selectWindow("Hsp");
		run("Close")
		
// this needs to be the local path of this macro
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm")

selectWindow("Colocalization");
saveAs("tiff", output + "Colocalization.tiff");
close()
IJ.renameResults("client_colocalisation")
selectWindow("client_colocalisation")
saveAs("Results", output + "client_colocalisation.csv"); 
selectWindow("client_colocalisation.csv");
     run("Close"); 

// Now getting the trajectories for the colocalised clients
roiManager("reset");

open(client_image);
open("client_colocalisation.csv");
IJ.renameResults("Results")

// This macro gets the x- and y-coordinates of fluorescent foci and puts them into the ROI manager
// so that these molecules can be accessed again for further analysis
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/results_to_ROI.txt"); // you need to put the location of your script.
selectWindow("Results");
        run("Close");
// This macro finds the fluorescence intensity of each of the foci (that are in the ROI manager) over time
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
selectWindow("Results");
        saveAs("Results", output + "client_colocal_traj.csv");
selectWindow("Results");   
		saveAs("Results", client_coloc_trajectories + Imagetitle +"_Client_colocal_traj.csv");  
        run("Close");
selectWindow("Client.tif");
        run("Close");
roiManager("reset");

// Getting the trajectories for the colocalised Hsps

open(Hsp_image);	//open original raw image
open("client_colocalisation.csv");
IJ.renameResults("Results")
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/v3_results_to_ROI_X2.txt"); // you need to put the location of your script
selectWindow("Results");
        run("Close");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
selectWindow("Results");
        saveAs("Results", output + "Hsp_colocal_traj.csv");
selectWindow("Results");
     	saveAs("Results", hsp_coloc_trajectories + Imagetitle + "_Hsp_colocal_traj.csv");
        run("Close");
selectWindow("Hsp background corrected.tif");
        run("Close");
roiManager("reset");

//-------------------------------------------------------------------------------------------------------------
// NON-COLOCALISATION SECTION with trajectories for non-colocalised molecules
//-------------------------------------------------------------------------------------------------------------

noncoloc_output_folder = trajectories_output + "/non-coloc/"
print(noncoloc_output_folder);
File.makeDirectory(noncoloc_output_folder);

//make subfolders for hsp vs client
client_noncoloc_trajectories = noncoloc_output_folder + "/Client/"
print(client_noncoloc_trajectories);
File.makeDirectory(client_noncoloc_trajectories);

hsp_noncoloc_trajectories = noncoloc_output_folder + "/Hsp/"
print(hsp_noncoloc_trajectories);
File.makeDirectory(hsp_noncoloc_trajectories);

//client
open(client_results);
IJ.renameResults("client");
open(Hsp_results);	
IJ.renameResults("Hsp");
run("count colocalized peaks Andrew", "table_1=client table_2=Hsp maximum_distance=3");
selectWindow("Hsp");
		run("Close")
selectWindow("client");
IJ.renameResults("Results");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_noncolocal_v2.ijm")
selectWindow("Colocalization");
close()
IJ.renameResults("client_non-colocalisation")
selectWindow("client_non-colocalisation")
saveAs("Results", output + "client_non-colocalisation.csv"); 
selectWindow("client_non-colocalisation.csv");
     run("Close"); 


open(client_image);
open("client_non-colocalisation.csv");
IJ.renameResults("Results")
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/results_to_ROI.txt"); // you need to put the location of your script
selectWindow("Results");
        run("Close");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
selectWindow("Results");
        saveAs("Results", output + "client_non-colocal_traj.csv");
selectWindow("Results");
     	saveAs("Results", client_noncoloc_trajectories + Imagetitle + "_Client_non-colocal_traj.csv");
        run("Close");
selectWindow("Client.tif");
        run("Close");
roiManager("reset");

//Hsp
open(Hsp_results);
IJ.renameResults("Hsp");
open(client_results);
IJ.renameResults("client");
run("count colocalized peaks Andrew", "table_1=Hsp table_2=client maximum_distance=3");

selectWindow("client");
		run("Close")
selectWindow("Hsp");
IJ.renameResults("Results");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_noncolocal_v2.ijm")
selectWindow("Colocalization");
		close()
IJ.renameResults("Hsp_non-colocalisation")
selectWindow("Hsp_non-colocalisation")
saveAs("Results", output + "Hsp_non-colocalisation.csv"); 

selectWindow("Hsp_non-colocalisation.csv");
     run("Close"); 

open(Hsp_image);	
open("Hsp_non-colocalisation.csv");
IJ.renameResults("Results")
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/results_to_ROI.txt"); // you need to put the location of your script
selectWindow("Results");
        run("Close");
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/LRplugins/plugins/Macros/peak_intensity.txt"); // you need to put the location of your script
//selectWindow("Results");
        saveAs("Results", output + "Hsp_non-colocal_traj.csv");
selectWindow("Results");
     	saveAs("Results", hsp_noncoloc_trajectories + Imagetitle + "_Hsp_non-colocal_traj.csv");
        run("Close");
selectWindow("Hsp background corrected.tif");
        run("Close");
roiManager("reset");

//-------------------------------------------------------------------------------------------------------------
// RANDOMISING ("SCRAMBLING") COORDINATES AND THEN COLOCALISATION WITH THESE COORDINATES SECTION
//-------------------------------------------------------------------------------------------------------------

// this section is to assess the degree of random colocalisations that may occur due to overlapping molecules on the coverslip
// to do this it randomises the locations of all of the Hsp foci and then looks for how much colocalisation there is with
// these randomised coordinates


open("Hsp_results.csv")
IJ.renameResults("Hsp");
open("Client_results.csv");
IJ.renameResults("Client");

// this is the macro that takes the x- and y-coordinates and randomises them - it does this by getting the maximum and 
// minimum x and y positions that are possible (to get an idea of how big the image is) and then randomises each foci
// within these maximum and minimum bounds
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/scramble_xy.js")
selectWindow("Hsp");
saveAs("Results", hsp_output_folder + Imagetitle + "_Hsp_scrambled_results.csv");
name_of_scrambled_csv = Imagetitle + "_Hsp_scrambled_results.csv";
IJ.renameResults("Hsp");

//now running the colocalisation macro plugin thing
run("count colocalized peaks Andrew", "table_1=Client table_2=Hsp maximum_distance=3");
selectWindow("Colocalization");
close()
selectWindow("Client");
//saveAs("Results", output + "Fibril_colocalisation.csv"); 
saveAs("Results", client_output_folder + Imagetitle + "_client_scramble_Hsp_results.csv");
IJ.renameResults("Results");
selectWindow("Hsp");
		run("Close")
		
//now filter these data for only those colocalised not all the spots combined.
runMacro("C:/Nicola/UNIVERSITY/PhD/SM/ImageJ macros/Filter_for_colocal.ijm")
IJ.renameResults("Client_scramble_colocalisation_only")
selectWindow("Client_scramble_colocalisation_only");
//saveAs("Results", output + "Fibril_colocalisation_only.csv"); 
saveAs("Results", client_output_folder + Imagetitle + "_scramble_colocalized.csv");
run("Close");
//name_of_scrambled_csv = Imagetitle + "_Hsp_scrambled_results.csv";
//selectWindow(name_of_scrambled_csv);
//run("Close");
roiManager("reset");

// ----------------- Saving some of the files in a different folder -----------------

open("Client_results.csv");
IJ.renameResults("Results");
saveAs("Results", client_output_folder + Imagetitle + "_client_results.csv");
run("Close")

open("client_colocalisation.csv");
IJ.renameResults("Results");
saveAs("Results", client_output_folder + Imagetitle + "_client_colocalisation.csv");
run("Close")

open("client_non-colocalisation.csv");
IJ.renameResults("Results");
saveAs("Results", client_output_folder + Imagetitle + "_client_non-colocalisation.csv");
run("Close")

open("Hsp_results.csv");
IJ.renameResults("Hsp");
saveAs("Results", hsp_output_folder + Imagetitle + "_Hsp_results.csv");
run("Close")

open("Hsp_non-colocalisation.csv");
IJ.renameResults("Results");
saveAs("Results", hsp_output_folder + Imagetitle + "_hsp_non-colocalisation.csv");
run("Close")

//-------------------------------------------------------------------------------------------------------------
// FINISHING UP
//-------------------------------------------------------------------------------------------------------------

// ----------------- Closing some things that are still open -----------------

// comment these out if they are not still open

selectWindow("Hsp");
run("Close");

selectWindow("Client");
run("Close");

// ----------------- End -----------------

roiManager("reset");

close("*");
waitForUser("All done! :) \n \nPress OK to continue. Close ROI manager before running script again :)");

}
