import 'package:flutter_bloc/flutter_bloc.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';
import '../models/discovery_astrologer.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc() : super(const DiscoveryInitial()) {
    on<LoadAstrologersEvent>(_onLoadAstrologers);
    on<RefreshAstrologersEvent>(_onRefreshAstrologers);
    on<SearchAstrologersEvent>(_onSearchAstrologers);
    on<ClearFiltersEvent>(_onClearFilters);
  }

  // Mock data for now - would be API call in production
  List<DiscoveryAstrologer> _getMockAstrologers() {
    return [
      const DiscoveryAstrologer(
        id: '1',
        name: 'Dr. Rajesh Kumar',
        title: 'Vedic Astrology Expert',
        profilePicture: 'https://randomuser.me/api/portraits/men/32.jpg',
        bio: 'Expert in Vedic Astrology with 12 years of experience. Specialized in career guidance, marriage compatibility, and gemstone recommendations.',
        specializations: ['Career', 'Marriage', 'Health', 'Business', 'Gemstones', 'Kundali'],
        languages: ['English', 'Hindi', 'Marathi'],
        experience: 12,
        ratePerMinute: 25.0,
        isOnline: true,
        isVerified: true,
        rating: 4.8,
        totalReviews: 230,
        totalConsultations: 1200,
        followers: 2450,
        responseTime: '5 min',
        repeatClients: 78,
        achievements: ['Best Astrologer Award 2023', 'Featured in Times of India', 'TEDx Speaker'],
      ),
      const DiscoveryAstrologer(
        id: '2',
        name: 'Priya Sharma',
        title: 'Tarot & Astrology Specialist',
        profilePicture: 'https://randomuser.me/api/portraits/women/44.jpg',
        bio: '8 years of experience in Tarot reading and Vedic astrology. Helping people find clarity in relationships and life decisions.',
        specializations: ['Tarot', 'Love & Relationships', 'Career', 'Spiritual Guidance'],
        languages: ['English', 'Hindi'],
        experience: 8,
        ratePerMinute: 20.0,
        isOnline: false,
        isVerified: true,
        rating: 4.9,
        totalReviews: 345,
        totalConsultations: 890,
        followers: 1850,
        responseTime: '10 min',
        repeatClients: 85,
        achievements: ['Certified Tarot Master', 'Top Rated Advisor 2023'],
      ),
      const DiscoveryAstrologer(
        id: '3',
        name: 'Acharya Vishwanath',
        title: 'KP Astrology Master',
        profilePicture: 'https://randomuser.me/api/portraits/men/52.jpg',
        bio: 'Renowned KP astrologer with 15+ years of experience. Precise predictions using Krishnamurti Paddhati system.',
        specializations: ['KP System', 'Marriage Timing', 'Career', 'Health', 'Finance'],
        languages: ['English', 'Hindi', 'Tamil', 'Telugu'],
        experience: 15,
        ratePerMinute: 30.0,
        isOnline: true,
        isVerified: true,
        rating: 4.7,
        totalReviews: 180,
        totalConsultations: 1450,
        followers: 3200,
        responseTime: '3 min',
        repeatClients: 72,
        achievements: ['KP Research Award', '20+ Years in Practice', 'Published Author'],
      ),
      const DiscoveryAstrologer(
        id: '4',
        name: 'Meera Patel',
        title: 'Numerology & Vastu Expert',
        profilePicture: 'https://randomuser.me/api/portraits/women/68.jpg',
        bio: 'Certified numerologist and Vastu consultant. Helping people harmonize their spaces and life paths through ancient sciences.',
        specializations: ['Numerology', 'Vastu', 'Name Correction', 'Lucky Numbers'],
        languages: ['English', 'Hindi', 'Gujarati'],
        experience: 10,
        ratePerMinute: 22.0,
        isOnline: true,
        isVerified: false,
        rating: 4.6,
        totalReviews: 156,
        totalConsultations: 670,
        followers: 980,
        responseTime: '15 min',
        repeatClients: 68,
        achievements: ['Vastu Shastra Certified', 'Numerology Master'],
      ),
      const DiscoveryAstrologer(
        id: '5',
        name: 'Pandit Suresh Joshi',
        title: 'Traditional Vedic Astrologer',
        profilePicture: 'https://randomuser.me/api/portraits/men/71.jpg',
        bio: '18 years of deep study in Vedic astrology and Sanskrit. Providing traditional remedies and spiritual guidance.',
        specializations: ['Vedic Astrology', 'Remedies', 'Muhurat', 'Puja', 'Gemstones'],
        languages: ['English', 'Hindi', 'Sanskrit'],
        experience: 18,
        ratePerMinute: 28.0,
        isOnline: false,
        isVerified: true,
        rating: 4.9,
        totalReviews: 420,
        totalConsultations: 2100,
        followers: 5600,
        responseTime: '20 min',
        repeatClients: 82,
        achievements: ['Jyotish Acharya', 'Temple Priest', 'Vedic Scholar'],
      ),
      const DiscoveryAstrologer(
        id: '6',
        name: 'Anjali Verma',
        title: 'Lal Kitab Specialist',
        profilePicture: 'https://randomuser.me/api/portraits/women/29.jpg',
        bio: 'Unique expertise in Lal Kitab astrology with simple and effective remedies. 7 years of dedicated practice.',
        specializations: ['Lal Kitab', 'Simple Remedies', 'Career', 'Business'],
        languages: ['English', 'Hindi', 'Punjabi'],
        experience: 7,
        ratePerMinute: 18.0,
        isOnline: true,
        isVerified: true,
        rating: 4.5,
        totalReviews: 98,
        totalConsultations: 450,
        followers: 720,
        responseTime: '8 min',
        repeatClients: 65,
        achievements: ['Lal Kitab Expert', 'Featured in Astrology Magazine'],
      ),
    ];
  }

  Future<void> _onLoadAstrologers(
    LoadAstrologersEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(const DiscoveryLoading());
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      List<DiscoveryAstrologer> astrologers = _getMockAstrologers();
      
      // Apply filters
      if (event.specialization != null) {
        astrologers = astrologers.where((a) => 
          a.specializations.any((s) => s.toLowerCase().contains(event.specialization!.toLowerCase()))
        ).toList();
      }
      
      if (event.language != null) {
        astrologers = astrologers.where((a) => 
          a.languages.any((l) => l.toLowerCase() == event.language!.toLowerCase())
        ).toList();
      }
      
      if (event.minRating != null) {
        astrologers = astrologers.where((a) => a.rating >= event.minRating!).toList();
      }
      
      if (event.onlineOnly == true) {
        astrologers = astrologers.where((a) => a.isOnline).toList();
      }
      
      // Apply sorting
      if (event.sortBy != null) {
        switch (event.sortBy) {
          case 'rating':
            astrologers.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case 'experience':
            astrologers.sort((a, b) => b.experience.compareTo(a.experience));
            break;
          case 'consultations':
            astrologers.sort((a, b) => b.totalConsultations.compareTo(a.totalConsultations));
            break;
        }
      }
      
      emit(DiscoveryLoaded(
        astrologers: astrologers,
        activeFilter: event.specialization ?? event.sortBy,
      ));
    } catch (e) {
      emit(DiscoveryError('Failed to load astrologers: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshAstrologers(
    RefreshAstrologersEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    // Reload without filters
    add(const LoadAstrologersEvent());
  }

  Future<void> _onSearchAstrologers(
    SearchAstrologersEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const LoadAstrologersEvent());
      return;
    }
    
    emit(const DiscoveryLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      List<DiscoveryAstrologer> astrologers = _getMockAstrologers();
      
      // Search by name, title, specialization, or language
      astrologers = astrologers.where((a) =>
        a.name.toLowerCase().contains(event.query.toLowerCase()) ||
        a.title.toLowerCase().contains(event.query.toLowerCase()) ||
        a.specializations.any((s) => s.toLowerCase().contains(event.query.toLowerCase())) ||
        a.languages.any((l) => l.toLowerCase().contains(event.query.toLowerCase()))
      ).toList();
      
      emit(DiscoveryLoaded(
        astrologers: astrologers,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(DiscoveryError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onClearFilters(
    ClearFiltersEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    add(const LoadAstrologersEvent());
  }
}

