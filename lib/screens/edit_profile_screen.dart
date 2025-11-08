import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelnomics_stable/services/auth_service.dart';
import 'package:pixelnomics_stable/utils/database_helper.dart';
import 'package:pixelnomics_stable/utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _authService = AuthService();
  final _picker = ImagePicker();

  final _fullNameController = TextEditingController();
  final _picturePathController = TextEditingController();

  int? _currentUserId;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _imageBase64;
  String _selectedCurrency = 'IDR';

  final Map<String, Map<String, dynamic>> _currencies = {
    'IDR': {'name': 'Indonesia', 'flag': '🇮🇩', 'symbol': 'Rp', 'code': 'IDR'},
    'USD': {
      'name': 'United States',
      'flag': '🇺🇸',
      'symbol': '\$',
      'code': 'USD',
    },
    'EUR': {'name': 'Europe', 'flag': '🇪🇺', 'symbol': '€', 'code': 'EUR'},
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUserId = await _authService.getUserId();
    if (_currentUserId != null) {
      final userData = await _dbHelper.getUserData(_currentUserId!);
      if (userData != null) {
        setState(() {
          _fullNameController.text =
              userData[DatabaseHelper.tableUsersColFullName] ?? '';
          _picturePathController.text =
              userData[DatabaseHelper.tableUsersColPicturePath] ?? '';
          _selectedCurrency =
              userData[DatabaseHelper.tableUsersColPreferredCurrency] ?? 'IDR';
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedImage = imageFile;
          _imageBase64 = base64String;
          _picturePathController.text = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Foto berhasil dipilih!'),
            backgroundColor: kSuccessColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedImage = imageFile;
          _imageBase64 = base64String;
          _picturePathController.text = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Foto berhasil diambil!'),
            backgroundColor: kSuccessColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Sumber Foto',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library_rounded, color: kPrimaryColor),
              ),
              title: Text('Galeri'),
              subtitle: Text('Pilih dari galeri foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt_rounded, color: kSecondaryColor),
              ),
              title: Text('Kamera'),
              subtitle: Text('Ambil foto baru'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_currentUserId == null) return;

    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama lengkap tidak boleh kosong!'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String finalPicturePath;
    if (_imageBase64 != null) {
      finalPicturePath = _imageBase64!;
    } else if (_picturePathController.text.isNotEmpty) {
      finalPicturePath = _picturePathController.text;
    } else {
      finalPicturePath = '';
    }

    await _dbHelper.updateUserData(
      _currentUserId!,
      _fullNameController.text.trim(),
      finalPicturePath,
      _selectedCurrency,
    );

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Profil berhasil diperbarui!'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildProfilePreview() {
    String? currentPicturePath = _picturePathController.text;

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (currentPicturePath.isNotEmpty &&
                        !currentPicturePath.startsWith('data:image'))
                  ? NetworkImage(currentPicturePath)
                  : null,
              child:
                  (_selectedImage == null &&
                      (currentPicturePath.isEmpty ||
                          currentPicturePath.startsWith('data:image')))
                  ? Icon(Icons.person, size: 60, color: kPrimaryColor)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: Text('Edit Profil'), elevation: 1),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildProfilePreview(),
                  SizedBox(height: 30),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Profil',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimaryColor,
                                ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                color: kPrimaryColor,
                              ),
                              helperText:
                                  'Nama yang akan ditampilkan di profil Anda',
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _picturePathController,
                            decoration: InputDecoration(
                              labelText: 'URL Gambar Profil (Opsional)',
                              prefixIcon: Icon(
                                Icons.link_rounded,
                                color: kPrimaryColor,
                              ),
                              helperText: 'Atau gunakan tombol kamera di atas',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedImage = null;
                                _imageBase64 = null;
                              });
                            },
                          ),
                          SizedBox(height: 24),
                          Divider(),
                          SizedBox(height: 16),
                          Text(
                            'Preferensi Mata Uang',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimaryColor,
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Harga game akan ditampilkan dalam mata uang ini',
                            style: TextStyle(
                              color: kTextSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 16),
                          ..._currencies.entries.map((entry) {
                            final currency = entry.value;
                            final isSelected = _selectedCurrency == entry.key;

                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCurrency = entry.key;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected
                                        ? kPrimaryColor.withOpacity(0.05)
                                        : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        currency['flag'],
                                        style: TextStyle(fontSize: 32),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currency['name'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: kTextPrimaryColor,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              '${currency['code']} (${currency['symbol']})',
                                              style: TextStyle(
                                                color: kTextSecondaryColor,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: kPrimaryColor,
                                          size: 28,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: kSuccessColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _picturePathController.dispose();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _loadUserData();
  // }

  // Future<void> _loadUserData() async {
  //   _currentUserId = await _authService.getUserId();
  //   if (_currentUserId != null) {
  //     final userData = await _dbHelper.getUserData(_currentUserId!);
  //     if (userData != null) {
  //       setState(() {
  //         _fullNameController.text = userData[DatabaseHelper.tableUsersColFullName] ?? '';
  //         _picturePathController.text = userData[DatabaseHelper.tableUsersColPicturePath] ?? '';
  //       });
  //     }
  //   }
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  // Future<void> _pickImageFromGallery() async {
  //   try {
  //     final XFile? pickedFile = await _picker.pickImage(
  //       source: ImageSource.gallery,
  //       maxWidth: 512,
  //       maxHeight: 512,
  //       imageQuality: 85,
  //     );

  //     if (pickedFile != null) {
  //       final File imageFile = File(pickedFile.path);
  //       final bytes = await imageFile.readAsBytes();
  //       final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

  //       setState(() {
  //         _selectedImage = imageFile;
  //         _imageBase64 = base64String;
  //         _picturePathController.text = '';
  //       });

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('✅ Foto berhasil dipilih!'),
  //           backgroundColor: kSuccessColor,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Gagal memilih foto: $e'),
  //         backgroundColor: kErrorColor,
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //       ),
  //     );
  //   }
  // }

  // Future<void> _pickImageFromCamera() async {
  //   try {
  //     final XFile? pickedFile = await _picker.pickImage(
  //       source: ImageSource.camera,
  //       maxWidth: 512,
  //       maxHeight: 512,
  //       imageQuality: 85,
  //     );

  //     if (pickedFile != null) {
  //       final File imageFile = File(pickedFile.path);
  //       final bytes = await imageFile.readAsBytes();
  //       final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

  //       setState(() {
  //         _selectedImage = imageFile;
  //         _imageBase64 = base64String;
  //         _picturePathController.text = '';
  //       });

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('✅ Foto berhasil diambil!'),
  //           backgroundColor: kSuccessColor,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Gagal mengambil foto: $e'),
  //         backgroundColor: kErrorColor,
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //       ),
  //     );
  //   }
  // }

  // void _showImageSourceDialog() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => Container(
  //       padding: EdgeInsets.all(20),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             'Pilih Sumber Foto',
  //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           SizedBox(height: 20),
  //           ListTile(
  //             leading: Container(
  //               padding: EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: kPrimaryColor.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(Icons.photo_library_rounded, color: kPrimaryColor),
  //             ),
  //             title: Text('Galeri'),
  //             subtitle: Text('Pilih dari galeri foto'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickImageFromGallery();
  //             },
  //           ),
  //           ListTile(
  //             leading: Container(
  //               padding: EdgeInsets.all(10),
  //               decoration: BoxDecoration(
  //                 color: kSecondaryColor.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(Icons.camera_alt_rounded, color: kSecondaryColor),
  //             ),
  //             title: Text('Kamera'),
  //             subtitle: Text('Ambil foto baru'),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickImageFromCamera();
  //             },
  //           ),
  //           SizedBox(height: 10),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Future<void> _saveProfile() async {
  //   if (_currentUserId == null) return;

  //   if (_fullNameController.text.trim().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Nama lengkap tidak boleh kosong!'),
  //         backgroundColor: kErrorColor,
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isSaving = true;
  //   });

  //   String finalPicturePath;
  //   if (_imageBase64 != null) {
  //     finalPicturePath = _imageBase64!;
  //   } else if (_picturePathController.text.isNotEmpty) {
  //     finalPicturePath = _picturePathController.text;
  //   } else {
  //     finalPicturePath = '';
  //   }

  //   await _dbHelper.updateUserData(
  //     _currentUserId!,
  //     _fullNameController.text.trim(),
  //     finalPicturePath,
  //   );

  //   setState(() {
  //     _isSaving = false;
  //   });

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('✅ Profil berhasil diperbarui!'),
  //       backgroundColor: kSuccessColor,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //     ),
  //   );
  //   Navigator.pop(context);
  // }

  // Widget _buildProfilePreview() {
  //   String? currentPicturePath = _picturePathController.text;

  //   return Center(
  //     child: Stack(
  //       children: [
  //         Container(
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: kPrimaryColor.withOpacity(0.3),
  //                 blurRadius: 20,
  //                 spreadRadius: 5,
  //               ),
  //             ],
  //           ),
  //           child: CircleAvatar(
  //             radius: 70,
  //             backgroundColor: kPrimaryColor.withOpacity(0.1),
  //             backgroundImage: _selectedImage != null
  //                 ? FileImage(_selectedImage!)
  //                 : (currentPicturePath.isNotEmpty &&
  //                    !currentPicturePath.startsWith('data:image'))
  //                     ? NetworkImage(currentPicturePath)
  //                     : null,
  //             child: (_selectedImage == null &&
  //                    (currentPicturePath.isEmpty ||
  //                     currentPicturePath.startsWith('data:image')))
  //                 ? Icon(
  //                     Icons.person,
  //                     size: 60,
  //                     color: kPrimaryColor,
  //                   )
  //                 : null,
  //           ),
  //         ),
  //         Positioned(
  //           bottom: 0,
  //           right: 0,
  //           child: GestureDetector(
  //             onTap: _showImageSourceDialog,
  //             child: Container(
  //               padding: EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: kPrimaryColor,
  //                 shape: BoxShape.circle,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: kPrimaryColor.withOpacity(0.4),
  //                     blurRadius: 8,
  //                     spreadRadius: 2,
  //                   ),
  //                 ],
  //               ),
  //               child: Icon(
  //                 Icons.camera_alt_rounded,
  //                 color: Colors.white,
  //                 size: 24,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: kBackgroundColor,
  //     appBar: AppBar(
  //       title: Text('Edit Profil'),
  //       elevation: 1,
  //     ),
  //     body: _isLoading
  //         ? Center(
  //             child: CircularProgressIndicator(color: kPrimaryColor),
  //           )
  //         : SingleChildScrollView(
  //             padding: const EdgeInsets.all(20.0),
  //             child: Column(
  //               children: [
  //                 SizedBox(height: 20),
  //                 _buildProfilePreview(),
  //                 SizedBox(height: 30),
  //                 Card(
  //                   elevation: 2,
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(20.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           'Informasi Profil',
  //                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                             fontWeight: FontWeight.bold,
  //                             color: kTextPrimaryColor,
  //                           ),
  //                         ),
  //                         SizedBox(height: 20),
  //                         TextField(
  //                           controller: _fullNameController,
  //                           decoration: InputDecoration(
  //                             labelText: 'Nama Lengkap',
  //                             prefixIcon: Icon(Icons.person_rounded, color: kPrimaryColor),
  //                             helperText: 'Nama yang akan ditampilkan di profil Anda',
  //                           ),
  //                         ),
  //                         SizedBox(height: 20),
  //                         TextField(
  //                           controller: _picturePathController,
  //                           decoration: InputDecoration(
  //                             labelText: 'URL Gambar Profil (Opsional)',
  //                             prefixIcon: Icon(Icons.link_rounded, color: kPrimaryColor),
  //                             helperText: 'Atau gunakan tombol kamera di atas',
  //                           ),
  //                           onChanged: (value) {
  //                             setState(() {
  //                               _selectedImage = null;
  //                               _imageBase64 = null;
  //                             });
  //                           },
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(height: 30),
  //                 SizedBox(
  //                   width: double.infinity,
  //                   child: ElevatedButton.icon(
  //                     icon: _isSaving
  //                         ? SizedBox(
  //                             width: 20,
  //                             height: 20,
  //                             child: CircularProgressIndicator(
  //                               strokeWidth: 2,
  //                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //                             ),
  //                           )
  //                         : Icon(Icons.save_rounded),
  //                     label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
  //                     onPressed: _isSaving ? null : _saveProfile,
  //                     style: ElevatedButton.styleFrom(
  //                       padding: EdgeInsets.symmetric(vertical: 16),
  //                       backgroundColor: kSuccessColor,
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(height: 40),
  //               ],
  //             ),
  //           ),
  //   );
  // }

  // @override
  // void dispose() {
  //   _fullNameController.dispose();
  //   _picturePathController.dispose();
  //   super.dispose();
  // }
}
