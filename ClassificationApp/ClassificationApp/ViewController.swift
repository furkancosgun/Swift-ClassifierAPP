//
//  ViewController.swift
//  ClassificationApp
//
//  Created by Furkan on 19.09.2022.
//

import UIKit

class ViewController: UIViewController , UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var selectedimage:UIImage?{
        
        didSet{
            guard let image =  selectedimage else {
                return
            }
            imagePlaceholder.image = selectedimage
            resultLabel.text = "Loading..."
            if let imagebuffer = convertImage(image: image) {
                
                if let predection = try? mobilenet.prediction(image: imagebuffer){
                     resultLabel.text =  " \(predection.classLabel) "
                }
            }
        }
        
    }
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var imagePlaceholder: UIImageView!
    
    let mobilenet = MobileNetV2()
    var  imagepicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagepicker.allowsEditing = false
        imagepicker.delegate = self
        // Do any additional setup after loading the view.
    }
    @IBAction func btnImageSelect(_ sender: Any) {
        present(imagepicker, animated: true, completion: nil)
    }
    
}

extension ViewController{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let seleted = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        self.selectedimage = seleted
        picker.dismiss(animated: true, completion: nil)
    }
    
    func convertImage(image: UIImage) -> CVPixelBuffer? {
    
      let newSize = CGSize(width: 224.0, height: 224.0)
      UIGraphicsBeginImageContext(newSize)
      image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
      
      guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
          return nil
      }
      
      UIGraphicsEndImageContext()
      
      // convert to pixel buffer
      
      let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer: CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(newSize.width),
                                       Int(newSize.height),
                                       kCVPixelFormatType_32ARGB,
                                       attributes,
                                       &pixelBuffer)
      
      guard let createdPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
          return nil
      }
      
      CVPixelBufferLockBaseAddress(createdPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(createdPixelBuffer)
      
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      guard let context = CGContext(data: pixelData,
                                    width: Int(newSize.width),
                                    height: Int(newSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(createdPixelBuffer),
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                      return nil
      }
      
      context.translateBy(x: 0, y: newSize.height)
      context.scaleBy(x: 1.0, y: -1.0)
      
      UIGraphicsPushContext(context)
      resizedImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(createdPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
      
      return createdPixelBuffer
  }
}
    
    
    

