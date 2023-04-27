//Written by Sean Dougherty - HST Innovations. Copyright 2023. All Rights Reserved.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:minio/minio.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:expense_report/AppDrawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;


import 'package:expense_report/login_screen.dart';

void main() => runApp(MyApp());

// void main() {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     theme: darkTheme,
//     home: LoginScreen(),
//   ));
//}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Report',
      theme: darkTheme,
      home: MyHomePage(title: 'Expense Report Entry Form'),
    );
  }
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  primaryColor: Colors.white,
  accentColor: Colors.white,
  textTheme: TextTheme(
    headline6: TextStyle(color: Colors.white),
    bodyText2: TextStyle(color: Colors.white),
  ),
);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = false;
  void clearDropdowns() {
    setState(() {
      _status = null;
      _corporateCreditCard = null;
      _businessPurposeController = null;
      // Add any other dropdowns you want to clear here
    });
  }

  bool isImageFile(String filePath) {
    final fileExtension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(fileExtension);
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late File? _image = null;
  final picker = ImagePicker();
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _transactionDateController =
      TextEditingController();
  late String? _businessPurposeController = null;
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _dollarsController = TextEditingController();
  late String? _company = 'Profile Extrusion Company';
  late String? _gl;
  late String? _corporateCreditCard = null;
  late String? _status = null;
  File? _file;

  List<String?> _companies = [
    'Profile Extrusion Company',
    'GPI',
    'GPI2',
    'AJ Glass',
    'CCN Enterprises LLC',
    'LS9',
    'MU6 LLC',
    'HST Innovations LLC',
    'AMD',
    'CAT5 Construction'
  ];

  List<String?> _businessPurposes = [
    'Employee Meals',
    'Lodging',
    'Miscellaneous',
    'Rental Car',
    'Parking',
    'Corporate Contributions',
    'Personal Car Mileage',
    'Air Travel',
    'Entertainment',
    'Outside Service Other',
    'Small Tools',
    'Suspense Charges Temporary',
    'Corporate and Licensing Fees'
  ];

  List<String?> _corporateCreditCards = [
    'Yes - a Corporate Credit Card was Used',
    'No - Personal Expense'
  ];

  List<String?> _statuses = [
    'On Hold',
    'Ready for Processing'
    //'Returned for Review',
    //'Approved'
  ];

  Future getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getFileFromGallery() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          String? path = result.files.single.path;
          if (path != null) {
            _file = File(path);
          } else {
            print("File path is null.");
          }
        });
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print("Error while picking the file: " + e.toString());
    }
  }

  Future<String?> uploadFileToS3(File file) async {
    final minio = Minio(
      endPoint: 's3.us-east-1.wasabisys.com',
      accessKey: 'U838PX8RD5761WY7IS7D',
      secretKey: 'N4mUU7AgOc7iPwGaRKkDnGgIDEpytrLCB9JAb5oi',
      useSSL: true,
    );

    final now = DateTime.now().toString();
    final fileExtension = path.extension(file.path);
    final filename = 'expense-report-file-$now$fileExtension';

    try {
      final bytes = await file.readAsBytes();
      final stream = Stream.fromIterable([bytes]);

      // Set the Expires header to 15 minutes in the future
      final expires =
      DateTime.now().add(Duration(minutes: 15)).toUtc().toIso8601String();

      await minio.putObject('appdevimages', filename, stream,
          metadata: {'Expires': expires});

      final endpoint =
          'https://s3.us-east-1.wasabisys.com'; // Replace with your Minio server URL
      final url = '$endpoint/appdevimages/$filename';
      return url;
    } catch (e) {
      print('Error uploading file to S3: $e');
      return null;
    }
  }



  // Future<String?> uploadImageToS3(File image) async {
  //   final minio = Minio(
  //     endPoint: 's3.us-east-1.wasabisys.com',
  //     accessKey: 'U838PX8RD5761WY7IS7D',
  //     secretKey: 'N4mUU7AgOc7iPwGaRKkDnGgIDEpytrLCB9JAb5oi',
  //     useSSL: true,
  //   );
  //
  //   final now = DateTime.now().toString();
  //   final filename = 'expense-report-image-$now.jpeg';
  //
  //   try {
  //     final bytes = await image.readAsBytes();
  //     final stream = Stream.fromIterable([bytes]);
  //
  //     // Set the Expires header to 15 minutes in the future
  //     final expires =
  //         DateTime.now().add(Duration(minutes: 15)).toUtc().toIso8601String();
  //
  //     await minio.putObject('appdevimages', filename, stream,
  //         metadata: {'Expires': expires});
  //
  //     final endpoint =
  //         'https://s3.us-east-1.wasabisys.com'; // Replace with your Minio server URL
  //     final url = '$endpoint/appdevimages/$filename';
  //     return url;
  //   } catch (e) {
  //     print('Error uploading image to S3: $e');
  //     return null;
  //   }
  // }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Get the values from the form fields
      final employee = _employeeController.text;
      final vendor = _vendorController.text;
      final transactionDate = _transactionDateController.text;
      final businessPurpose = _businessPurposeController;
      final itemDesc = _itemDescController.text;
      final dollars = _dollarsController.text;

      // Determine the GL value based on the selected business purpose
      switch (businessPurpose) {
        case 'Employee Meals':
          _gl = '7817-800';
          break;
        case 'Lodging':
          _gl = '7818-800';
          break;
        case 'Miscellaneous':
          _gl = '7816-800';
          break;
        case 'Rental Car':
          _gl = '7821-800';
          break;
        case 'Corporate Contributions':
          _gl = '7839-800';
          break;
        case 'Personal Car Mileage':
          _gl = '7814-800';
          break;
        case 'Air Travel':
          _gl = '7820-800';
          break;
        case 'Entertainment':
          _gl = '7809-800';
          break;
        case 'Outside Service Other':
          _gl = '7822-800';
          break;
        case 'Small Tools':
          _gl = '7606-800';
          break;
        case 'Corporate and Licensing Fees':
          _gl = '7682-800';
          break;
        case 'Parking':
          _gl = '7816-800';
          break;
        case 'Suspense Charges Temporary':
          _gl = '2030';
          break;
      }

      // Send the form data to the PHP API
      final url = 'https://appdata.netstoic.com/expense_rpt/adddata.php';
      final response = await http.post(Uri.parse(url), body: {
        'company': _company,
        'employee': employee,
        'vendor': vendor,
        'trans_date': transactionDate,
        'business_purpose': businessPurpose,
        'item_desc': itemDesc,
        'gl': _gl,
        'dollars': dollars,
        'corp_cc': _corporateCreditCard,
        'status': _status,
      });

      if (response.statusCode == 200) {
        clearDropdowns();
        // _status = null;
        // _corporateCreditCard = null;
        // _businessPurposeController = null;
        print('Form data submitted successfully');
        // _statuses = 'Test' as List<String>;
        // _corporateCreditCards.clear();
        // _businessPurposes.clear();
      } else {
        print('Error submitting form data: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: _loading,
        child: Scaffold(
          // return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Upload the image to S3 and get its URL
                      //final imageUrl = await uploadImageToS3(_image!);
                      setState(() {
                        _loading = true; // Show the loading indicator
                      });

                      String? imageUrl;
                      if (_image != null) {
                        imageUrl = await uploadFileToS3(_image!);
                      }

                      String? fileUrl;
                      if (_file != null) {
                        fileUrl = await uploadFileToS3(_file!);
                      }

                      // Submit the form data and the image URL to the PHP API
                      final url =
                          'https://appdata.netstoic.com/expense_rpt/adddata.php';
                      final response = await http.post(Uri.parse(url), body: {
                        'company': _company,
                        'employee': _employeeController.text,
                        'vendor': _vendorController.text,
                        'trans_date': _transactionDateController.text,
                        'business_purpose': _businessPurposeController,
                        'item_desc': _itemDescController.text,
                        'gl': _gl,
                        'dollars': _dollarsController.text,
                        'corp_cc': _corporateCreditCard,
                        if (imageUrl != null) 'img_url': imageUrl,
                        if (_file != null) 'img_url': fileUrl,
                        // Add img_url only if imageUrl is not null
                        //'img_url': imageUrl,
                        'status': _status,
                      });

                      if (response.statusCode == 200) {
                        setState(() {
                          _loading = false; // Hide the loading indicator
                        });
                        // Clear the form fields
                        //setState(() => _);
                        //_employeeController.clear();
                        _vendorController.clear();
                        _transactionDateController.clear();
                        _itemDescController.clear();
                        _dollarsController.clear();
                        setState(() {
                          _image = null;
                        });
                        setState(() {
                          _file = null;
                        });
                        clearDropdowns();
                        // _status = null;
                        // _corporateCreditCard = null;
                        // _businessPurposeController = null;
                        // _statuses.clear();
                        // _corporateCreditCards.clear();
                        // _businessPurposes.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense submitted successfully!'),
                            duration: Duration(seconds: 3),
                          ),
                        ); //_submitForm,
                      }
                    }
                  })
            ],
          ),

          drawer: AppDrawer(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DefaultTextStyle(
                      style: TextStyle(fontWeight: FontWeight.bold),
                      child: Text('Company'),
                    ),
                    DropdownButtonFormField<String?>(
                      value: _company,
                      items: _companies.map((company) {
                        return DropdownMenuItem<String?>(
                          value: company,
                          child: Text(company!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _company = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a company';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Employee',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: _employeeController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an employee';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Vendor',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: _vendorController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a vendor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    RichText(
                      text: const TextSpan(
                        text: 'Transaction Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Show the date picker
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        // Update the _transactionDateController with the selected date
                        if (pickedDate != null) {
                          setState(() {
                            _transactionDateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
                      child: Text(
                        _transactionDateController.text.isNotEmpty
                            ? _transactionDateController.text
                            : 'Select the Date of Your Transaction',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        backgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // SizedBox(height: 16),
                    // Text('Transaction Date'),
                    // TextFormField(
                    //   controller: _transactionDateController,
                    //   validator: (value) {
                    //     if (value == null || value.isEmpty) {
                    //       return 'Please enter a transaction date';
                    //     }
                    //     return null;
                    //   },
                    // ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Business Purpose',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButtonFormField<String?>(
                      value: _businessPurposeController,
                      items: _businessPurposes.map((businessPurpose) {
                        return DropdownMenuItem<String?>(
                          value: businessPurpose,
                          child: Text(businessPurpose!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _businessPurposeController = value!;
                          switch (value) {
                            case 'Employee Meals':
                              _gl = '7817-800';
                              break;
                            case 'Lodging':
                              _gl = '7818-800';
                              break;
                            case 'Miscellaneous':
                              _gl = '7816-800';
                              break;
                            case 'Rental Car':
                              _gl = '7821-800';
                              break;
                            case 'Corporate Contributions':
                              _gl = '7839-800';
                              break;
                            case 'Personal Car Mileage':
                              _gl = '7814-800';
                              break;
                            case 'Air Travel':
                              _gl = '7820-800';
                              break;
                            case 'Entertainment':
                              _gl = '7809-800';
                              break;
                            case 'Outside Service Other':
                              _gl = '7822-800';
                              break;
                            case 'Small Tools':
                              _gl = '7818-800';
                              break;
                            case 'Corporate and Licensing Fees':
                              _gl = '7682-800';
                              break;
                            case 'Parking':
                              _gl = '7816-800';
                              break;
                            case 'Suspense Charges Temporary':
                              _gl = '2030';
                              break;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a business purpose';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Item Description',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: _itemDescController,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Dollars',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextFormField(
                      controller: _dollarsController,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Corporate Credit Card',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButtonFormField<String?>(
                      value: _corporateCreditCard,
                      items: _corporateCreditCards.map((creditCard) {
                        return DropdownMenuItem<String?>(
                          value: creditCard,
                          child: Text(creditCard!),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _corporateCreditCard = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a corporate credit card option';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButtonFormField<String?>(
                      value: _status,
                      items: _statuses.map((status) {
                        return DropdownMenuItem<String?>(
                          value: status,
                          child: Text(status!),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _status = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a status';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Attach Receipt Image',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: getImageFromCamera,
                          child: Text('Camera'),
                        ),

                        //Begin Gallery Button
                        // ElevatedButton(
                        //   onPressed: getImageFromGallery,
                        //   child: Text('Gallery'),
                        // ),
                        //End Gallery Button

                        ElevatedButton(
                          onPressed: getFileFromGallery,
                          child: Text('File'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Center(
                    //   child: _image == null
                    //       ? Text('No image selected.')
                    //       : Image.file(_image!),
                    // ),
                    // Center(
                    //   child: _file == null
                    //       ? Text('No file selected.')
                    //       : (isImageFile(_file!.path)
                    //       ? Image.file(_file!)
                    //       : Text('Selected File: ${path.basename(_file!.path)}')),
                    // ),
                    Center(
                      child: _file == null
                          ? (_image == null
                          ? Text('No file or image selected.')
                          : Image.file(_image!))
                          : (isImageFile(_file!.path)
                          ? Image.file(_file!)
                          : Text('Selected File: ${path.basename(_file!.path)}')),
                    ),


                    SizedBox(height: 16),
                    // Center(
                    //   child: ElevatedButton(
                    //     onPressed: () async {
                    //       if (_formKey.currentState!.validate()) {
                    //         // Upload the image to S3 and get its URL
                    //         //final imageUrl = await uploadImageToS3(_image!);
                    //         setState(() {
                    //           _loading = true; // Show the loading indicator
                    //         });
                    //
                    //         String? imageUrl;
                    //         if (_image != null) {
                    //           imageUrl = await uploadImageToS3(_image!);
                    //         }
                    //
                    //         // Submit the form data and the image URL to the PHP API
                    //         final url = 'https://appdata.netstoic.com/expense_rpt/adddata.php';
                    //         final response = await http.post(Uri.parse(url), body: {
                    //           'company': _company,
                    //           'employee': _employeeController.text,
                    //           'vendor': _vendorController.text,
                    //           'trans_date': _transactionDateController.text,
                    //           'business_purpose': _businessPurposeController,
                    //           'item_desc': _itemDescController.text,
                    //           'gl': _gl,
                    //           'dollars': _dollarsController.text,
                    //           'corp_cc': _corporateCreditCard,
                    //           if (imageUrl != null) 'img_url': imageUrl, // Add img_url only if imageUrl is not null
                    //           //'img_url': imageUrl,
                    //           'status': _status,
                    //         });
                    //
                    //         if (response.statusCode == 200) {
                    //           setState(() {
                    //             _loading = false; // Hide the loading indicator
                    //           });
                    //           // Clear the form fields
                    //           //setState(() => _);
                    //           //_employeeController.clear();
                    //           _vendorController.clear();
                    //           _transactionDateController.clear();
                    //           _itemDescController.clear();
                    //           _dollarsController.clear();
                    //           setState(() {_image = null;});
                    //           clearDropdowns();
                    //           // _status = null;
                    //           // _corporateCreditCard = null;
                    //           // _businessPurposeController = null;
                    //           // _statuses.clear();
                    //           // _corporateCreditCards.clear();
                    //           // _businessPurposes.clear();
                    //
                    //           ScaffoldMessenger.of(context).showSnackBar(
                    //             const SnackBar(
                    //               content: Text('Expense submitted successfully!'),
                    //               duration: Duration(seconds: 3),
                    //             ),
                    //           );
                    //
                    //           print('Form data submitted successfully');
                    //         } else {
                    //           print('Error submitting form data: ${response.body}');
                    //         }
                    //       }
                    //     },
                    //     child: Text('Submit'),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
