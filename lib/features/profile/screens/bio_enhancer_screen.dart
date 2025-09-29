import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/profile_bloc.dart';
import '../services/ai_enhancement_service.dart';
import '../../auth/models/astrologer_model.dart';
import '../../../shared/theme/services/theme_service.dart';

class BioEnhancerScreen extends StatefulWidget {
  final AstrologerModel currentUser;
  final VoidCallback? onBioUpdated;

  const BioEnhancerScreen({
    Key? key,
    required this.currentUser,
    this.onBioUpdated,
  }) : super(key: key);

  @override
  State<BioEnhancerScreen> createState() => _BioEnhancerScreenState();
}

class _BioEnhancerScreenState extends State<BioEnhancerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  Map<String, String> _enhancedBios = {};
  String? _selectedVersion;
  String? _selectedBio;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _enhanceBio() async {
    if (widget.currentUser.bio.isEmpty) {
      _showSnackBar('Please add a bio first before enhancing it', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final enhancedBios = await AIEnhancementService.enhanceBio(
        widget.currentUser.bio,
        name: widget.currentUser.name,
        experience: widget.currentUser.experience,
        specializations: widget.currentUser.specializations,
        languages: widget.currentUser.languages,
        awards: widget.currentUser.awards,
        certificates: widget.currentUser.certificates,
      );
      setState(() {
        _enhancedBios = enhancedBios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Failed to enhance bio';
      if (e.toString().contains('API Error')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else if (e.toString().contains('Failed to enhance bio')) {
        errorMessage = e.toString().replaceFirst('Exception: Failed to enhance bio: ', '');
      }
      
      _showSnackBar(errorMessage, isError: true);
    }
  }

  void _selectBio(String version, String bio) {
    setState(() {
      _selectedVersion = version;
      _selectedBio = bio;
    });
  }

  Future<void> _updateBio() async {
    if (_selectedBio == null) {
      _showSnackBar('Please select a bio version first', isError: true);
      return;
    }

    try {
      // Update bio using existing profile API
      await context.read<ProfileBloc>().updateBio(_selectedBio!);
      
      // Call the callback to notify parent
      widget.onBioUpdated?.call();
      
      _showSnackBar('Bio updated successfully!', isError: false);
      Navigator.pop(context, true); // Return true to indicate bio was updated
    } catch (e) {
      _showSnackBar('Failed to update bio: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bio Enhancer',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: themeService.textPrimary,
          ),
        ),
        backgroundColor: themeService.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: themeService.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedBio != null)
            TextButton(
              onPressed: _updateBio,
              child: Text(
                'Update',
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(themeService),
                const SizedBox(height: 24),
                _buildOriginalBioCard(themeService),
                const SizedBox(height: 24),
                _buildEnhanceButton(themeService),
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  _buildLoadingCard(themeService),
                ],
                if (_enhancedBios.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildEnhancedBiosSection(themeService),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeService.primaryColor, themeService.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeService.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'AI Bio Enhancer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transform your bio with AI-powered enhancements. Get 3 professional versions tailored for different audiences.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalBioCard(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: themeService.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Bio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeService.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.currentUser.bio.isEmpty 
                ? 'No bio available. Please add a bio first.'
                : widget.currentUser.bio,
            style: TextStyle(
              fontSize: 16,
              color: themeService.textPrimary.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanceButton(ThemeService themeService) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _enhanceBio,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeService.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enhance My Bio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeService themeService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'AI is enhancing your bio...',
            style: TextStyle(
              fontSize: 16,
              color: themeService.textPrimary.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(
              fontSize: 14,
              color: themeService.textPrimary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBiosSection(ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: themeService.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Enhanced Versions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._enhancedBios.entries.map((entry) => _buildBioVersionCard(entry.key, entry.value, themeService)),
      ],
    );
  }

  Widget _buildBioVersionCard(String version, String bio, ThemeService themeService) {
    final isSelected = _selectedVersion == version;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? themeService.primaryColor.withOpacity(0.1) : themeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? themeService.primaryColor : themeService.borderColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? themeService.primaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectBio(version, bio),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? themeService.primaryColor
                            : themeService.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        version,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white
                              : themeService.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: themeService.primaryColor,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeService.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
