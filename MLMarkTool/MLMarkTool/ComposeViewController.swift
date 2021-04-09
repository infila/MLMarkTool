//
//  ComposeViewController.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/21.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

struct TargetImageMarker {
  var label: String?
  var subMarkers: [Marker] = []
}

enum SelectedImageSource {
  case background
  case target
  case result
}

class ComposeViewController: NSViewController {
  @IBOutlet var backgroundDragDetectView: DragDetectView!
  @IBOutlet var backgroundImageTableView: NSTableView!
  @IBOutlet var resultTableView: NSTableView!

  @IBOutlet var targetDragDetectView: DragDetectView!
  @IBOutlet var targetImageTableView: NSTableView!
  @IBOutlet var labelTextField: NSTextField!
  @IBOutlet var subLabelTextField: NSTextField!
  @IBOutlet var xTextField: NSTextField!
  @IBOutlet var yTextField: NSTextField!
  @IBOutlet var widthTextField: NSTextField!
  @IBOutlet var heightTextField: NSTextField!

  @IBOutlet var imageScrollView: NSScrollView!
  @IBOutlet var imageContainerView: NSView!
  @IBOutlet var exportButton: NSButton!
  
  @IBOutlet var backgroundHintLabel: NSTextField!
  @IBOutlet var targetHintLabel: NSTextField!

  private var backgroundImageUrls: [URL] = []
  private var targetImageUrls: [URL] = []
  private var targetMarkers: [TargetImageMarker] = []

  private var resultImages: [String: NSImage] = [:]
  private var resultMarkers: [String: [Marker]] = [:] {
    didSet {
      exportButton.isEnabled = resultMarkers.count != 0
    }
  }

  private var selectedMarkerIndex: Int = -1 {
    didSet {
      refreshHighlightedMarkerRect()
      refreshMarkerPanel()
    }
  }

  private var imageView: SelectableImageView?
  private var imageSource: SelectedImageSource = .background
  private var currentImageKey: String {
    if imageSource == .background && backgroundImageTableView.selectedRow >= 0 {
      return backgroundImageUrls[backgroundImageTableView.selectedRow].lastPathComponent
    } else if imageSource == .result && resultTableView.selectedRow >= 0 {
      return resultImages.keys[resultTableView.selectedRow]
    }
    return ""
  }

  private var markerRectViews: [BorderRectView] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    backgroundDragDetectView.onFileChoosed = { [weak self] (urls: [URL]) in
      guard let self = self, urls.count > 0 else {
        return
      }

      self.backgroundImageUrls.append(contentsOf: urls)
      self.removeDuplicatedUrls()
      self.refreshBackgroundTableView(selectedRow: self.backgroundImageUrls.firstIndex(of: urls[0])!)
    }
    refreshBackgroundTableView(selectedRow: -1)
    
