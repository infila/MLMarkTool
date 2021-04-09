//
//  ViewController.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/14.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

class MarkViewController: NSViewController {
  
  @IBOutlet weak var dragDetectView: DragDetectView!
  @IBOutlet weak var filesTableView: NSTableView!
  
  @IBOutlet weak var labelTextField: NSTextField!
  @IBOutlet weak var xTextField: NSTextField!
  @IBOutlet weak var yTextField: NSTextField!
  @IBOutlet weak var widthTextField: NSTextField!
  @IBOutlet weak var heightTextField: NSTextField!

  @IBOutlet weak var imageScrollView: NSScrollView!
  @IBOutlet weak var imageContainerView: NSView!
  @IBOutlet weak var exportButton: NSButton!
  @IBOutlet weak var hintLabel: NSTextField!

  @IBOutlet weak var fastLabelsScrollView: NSScrollView!

  private var imageUrls: [URL] = []
  private var markersDic: [String: [Marker]] = [:] {
    didSet {
      self.exportButton.isEnabled = self.markersDic.count != 0
    }
  }
  
  private var selectedMarkerIndex: Int = -1 {
    didSet {
      refreshHighlightedMarkerRect()
      refreshMarkerPanel()
      refreshFastLabels()
    }
  }
  private var imageView: SelectableImageView?
  private var currentImageKey: String {
    if self.filesTableView.selectedRow >= 0 {
      return self.imageUrls[self.filesTableView.selectedRow].lastPathComponent
    }
    return ""
  }
  private var markerRectViews: [BorderRectView] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    dragDetectView.onFileChoosed = { [weak self] (urls: [URL]) in
      guard let self = self, urls.count > 0 else {
        return
      }
      
      self.imageUrls.append(contentsOf: urls)
      self.removeDuplicatedUrls()
      self.refreshAll(tableViewSelectedRow: self.imageUrls.firstIndex(of: urls[0])!)
    }
    refreshAll(tableViewSelectedRow: -1)
  }
  
  private func removeDuplicatedUrls() {
    imageUrls = Array(Set(self.imageUrls))
  }
  
  private func refreshAll(tableViewSelectedRow: Int) {
    filesTableView.reloadData()
    if tableViewSelectedRow >= 0 {
      filesTableView.selectRowIndexes(IndexSet(arrayLiteral: tableViewSelectedRow), byExtendingSelection: false)
    }
    refreshImageScrollView()
    refreshMarkerPanel()
    exportButton.isEnabled = markersDic.count != 0
    hintLabel.isHidden = imageUrls.count != 0
  }
  
  private func refreshImageScrollView() {
    imageScrollView.magnification = 1
    imageContainerView.removeSubviews()
    guard filesTableView.selectedRow >= 0 else {
      return
    }
    markerRectViews = []
    drawCurrentImage()
    drawMarkLabels()
  }
  
  private func drawCurrentImage() {
    let image = NSImage(byReferencing: imageUrls[filesTableView.selectedRow])
    let imageView = SelectableImageView(image: image)
    imageView.imageScaling = .scaleProportionallyUpOrDown
    self.imageView = imageView
    var x: CGFloat = 0
    var y: CGFloat = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
    if image.size.width / image.size.height > (imageContainerView.frame.size.width / imageContainerView.frame.size.height) {
      width = imageContainerView.frame.size.width
      height = image.size.height / image.size.width * width
      y = (imageContainerView.frame.size.height - height) / 2
      imageView.autoresizingMask = NSView.AutoresizingMask(rawValue: NSView.AutoresizingMask.width.rawValue + NSView.AutoresizingMask.height.rawValue + NSView.AutoresizingMask.minXMargin.rawValue + NSView.AutoresizingMask.maxXMargin.rawValue)
    } else {
      height = imageContainerView.frame.size.height
      width = image.size.width / image.size.height * height
      x = (imageContainerView.frame.size.width - width) / 2
      imageView.autoresizingMask = NSView.AutoresizingMask(rawValue: NSView.AutoresizingMask.width.rawValue + NSView.AutoresizingMask.height.rawValue + NSView.AutoresizingMask.minYMargin.rawValue + NSView.AutoresizingMask.maxYMargin.rawValue)
    }
    imageView.frame = NSRect(x: x, y: y, width: width, height: height)
    imageContainerView.addSubview(imageView)
    imageView.onRectSelected = { [weak self] (rect: CGRect) in
      guard let self = self, let imageView = self.imageView else { return }
      let imageKey = self.imageUrls[self.filesTableView.selectedRow].lastPathComponent
      if self.markersDic[imageKey] == nil {
        self.markersDic[imageKey] = []
      }
      self.markersDic[imageKey]!.append(Marker(label: self.labelTextField.stringValue,
                                               rect: self.convertToMLCoordinate(from: rect, imageView: imageView)))
      self.selectedMarkerIndex = self.markersDic[imageKey]!.count - 1
      self.drawMarkLabel(rect: rect, tag: self.selectedMarkerIndex)
      imageView.display()
    }
  }
  
  private func roundingRect(rect: CGRect) -> CGRect {
    return CGRect(x: lrintf(Float(rect.origin.x)),
                  y: lrintf(Float(rect.origin.y)),
                  width: lrintf(Float(rect.size.width)),
                  height: lrintf(Float(rect.size.height)))
  }
    
  private func drawMarkLabels() {
    guard let markers = markersDic[imageUrls[filesTableView.selectedRow].lastPathComponent],
      let imageView = imageView else {
      return
    }
    for i in 0 ..< markers.count {
      let marker = markers[i]
      drawMarkLabel(rect: convertToUICoordinate(from: marker.rect, imageView: imageView), tag: i)
    }
    self.selectedMarkerIndex = markers.count - 1
  }
  
  private func drawMarkLabel(rect: CGRect, tag: Int) {
    let view = BorderRectView(frame: rect)
    view.tag = tag
    view.onClicked = { [weak self] (view) in
      guard let self = self else { return }
      if self.selectedMarkerIndex != view.tag {
        self.selectedMarkerIndex = view.tag
      }
    }
    markerRectViews.append(view)
    imageView?.addSubview(view)
  }
  
  private func refreshHighlightedMarkerRect() {
    for i in 0 ..< markerRectViews.count {
      let view = markerRectViews[i]
      if i == selectedMarkerIndex {
        view.highLighted = true
      } else {
        view.highLighted = false
      }
    }
  }
  
  private func refreshMarkerPanel() {
    var enable = false
    if selectedMarkerIndex >= 0,
      let rect = markersDic[currentImageKey]?[selectedMarkerIndex].rect {
      enable = true
      xTextField.stringValue = String(format: "%.0f", rect.origin.x)
      yTextField.stringValue = String(format: "%.0f", rect.origin.y)
      widthTextField.stringValue = String(format: "%.0f", rect.size.width)
      heightTextField.stringValue = String(format: "%.0f", rect.size.height)
      let label = markersDic[currentImageKey]?[self.selectedMarkerIndex].label ?? ""
      if labelTextField.stringValue != label {
        labelTextField.stringValue = label
      }
    } else {
      xTextField.stringValue = ""
      yTextField.stringValue = ""
      widthTextField.stringValue = ""
      heightTextField.stringValue = ""
    }
    labelTextField.isEnabled = enable
    xTextField.isEnabled = enable
    yTextField.isEnabled = enable
    widthTextField.isEnabled = enable
    heightTextField.isEnabled = enable
  }
  
  private func refreshFastLabels() {
    fastLabelsScrollView.contentView.removeSubviews()
    guard markersDic.count != 0 else {
      return
    }

    var labels: [String] = []
    for (_, markers) in markersDic {
      for marker in markers {
        if let label = marker.label, !label.isEmpty && !labels.contains(label) {
          labels.append(label)
        }
      }
    }
    guard labels.count != 0 else {
      return
    }
    var x: CGFloat = 15
    let buttonWidth: (CGFloat, CGFloat) = (45, 80)
    let buttonHeight: CGFloat = 30
    let space: CGFloat = 15
    let containerHeight = fastLabelsScrollView.height
    for label in labels {
      let button = NSButton(title: label, target: self, action: #selector(fastLabelClicked(button:)))
      button.bezelStyle = .texturedRounded
      button.sizeToFit()
      let width = min(max(button.width, buttonWidth.0), buttonWidth.1)
      button.frame = CGRect(x: x, y: (containerHeight - buttonHeight) / 2, width: width, height: buttonHeight)
      fastLabelsScrollView.contentView.addSubview(button)
      x += width + space
    }
  }
  
  @objc private func fastLabelClicked(button: NSButton) {
    labelTextField.stringValue = button.title
    markersDic[currentImageKey]?[selectedMarkerIndex].label = button.title
  }
  
  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    if event.keyCode == 51 {
      if markerRectViews.count > 0 {
        markerRectViews[selectedMarkerIndex].removeFromSuperview()
        markerRectViews.remove(at: selectedMarkerIndex)
        markersDic[currentImageKey]?.remove(at: selectedMarkerIndex)
        selectedMarkerIndex = markerRectViews.count - 1
      } else if filesTableView.selectedRow >= 0 {
        let selectedRow = filesTableView.selectedRow
        imageUrls.remove(at: selectedRow)
        refreshAll(tableViewSelectedRow: min(selectedRow, imageUrls.count - 1))
      }
    }
  }
  
  private func convertToMLCoordinate(from UICoordinate: CGRect, imageView: SelectableImageView) -> CGRect {
    let x = UICoordinate.origin.x / imageView.imageScale
    let y = (imageView.frame.size.height - UICoordinate.origin.y - UICoordinate.size.height) / imageView.imageScale
    let width = UICoordinate.size.width / imageView.imageScale
    let height = UICoordinate.size.height / imageView.imageScale
    return CGRect(x: x, y: y, width: width, height: height)
  }
  
  private func convertToUICoordinate(from MLCoordinate: CGRect, imageView: SelectableImageView) -> CGRect {
    let x = MLCoordinate.origin.x * imageView.imageScale
    let y = imageView.frame.size.height - (MLCoordinate.origin.y + MLCoordinate.size.height) * imageView.imageScale
    let width = MLCoordinate.size.width * imageView.imageScale
    let height = MLCoordinate.size.height * imageView.imageScale
    return CGRect(x: x, y: y, width: width, height: height)
  }
}

