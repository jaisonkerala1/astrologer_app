/**
 * Admin Authentication Middleware
 * Validates admin access using a secret key from environment variables
 */

const adminAuth = (req, res, next) => {
  try {
    // Get admin key from header
    const adminKey = req.headers['x-admin-key'];
    
    // Check if admin key is provided
    if (!adminKey) {
      return res.status(401).json({
        success: false,
        message: 'Admin authentication required',
        error: 'No admin key provided'
      });
    }
    
    // Validate against environment variable
    const validAdminKey = process.env.ADMIN_SECRET_KEY;
    
    if (!validAdminKey) {
      console.error('ADMIN_SECRET_KEY not set in environment variables');
      return res.status(500).json({
        success: false,
        message: 'Server configuration error',
        error: 'Admin authentication not configured'
      });
    }
    
    if (adminKey !== validAdminKey) {
      return res.status(403).json({
        success: false,
        message: 'Invalid admin credentials',
        error: 'Admin key does not match'
      });
    }
    
    // Admin authenticated successfully
    req.isAdmin = true;
    req.adminAuthenticatedAt = new Date();
    
    next();
  } catch (error) {
    console.error('Admin auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication error',
      error: error.message
    });
  }
};

module.exports = adminAuth;


