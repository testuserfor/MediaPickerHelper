//
//  ImagePickerHelper.swift
//
//  A swift extension for handling the selection process if image/video.
//

import Foundation
import UIKit
import Photos
import MobileCoreServices

enum PickingMediaType {
    case video
    case image
    case imageAndVideo
    case photoGallery
    case cameraForImage
    case cameraForVideo
}

typealias ImageCompletionHandler = (_ response:Any?) -> ()
fileprivate var imagePickingHandler: ImageCompletionHandler?
fileprivate var requestedMediaType: PickingMediaType?
fileprivate var shouldEditingEnabled: Bool?

extension UIViewController {
    
    //-----------------------------------------------------------------------------------------------------------
    func showImagePickingOptions(type mediaType: PickingMediaType, allowEditing allow: Bool, _ success:@escaping ImageCompletionHandler)
    //-----------------------------------------------------------------------------------------------------------
    {
        requestedMediaType = mediaType
        shouldEditingEnabled = allow
        imagePickingHandler = success
        
        switch mediaType {
        case .photoGallery:
            self.showGallery(forMedia: [kUTTypeImage])
        case .cameraForImage:
            self.openCamera(forMedia: [kUTTypeImage])
        case .cameraForVideo:
            self.openCamera(forMedia: [kUTTypeMovie])
        default:
            showOptionSheet()
        }
    }
    
    private func showOptionSheet() {
        
        if requestedMediaType == .imageAndVideo {
            
            self.showActionSheetWithTitle(title: nil, message: nil, onViewController: self, withButtonArray: ["Image", "Video"]) { [unowned self] (index) in
                
                requestedMediaType = (index == 0) ? .image : .video
                self.showOptionSheet()
            }
            
        } else {
            
            self.showActionSheetWithTitle(title: nil, message: nil, onViewController: self, withButtonArray: ["Choose from Gallery", "Capture using Camera"]) { [unowned self] (index) in
                
                let requestedMedia = (requestedMediaType == .image) ? [kUTTypeImage] : [kUTTypeMovie]
                if index == 0 {
                    self.showGallery(forMedia: requestedMedia)
                } else if index == 1 {
                    self.openCamera(forMedia: requestedMedia)
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    private func showGallery(forMedia mediaType: [CFString])
        //-----------------------------------------------------------------------------------------------------------
    {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let authStatus = PHPhotoLibrary.authorizationStatus()
            if authStatus == .notDetermined {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    if status == PHAuthorizationStatus.authorized {
                        self.showImagePicker(withSource: .photoLibrary, andMedia: mediaType)
                    }
                })
            } else if authStatus == .restricted || authStatus == .denied {
                self.showGalleryDisableAlert()
            } else {
                self.showImagePicker(withSource: .photoLibrary, andMedia: mediaType)
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    private func openCamera(forMedia mediaType: [CFString])
        //-----------------------------------------------------------------------------------------------------------
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.checkForCamera(forMedia: mediaType)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    private func showImagePicker(withSource source: UIImagePickerControllerSourceType, andMedia mediaType: [CFString])
        //-----------------------------------------------------------------------------------------------------------
    {
        let mediaTypes = mediaType as [String]
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = source
        imagePicker.mediaTypes = mediaTypes
        imagePicker.allowsEditing = shouldEditingEnabled!
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    //-----------------------------------------------------------------------------------------------------------
    private func checkForCamera(forMedia mediaType: [CFString])
        //-----------------------------------------------------------------------------------------------------------
    {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                if granted == true {
                    self.showImagePicker(withSource: .camera, andMedia: mediaType)
                }
            })
        } else if authStatus == .restricted || authStatus == .denied {
            self.showCameraDisableAlert()
        } else {
            self.showImagePicker(withSource: .camera, andMedia: mediaType)
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    private func showGalleryDisableAlert()
        //-----------------------------------------------------------------------------------------------------------
    {
        self.showAlertWithTitle(title: "Photo Access Denied", message: "Please enable photo library access in your privacy settings", onViewController: self, withButtonArray: nil, dismissHandler: nil)
    }
    
    //-----------------------------------------------------------------------------------------------------------
    private func showCameraDisableAlert()
        //-----------------------------------------------------------------------------------------------------------
    {
        self.showAlertWithTitle(title: "Camera Access Denied", message: "Please enable camera access in your privacy settings", onViewController: self, withButtonArray: nil, dismissHandler: nil)
    }
}

extension UIViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //-----------------------------------------------------------------------------------------------------------
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
        //-----------------------------------------------------------------------------------------------------------
    {
        if requestedMediaType == .image ||
            requestedMediaType == .photoGallery ||
            requestedMediaType == .cameraForImage {
                
            let selectedImage: UIImage = (info[shouldEditingEnabled! ? UIImagePickerControllerEditedImage : UIImagePickerControllerOriginalImage] as? UIImage)!
            picker.dismiss(animated: true) {
                imagePickingHandler!(selectedImage)
            }
        } else {
            let videoUrl = info[UIImagePickerControllerMediaURL]
            picker.dismiss(animated: true) {
                imagePickingHandler!(videoUrl)
            }
        }
    }
    
    //-----------------------------------------------------------------------------------------------------------
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
        //-----------------------------------------------------------------------------------------------------------
    {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension UIViewController {
    
    fileprivate func showActionSheetWithTitle(title:String? = "", message:String? = "", onViewController:UIViewController?, withButtonArray buttonArray:[String]? = [], dismissHandler:((_ buttonIndex:Int)->())?) -> Void {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        var ignoreButtonArray = false
        
        if buttonArray == nil
        {
            ignoreButtonArray = true
        }
        
        if !ignoreButtonArray
        {
            for item in buttonArray!
            {
                let action = UIAlertAction(title: item, style: .default, handler: { (action) in
                    
                    alertController.dismiss(animated: true, completion: nil)
                    
                    guard (dismissHandler != nil) else
                    {
                        return
                    }
                    dismissHandler!(buttonArray!.index(of: item)!)
                })
                alertController.addAction(action)
            }
        }
        
        let action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(action)
        
        onViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWithTitle(title:String? = "", message:String? = "", onViewController:UIViewController?, withButtonArray buttonArray:[String]? = [], dismissHandler:((_ buttonIndex:Int)->())?) -> Void {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        var ignoreButtonArray = false
        
        if buttonArray == nil
        {
            ignoreButtonArray = true
        }
        
        if !ignoreButtonArray
        {
            for item in buttonArray!
            {
                let action = UIAlertAction(title: item, style: .default, handler: { (action) in
                    
                    alertController.dismiss(animated: true, completion: nil)
                    
                    guard (dismissHandler != nil) else
                    {
                        return
                    }
                    dismissHandler!(buttonArray!.index(of: item)!)
                })
                alertController.addAction(action)
            }
        }
        
        if buttonArray == nil || (buttonArray?.isEmpty)! {
            let action = UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in

                guard (dismissHandler != nil) else
                {
                    return
                }
                dismissHandler!(LONG_MAX)
            })
            alertController.addAction(action)
        }
        
        onViewController?.present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = AppColor.blue
    }
}
