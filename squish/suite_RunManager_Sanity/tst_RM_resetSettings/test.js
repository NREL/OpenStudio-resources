
function main()
{
    // This test doesn't seem to actually restore the defaults of the program. It could be that the 
    // squishserver doesn't have permission to change the settings file, or only changes it in some sort of sandbox
    startApplication("RunManager");
    activateItem(waitForObjectItem(":Run Manager.menubar_QMenuBar", "Settings"));
    activateItem(waitForObjectItem(":Run Manager.Settings_QMenu", "Preferences..."));
    waitFor("object.exists(':tab.idfLocationTxt_QLineEdit')", 20000);
    test.compare(findObject(":tab.idfLocationTxt_QLineEdit").objectName, "idfLocationTxt");
    waitFor("object.exists(':tab.epwLocationTxt_QLineEdit')", 20000);
    test.compare(findObject(":tab.epwLocationTxt_QLineEdit").objectName, "epwLocationTxt");
    waitFor("object.exists(':tab.In Place_QCheckBox')", 20000);
    test.compare(findObject(":tab.In Place_QCheckBox").checked, false);
    test.compare(findObject(":tab.In Place_QCheckBox").checkable, true);
    clickButton(waitForObject(":Run Manager Preferences.OK_QPushButton"));
    activateItem(waitForObjectItem(":Run Manager.menubar_QMenuBar", "File"));
    activateItem(waitForObjectItem(":Run Manager.File_QMenu", "Settings File"));
    clickButton(waitForObject(":Settings File.Restore Defaults_QPushButton"));
    snooze(1.0);
    sendEvent("QMouseEvent", waitForObject(":Restore Defaults.OK_QPushButton"), QEvent.MouseButtonPress, 36, 13, Qt.LeftButton, 0);
    sendEvent("QMouseEvent", waitForObject(":Restore Defaults.OK_QPushButton"), QEvent.MouseButtonRelease, 36, 13, Qt.LeftButton, 1);  
    
}
