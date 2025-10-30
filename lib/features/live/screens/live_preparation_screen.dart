import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import 'live_streaming_screen.dart';

class LivePreparationScreen extends StatefulWidget {
  final VoidCallback? onClose;
  
  const LivePreparationScreen({super.key, this.onClose});

  @override
  State<LivePreparationScreen> createState() => _LivePreparationScreenState();
}

class _LivePreparationScreenState extends State<LivePreparationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  LiveStreamCategory _selectedCategory = LiveStreamCategory.astrology;
  bool _isLoading = false;

  final LiveStreamService _liveService = LiveStreamService();

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Daily Astrology Reading';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final theme = themeService;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                theme.isDarkMode() ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                theme.isDarkMode() ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.surfaceColor,
              leading: IconButton(
                icon: Icon(Icons.close, color: theme.textPrimary),
                onPressed: () {
                  // Use callback if provided (PageView context), otherwise pop (Route context)
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                'Go Live',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: Container(
              decoration: BoxDecoration(gradient: theme.backgroundGradient),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(theme),
                      const SizedBox(height: 28),
                      _buildInfoBanner(theme),
                      const SizedBox(height: 24),
                      _buildTitleField(theme),
                      const SizedBox(height: 20),
                      _buildDescriptionField(theme),
                      const SizedBox(height: 28),
                      _buildCategorySection(theme),
                      const SizedBox(height: 32),
                      _buildStartLiveButton(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(ThemeService theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [theme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to start streaming?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set up the perfect session before going live.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your audience is waiting',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Craft a compelling title and description. Focus on the transformation viewers will experience.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(ThemeService theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.infoColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.infoColor.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: theme.infoColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make it discoverable',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use clear, benefit-driven titles so the right viewers can find you quickly.',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTitleField(ThemeService theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stream title *',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _titleController,
          style: TextStyle(color: theme.textPrimary, fontSize: 16),
          decoration: _inputDecoration(
            theme,
            hint: 'Example: Live Tarot for upcoming relationships',
            icon: Icons.title_rounded,
          ),
          maxLength: 80,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please add a title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeService theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (optional)',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descriptionController,
          style: TextStyle(color: theme.textPrimary, fontSize: 15, height: 1.4),
          decoration: _inputDecoration(
            theme,
            hint: 'Outline what you will cover and highlight the outcomes viewers will receive.',
            icon: Icons.short_text_rounded,
          ),
          maxLines: 4,
          maxLength: 400,
        ),
      ],
    );
  }

  Widget _buildCategorySection(ThemeService theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: theme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Category',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: LiveStreamCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(
                _getCategoryDisplayName(category),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : theme.textSecondary,
                ),
              ),
              avatar: Icon(
                _getCategoryIcon(category),
                size: 18,
                color: isSelected ? Colors.white : theme.textSecondary,
              ),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: theme.primaryColor,
              backgroundColor: theme.surfaceColor,
              side: BorderSide(
                color: isSelected
                    ? theme.primaryColor
                    : theme.borderColor.withOpacity(0.8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              pressElevation: 0,
              elevation: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartLiveButton(ThemeService theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _startLiveStream,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
              shadowColor: const Color(0xFFFF2D55).withOpacity(0.45),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5F6D), Color(0xFFFF2D55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_button_checked_rounded, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Start live stream',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your stream will be public. Adjust advanced settings once you are live.',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getCategoryDisplayName(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return 'General';
      case LiveStreamCategory.astrology:
        return 'Astrology';
      case LiveStreamCategory.healing:
        return 'Healing';
      case LiveStreamCategory.meditation:
        return 'Meditation';
      case LiveStreamCategory.tarot:
        return 'Tarot';
      case LiveStreamCategory.numerology:
        return 'Numerology';
      case LiveStreamCategory.palmistry:
        return 'Palmistry';
      case LiveStreamCategory.spiritual:
        return 'Spiritual';
    }
  }

  IconData _getCategoryIcon(LiveStreamCategory category) {
    switch (category) {
      case LiveStreamCategory.general:
        return Icons.auto_awesome;
      case LiveStreamCategory.astrology:
        return Icons.nights_stay;
      case LiveStreamCategory.healing:
        return Icons.self_improvement;
      case LiveStreamCategory.meditation:
        return Icons.spa;
      case LiveStreamCategory.tarot:
        return Icons.filter_frames;
      case LiveStreamCategory.numerology:
        return Icons.calculate;
      case LiveStreamCategory.palmistry:
        return Icons.pan_tool_alt;
      case LiveStreamCategory.spiritual:
        return Icons.brightness_high;
    }
  }

  Future<void> _startLiveStream() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final success = await _liveService.startLiveStream(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        quality: LiveStreamQuality.high,
        isPrivate: false,
        tags: const [],
      );

      if (success && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LiveStreamingScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start live stream. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    ThemeService theme, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.textHint,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: theme.textSecondary),
      filled: true,
      fillColor: theme.surfaceColor,
      counterStyle: TextStyle(color: theme.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.errorColor, width: 1.5),
      ),
    );
  }
}
