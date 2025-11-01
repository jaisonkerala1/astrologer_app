import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../auth/models/astrologer_model.dart';
import 'verification_submitted_celebration_screen.dart';

class VerificationDocumentUploadScreen extends StatefulWidget {
  final AstrologerModel astrologer;
  final bool isResubmission;
  
  const VerificationDocumentUploadScreen({
    super.key,
    required this.astrologer,
    this.isResubmission = false,
  });

  @override
  State<VerificationDocumentUploadScreen> createState() => _VerificationDocumentUploadScreenState();
}

class _VerificationDocumentUploadScreenState extends State<VerificationDocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _certificateImage;
  File? _idProofImage;
  File? _storefrontImage;
  
  bool _isUploading = false;

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case 'certificate':
              _certificateImage = File(image.path);
              break;
            case 'idProof':
              _idProofImage = File(image.path);
              break;
            case 'storefront':
              _storefrontImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case 'certificate':
              _certificateImage = File(image.path);
              break;
            case 'idProof':
              _idProofImage = File(image.path);
              break;
            case 'storefront':
              _storefrontImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(String type, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeService.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                  const SizedBox(height: 20),
                  Text(
                    'Upload $title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeService.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.photo_camera, color: themeService.primaryColor),
                    title: const Text('Take Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto(type);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: themeService.primaryColor),
                    title: const Text('Choose from Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(type);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitDocuments(ThemeService themeService) async {
    if (_idProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload ID Proof (required)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isUploading = false;
      });

      // Navigate to celebration screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerificationSubmittedCelebrationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: Text(widget.isResubmission ? 'Re-submit Documents' : 'Upload Documents'),
            backgroundColor: themeService.cardColor,
            elevation: 0,
            iconTheme: IconThemeData(color: themeService.textPrimary),
            titleTextStyle: TextStyle(
              color: themeService.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isResubmission) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Previous Rejection Reason',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.astrologer.verificationRejectionReason ?? 'Please resubmit with correct documents',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: themeService.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                Text(
                  'Required Documents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeService.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only ID Proof is mandatory. You can submit Certificate or Storefront image if available.',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeService.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                _buildDocumentUpload(
                  'Government ID Proof',
                  'Aadhaar, PAN, Passport, or Driver\'s License',
                  _idProofImage,
                  'idProof',
                  Icons.badge,
                  true,
                  themeService,
                ),
                const SizedBox(height: 16),

                _buildDocumentUpload(
                  'Astrology Certificate (Optional)',
                  'Upload if you have valid astrology certification',
                  _certificateImage,
                  'certificate',
                  Icons.workspace_premium,
                  false,
                  themeService,
                ),
                const SizedBox(height: 16),

                _buildDocumentUpload(
                  'Storefront Image (Optional)',
                  'Photo of your shop/office or consultation space',
                  _storefrontImage,
                  'storefront',
                  Icons.store,
                  false,
                  themeService,
                ),
                const SizedBox(height: 32),

                AnimatedButton(
                  onPressed: _isUploading ? null : () => _submitDocuments(themeService),
                  text: _isUploading 
                      ? 'Submitting...' 
                      : widget.isResubmission 
                          ? 'Re-submit Documents'
                          : 'Submit for Review',
                  icon: _isUploading ? null : Icons.upload_file,
                  backgroundColor: themeService.primaryColor,
                  foregroundColor: Colors.white,
                  width: double.infinity,
                  height: 56,
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your documents will be reviewed within 24-48 hours. You\'ll receive a notification once the review is complete.',
                          style: TextStyle(
                            fontSize: 13,
                            color: themeService.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentUpload(
    String title,
    String subtitle,
    File? image,
    String type,
    IconData icon,
    bool required,
    ThemeService themeService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: image != null 
              ? Colors.green.withOpacity(0.5)
              : themeService.borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: themeService.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeService.textPrimary,
                            ),
                          ),
                          if (required) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '*',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeService.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (image != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _buildImageActionButton(
                        Icons.edit,
                        () => _showImageSourceDialog(type, title),
                        themeService,
                      ),
                      const SizedBox(width: 8),
                      _buildImageActionButton(
                        Icons.delete,
                        () {
                      setState(() {
                        switch (type) {
                          case 'certificate':
                            _certificateImage = null;
                            break;
                          case 'idProof':
                            _idProofImage = null;
                            break;
                          case 'storefront':
                            _storefrontImage = null;
                            break;
                        }
                      });
                        },
                        themeService,
                        isDelete: true,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: () => _showImageSourceDialog(type, title),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 40,
                        color: themeService.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeService.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton(
    IconData icon,
    VoidCallback onTap,
    ThemeService themeService, {
    bool isDelete = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDelete ? Colors.red : themeService.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isDelete ? Colors.red : themeService.primaryColor).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

