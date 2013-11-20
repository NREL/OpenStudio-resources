
function main()
{
    startApplication("ResultsViewer");
    activateItem(waitForObjectItem(":Results Viewer.menuBar_QMenuBar", "File"));
    activateItem(waitForObjectItem(":Results Viewer.File_QMenu", "Open"));
    waitForObjectItem(":splitter.sidebar_QSidebar", "My Computer");
    doubleClickItem(":splitter.sidebar_QSidebar", "My Computer", 53, 13, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "C:");
    clickItem(":stackedWidget.listView_QListView", "C:", 19, 13, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "C:");
    doubleClickItem(":stackedWidget.listView_QListView", "C:", 16, 10, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "projects");
    doubleClickItem(":stackedWidget.listView_QListView", "projects", 42, 4, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "openstudio-resources");
    doubleClickItem(":stackedWidget.listView_QListView", "openstudio-resources", 51, 6, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "squish");
    doubleClickItem(":stackedWidget.listView_QListView", "squish", 35, 7, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "suite\\_ResultsViewer\\_Sanity");
    doubleClickItem(":stackedWidget.listView_QListView", "suite\\_ResultsViewer\\_Sanity", 61, 4, 0, Qt.LeftButton);
    waitForObjectItem(":stackedWidget.listView_QListView", "Daylighting\\_Office\\.sql");
    clickItem(":stackedWidget.listView_QListView", "Daylighting\\_Office\\.sql", 55, 11, 0, Qt.LeftButton);
    sendEvent("QMouseEvent", waitForObject(":Open SQLite Database.Open_QPushButton"), QEvent.MouseButtonPress, 48, 7, Qt.LeftButton, 0);
    sendEvent("QMouseEvent", waitForObject(":Open SQLite Database.Open_QPushButton"), QEvent.MouseButtonRelease, 48, 7, Qt.LeftButton, 1);
    waitFor("object.exists(':Select File.suite_ResultsViewer_Sanity_QModelIndex')", 20000);
    test.compare(findObject(":Select File.suite_ResultsViewer_Sanity_QModelIndex").text, "suite_ResultsViewer_Sanity");
    sendEvent("QCloseEvent", waitForObject(":Results Viewer_resultsviewer::MainWindow"));
}
