

function universalcode()
{
    // set variable for idf path based on test case name.
    var fullPath = squishinfo.testCase;
    var casename = fullPath.replace(/^.*\\/, '');//regex to isolate path
    var filename = casename.replace('tst_',''); // removing squish prefix
    var vpname = filename.replace ('.idf',''); // used to create unique names for VP's in shared folder
    var nonsvnpath = ('C:\\OpenStudio_Squish_SVN\\squish'); // user or cmake needs to set this path
    var squishtestingresources = (nonsvnpath + '\\SquishTestingResources\\');// changes based on suite name
    var sourcepath = ('C:\\EnergyPlusV6-0-0\\ExampleFiles\\') // this is set by test programmer for each test suite
    var exportpath = (nonsvnpath + '\\SquishTestingExports\\OSSP_XP_IDF_xmpl-exports\\' + vpname + '.osm'); // user or cmake needs to make these folders
    // test.log ('path to resources - ' + squishtestingresources);
    // test.log ('path to Source files - ' + sourcepath);
    // test.log ('path to export - ' + exportpath);
    
    testSettings.logScreenshotOnFail = true;
    testSettings.logScreenshotOnError = true;
    snooze(2.0);
    startApplication("SketchUp");
    snooze(2.0);

    // seems I may need a mouse click before text for squish via command line to run properly
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Edit"));
    mouseClick(waitForObjectItem(":Edit_MenuItem", "Select All"));
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Edit"));
    mouseClick(waitForObjectItem(":Edit_MenuItem", "Select None"));

    // this will close the model info dialog if it has previouslly been left open
    if (object.exists(":Model Info_Dialog"))
    mouseClick(waitForObject(":Model Info_Dialog"), 449, 11, MouseButton.LeftButton);
    else
      ; //do nothing
    
        // this will close the model info dialog if it has previouslly been left open
    if (object.exists(":Rendering Settings_Dialog"))
    mouseClick(waitForObject(":Rendering Settings_Dialog"), 672, 16, MouseButton.LeftButton);
    else
      ; //do nothing

    snooze(2.0);
    type(waitForObject(":Untitled - SketchUp Pro_WindowsControl"), "<Ctrl+O>");
    snooze(2.0); // these one second snoozes are adding stability to the test
    type(waitForObject(":Open_Edit"), squishtestingresources + "four_scenes.skp"); //this is an emtpy SketchUp file with four scenes saved for VP screenshots
    snooze(1.0);
    type(waitForObject(":Open_Edit"), "<Return>");
    snooze(2.0);
    type(waitForObject(":four_scenes.skp - SketchUp Pro_WindowsControl"), "<Ctrl+Alt+O>"); //Ctrl+Alt+O shortcut is set to import IDF
    snooze(1.0);
    // don't save currently open model
    type(waitForObject(":SketchUp.Yes_Button"), "<Tab>");
    type(waitForObject(":SketchUp.No_Button"), "<Return>");
    snooze(1.0);
    type(waitForObject(":_Edit"), sourcepath + filename);
    snooze(1.0);
    type(waitForObject(":_Edit"), "<Return>");
    // start IDF Import Timer
    var dTime = new Date();
    var millisec_a = dTime.getTime();
    type(waitForObject(":SketchUp.Yes_Button",600000), "<Tab>");// 10 minute delay allowed for file opening

    // either default construction or bad file alert will come up if else statement to deal with them
    if (object.exists(":SketchUp.File does not have a default construction set."))
        type(waitForObject(":SketchUp.No_Button"), "<Return>");
    else
        //this will only run if alert is open e.g. if file is already bad
        type(waitForObject(":SketchUp.No_Button"), "<Return>"),
        waitFor("object.exists(':OpenStudio:  Input File Errors And Warnings_Edit')", 20000),
        test.log ('bad file warning - ' + findObject(":OpenStudio:  Input File Errors And Warnings_Edit").text),
        type(waitForObject(":OpenStudio:  Input File Errors And Warnings.OK_Button"), "<Return>"),
        exit;
        //end test here

    // report IDF Import Timer
    var dTime = new Date();
    var millisec_b = dTime.getTime();
    var elapsedtime = (millisec_b - millisec_a)/1000;
    test.log ("IDF Import - seconds elapsed = " + elapsedtime);
    snooze(1.0);

    // log text in error and warning dialog
    waitFor("object.exists(':OpenStudio:  Input File Errors And Warnings_Edit')", 5000);
    if (object.exists(":OpenStudio:  Input File Errors And Warnings.OK_Button"))
    // if had individual scripts for each IDF could use compare verification to expected results vs just a log
    test.log ('import warning - ' + findObject(":OpenStudio:  Input File Errors And Warnings_Edit").text),
    type(waitForObject(":OpenStudio:  Input File Errors And Warnings.OK_Button"), "<Return>");
    else
        ;//nothing to do, procede with rest of test
    snooze(1.0);
   
    // open model info to make statistics visible - add if statement no to open if already open
    mouseClick(waitForObjectItem(":four_scenes.skp - SketchUp Pro_MenuBar", "Window")),     
    mouseClick(waitForObjectItem(":Window_MenuItem", "Model Info")),
    mouseClick(waitForObjectItem(":Model Info_List", "Statistics"));
    snooze(1.0);
    
    // log how many faces and groups and edges in model
    test.log ('number of edges ' + findObject("{container=':Edges_ListViewItem'}").text)
    test.log ('number of faces ' + findObject("{container=':Faces_ListViewItem'}").text)
    test.log ('number of groups ' + findObject("{container=':Groups_ListViewItem'}").text)
    mouseClick(waitForObjectItem(":four_scenes.skp - SketchUp Pro_MenuBar", "Window"));
    mouseClick(waitForObjectItem(":Window_MenuItem", "Model Info"));

    snooze(1.0);
    type(waitForObject(":four_scenes.skp - SketchUp Pro_WindowsControl"), "<Alt+S>"); //Alt+S shortcut is set to save the OSM model.
    snooze(1.0);
    type(waitForObject(":_Edit"), exportpath);
    snooze(1.0);
    type(waitForObject(":_Edit"), "<Return>");
    snooze(1.0);
    // start OSM Save Timer
    var dTime = new Date();
    var millisec_a = dTime.getTime();

     // overwrite if there is an existing OSM
    if (object.exists(":Save OpenStudio Model.No_Button"))
        type(waitForObject(":Save OpenStudio Model.No_Button"), "<Tab>"),
        type(waitForObject(":Save OpenStudio Model.Yes_Button"), "<Return>");
    else
        ;//nothing to do, procede with rest of test

    // need to put object here to wait until save is done
    waitFor("object.exists(':four_scenes.skp - SketchUp Pro_MenuBar')", 900000);

    // report OSM Save Timer
    var dTime = new Date();
    var millisec_b = dTime.getTime();
    var elapsedtime = (millisec_b - millisec_a)/1000;
    test.log ("OSM Save - seconds elapsed = " + elapsedtime);
    // for now I replaced the screenshot verification with a basic screenshot capture
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "r"); // r shortcut is set to zoom extents
    snooze(1.0);
    //capture screenshot here, Alt+2 set as shortcut for 2d export
    type(waitForObject(":four_scenes.skp - SketchUp Pro_WindowsControl"), "<Alt+2>");
    type(waitForObject(":_Edit"), nonsvnpath + '\\SquishTestingExports\\OSSP_XP_IDF_xmpl-exports\\' + vpname + '.jpg');
    type(waitForObject(":_Edit"), "<Return>");

    //dismiss jpg warning if it already exists, overwrite if there is an existing jpg
    if (object.exists(":Export 2D Graphic.No_Button"))
       type(waitForObject(":Export 2D Graphic.No_Button"), "<Tab>"),
       type(waitForObject(":Export 2D Graphic.Yes_Button"), "<Return>");
    else
        ;//nothing to do, procede with rest of test

    // re-open OSM that was just saved to record elpased open time
    snooze(1.0);
    type(waitForObject(":four_scenes.skp - SketchUp Pro_WindowsControl"), "<Alt+O>"); //Alt+O shortcut is set to open an OSM
    snooze(1.0);
    // don't save currently open model
    type(waitForObject(":SketchUp.Yes_Button"), "<Tab>");
    type(waitForObject(":SketchUp.No_Button"), "<Return>");
    snooze(1.0);
    type(waitForObject(":_Edit"), exportpath);
    snooze(1.0);
    type(waitForObject(":_Edit"), "<Return>");
    // start OSM Open Timer
    var dTime = new Date();
    var millisec_a = dTime.getTime();
    type(waitForObject(":SketchUp.Yes_Button",600000), "<Tab>");// 10 minute delay allowed for file opening

    // either default construction or bad file alert will come up if else statement to deal with them
    if (object.exists(":SketchUp.File does not have a default construction set."))
        type(waitForObject(":SketchUp.No_Button"), "<Return>");
    else
        //this will only run if alert is open e.g. if file is already bad
        //may need to re-write this for osm file, but should have any bad files if the IDF opened
        type(waitForObject(":SketchUp.No_Button"), "<Return>"),
        waitFor("object.exists(':OpenStudio:  Input File Errors And Warnings_Edit')", 20000),
        test.log ('bad file warning - ' + findObject(":OpenStudio:  Input File Errors And Warnings_Edit").text),
        type(waitForObject(":OpenStudio:  Input File Errors And Warnings.OK_Button"), "<Return>"),
        exit;
        //end test here

    // report OSM Open Timer
    var dTime = new Date();
    var millisec_b = dTime.getTime();
    var elapsedtime = (millisec_b - millisec_a)/1000;
    test.log ("OSM Open - seconds elapsed = " + elapsedtime);
}