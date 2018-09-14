# MediaPickerHelper
Swift extension for handling the process of image/video selection.

## Getting Started
This is a simple UIViewController extension file, just place it with your code and use.

### Use
Call the following function from your UIViewController:
```
showImagePickingOptions(type: .image, allowEditing: true) { [unowned self] (image) in
    if let _image = image as? UIImage {
        self.imageView.image = _image
    } else {
        self.imageView.image = UIImage(named: "defaultImage")
    }
}
```
with any of following types:
  * **video**: will let you choose video from camera/gallery
  * **image**: will let you choose image from camera/gallery
  * **imageAndVideo**: will let you choose from image/video options from camera/gallery
  * **photoGallery**: will let you choose image/video from photo gallery
  * **cameraForImage**: will let you capture image using camera
  * **cameraForVideo**: will let you capture video using camera