extension MarkViewController: NSTableViewDataSource, NSTableViewDelegate {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.imageUrls.count
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    return nil
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCell"), owner: nil) as? NSTableCellView, imageUrls.count > row {
      cell.textField!.stringValue = String(imageUrls[row].lastPathComponent)
      return cell
    }
    return nil
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    refreshImageScrollView()
    refreshMarkerPanel()
    refreshFastLabels()
  }
}

extension MarkViewController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    guard let textField = obj.object as? NSTextField else { return }
    if textField == labelTextField {
      markersDic[currentImageKey]?[selectedMarkerIndex].label = textField.stringValue
      return
    }
    if textField.intValue < 0 {
      textField.intValue = 1
    }
    let rect = CGRect(x: xTextField.integerValue,
                      y: yTextField.integerValue,
                      width: widthTextField.integerValue,
                      height: heightTextField.integerValue)
    markersDic[currentImageKey]?[selectedMarkerIndex].rect = rect
    markerRectViews[selectedMarkerIndex].frame = convertToUICoordinate(from: rect, imageView: imageView!)
  }
}

extension MarkViewController {
  @IBAction func exportButtonClicked(sender: Any) {
    if validationData() {
      chooseFileUrlAndExport()
    }
  }
  
  func validationData() -> Bool {
    for i in 0 ..< imageUrls.count {
      let url = imageUrls[i]
      // check every image in dic
      let imageName = url.lastPathComponent
      guard let markers = markersDic[imageName], let _ = markersDic[imageName]?[0] else {
        refreshAll(tableViewSelectedRow: i)
        Util.showMessage(message: url.lastPathComponent + " need to have at least one marker")
        return false
      }
      for j in 0 ..< markers.count {
        let marker = markers[j]
        if marker.label?.isEmpty ?? false {
          refreshAll(tableViewSelectedRow: i)
          selectedMarkerIndex = j
          Util.showMessage(message: url.lastPathComponent + " required a valid label name")
          return false
        }
      }
    }
    return true
  }
  
