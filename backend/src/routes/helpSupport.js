const express = require('express');
const router = express.Router();
const HelpArticle = require('../models/HelpArticle');
const FAQ = require('../models/FAQ');
const auth = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// ============================================================================
// HELP ARTICLES - USER ENDPOINTS
// ============================================================================

/**
 * @route   GET /api/support/articles
 * @desc    Get all published help articles
 * @access  Public
 */
router.get('/articles', async (req, res) => {
  try {
    const { category, page = 1, limit = 20, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;

    const filter = { status: 'published' };
    if (category) {
      filter.category = category;
    }

    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [articles, totalCount] = await Promise.all([
      HelpArticle.find(filter).sort(sort).skip(skip).limit(parseInt(limit)).lean(),
      HelpArticle.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        articles: articles.map((a) => ({ ...a, id: a._id })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          totalItems: totalCount,
          itemsPerPage: parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('❌ [HELP-ARTICLES] Error fetching articles:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch articles',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/support/articles/:id
 * @desc    Get article by ID
 * @access  Public
 */
router.get('/articles/:id', async (req, res) => {
  try {
    const article = await HelpArticle.findById(req.params.id).lean();

    if (!article || article.status !== 'published') {
      return res.status(404).json({
        success: false,
        message: 'Article not found',
      });
    }

    // Increment view count
    await HelpArticle.findByIdAndUpdate(req.params.id, { $inc: { viewCount: 1 } });

    res.json({
      success: true,
      data: { ...article, id: article._id },
    });
  } catch (error) {
    console.error('❌ [HELP-ARTICLES] Error fetching article:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch article',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/support/articles/search
 * @desc    Search articles
 * @access  Public
 */
router.get('/articles/search', async (req, res) => {
  try {
    const { q, limit = 10 } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const articles = await HelpArticle.find(
      {
        $text: { $search: q },
        status: 'published',
      },
      {
        score: { $meta: 'textScore' },
      }
    )
      .sort({ score: { $meta: 'textScore' } })
      .limit(parseInt(limit))
      .lean();

    res.json({
      success: true,
      data: articles.map((a) => ({ ...a, id: a._id })),
    });
  } catch (error) {
    console.error('❌ [HELP-ARTICLES] Error searching articles:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search articles',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/support/articles/:id/helpful
 * @desc    Mark article as helpful or not
 * @access  Private
 */
router.post('/articles/:id/helpful', auth, async (req, res) => {
  try {
    const { isHelpful } = req.body;

    const updateField = isHelpful ? 'helpfulCount' : 'notHelpfulCount';
    const article = await HelpArticle.findByIdAndUpdate(
      req.params.id,
      { $inc: { [updateField]: 1 } },
      { new: true }
    );

    if (!article) {
      return res.status(404).json({
        success: false,
        message: 'Article not found',
      });
    }

    res.json({
      success: true,
      message: 'Feedback recorded',
      data: {
        helpfulCount: article.helpfulCount,
        notHelpfulCount: article.notHelpfulCount,
      },
    });
  } catch (error) {
    console.error('❌ [HELP-ARTICLES] Error recording feedback:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to record feedback',
      error: error.message,
    });
  }
});

// ============================================================================
// FAQ - USER ENDPOINTS
// ============================================================================

/**
 * @route   GET /api/support/faq
 * @desc    Get all published FAQs
 * @access  Public
 */
router.get('/faq', async (req, res) => {
  try {
    const { category } = req.query;

    const filter = { isPublished: true };
    if (category) {
      filter.category = category;
    }

    const faqs = await FAQ.find(filter).sort({ category: 1, order: 1 }).lean();

    res.json({
      success: true,
      data: faqs.map((f) => ({ ...f, id: f._id })),
    });
  } catch (error) {
    console.error('❌ [FAQ] Error fetching FAQs:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch FAQs',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/support/faq/:id/helpful
 * @desc    Mark FAQ as helpful or not
 * @access  Private
 */
router.post('/faq/:id/helpful', auth, async (req, res) => {
  try {
    const { isHelpful } = req.body;

    const updateField = isHelpful ? 'helpfulCount' : 'notHelpfulCount';
    const faq = await FAQ.findByIdAndUpdate(
      req.params.id,
      { $inc: { [updateField]: 1, viewCount: 1 } },
      { new: true }
    );

    if (!faq) {
      return res.status(404).json({
        success: false,
        message: 'FAQ not found',
      });
    }

    res.json({
      success: true,
      message: 'Feedback recorded',
      data: {
        helpfulCount: faq.helpfulCount,
        notHelpfulCount: faq.notHelpfulCount,
      },
    });
  } catch (error) {
    console.error('❌ [FAQ] Error recording feedback:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to record feedback',
      error: error.message,
    });
  }
});

// ============================================================================
// HELP ARTICLES - ADMIN ENDPOINTS
// ============================================================================

/**
 * @route   GET /api/admin/support/articles
 * @desc    Get all articles (including drafts)
 * @access  Private (Admin only)
 */
router.get('/admin/articles', adminAuth, async (req, res) => {
  try {
    const { status, category, page = 1, limit = 50 } = req.query;

    const filter = {};
    if (status) filter.status = status;
    if (category) filter.category = category;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [articles, totalCount] = await Promise.all([
      HelpArticle.find(filter).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)).lean(),
      HelpArticle.countDocuments(filter),
    ]);

    res.json({
      success: true,
      data: {
        articles: articles.map((a) => ({ ...a, id: a._id })),
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCount / parseInt(limit)),
          totalItems: totalCount,
        },
      },
    });
  } catch (error) {
    console.error('❌ [ADMIN-ARTICLES] Error fetching articles:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch articles',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/admin/support/articles
 * @desc    Create new article
 * @access  Private (Admin only)
 */
router.post('/admin/articles', adminAuth, async (req, res) => {
  try {
    const { title, content, category, tags, metaDescription, status } = req.body;

    if (!title || !content || !category) {
      return res.status(400).json({
        success: false,
        message: 'Title, content, and category are required',
      });
    }

    const article = new HelpArticle({
      title,
      content,
      category,
      tags: tags || [],
      metaDescription,
      status: status || 'draft',
      authorId: req.userId,
      authorName: req.userName || 'Admin',
    });

    await article.save();

    console.log(`✅ [ADMIN-ARTICLES] Article created: ${article.title}`);

    res.status(201).json({
      success: true,
      message: 'Article created successfully',
      data: { ...article.toObject(), id: article._id },
    });
  } catch (error) {
    console.error('❌ [ADMIN-ARTICLES] Error creating article:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create article',
      error: error.message,
    });
  }
});

/**
 * @route   PUT /api/admin/support/articles/:id
 * @desc    Update article
 * @access  Private (Admin only)
 */
router.put('/admin/articles/:id', adminAuth, async (req, res) => {
  try {
    const { title, content, category, tags, metaDescription, status } = req.body;

    const article = await HelpArticle.findById(req.params.id);

    if (!article) {
      return res.status(404).json({
        success: false,
        message: 'Article not found',
      });
    }

    // Update fields
    if (title) article.title = title;
    if (content) article.content = content;
    if (category) article.category = category;
    if (tags) article.tags = tags;
    if (metaDescription !== undefined) article.metaDescription = metaDescription;
    if (status) article.status = status;
    
    article.lastEditedBy = req.userId;
    article.lastEditedByName = req.userName || 'Admin';

    await article.save();

    console.log(`✅ [ADMIN-ARTICLES] Article updated: ${article.title}`);

    res.json({
      success: true,
      message: 'Article updated successfully',
      data: { ...article.toObject(), id: article._id },
    });
  } catch (error) {
    console.error('❌ [ADMIN-ARTICLES] Error updating article:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update article',
      error: error.message,
    });
  }
});

/**
 * @route   DELETE /api/admin/support/articles/:id
 * @desc    Delete article
 * @access  Private (Admin only)
 */
router.delete('/admin/articles/:id', adminAuth, async (req, res) => {
  try {
    const article = await HelpArticle.findByIdAndDelete(req.params.id);

    if (!article) {
      return res.status(404).json({
        success: false,
        message: 'Article not found',
      });
    }

    console.log(`✅ [ADMIN-ARTICLES] Article deleted: ${article.title}`);

    res.json({
      success: true,
      message: 'Article deleted successfully',
    });
  } catch (error) {
    console.error('❌ [ADMIN-ARTICLES] Error deleting article:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete article',
      error: error.message,
    });
  }
});

/**
 * @route   PATCH /api/admin/support/articles/:id/publish
 * @desc    Publish or unpublish article
 * @access  Private (Admin only)
 */
router.patch('/admin/articles/:id/publish', adminAuth, async (req, res) => {
  try {
    const { publish } = req.body; // true or false

    const article = await HelpArticle.findById(req.params.id);

    if (!article) {
      return res.status(404).json({
        success: false,
        message: 'Article not found',
      });
    }

    article.status = publish ? 'published' : 'draft';
    if (publish && !article.publishedAt) {
      article.publishedAt = new Date();
    }

    await article.save();

    console.log(`✅ [ADMIN-ARTICLES] Article ${publish ? 'published' : 'unpublished'}: ${article.title}`);

    res.json({
      success: true,
      message: `Article ${publish ? 'published' : 'unpublished'} successfully`,
      data: { ...article.toObject(), id: article._id },
    });
  } catch (error) {
    console.error('❌ [ADMIN-ARTICLES] Error publishing article:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to publish article',
      error: error.message,
    });
  }
});

// ============================================================================
// FAQ - ADMIN ENDPOINTS
// ============================================================================

/**
 * @route   GET /api/admin/support/faq
 * @desc    Get all FAQs (admin view)
 * @access  Private (Admin only)
 */
router.get('/admin/faq', adminAuth, async (req, res) => {
  try {
    const { category, isPublished } = req.query;

    const filter = {};
    if (category) filter.category = category;
    if (isPublished !== undefined) filter.isPublished = isPublished === 'true';

    const faqs = await FAQ.find(filter).sort({ category: 1, order: 1 }).lean();

    res.json({
      success: true,
      data: faqs.map((f) => ({ ...f, id: f._id })),
    });
  } catch (error) {
    console.error('❌ [ADMIN-FAQ] Error fetching FAQs:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch FAQs',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/admin/support/faq
 * @desc    Create new FAQ
 * @access  Private (Admin only)
 */
router.post('/admin/faq', adminAuth, async (req, res) => {
  try {
    const { question, answer, category, order, isPublished } = req.body;

    if (!question || !answer || !category) {
      return res.status(400).json({
        success: false,
        message: 'Question, answer, and category are required',
      });
    }

    const faq = new FAQ({
      question,
      answer,
      category,
      order: order || 0,
      isPublished: isPublished !== false,
      createdBy: req.userId,
      createdByName: req.userName || 'Admin',
    });

    await faq.save();

    console.log(`✅ [ADMIN-FAQ] FAQ created: ${question.substring(0, 50)}...`);

    res.status(201).json({
      success: true,
      message: 'FAQ created successfully',
      data: { ...faq.toObject(), id: faq._id },
    });
  } catch (error) {
    console.error('❌ [ADMIN-FAQ] Error creating FAQ:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create FAQ',
      error: error.message,
    });
  }
});

/**
 * @route   PUT /api/admin/support/faq/:id
 * @desc    Update FAQ
 * @access  Private (Admin only)
 */
router.put('/admin/faq/:id', adminAuth, async (req, res) => {
  try {
    const { question, answer, category, order, isPublished } = req.body;

    const faq = await FAQ.findById(req.params.id);

    if (!faq) {
      return res.status(404).json({
        success: false,
        message: 'FAQ not found',
      });
    }

    if (question) faq.question = question;
    if (answer) faq.answer = answer;
    if (category) faq.category = category;
    if (order !== undefined) faq.order = order;
    if (isPublished !== undefined) faq.isPublished = isPublished;
    
    faq.lastEditedBy = req.userId;
    faq.lastEditedByName = req.userName || 'Admin';

    await faq.save();

    console.log(`✅ [ADMIN-FAQ] FAQ updated: ${faq.question.substring(0, 50)}...`);

    res.json({
      success: true,
      message: 'FAQ updated successfully',
      data: { ...faq.toObject(), id: faq._id },
    });
  } catch (error) {
    console.error('❌ [ADMIN-FAQ] Error updating FAQ:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update FAQ',
      error: error.message,
    });
  }
});

/**
 * @route   DELETE /api/admin/support/faq/:id
 * @desc    Delete FAQ
 * @access  Private (Admin only)
 */
router.delete('/admin/faq/:id', adminAuth, async (req, res) => {
  try {
    const faq = await FAQ.findByIdAndDelete(req.params.id);

    if (!faq) {
      return res.status(404).json({
        success: false,
        message: 'FAQ not found',
      });
    }

    console.log(`✅ [ADMIN-FAQ] FAQ deleted: ${faq.question.substring(0, 50)}...`);

    res.json({
      success: true,
      message: 'FAQ deleted successfully',
    });
  } catch (error) {
    console.error('❌ [ADMIN-FAQ] Error deleting FAQ:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete FAQ',
      error: error.message,
    });
  }
});

/**
 * @route   PATCH /api/admin/support/faq/:id/reorder
 * @desc    Update FAQ display order
 * @access  Private (Admin only)
 */
router.patch('/admin/faq/:id/reorder', adminAuth, async (req, res) => {
  try {
    const { order } = req.body;

    if (order === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Order is required',
      });
    }

    const faq = await FAQ.findByIdAndUpdate(
      req.params.id,
      { order },
      { new: true }
    );

    if (!faq) {
      return res.status(404).json({
        success: false,
        message: 'FAQ not found',
      });
    }

    res.json({
      success: true,
      message: 'FAQ order updated',
      data: { id: faq._id, order: faq.order },
    });
  } catch (error) {
    console.error('❌ [ADMIN-FAQ] Error reordering FAQ:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reorder FAQ',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/support/categories
 * @desc    Get all categories
 * @access  Public
 */
router.get('/categories', (req, res) => {
  res.json({
    success: true,
    data: {
      articleCategories: [
        'Getting Started',
        'Account Management',
        'Calendar & Scheduling',
        'Consultations',
        'Payments & Earnings',
        'Live Streaming',
        'Technical Issues',
        'Best Practices',
        'Other',
      ],
      faqCategories: [
        'General',
        'Account & Profile',
        'Calendar & Availability',
        'Consultations',
        'Payments',
        'Live Streaming',
        'Technical',
        'Policies',
        'Other',
      ],
    },
  });
});

module.exports = router;
