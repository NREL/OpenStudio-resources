

function universalcode()
{
    // set variable for idf path based on test case name.
    var fullPath = squishinfo.testCase;
    var casename = fullPath.replace(/^.*\\/, '');//regex to isolate path
    var filename = casename.replace('tst_',''); // removing squish prefix
    var vpname = filename.replace ('.idf',''); // used to create unique names for VP's in shared folder
    var squishtestingresources = fullPath.replace('suite_OS_SP_IdfImport\\tst_' + filename,'SquishTestingResources\\');// changes based on suite name
    test.log ('path to resources - ' + squishtestingresources);
    var nonsvnpath = ('C:\\OpenStudio_Squish_SVN\\squish'); // user or cmake needs to set this path
    var sourcepath = ('EP6 IDF test inputs\\') // this is set by test programmer for each test suite
    var exportpath = (nonsvnpath + '\\SquishTestingExports\\OS_SP_IdfImport-exports\\' + vpname + '.osm'); // user or cmake needs to make these folders
    test.log ('path to export - ' + exportpath);

    testSettings.logScreenshotOnFail = true; 
    testSettings.logScreenshotOnError = true;
    snooze(1.0);
    type(waitForObject(":Untitled - SketchUp Pro_WindowsControl"), "<Ctrl+O>");
    snooze(1.0); // these one second snoozes are adding stability to the test
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
    type(waitForObject(":_Edit"), squishtestingresources + sourcepath + filename);
    snooze(1.0);
    type(waitForObject(":_Edit"), "<Return>");
    test.log ("IDF Import - Start");
    type(waitForObject(":SketchUp.Yes_Button",300000), "<Tab>");// 5 minute delay allowed for file opening

    // either default construction or bad file alert will come up if else statement to deal with them
    if (object.exists(":SketchUp.File does not have a default construction set."))
        type(waitForObject(":SketchUp.No_Button"), "<Return>"),
        test.log ("IDF Import - Finish"),
        snooze(1.0);
    else
        //this will only run if alert is open e.g. if file is already bad
        type(waitForObject(":SketchUp.No_Button"), "<Return>"),
        waitFor("object.exists(':OpenStudio:  Input File Errors And Warnings_Edit')", 20000),
        test.log ('bad file warning - ' + findObject(":OpenStudio:  Input File Errors And Warnings_Edit").text),
        type(waitForObject(":OpenStudio:  Input File Errors And Warnings.OK_Button"), "<Return>"),
        exit;
        //end test here
    
    // log text in error and warning dialog
    // in the future this will come up when populated, so I can do an if else statement to log and close it
    mouseClick(waitForObjectItem(":four_scenes.skp - SketchUp Pro_MenuBar", "Plugins"));
    mouseClick(waitForObjectItem(":Plugins_MenuItem_2", "OpenStudio"));
    mouseClick(waitForObjectItem(":Plugins.OpenStudio_MenuItem_2", "Show Errors And Warnings"));
    waitFor("object.exists(':OpenStudio:  Input File Errors And Warnings_Edit')", 20000);
    // if had individual scripts for each IDF could use compare verification to expected results vs just a log
    test.log ('import warning - ' + findObject(":OpenStudio:  Input File Errors And Warnings_Edit").text)
    type(waitForObject(":OpenStudio:  Input File Errors And Warnings.OK_Button"), "<Return>");
            
    // log how many faces and groups in model
    mouseClick(waitForObjectItem(":four_scenes.skp - SketchUp Pro_MenuBar", "Window"));
    mouseClick(waitForObjectItem(":Window_MenuItem", "Model Info"));
    mouseClick(waitForObjectItem(":Model Info_List", "Statistics"));
    snooze(1.0);

    //test.compare(findObject("{container=':Faces_ListViewItem'}").text, "43");
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
    test.log ("OSM Save - Start");
    snooze(1.0);
   
     // overwrite if there is an existing OSM
    if (object.exists(":Save OpenStudio Model.No_Button"))
        type(":Save OpenStudio Model.No_Button", "<Tab>"),
        snooze(1.0),
        type(":Save OpenStudio Model.Yes_Button", "<Return>"),
        snooze(1.0);
    else
        ;//nothing to do, procede with rest of test
    
    test.log ("OSM Save - Finish");
    // the VP files need to exist before this can be run, on dymaic test may need to skip this or find another solution
    // also is running hundreds of files, I may just want a single screenshot vs. verification?
    mouseClick(waitForObject(":four_scenes.skp - SketchUp Pro_Window"), 1, 1, MouseButton.LeftButton);
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "r"); // r shortcut is set to zoom extents
    snooze(1.0);
    test.vp(vpname + "_VP1"); // this is the first of four squish screenshot verification points
    snooze(1.0);
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "<PageDown>");
    snooze(1.0);
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "r");
    test.vp(vpname + "_VP2");
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "<PageDown>");
    snooze(1.0);
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "r");
    test.vp(vpname + "_VP3");
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "<PageDown>");
    snooze(1.0);
    type(":four_scenes.skp - SketchUp Pro_WindowsControl", "r");
    test.vp(vpname + "_VP4");
 }
