const normalizeAstrologer = (astrologerDoc) => {
  if (!astrologerDoc) {
    return null;
  }

  const astro = typeof astrologerDoc.toObject === 'function'
    ? astrologerDoc.toObject({ virtuals: true })
    : astrologerDoc;

  const id = astro._id?.toString?.() || astro.id || null;

  return {
    id,
    _id: id,
    phone: astro.phone || '',
    name: astro.name || '',
    email: astro.email || '',
    profilePicture: astro.profilePicture || null,
    specializations: Array.isArray(astro.specializations) ? astro.specializations : [],
    languages: Array.isArray(astro.languages) ? astro.languages : [],
    experience: astro.experience ?? 0,
    ratePerMinute: astro.ratePerMinute ?? 0,
    isOnline: astro.isOnline ?? false,
    totalEarnings: astro.totalEarnings ?? 0,
    isActive: astro.isActive ?? true,
    bio: astro.bio || '',
    awards: astro.awards || '',
    certificates: astro.certificates || '',
    lastSeen: astro.lastSeen || null,
    createdAt: astro.createdAt || null,
    updatedAt: astro.updatedAt || null,
    // Admin approval fields
    isApproved: astro.isApproved ?? false,
    approvedAt: astro.approvedAt || null,
    approvedBy: astro.approvedBy || null,
    isSuspended: astro.isSuspended ?? false,
    suspendedAt: astro.suspendedAt || null,
    suspensionReason: astro.suspensionReason || null,
    sessionId: astro.activeSession?.sessionId || astro.sessionId || null,
    activeSession: astro.activeSession
      ? {
          sessionId: astro.activeSession.sessionId || null,
          deviceInfo: astro.activeSession.deviceInfo || {},
          createdAt: astro.activeSession.createdAt || null,
          lastSeenAt: astro.activeSession.lastSeenAt || null,
        }
      : null,
  };
};

module.exports = normalizeAstrologer;
const sanitizeAstrologer = (astrologer) => {
  if (!astrologer) {
    return null;
  }

  const astroObj = typeof astrologer.toObject === 'function'
    ? astrologer.toObject({ virtuals: true })
    : astrologer;

  const id = astroObj._id?.toString?.() || astroObj.id || astroObj._id;

  return {
    id,
    _id: id,
    phone: astroObj.phone || '',
    name: astroObj.name || '',
    email: astroObj.email || '',
    profilePicture: astroObj.profilePicture || null,
    specializations: Array.isArray(astroObj.specializations) ? astroObj.specializations : [],
    languages: Array.isArray(astroObj.languages) ? astroObj.languages : [],
    experience: astroObj.experience ?? 0,
    ratePerMinute: astroObj.ratePerMinute ?? 0,
    isOnline: astroObj.isOnline ?? false,
    totalEarnings: astroObj.totalEarnings ?? 0,
    isActive: astroObj.isActive ?? true,
    bio: astroObj.bio || '',
    awards: astroObj.awards || '',
    certificates: astroObj.certificates || '',
    lastSeen: astroObj.lastSeen || null,
    createdAt: astroObj.createdAt || null,
    updatedAt: astroObj.updatedAt || null,
    // Admin approval fields
    isApproved: astroObj.isApproved ?? false,
    approvedAt: astroObj.approvedAt || null,
    approvedBy: astroObj.approvedBy || null,
    isSuspended: astroObj.isSuspended ?? false,
    suspendedAt: astroObj.suspendedAt || null,
    suspensionReason: astroObj.suspensionReason || null,
    sessionId: astroObj.activeSession?.sessionId || null,
    activeSession: astroObj.activeSession
      ? {
          sessionId: astroObj.activeSession.sessionId || null,
          deviceInfo: astroObj.activeSession.deviceInfo || {},
          createdAt: astroObj.activeSession.createdAt || null,
          lastSeenAt: astroObj.activeSession.lastSeenAt || null,
        }
      : null,
  };
};

// Export both functions
module.exports = normalizeAstrologer;
module.exports.sanitizeAstrologer = sanitizeAstrologer;

