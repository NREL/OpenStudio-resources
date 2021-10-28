function Controller () {
  // silent install is not an option until QtIFW v3.0.1
  // gui.setSilent(true);
}

Controller.prototype.IntroductionPageCallback = function () {
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function () {
  var widget = gui.currentPageWidget();

  // to install a subset of components, uncomment the code below and edit as neccesary
  //widget.deselectAll();
  //widget.selectComponent('CLI');
  //widget.selectComponent('RubyAPI');
  //widget.selectComponent('CSharpAPI');
  //widget.selectComponent('EnergyPlus');
  //widget.selectComponent('Resources');

  gui.clickButton(buttons.NextButton);
}

Controller.prototype.TargetDirectoryPageCallback = function () {
  // set install directory if needed
  var widget = gui.currentPageWidget();
  widget.TargetDirectoryLineEdit.setText("c:\\openstudio")
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function () {
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function () {
  gui.clickButton(buttons.NextButton);
}

Controller.prototype.FinishedPageCallback = function () {
  gui.clickButton(buttons.FinishButton);
}