    targetDragDetectView.onFileChoosed = { [weak self] (urls: [URL]) in
      guard let self = self, urls.count > 0 else {
        return
      }

      self.targetImageUrls.append(contentsOf: urls)
      self.removeDuplicatedUrls()
      for _ in self.targetMarkers.count ..< self.targetImageUrls.count {
        self.targetMarkers.append(TargetImageMarker())
      }
      self.refreshTargetTableView(selectedRow: self.targetImageUrls.firstIndex(of: urls[0])!)
    }
    refreshTargetTableView(selectedRow: -1)
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    guard let window = view.window else { return }
    window.addObserver(self, forKeyPath: "firstResponder", options: [.old, .new], context: nil)
  }

  override func viewWillDisappear() {
    super.viewWillDisappear()
    guard let window = view.window else { return }
    window.removeObserver(self, forKeyPath: "firstResponder")
  }

  private func removeDuplicatedUrls() {
    backgroundImageUrls = Array(Set(backgroundImageUrls))
  }

  private func refreshBackgroundTableView(selectedRow: Int) {
    view.window?.makeFirstResponder(backgroundImageTableView)
    backgroundImageTableView.reloadData()
    if selectedRow >= 0 {
      backgroundImageTableView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow), byExtendingSelection: false)
    }
    refreshImageScrollView()
    refreshMarkerPanel()
  }
  
  private func refreshTargetTableView(selectedRow: Int) {
    view.window?.makeFirstResponder(targetImageTableView)
    targetImageTableView.reloadData()
    if selectedRow >= 0 {
      targetImageTableView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow), byExtendingSelection: false)
    }
    refreshImageScrollView()
    refreshMarkerPanel()
  }

  private func refreshResultTableView(selectedRow: Int) {
    view.window?.makeFirstResponder(resultTableView)
    resultTableView.reloadData()
    if selectedRow >= 0 {
      resultTableView.selectRowIndexes(IndexSet(arrayLiteral: selectedRow), byExtendingSelection: false)
    }
    refreshImageScrollView()
    refreshMarkerPanel()
    exportButton.isEnabled = resultMarkers.count != 0
  }

  private func refreshImageScrollView() {
    imageScrollView.magnification = 1
    imageContainerView.removeSubviews()
    backgroundHintLabel.isHidden = backgroundImageUrls.count != 0
    targetHintLabel.isHidden = targetImageUrls.count != 0

    var image: NSImage?
    var markers: [Marker]?
    if imageSource == .background {
      guard backgroundImageTableView.selectedRow >= 0 else {
        return
      }
      image = NSImage(byReferencing: backgroundImageUrls[backgroundImageTableView.selectedRow])
    } else if imageSource == .result {
      guard resultTableView.selectedRow >= 0 else {
        return
      }
      image = resultImages.values[resultTableView.selectedRow]
      markers = resultMarkers[resultImages.keys[resultTableView.selectedRow]]
    } else if imageSource == .target {
      guard targetImageTableView.selectedRow >= 0 else {
        return
      }
      image = NSImage(byReferencing: targetImageUrls[targetImageTableView.selectedRow])
      markers = targetMarkers[targetImageTableView.selectedRow].subMarkers
    }

    guard let drawImage = image else { return }
    drawImageOnSelectableImageView(drawImage)
    markerRectViews = []
    guard let drawMarkers = markers else { return }
    drawMarkerLabels(drawMarkers)
  }

  private func drawImageOnSelectableImageView(_ image: NSImage) {
    let imageView = SelectableImageView(image: image)
    imageView.selectable = imageSource == .target
    imageView.imageScaling = .scaleProportionallyUpOrDown
    self.imageView = imageView
    var x: CGFloat = 0
    var y: CGFloat = 0
    var width: CGFloat = 0
    var height: CGFloat = 0
    if image.size.width / image.size.height > (imageContainerView.width / imageContainerView.height) {
      width = imageContainerView.width
      height = image.size.height / image.size.width * width
      y = (imageContainerView.height - height) / 2
      imageView.autoresizingMask = NSView.AutoresizingMask(rawValue: NSView.AutoresizingMask.width.rawValue + NSView.AutoresizingMask.height.rawValue + NSView.AutoresizingMask.minXMargin.rawValue + NSView.AutoresizingMask.maxXMargin.rawValue)
    } else {
      height = imageContainerView.height
      width = image.size.width / image.size.height * height
      x = (imageContainerView.width - width) / 2
      imageView.autoresizingMask = NSView.AutoresizingMask(rawValue: NSView.AutoresizingMask.width.rawValue + NSView.AutoresizingMask.height.rawValue + NSView.AutoresizingMask.minYMargin.rawValue + NSView.AutoresizingMask.maxYMargin.rawValue)
    }
    imageView.frame = NSRect(x: x, y: y, width: width, height: height)
    imageContainerView.addSubview(imageView)
    imageView.onRectSelected = { [weak self] (rect: CGRect) in
      guard let self = self, let imageView = self.imageView else { return }
      if self.imageSource == .target {
        let rect = self.convertToMLCoordinate(from: rect, imageView: imageView)
        var marker = self.targetMarkers[self.targetImageTableView.selectedRow]
        marker.subMarkers.append(Marker(label: self.labelTextField.stringValue,
                                        rect: rect))
        self.targetMarkers[self.targetImageTableView.selectedRow] = marker
        self.selectedMarkerIndex = marker.subMarkers.count - 1
        self.drawMarkLabel(rect: self.convertToUICoordinate(from: rect, imageView: imageView), tag: self.selectedMarkerIndex)
        imageView.display()
        self.view.window?.makeFirstResponder(self.imageView)
      }
    }
  }

  private func roundingRect(rect: CGRect) -> CGRect {
    return CGRect(x: lrintf(Float(rect.x)),
                  y: lrintf(Float(rect.y)),
                  width: lrintf(Float(rect.size.width)),
                  height: lrintf(Float(rect.size.height)))
  }

  private func drawMarkerLabels(_ markers: [Marker]) {
    guard let imageView = imageView else {
      return
    }
    for i in 0 ..< markers.count {
      let marker = markers[i]
      drawMarkLabel(rect: convertToUICoordinate(from: marker.rect, imageView: imageView), tag: i)
    }
    selectedMarkerIndex = markers.count - 1
  }

  private func drawMarkLabel(rect: CGRect, tag: Int) {
    let view = BorderRectView(frame: rect)
    view.tag = tag
    view.onClicked = { [weak self] view in
      guard let self = self else { return }
      if self.selectedMarkerIndex != view.tag {
        self.selectedMarkerIndex = view.tag
      }
      self.view.window?.makeFirstResponder(self.imageView)
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
    var marker: Marker?
    if imageSource == .target && selectedMarkerIndex >= 0 {
      marker = targetMarkers[targetImageTableView.selectedRow].subMarkers[selectedMarkerIndex]
    } else if imageSource == .background {
      marker = nil
    } else if imageSource == .result && selectedMarkerIndex >= 0 {
      marker = resultMarkers[currentImageKey]?[selectedMarkerIndex]
    }

    if let rect = marker?.rect {
      enable = true
      xTextField.stringValue = String(format: "%.0f", rect.x)
      yTextField.stringValue = String(format: "%.0f", rect.y)
      widthTextField.stringValue = String(format: "%.0f", rect.size.width)
      heightTextField.stringValue = String(format: "%.0f", rect.size.height)
      let label = marker?.label ?? ""
      if subLabelTextField.stringValue != label {
        subLabelTextField.stringValue = label
      }
    } else {
      xTextField.stringValue = ""
      yTextField.stringValue = ""
      widthTextField.stringValue = ""
      heightTextField.stringValue = ""
    }
    labelTextField.isEnabled = (imageSource == .target && targetImageUrls.count > 0)
    subLabelTextField.isEnabled = enable
    xTextField.isEnabled = enable
    yTextField.isEnabled = enable
    widthTextField.isEnabled = enable
    heightTextField.isEnabled = enable
  }

  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    if event.keyCode != 51 {
      return
    }

    if markerRectViews.count > 0 {
      markerRectViews[selectedMarkerIndex].removeFromSuperview()
      markerRectViews.remove(at: selectedMarkerIndex)
      if imageSource == .target {
        targetMarkers[targetImageTableView.selectedRow].subMarkers.remove(at: selectedMarkerIndex)
      } else if imageSource == .result {
        resultMarkers[currentImageKey]?.remove(at: selectedMarkerIndex)
      }
      selectedMarkerIndex = markerRectViews.count - 1
    } else {
      if imageSource == .background && backgroundImageTableView.selectedRow >= 0 {
        let selectedRow = backgroundImageTableView.selectedRow
        backgroundImageUrls.remove(at: selectedRow)
        refreshBackgroundTableView(selectedRow: min(selectedRow, backgroundImageUrls.count - 1))
      } else if imageSource == .target && targetImageTableView.selectedRow >= 0 {
        let selectedRow = targetImageTableView.selectedRow
        targetImageUrls.remove(at: selectedRow)
        targetMarkers.remove(at: selectedRow)
        refreshTargetTableView(selectedRow: min(selectedRow, backgroundImageUrls.count - 1))
        refreshMarkerPanel()
      } else if imageSource == .result && resultTableView.selectedRow >= 0 {
        let selectedRow = backgroundImageTableView.selectedRow
        resultMarkers[currentImageKey] = nil
        resultImages[currentImageKey] = nil
        refreshResultTableView(selectedRow: min(selectedRow, resultImages.count - 1))
      }
    }
  }

  private func convertToMLCoordinate(from UICoordinate: CGRect, imageView: SelectableImageView) -> CGRect {
    let x = UICoordinate.x / imageView.imageScale
    let y = (imageView.height - UICoordinate.y - UICoordinate.size.height) / imageView.imageScale
    let width = UICoordinate.size.width / imageView.imageScale
    let height = UICoordinate.size.height / imageView.imageScale
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private func convertToUICoordinate(from MLCoordinate: CGRect, imageView: SelectableImageView) -> CGRect {
    let x = MLCoordinate.x * imageView.imageScale
    let y = imageView.height - (MLCoordinate.y + MLCoordinate.size.height) * imageView.imageScale
    let width = MLCoordinate.size.width * imageView.imageScale
    let height = MLCoordinate.size.height * imageView.imageScale
    return CGRect(x: x, y: y, width: width, height: height)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    guard let newValue = change?[NSKeyValueChangeKey.newKey] as? NSResponder, keyPath == "firstResponder" else { return }
    if newValue == targetImageTableView {
      imageSource = .target
    } else if newValue == backgroundImageTableView {
      imageSource = .background
    } else if newValue == resultTableView {
      imageSource = .result
    }
    refreshImageScrollView()
    refreshMarkerPanel()
  }
}