  func chooseFileUrlAndExport() {
    let defaultName = "example.json"
    let savePanel = NSSavePanel()
    let window = self.view.window!
    savePanel.nameFieldStringValue = defaultName
    savePanel.beginSheetModal(for: window) {[weak self] (response) in
      if let url = savePanel.url, let self = self,
        response == NSApplication.ModalResponse.OK {
        self.exportData(to: url)
      }
    }
  }
  
  func exportData(to url:URL) {
    var string = "[\n"
    for (index, element) in markersDic.enumerated() {
      let (key, markers): (String, [Marker]) = element
      string += "\t{\n"
      string += "\t\t\"image\":\"" + key + "\",\n"
      string += "\t\t\"annotations\":[\n"
      for i in 0 ..< markers.count {
        let marker = markers[i]
        string += "\t\t\t{\n"
        string += "\t\t\t\t\"label\":\"" + marker.label! + "\",\n"
        string += "\t\t\t\t\"coordinates\":{\n"
        let rect = roundingRect(rect: marker.rect)
        string += String(format: "\t\t\t\t\t\"x\":%.0f,\n", rect.origin.x)
        string += String(format: "\t\t\t\t\t\"y\":%.0f,\n", rect.origin.y)
        string += String(format: "\t\t\t\t\t\"width\":%.0f,\n", rect.size.width)
        string += String(format: "\t\t\t\t\t\"height\":%.0f\n", rect.size.height)
        string += "\t\t\t\t}\n"
        if i == markers.count - 1 {
          string += "\t\t\t}\n"
        } else {
          string += "\t\t\t},\n"
        }
      }
      string += "\t\t]\n"
      if index == markersDic.count - 1 {
        string += "\t}\n"
      } else {
        string += "\t},\n"
      }
    }
    string += "]"
    
    do {
      try string.write(to: url, atomically: true, encoding: .utf8)
    } catch {
      Util.showMessage(message: error.localizedDescription)
    }
  }
}
