
function main()
{
    var scratchFile = "C:\\OpenStudio_Squish_SVN\\squish\\SquishTestingResources\\scratch\\Untitled.osm";
    var expectedResult = "C:/OpenStudio_Squish_SVN/squish/SquishTestingResources/scratch/Untitled.osm";
    
    // remove scratch file
    if(File.exists(scratchFile)){
        File.remove(scratchFile);
    }
    test.verify(!File.exists(scratchFile));
        
    // open ruby console
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Window"));
    mouseClick(waitForObjectItem(":Window_MenuItem", "Ruby Console"));
    mouseClick(waitForObject(":_Edit"), 85, 19, MouseButton.LeftButton);
    waitFor("object.exists(':Ruby Console_Edit')", 20000);
    
    // load test file
    snooze(1)
    type(waitForObject(":_Edit"), "require 'openstudio/sketchup_plugin/test/clear_ruby_console.rb'");
    type(waitForObject(":_Edit"), "<Return>");
    snooze(1)
    
    // check path is nil
    type(waitForObject(":_Edit"), "clear_ruby_console");
    type(waitForObject(":_Edit"), "<Return>");
    type(waitForObject(":_Edit"), "OpenStudio::Plugin.model_manager.model_interface.openstudio_path");
    type(waitForObject(":_Edit"), "<Return>");
    snooze(1)
    test.log(findObject(":Ruby Console_Edit").text)
    test.compare(findObject(":Ruby Console_Edit").text, "\r\nOpenStudio::Plugin.model_manager.model_interface.openstudio_path\r\nnil\r\n");
    
    // check pathwatcher is nil
    type(waitForObject(":_Edit"), "clear_ruby_console");
    type(waitForObject(":_Edit"), "<Return>");
    type(waitForObject(":_Edit"), "OpenStudio::Plugin.model_manager.model_interface.path_watcher");
    type(waitForObject(":_Edit"), "<Return>");
    snooze(1)
    test.log(findObject(":Ruby Console_Edit").text)
    test.compare(findObject(":Ruby Console_Edit").text, "\r\nOpenStudio::Plugin.model_manager.model_interface.path_watcher\r\nnil\r\n");
    
    // save file
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "Plugins"));
    mouseClick(waitForObjectItem(":Plugins_MenuItem", "OpenStudio"));
    mouseClick(waitForObjectItem(":Plugins.OpenStudio_MenuItem", "Save OpenStudio Model"));
    type(waitForObject(":Save OpenStudio Model_Edit"), scratchFile);
    type(waitForObject(":Save OpenStudio Model_Edit"), "<Return>");
        
    test.verify(!object.exists(":Confirm Save As.Yes_Button"))
    test.verify(!object.exists(":Confirm Save As.No_Button"))

    snooze(10)
    
    test.verify(File.exists(scratchFile));

    // check path is correct
    type(waitForObject(":_Edit"), "clear_ruby_console");
    type(waitForObject(":_Edit"), "<Return>");
    type(waitForObject(":_Edit"), "OpenStudio::Plugin.model_manager.model_interface.openstudio_path");
    type(waitForObject(":_Edit"), "<Return>");
    snooze(1)
    test.log(findObject(":Ruby Console_Edit").text)
    test.compare(findObject(":Ruby Console_Edit").text, "\r\nOpenStudio::Plugin.model_manager.model_interface.openstudio_path\r\n" + expectedResult + "\r\n");

    // check pathwatcher is not nil
    type(waitForObject(":_Edit"), "clear_ruby_console");
    type(waitForObject(":_Edit"), "<Return>");
    type(waitForObject(":_Edit"), "OpenStudio::Plugin.model_manager.model_interface.path_watcher");
    type(waitForObject(":_Edit"), "<Return>");
    snooze(1)
    test.log(findObject(":Ruby Console_Edit").text)
    test.xcompare(findObject(":Ruby Console_Edit").text, "\r\nOpenStudio::Plugin.model_manager.model_interface.path_watcher\r\nnil\r\n");
        
    mouseClick(waitForObjectItem(":Untitled - SketchUp Pro_MenuBar", "File"));
    mouseClick(waitForObjectItem(":File_MenuItem", "Exit"));
}