extension ComposeViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    if tableView == backgroundImageTableView {
      return backgroundImageUrls.count
    } else if tableView == targetImageTableView {
      return targetImageUrls.count
    } else if tableView == resultTableView {
      return resultImages.count
    }
    return 0
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    return nil
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCell"), owner: nil) as? NSTableCellView
    else { return nil }
    if tableView == backgroundImageTableView {
      cell.textField!.stringValue = String(backgroundImageUrls[row].lastPathComponent)
    } else if tableView == targetImageTableView {
      cell.textField!.stringValue = String(targetImageUrls[row].lastPathComponent)
    } else if tableView == resultTableView {
      cell.textField!.stringValue = resultImages.keys[row]
    }
    return cell
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    refreshImageScrollView()
    refreshMarkerPanel()
  }
}

extension ComposeViewController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    guard let textField = obj.object as? NSTextField else { return }
    if textField == labelTextField {
      targetMarkers[targetImageTableView.selectedRow].label = textField.stringValue
      return
    } else if textField == subLabelTextField {
      targetMarkers[targetImageTableView.selectedRow].subMarkers[selectedMarkerIndex].label = textField.stringValue
      return
    }
    if textField.intValue < 0 {
      textField.intValue = 1
    }
    let rect = CGRect(x: xTextField.integerValue,
                      y: yTextField.integerValue,
                      width: widthTextField.integerValue,
                      height: heightTextField.integerValue)
    if imageSource == .target {
      targetMarkers[targetImageTableView.selectedRow].subMarkers[selectedMarkerIndex].rect = rect
    } else if imageSource == .result {
      resultMarkers[currentImageKey]?[selectedMarkerIndex].rect = rect
    }
    markerRectViews[selectedMarkerIndex].frame = convertToUICoordinate(from: rect, imageView: imageView!)
  }
}

