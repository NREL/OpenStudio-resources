
function main()
{
    startApplication("RunManager");
    waitFor("object.exists(':listFiles.1ZoneEvapCooler.idf_QModelIndex')", 20000);
    test.compare(findObject(":listFiles.1ZoneEvapCooler.idf_QModelIndex").text, "1ZoneEvapCooler.idf");
    waitFor("object.exists(':listFiles.1ZoneParameterAspect.idf_QModelIndex')", 20000);
    test.compare(findObject(":listFiles.1ZoneParameterAspect.idf_QModelIndex").text, "1ZoneParameterAspect.idf");
    waitFor("object.exists(':listFiles.1ZoneUncontrolled.idf_QModelIndex')", 20000);
    test.compare(findObject(":listFiles.1ZoneUncontrolled.idf_QModelIndex").text, "1ZoneUncontrolled.idf");
    waitFor("object.exists(':listFiles.1ZoneUncontrolledCondFDWithVariableKat24C.idf_QModelIndex')", 20000);
    test.compare(findObject(":listFiles.1ZoneUncontrolledCondFDWithVariableKat24C.idf_QModelIndex").text, "1ZoneUncontrolledCondFDWithVariableKat24C.idf");
    openItemContextMenu(waitForObject(":tab.listFiles_QTreeView"), "1ZoneEvapCooler\\.idf", 55, 5, 0);
    waitForObjectItem(":tab.listFiles_QTreeView", "1ZoneEvapCooler\\.idf");
    clickItem(":tab.listFiles_QTreeView", "1ZoneEvapCooler\\.idf", 35, 6, 0, Qt.LeftButton);
    openItemContextMenu(waitForObject(":tab.listFiles_QTreeView"), "5ZoneAirCooled\\.idf", 53, 7, 0);
    waitForObjectItem(":tab.listFiles_QTreeView", "1ZoneEvapCooler\\.idf");
    clickItem(":tab.listFiles_QTreeView", "1ZoneEvapCooler\\.idf", 55, 9, 0, Qt.LeftButton);
    type(waitForObject(":tab.listFiles_QTreeView"), "<Shift>");
    waitForObjectItem(":tab.listFiles_QTreeView", "5ZoneAirCooled\\.idf");
    clickItem(":tab.listFiles_QTreeView", "5ZoneAirCooled\\.idf", 58, 5, 33554432, Qt.LeftButton);
    openItemContextMenu(waitForObject(":tab.listFiles_QTreeView"), "5ZoneAirCooled\\.idf", 58, 5, 0);
    activateItem(waitForObjectItem(":Run Manager_QMenu", "Check Selected"));
    clickButton(waitForObject(":tab.Add to Queue_QPushButton"));
    clickButton(waitForObject(":No EPW Selected.OK_QPushButton"));
    clickButton(waitForObject(":Add Jobs To Queue?.OK_QPushButton"));
    clickTab(waitForObject(":Run Manager.qt_tabwidget_tabbar_QTabBar"), "Job Queue");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneEvapCooler.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneEvapCooler.idf)_QModelIndex").text, "EnergyPlus (1ZoneEvapCooler.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneParameterAspect.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneParameterAspect.idf)_QModelIndex").text, "EnergyPlus (1ZoneParameterAspect.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneUncontrolled.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneUncontrolled.idf)_QModelIndex").text, "EnergyPlus (1ZoneUncontrolled.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneUncontrolledCondFDWithVariableKat24C.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneUncontrolledCondFDWithVariableKat24C.idf)_QModelIndex").text, "EnergyPlus (1ZoneUncontrolledCondFDWithVariableKat24C.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneUncontrolled_DDChanges.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneUncontrolled_DDChanges.idf)_QModelIndex").text, "EnergyPlus (1ZoneUncontrolled_DDChanges.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneUncontrolled_FCfactor_Slab_UGWall.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneUncontrolled_FCfactor_Slab_UGWall.idf)_QModelIndex").text, "EnergyPlus (1ZoneUncontrolled_FCfactor_Slab_UGWall.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneUncontrolled_win_1.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneUncontrolled_win_1.idf)_QModelIndex").text, "EnergyPlus (1ZoneUncontrolled_win_1.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (1ZoneUncontrolled_win_2.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (1ZoneUncontrolled_win_2.idf)_QModelIndex").text, "EnergyPlus (1ZoneUncontrolled_win_2.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (4ZoneWithShading_Simple_1.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (4ZoneWithShading_Simple_1.idf)_QModelIndex").text, "EnergyPlus (4ZoneWithShading_Simple_1.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (4ZoneWithShading_Simple_2.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (4ZoneWithShading_Simple_2.idf)_QModelIndex").text, "EnergyPlus (4ZoneWithShading_Simple_2.idf)");
    waitFor("object.exists(':treeView.EnergyPlus (5ZoneAirCooled.idf)_QModelIndex')", 20000);
    test.compare(findObject(":treeView.EnergyPlus (5ZoneAirCooled.idf)_QModelIndex").text, "EnergyPlus (5ZoneAirCooled.idf)");
    clickButton(waitForObject(":Run Manager.Pause_QToolButton"));
    waitForObjectItem(":tab_2.completedTreeView_QTreeView", "0_6");
    clickItem(":tab_2.completedTreeView_QTreeView", "0_6", 59, 10, 0, Qt.LeftButton);
    var running = new Boolean(true);
    var count = 0;
    while( running ) {
        if(object.exists(":completedTreeView.EnergyPlus (5ZoneAirCooled.idf)_QModelIndex")) {
            running = false;
        }else {
            snooze(5.0);
            ++count;
        }
        // Timeout if EnergyPlus gets stuck
        if( count > 20 ) {
            running = false;
        }
    }
    waitFor("object.exists(':completedTreeView.EnergyPlus (5ZoneAirCooled.idf)_QModelIndex')", 20000);
    test.vp("VP2");
    test.compare(findObject(":completedTreeView.EnergyPlus (5ZoneAirCooled.idf)_QModelIndex").text, "EnergyPlus (5ZoneAirCooled.idf)");
    openItemContextMenu(waitForObject(":tab_2.completedTreeView_QTreeView"), "EnergyPlus (5ZoneAirCooled\\.idf)", 11, 5, 0);
    activateItem(waitForObjectItem(":Run Manager_QMenu", "Show Job Warnings And Errors"));
    clickButton(waitForObject(":Dialog.OK_QPushButton"));
    openItemContextMenu(waitForObject(":tab_2.completedTreeView_QTreeView"), "EnergyPlus (1ZoneEvapCooler\\.idf)", 19, 10, 0);
    activateItem(waitForObjectItem(":Run Manager_QMenu", "Show Job Warnings And Errors"));
    clickButton(waitForObject(":Dialog.OK_QPushButton"));
    sendEvent("QMouseEvent", waitForObject(":Run Manager.qt_tabwidget_tabbar_QTabBar"), QEvent.MouseButtonPress, 150, 20, Qt.LeftButton, 0);
    sendEvent("QMouseEvent", waitForObject(":Run Manager.qt_tabwidget_tabbar_QTabBar_2"), QEvent.MouseButtonRelease, 150, 20, Qt.LeftButton, 1);
    waitForObjectItem(":tab_3.treeJobs_QTreeView", "EnergyPlus (1ZoneEvapCooler\\.idf)");
    clickItem(":tab_3.treeJobs_QTreeView", "EnergyPlus (1ZoneEvapCooler\\.idf)", 55, 11, 0, Qt.LeftButton);
    waitForObjectItem(":tab_3.treeView_QTreeView", "EnergyPlus (5ZoneAirCooled\\.idf)");
    clickItem(":tab_3.treeView_QTreeView", "EnergyPlus (5ZoneAirCooled\\.idf)", 93, 9, 0, Qt.LeftButton);
    waitForObjectItem(":tab_3.treeJobs_QTreeView", "EnergyPlus (5ZoneAirCooled\\.idf)");
    clickItem(":tab_3.treeJobs_QTreeView", "EnergyPlus (5ZoneAirCooled\\.idf)", 86, 9, 0, Qt.LeftButton);
    scrollTo(waitForObject(":txtStandardOut_QScrollBar"), 71);
    clickTab(waitForObject(":Run Manager.qt_tabwidget_tabbar_QTabBar"), "Details");
    snooze(1.0);
}
