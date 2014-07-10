OneNotePickerLibrary for IOS README
================================

### Version info
Version 1.0

Microsoft Open Technologies, Inc. (MS Open Tech) has built the OneNote Picker for iOS, an open source project that strives to help iOS developers use the OneNote API from their apps.

### Prerequisites

**Tools and Libraries** you will need to download, install, and configure for your development environment to use the OneNotePickerLibrary. 

* [XCode 5.1+](https://developer.apple.com/xcode/)
* iOS 7+ SDK

**Accounts**

* As the user, you'll need to [have a Microsoft account](http://msdn.microsoft.com/EN-US/library/office/dn575426.aspx) 
so your project can authenticate with the [Microsoft Live connect SDK](https://github.com/liveservices/LiveSDK-for-iOS).

###Build and Reference the Library

To build OneNotePicker.framework,...

* Download the repo as a ZIP file to your local computer, and extract the files. Or, clone the repository into a local copy of Git.
* Start XCode, if it is not already running.
* Open the OneNotePicker.xcodeproj file.
* Click the "Build & Run" button.
* The OneNotePicker.framework file will show up in OneNotePicker/Products.

To include OneNotePicker.framework in a project,...

* Drag OneNotePicker.framework into your project.
* Click on your project in the side bar to bring up project settings.
* Select the target in which you want to use the framework.
* Click on the "Build Phases" tab.
* Drag OneNotePicker.framework into the "Copy Bundle Resources" build phase.
* Add the following line to your source file: 
    `#import <OneNotePicker/OneNotePickerController.h>`

### Using the library

The **OneNotePickerLibrary** provides a class called **OneNotePickerController** that is a subclass of the [UINavigationController class](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UINavigationController_Class/Reference/Reference.html).

####Input

Specify the required and optional properties for the **OneNotePickerController** class:

* **delegate** (Required): An object that conforms to the [UINavigationControllerDelegate protocol](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UINavigationControllerDelegate_Protocol/Reference/Reference.html#//apple_ref/occ/intf/UINavigationControllerDelegate). This is required by the [UINavigationController class](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UINavigationController_Class/Reference/Reference.html) and that defines methods that you must implement in order to receive information about whether the picker succeeded and what information the user picked if the operation is successful. This object receives notifications when the user picks a section or exits the picker interface. It also decides when to close the picker. If you don't provide a value for the **delegate** property, the picker will be dismissed immediately whenever you try to show it.
*  **accessToken** (Required):  An **NSString** that specifies the access token to be used for authentication. See [Authenticate the user for the OneNote API](http://msdn.microsoft.com/en-us/library/office/dn575435(v=office.15).aspx) to learn how to authenticate your product.
*  **navTextColor** (Optional): A **UIColor** object that specifies the color of the properties in the action bar (the text, back arrow, and cancel button). If this is not set, then the color will be set by default to **#80397B** (the OneNote brand color).
*  **headerInstructions** (Optional): An **NSString** that specifies the text at the top of the picker (above the navigational elements and the name of the notebook, section, or section group). If you don't include a value for this property, no text will appear in that part of the picker. The following image shows where this text fits.

![](images/OneNotePickerIOSHeader.png)

####OneNotePickerControllerDelegate methods

The methods of this protocol notify the delegate when the user either picks a section or cancels the picker operation, or when the picker is dismissed because of an error in the API or on the device.

Three delegate methods are responsible for dismissing the picker when the operation completes. To close the picker, call the **dismissViewControllerAnimated:** method of the controller responsible for displaying the **OneNotePickerController** object.

When the user successfully picks a section, the delegate passes back information about the user's selection through the **oneNotePickerController:didFinishPickingSectionWithInfo:** method:

    (void)oneNotePickerController:(OneNotePickerController *) picker 
    didFinishPickingSectionWithInfo:(NSDictionary *)info

The **picker** parameter is the controller that manages the picker interface. The **info** parameter is a dictionary containing the information about the section that the user selected. The **info** dictionary contains the following keys:

* **OneNotePickerControllerSectionID**: An **NSString** that specifies the ID of the selected section.
* **OneNotePickerControllerSectionName**: An **NSString** that specifies the name of the selected section.
* **OneNotePickerControllerPagesURL**: An **NSURL** that specifies the REST URL to use to create or get pages in the selected section.
* **OneNotePickerControllerCreatedTime**: An **NSDate** object that specifies the date/time when the selected section was created.
* **OneNotePickerControllerModifiedTime**: An **NSDate** object that specifies the date/time when any page in the selected section was last modified.
* **OneNotePickerControllerLastModifiedBy**: An **NSString** that specifies the name of the user who last modified any page in the selected section.

When the user cancels the picker operation, the delegate notifies you that this has happened through the **oneNotePickerControllerDidCancel:** method:

    (void)oneNotePickerControllerDidCancel:(OneNotePickerController *)picker

The **picker** parameter is the controller that manages the picker interface.

When the picker operation fails because of an error generated by the OneNote API or by a system exception on the device, the delegate passes information about the error or exception through the **oneNotePickerController:didErrorWithInfo:** method:
    
    (void)oneNotePickerController:(OneNotePickerController *)picker 
    didErrorWithInfo:(NSDictionary *)info


The **picker** parameter is the controller that manages the picker interface. The **info** parameter is a dictionary containing the information about the API error or system exception. The **info** dictionary contains the following keys:

* **OneNotePickerControllerSystemError**: An **NSError** object that specifies the error that is returned by the platform if the error is a system exception. This value will be null if the error is due a OneNote API error.
* **OneNotePickerControllerIsAPIError**: An **NSNumber** value (treated as a Boolean) that 
 specifies whether the error came from the OneNote API (as opposed to a system error). If this is true, the value of **OneNotePickerControllerSystemError** will be null and the next three keys will have values.
* **OneNotePickerControllerAPIErrorCode**: An **NSString** that specifies the value of the error code returned by the OneNote API. See [OneNote API error and warning codes](http://msdn.microsoft.com/en-us/library/office/dn750990(v=office.15).aspx) for a list of possible error codes.
* **OneNotePickerControllerAPIErrorURL**: An **NSURL** that specifies the value of the explanatory error URL returned by the OneNote API.
* **OneNotePickerControllerAPIErrorString**: An **NSString** that contains a description of the error.


####Example

The following example shows how to create a new instance of the **OneNotePickerController** class, set the required and optional values, and handle errors and exceptions that might be returned. The following code is in a header file called ExampleController.h:

    #import <UIKit/UIKit.h> 
    
    @interface ExampleController : UIViewController <UINavigationControllerDelegate, OneNotePickerControllerDelegate> {     
        OneNotePickerController *oneNotePicker; 
    } 
    @end 

The following code is in the .m file:

    #import "ExampleController.h" 
    
    
    @interface ExampleController () 
    - (void)createOneNotePicker; 
    @end 
    
    
    @implementation ExampleController 
    
    - (void)createOneNotePicker { 
      oneNotePicker = [[OneNotePickerController alloc] init]; 
      oneNotePicker.accessToken = @"<INSERT OAuth TOKEN HERE>"; 
      oneNotePicker.headerInstructions = @"Please choose a section in which to create your note."; 
      oneNotePicker.delegate = self; 
    } 
    
    
    - (void)viewDidLoad { 
      [super viewDidLoad]; 
      [self createOneNotePicker]; 
    } 
    
    - (void)viewWillAppear:(BOOL)animated { 
         [self presentViewController:oneNotePicker animated:animated completion:nil]; 
    } 
    
    - (void)oneNotePickerController:(OneNotePickerController *)picker didFinishPickingSectionWithInfo:(NSDictionary *)info { 
    
    //Store the information.
    
    
    NSString *sectionID = [info valueForKey:OneNotePickerControllerSectionID]; 
    NSString *sectionName = [info valueForKey:OneNotePickerControllerSectionName]; 
    NSURL *pagesURL = [info valueForKey:OneNotePickerControllerPagesURL]; 
    NSDate *createdTime = [info valueForKey:OneNotePickerControllerCreatedTime]; 
    NSDate *modifiedTime = [info valueForKey:OneNotePickerControllerModifiedTime]; 
    NSString *lastModifiedBy = [info valueForKey:OneNotePickerControllerLastModifiedBy]; 
    
    //Do something with the information.
    } 
    
    - (void)oneNotePickerControllerDidCancel:(OneNotePickerController *)picker { 
    //Do something if the user cancels.
    } 
    
    - (void)oneNotePickerController:(OneNotePickerController *)picker didErrorWithInfo:(NSDictionary *)info { 
    //Handle an API error.
    NSNumber *isAPIError = [info valueForKey:OneNotePickerControllerIsAPIError]; 
    if([isAPIError boolValue]) { 
    //Store API error values.
    NSString *errorCode = [info valueForKey:OneNotePickerControllerAPIErrorCode]; 
    NSString *errorString = [info valueForKey:OneNotePickerControllerAPIErrorName]; 
    NSURL *errorURL = [info valueForKey:OneNotePickerControllerAPIErrorURL]; 
    //Do  something  with  the  API error information.
    } 
    
    
    else { 
    //Handle system error.
    NSError *systemError = [info valueForKey:OneNotePickerControllerSystemError]; 
    //Do  something with the system error information. 
    } 
    } 


### OneNote API functionality used by this library

The following aspects of the API are used in this library. You can 
find additional documentation at the links below.

* [GET notebooks to which the user has access](http://msdn.microsoft.com/en-us/library/office/dn769050(v=office.15).aspx)
* [GET section groups to which the user has access](http://msdn.microsoft.com/en-us/library/office/dn769052(v=office.15).aspx)
* [GET a specific section group to which the user has access](http://msdn.microsoft.com/en-us/library/office/dn770192(v=office.15).aspx)
* [GET sections to which the user has access](http://msdn.microsoft.com/en-us/library/office/dn769049(v=office.15).aspx)
* [GET a specific section to which the user has access](http://msdn.microsoft.com/en-us/library/office/dn770191(v=office.15).aspx)