extension ComposeViewController {
  @IBAction func randomButtonClicked(sender: Any) {
    if validationInputData() {
      resultImages = [:]
      resultMarkers = [:]
      randomTargetImageToBackground()
    }
  }

  @IBAction func exportButtonClicked(sender: Any) {
    if validationResultData() {
      chooseFileUrlAndExport()
    }
  }

  func validationInputData() -> Bool {
    if backgroundImageUrls.count == 0 {
      Util.showMessage(message: "Needs at least one background image")
      return false
    }
    if targetImageUrls.count == 0 {
      Util.showMessage(message: "Needs at least one target image")
      return false
    }
    for marker in targetMarkers {
      if marker.label?.isEmpty ?? true && marker.subMarkers.first?.label?.isEmpty ?? true {
        Util.showMessage(message: "Target image needs at least one marker")
        return false
      }
    }
    return true
  }

  func validationResultData() -> Bool {
    for i in 0 ..< backgroundImageUrls.count {
      let url = backgroundImageUrls[i]
      // check every image in dic
      guard let markers = resultMarkers[currentImageKey], let _ = resultMarkers[currentImageKey]?[0] else {
        refreshResultTableView(selectedRow: i)
        Util.showMessage(message: url.lastPathComponent + " needs to have at least one marker")
        return false
      }
      for j in 0 ..< markers.count {
        let marker = markers[j]
        if marker.label?.isEmpty ?? false {
          refreshResultTableView(selectedRow: i)
          selectedMarkerIndex = j
          Util.showMessage(message: url.lastPathComponent + " missing a valid label")
          return false
        }
      }
    }
    return true
  }

  func chooseFileUrlAndExport() {
    let defaultName = "example.json"
    let openPanel = NSOpenPanel()
    let window = view.window!
    openPanel.title = "Select a folder to export images and .json files"
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.nameFieldStringValue = defaultName
    openPanel.beginSheetModal(for: window) { [weak self] response in
      if let url = openPanel.url, let self = self,
        response == NSApplication.ModalResponse.OK {
        self.exportData(to: url)
      }
    }
  }

