
function main()
{
    startApplication("ResultsViewer");
    activateItem(waitForObjectItem(":Results Viewer.menuBar_QMenuBar", "File"));
    activateItem(waitForObjectItem(":Results Viewer.File_QMenu", "Open"));
    waitForObjectItem(":stackedWidget.listView_QListView", "Daylighting\\_Office\\.sql");
    clickItem(":stackedWidget.listView_QListView", "Daylighting\\_Office\\.sql", 108, 1, 0, Qt.LeftButton);
    sendEvent("QMouseEvent", waitForObject(":Open SQLite Database.Open_QPushButton"), QEvent.MouseButtonPress, 41, 9, Qt.LeftButton, 0);
    sendEvent("QMouseEvent", waitForObject(":Open SQLite Database.Open_QPushButton"), QEvent.MouseButtonRelease, 41, 9, Qt.LeftButton, 1);
    openItemContextMenu(waitForObject(":qt_tabwidget_stackedwidget_resultsviewer::TableView"), "10/0", 104, 20, 0);
    activateItem(waitForObjectItem(":Results Viewer.Table Context Menu_QMenu", "Line Plot"));
    test.vp("VP1");
    sendEvent("QCloseEvent", waitForObject(":Results Viewer_resultsviewer::MainWindow"));
}
