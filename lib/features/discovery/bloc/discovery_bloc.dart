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
      const DiscoveryAstrologer(
        id: '7',
        name: 'Vikram Singh',
        title: 'Horary Astrology Specialist',
        profilePicture: 'https://randomuser.me/api/portraits/men/45.jpg',
        bio: 'Expert in answering specific questions using Horary astrology. Quick and accurate predictions for urgent matters.',
        specializations: ['Horary', 'Prashna', 'Lost & Found', 'Quick Predictions'],
        languages: ['English', 'Hindi'],
        experience: 9,
        ratePerMinute: 24.0,
        isOnline: true,
        isVerified: true,
        rating: 4.7,
        totalReviews: 167,
        totalConsultations: 820,
        followers: 1340,
        responseTime: '5 min',
        repeatClients: 74,
        achievements: ['Horary Expert', 'Quick Response Specialist'],
      ),
      const DiscoveryAstrologer(
        id: '8',
        name: 'Kavita Desai',
        title: 'Palmistry & Face Reading Expert',
        profilePicture: 'https://randomuser.me/api/portraits/women/55.jpg',
        bio: 'Traditional palmist with modern interpretations. Specialized in hand analysis and facial features reading.',
        specializations: ['Palmistry', 'Face Reading', 'Character Analysis', 'Future Predictions'],
        languages: ['English', 'Hindi', 'Gujarati'],
        experience: 11,
        ratePerMinute: 21.0,
        isOnline: true,
        isVerified: true,
        rating: 4.6,
        totalReviews: 203,
        totalConsultations: 950,
        followers: 1560,
        responseTime: '12 min',
        repeatClients: 69,
        achievements: ['Certified Palmist', 'Published Research Papers'],
      ),
      const DiscoveryAstrologer(
        id: '9',
        name: 'Swami Ananda',
        title: 'Spiritual Astrologer & Healer',
        profilePicture: 'https://randomuser.me/api/portraits/men/62.jpg',
        bio: 'Combining astrology with spiritual healing and meditation. Helping souls find their true path and inner peace.',
        specializations: ['Spiritual Astrology', 'Meditation', 'Energy Healing', 'Life Purpose'],
        languages: ['English', 'Hindi', 'Sanskrit'],
        experience: 20,
        ratePerMinute: 35.0,
        isOnline: true,
        isVerified: true,
        rating: 4.9,
        totalReviews: 512,
        totalConsultations: 3200,
        followers: 8900,
        responseTime: '2 min',
        repeatClients: 88,
        achievements: ['Spiritual Master', 'Yoga Guru', 'International Speaker'],
      ),
      const DiscoveryAstrologer(
        id: '10',
        name: 'Nisha Kapoor',
        title: 'Western Astrology Expert',
        profilePicture: 'https://randomuser.me/api/portraits/women/38.jpg',
        bio: 'Specialized in Western tropical astrology with psychological insights. Modern approach to ancient wisdom.',
        specializations: ['Western Astrology', 'Zodiac', 'Transits', 'Psychology'],
        languages: ['English'],
        experience: 6,
        ratePerMinute: 19.0,
        isOnline: true,
        isVerified: false,
        rating: 4.4,
        totalReviews: 87,
        totalConsultations: 380,
        followers: 620,
        responseTime: '10 min',
        repeatClients: 61,
        achievements: ['Western Astrology Certified', 'Psychology Background'],
      ),
      const DiscoveryAstrologer(
        id: '11',
        name: 'Guru Raghavendra',
        title: 'Nadi Astrology Master',
        profilePicture: 'https://randomuser.me/api/portraits/men/76.jpg',
        bio: 'Ancient Nadi astrology practitioner from Tamil Nadu. Reading palm leaf manuscripts for destiny insights.',
        specializations: ['Nadi Astrology', 'Tamil Astrology', 'Destiny Reading', 'Past Life'],
        languages: ['English', 'Tamil', 'Telugu', 'Kannada'],
        experience: 25,
        ratePerMinute: 40.0,
        isOnline: true,
        isVerified: true,
        rating: 4.8,
        totalReviews: 289,
        totalConsultations: 1870,
        followers: 4200,
        responseTime: '30 min',
        repeatClients: 79,
        achievements: ['Nadi Expert', 'Palm Leaf Reader', 'Heritage Practitioner'],
      ),
      const DiscoveryAstrologer(
        id: '12',
        name: 'Ritu Malhotra',
        title: 'Career & Business Astrologer',
        profilePicture: 'https://randomuser.me/api/portraits/women/47.jpg',
        bio: 'Focused on professional growth and business success through astrological guidance. MBA with astrology expertise.',
        specializations: ['Career', 'Business', 'Finance', 'Job Change', 'Entrepreneurship'],
        languages: ['English', 'Hindi'],
        experience: 8,
        ratePerMinute: 26.0,
        isOnline: true,
        isVerified: true,
        rating: 4.7,
        totalReviews: 142,
        totalConsultations: 710,
        followers: 1120,
        responseTime: '7 min',
        repeatClients: 76,
        achievements: ['MBA + Astrology', 'Business Consultant', 'Career Specialist'],
      ),
      const DiscoveryAstrologer(
        id: '13',
        name: 'Pandit Ganesh Iyer',
        title: 'Temple Astrologer & Ritualist',
        profilePicture: 'https://randomuser.me/api/portraits/men/81.jpg',
        bio: 'Traditional temple astrologer specializing in pujas, homas, and vedic remedies. Family tradition of 5 generations.',
        specializations: ['Temple Astrology', 'Pujas', 'Homas', 'Vedic Remedies', 'Muhurat'],
        languages: ['English', 'Hindi', 'Sanskrit', 'Malayalam'],
        experience: 16,
        ratePerMinute: 27.0,
        isOnline: true,
        isVerified: true,
        rating: 4.8,
        totalReviews: 234,
        totalConsultations: 1340,
        followers: 2870,
        responseTime: '6 min',
        repeatClients: 81,
        achievements: ['Temple Priest', 'Vedic Scholar', '5th Generation Astrologer'],
      ),
      const DiscoveryAstrologer(
        id: '14',
        name: 'Shalini Reddy',
        title: 'Medical Astrologer',
        profilePicture: 'https://randomuser.me/api/portraits/women/64.jpg',
        bio: 'Unique combination of medical knowledge and astrology. Predicting health issues and suggesting preventive measures.',
        specializations: ['Medical Astrology', 'Health Predictions', 'Remedies', 'Wellness'],
        languages: ['English', 'Hindi', 'Telugu'],
        experience: 10,
        ratePerMinute: 29.0,
        isOnline: true,
        isVerified: true,
        rating: 4.6,
        totalReviews: 176,
        totalConsultations: 890,
        followers: 1450,
        responseTime: '15 min',
        repeatClients: 72,
        achievements: ['Medical Astrology Specialist', 'Healthcare Background'],
      ),
      const DiscoveryAstrologer(
        id: '15',
        name: 'Arjun Bhardwaj',
        title: 'Love & Relationship Expert',
        profilePicture: 'https://randomuser.me/api/portraits/men/33.jpg',
        bio: 'Specializing in compatibility analysis, relationship counseling through astrology. Helping couples find harmony.',
        specializations: ['Love', 'Relationship', 'Compatibility', 'Marriage', 'Breakup'],
        languages: ['English', 'Hindi'],
        experience: 7,
        ratePerMinute: 23.0,
        isOnline: true,
        isVerified: true,
        rating: 4.8,
        totalReviews: 198,
        totalConsultations: 920,
        followers: 1780,
        responseTime: '4 min',
        repeatClients: 83,
        achievements: ['Relationship Expert', 'Compatibility Specialist', 'Top Rated Advisor'],
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