  private func exportData(to url: URL) {
    exportImages(toFolder: url)

    var string = "[\n"
    for (index, element) in resultMarkers.enumerated() {
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
        string += String(format: "\t\t\t\t\t\"x\":%.0f,\n", rect.x)
        string += String(format: "\t\t\t\t\t\"y\":%.0f,\n", rect.y)
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
      if index == resultMarkers.count - 1 {
        string += "\t}\n"
      } else {
        string += "\t},\n"
      }
    }
    string += "]"

    do {
      try string.write(to: url.appendingPathComponent("result.json"), atomically: true, encoding: .utf8)
    } catch {
      Util.showMessage(message: error.localizedDescription)
    }
  }

  private func exportImages(toFolder url: URL) {
    for (key, image) in resultImages {
      let filePath = url.appendingPathComponent(key)
      _ = image.pngWrite(to: filePath)
    }
  }

  private func randomTargetImageToBackground() {
    let scaleRange: ClosedRange<CGFloat> = 0.8 ... 1.2
    let alphaRange: ClosedRange<CGFloat> = 0.7 ... 1.2
    let rotationRange: ClosedRange<CGFloat> = 0 ... CGFloat.pi * 2
    for url in backgroundImageUrls {
      let backgroundImage = NSImage(byReferencing: url)
      let scale: CGFloat = CGFloat.random(in: scaleRange)
      let alpha = CGFloat.random(in: alphaRange)
      let rotation = CGFloat.random(in: rotationRange)
      let backgroundImageName = String(url.lastPathComponent.split(separator: ".").first ?? "")
      var resultImageName = backgroundImageName
      var resultImage = backgroundImage
      var markers: [Marker] = []
      for (i, targetUrl) in targetImageUrls.enumerated() {
        let targetImage = NSImage(byReferencing: targetUrl)
        let targetImageName = targetUrl.lastPathComponent.split(separator: ".").first ?? ""
        guard backgroundImage.size.width - targetImage.size.width * scale > 0,
              backgroundImage.size.height - targetImage.size.height * scale > 0 else {
          Util.showMessage(message: "\(targetImageName) is bigger than \(backgroundImageName), smaller is required")
          return
        }
        let widthRange = 0 ... backgroundImage.size.width - targetImage.size.width * scale
        let heightRange = 0 ... backgroundImage.size.height - targetImage.size.height * scale
        let point = CGPoint(x: CGFloat.random(in: widthRange),
                            y: CGFloat.random(in: heightRange))

        // generic image
        let centerPoint = CGPoint(x: point.x + targetImage.size.width / 2, y: point.y + targetImage.size.height / 2)
        resultImage = resultImage.draw(image: targetImage, atCenterPoint: centerPoint, withScale: scale, alpha: alpha, andRotation: rotation)
        resultImageName = resultImageName + "_" + targetImageName

        // generic markers
        let rect = CGRect(x: point.x,
                          y: point.y,
                          width: targetImage.size.width,
                          height: targetImage.size.height)
        let transformedRect = rect.transform(byRotation: rotation, scale: scale)
        if let targetMarkerLabel = targetMarkers[i].label, !targetMarkerLabel.isEmpty {
          markers.append(Marker(label: targetMarkerLabel, rect: transformedRect))
        }
        let targetMarker = targetMarkers[i]
        for marker in targetMarker.subMarkers {
          let subrect = marker.rect
          let subcenterPoint = CGPoint(x: subrect.midX, y: subrect.midY).offset(x: -rect.width / 2, y: -rect.height / 2)
          let transformedSubcenterPoint = subcenterPoint.transform(byRotation: rotation, andScale: scale)
          var transformedSubrect = subrect.transform(byRotation: rotation, scale: scale)
          let origin = transformedSubcenterPoint.offset(x: -transformedSubrect.width / 2, y: -transformedSubrect.height / 2).offset(x: transformedRect.midX, y: transformedRect.midY)
          transformedSubrect.origin = origin
          markers.append(Marker(label: marker.label, rect: transformedSubrect))
        }
      }
      resultImageName = resultImageName + ".jpg"
      resultImages[resultImageName] = resultImage
      resultMarkers[resultImageName] = markers
    }
    refreshResultTableView(selectedRow: 0)
  }
}
