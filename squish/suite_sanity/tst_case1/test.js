
function main()
{
    startApplication("SketchUp");

    snooze(5.0);
    // seems I may need a mouse click before text for squish via command line to run properly
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Edit"));
    mouseClick(waitForObjectItem(":Edit_MenuItem", "Select All"));
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Edit"));
    mouseClick(waitForObjectItem(":Edit_MenuItem", "Select None")); 
    
    snooze(2.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "<Alt+O>");
    snooze(2.0);
    type(":SketchUp.Yes_Button", "<Tab>");
    type(":SketchUp.No_Button", "<Return>");
    snooze(2.0);
    type(":Open OpenStudio Model File_Edit", "c:\\OpenStudio_Squish_SVN\\squish\\SquishTestingResources\\clean.osm");
    snooze(2.0);
    type(":Open OpenStudio Model File_Edit", "<Return>");
    snooze(2.0);
    mouseClick(":10509_ToolbarItem");
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "80");
    type(":Untitled - SketchUp Pro_WindowsControl", "<Return>");
    snooze(2.0);
    mouseClick(":50018_ToolbarItem");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 488, 556, MouseButton.LeftButton);
    snooze(2.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "`z");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 534, 554, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 821, 571, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "s");
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 670, 570, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 622, 397, MouseButton.LeftButton);
    snooze(2.0);
    mouseClick(":21094_ToolbarItem");
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 540, 428, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 587, 494, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 615, 465, MouseButton.LeftButton);
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 672, 617, MouseButton.LeftButton);
    snooze(2.0);
    mouseClick(":50019_ToolbarItem");
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 400, 621, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "`z");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 421, 623, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 560, 638, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "s");
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 490, 636, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 442, 534, MouseButton.LeftButton);
    snooze(2.0);
    type(":Untitled - SketchUp Pro_WindowsControl", " ");
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "<Escape>");
    snooze(2.0);
    mouseClick(":50020_ToolbarItem");
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 549, 729, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "`z");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 554, 729, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 750, 730, MouseButton.LeftButton);
    type(":Untitled - SketchUp Pro_WindowsControl", "s");
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 674, 729, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 626, 639, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", " ");
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "<Escape>");
    snooze(1.0);
    mouseClick(":50021_ToolbarItem");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 347, 687, MouseButton.LeftButton);
    snooze(2.0);
    mouseClick(":50022_ToolbarItem");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 803, 679, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", " ");
    type(":Untitled - SketchUp Pro_WindowsControl", "<Escape>");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 667, 463, MouseButton.LeftButton);
    snooze(3.0);
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Edit"));
    snooze(1.0);
    mouseClick(waitForObjectItem(":Edit_MenuItem", "Copy"));
    snooze(1.0);
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Edit"));
    snooze(1.0);
    mouseClick(waitForObjectItem(":Edit_MenuItem", "Paste"));
    snooze(3.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 1090, 544, MouseButton.LeftButton);
    snooze(2.0);
    mouseClick(":50018_ToolbarItem");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 1222, 741, MouseButton.LeftButton);
    snooze(2.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "`z");
    snooze(2.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 1243, 736, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 1535, 712, MouseButton.LeftButton);
    snooze(1.0);
    type(":Untitled - SketchUp Pro_WindowsControl", "s");
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 1423, 734, MouseButton.LeftButton);
    snooze(1.0);
    mouseClick(":Untitled - SketchUp Pro_WindowsControl", 1394, 616, MouseButton.LeftButton);
    snooze(2.0);
    type(":Untitled - SketchUp Pro_WindowsControl", " ");
    type(":Untitled - SketchUp Pro_WindowsControl", "<Escape>");
    snooze(1.0);
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Plugins"));
    snooze(1.0);
    mouseClick(waitForObjectItem(":Plugins_MenuItem", "OpenStudio"));
    snooze(1.0);
    mouseClick(waitForObjectItem(":Plugins.OpenStudio_MenuItem", "Save OpenStudio Model As"));
    snooze(1.0);
    type(":Save OpenStudio Model_Edit", "c:\\OpenStudio_Squish_SVN\\squish\\SquishTestingExports\\OSSP_XP_sanity-exports\\newname.osm");
    snooze(2.0);
    type(":Save OpenStudio Model_Edit", "<Return>");
    snooze(1.0);
    type(":Save OpenStudio Model.No_Button", "<Tab>");
    snooze(1.0);
    type(":Save OpenStudio Model.Yes_Button", "<Return>");
    snooze(2.0);
    mouseClick(":50042_ToolbarItem");
    snooze(2.0);
    type(":Run Simulation_WindowsControl", "<Return>");
    // long snooze to allow annual simulation to run
    snooze(73.0);
    // need better way to close status. Noot good if box is resized
    mouseClick(":Simulation Status_Window", 658, 14, MouseButton.LeftButton);
    snooze(2.0);
    mouseClick(":50043_ToolbarItem");
    snooze(2.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Return>");
    // pause to allow sql to load
    snooze(5.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Tab>");
    type(":Rendering Settings_WindowsControl", "<Tab>");
    snooze(1.0);
    type(":Rendering Settings_WindowsControl", "<Return>");
    // pause to allow variable to load
    snooze(5.0);
    mouseClick(":50036_ToolbarItem");
    snooze(2.0);

    // for now I replaced the screenshot verification with a basic screenshot capture
    type(":Untitled - SketchUp Pro_WindowsControl", "r"); // r shortcut is set to zoom extents
    snooze(1.0);
    //capture screenshot here, Alt+2 set as shortcut for 2d export
    type(waitForObject(":Untitled - SketchUp Pro_WindowsControl"), "<Alt+2>");
    type(waitForObject(":Export 2D Graphic_Edit"), 'c:\\OpenStudio_Squish_SVN\\squish\\SquishTestingResources\\newname.jpg');
    type(waitForObject(":Export 2D Graphic_Edit"), "<Return>");
    //dismiss jpg warning if it already exists, overwrite if there is an existing jpg
    // not sure why if statement isn't working
    //if (object.exists(":Export 2D Graphic.No_Button"))
        type(waitForObject(":Export 2D Graphic.No_Button"), "<Tab>"),
        type(waitForObject(":Export 2D Graphic.Yes_Button"), "<Return>");
    //else
    //    ;//nothing to do, procede with rest of test

    // launch ResultsViewer
    mouseClick(waitForObject(":50043_ToolbarItem"));
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Tab>");
    type(waitForObject(":Rendering Settings_WindowsControl"), "<Return>");
    ctx_1 = waitForApplicationLaunch();    
    snooze(5.0);
}
