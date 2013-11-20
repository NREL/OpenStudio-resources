
function main()
{
    startApplication("ResultsViewer");
    activateItem(waitForObjectItem(":Results Viewer.menuBar_QMenuBar", "File"));
    activateItem(waitForObjectItem(":Results Viewer.File_QMenu", "Open"));
    waitForObjectItem(":stackedWidget.listView_QListView", "Daylighting\\_Office\\.sql");
    clickItem(":stackedWidget.listView_QListView", "Daylighting\\_Office\\.sql", 44, 10, 0, Qt.LeftButton);
    sendEvent("QMouseEvent", waitForObject(":Open SQLite Database.Open_QPushButton"), QEvent.MouseButtonPress, 35, 8, Qt.LeftButton, 0);
    sendEvent("QMouseEvent", waitForObject(":Open SQLite Database.Open_QPushButton"), QEvent.MouseButtonRelease, 35, 8, Qt.LeftButton, 1);
    clickTab(waitForObject(":MainSplitter.qt_tabwidget_tabbar_QTabBar"), "Tree View");
    waitForObjectItem(":qt_tabwidget_stackedwidget_resultsviewer::TreeView", "(suite\\_ResultsViewer\\_Sanity) - C:/projects/openstudio-resources/squish/suite\\_ResultsViewer\\_Sanity/Daylighting\\_Office\\.sql.RUNPERIOD 1.Hourly.Air Loop Total Cooling Energy.PSZ-AC:1");
    clickItem(":qt_tabwidget_stackedwidget_resultsviewer::TreeView", "(suite\\_ResultsViewer\\_Sanity) - C:/projects/openstudio-resources/squish/suite\\_ResultsViewer\\_Sanity/Daylighting\\_Office\\.sql.RUNPERIOD 1.Hourly.Air Loop Total Cooling Energy.PSZ-AC:1", 19, 9, 0, Qt.LeftButton);
    openItemContextMenu(waitForObject(":qt_tabwidget_stackedwidget_resultsviewer::TreeView"), "(suite\\_ResultsViewer\\_Sanity) - C:/projects/openstudio-resources/squish/suite\\_ResultsViewer\\_Sanity/Daylighting\\_Office\\.sql.RUNPERIOD 1.Hourly.Air Loop Total Cooling Energy.PSZ-AC:1", 19, 9, 0);
    activateItem(waitForObjectItem(":Results Viewer.Tree Context Menu_QMenu", "Flood Plot"));
    test.vp("VP1");
    sendEvent("QCloseEvent", waitForObject(":Results Viewer_resultsviewer::MainWindow"));
}
