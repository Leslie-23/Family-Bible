import 'dotenv/config';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';
import { customAlphabet } from 'nanoid';

const app = express();
const inviteCode = customAlphabet('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 8);
const env = (key) => process.env[key]?.trim();

app.use(express.json({ limit: '1mb' }));
app.use(
  cors({
    origin(origin, callback) {
      const configured = env('APP_ORIGIN');
      if (!origin || !configured || configured === '*') {
        return callback(null, true);
      }
      const allowed = (configured || '')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean);
      return callback(null, allowed.includes(origin));
    },
    credentials: true,
  }),
);

let connectionPromise;

function connect() {
  const mongoUri = env('MONGODB_URI');
  if (!mongoUri) {
    throw new Error('MONGODB_URI is required');
  }

  if (!connectionPromise) {
    connectionPromise = mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 10000,
    });
  }

  return connectionPromise;
}

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    passwordHash: { type: String, required: true },
    brandingName: { type: String, default: 'Leslie-23' },
    lastReadAt: Date,
    lastReadVerse: {
      versionTitle: String,
      book: String,
      chapter: Number,
      verse: Number,
    },
  },
  { timestamps: true },
);

const familySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    inviteCode: { type: String, required: true, unique: true },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    members: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
          required: true,
        },
        role: {
          type: String,
          enum: ['owner', 'member'],
          default: 'member',
        },
        joinedAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true },
);

const noteSchema = new mongoose.Schema(
  {
    familyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Family',
      required: true,
      index: true,
    },
    authorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    verseKey: { type: String, required: true, index: true },
    versionTitle: { type: String, required: true },
    book: { type: String, required: true },
    chapter: { type: Number, required: true },
    verse: { type: Number, required: true },
    verseText: { type: String, default: '' },
    note: { type: String, default: '' },
    highlightColor: { type: String, default: 'none' },
    visibility: {
      type: String,
      enum: ['family', 'private'],
      default: 'family',
    },
  },
  { timestamps: true },
);

const commentSchema = new mongoose.Schema(
  {
    noteId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Note',
      required: true,
      index: true,
    },
    familyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Family',
      required: true,
      index: true,
    },
    authorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    body: { type: String, required: true, trim: true },
  },
  { timestamps: true },
);

const activitySchema = new mongoose.Schema(
  {
    familyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Family',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    event: {
      type: String,
      enum: ['read', 'note', 'comment', 'highlight'],
      required: true,
    },
    verseKey: String,
    metadata: mongoose.Schema.Types.Mixed,
  },
  { timestamps: true },
);

const deviceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    platform: { type: String, enum: ['android', 'ios', 'web'], required: true },
    pushToken: { type: String, required: true },
    lastSeenAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

const deletionRequestSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, lowercase: true, trim: true },
    name: { type: String, trim: true },
    reason: { type: String, trim: true },
    requestType: {
      type: String,
      enum: ['account', 'data'],
      default: 'account',
    },
    dataTypes: [
      {
        type: String,
        enum: ['notes', 'highlights', 'comments', 'reading_activity', 'devices'],
      },
    ],
    status: {
      type: String,
      enum: ['requested', 'completed', 'rejected'],
      default: 'requested',
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    requestedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

noteSchema.index({ familyId: 1, verseKey: 1, authorId: 1 }, { unique: true });
activitySchema.index({ familyId: 1, userId: 1, createdAt: -1 });
deviceSchema.index({ userId: 1, pushToken: 1 }, { unique: true });
deletionRequestSchema.index({ email: 1, status: 1 });

const User = mongoose.models.User || mongoose.model('User', userSchema);
const Family =
  mongoose.models.Family || mongoose.model('Family', familySchema);
const Note = mongoose.models.Note || mongoose.model('Note', noteSchema);
const Comment =
  mongoose.models.Comment || mongoose.model('Comment', commentSchema);
const Activity =
  mongoose.models.Activity || mongoose.model('Activity', activitySchema);
const Device =
  mongoose.models.Device || mongoose.model('Device', deviceSchema);
const DeletionRequest =
  mongoose.models.DeletionRequest ||
  mongoose.model('DeletionRequest', deletionRequestSchema);

function tokenFor(user) {
  const jwtSecret = env('JWT_SECRET');
  if (!jwtSecret) {
    throw new Error('JWT_SECRET is required');
  }

  return jwt.sign(
    {
      sub: user._id.toString(),
      email: user.email,
      name: user.name,
    },
    jwtSecret,
    { expiresIn: '30d' },
  );
}

async function requireAuth(req, res, next) {
  try {
    await connect();
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return res.status(401).json({ error: 'Missing auth token' });
    }

    const payload = jwt.verify(token, env('JWT_SECRET'));
    const user = await User.findById(payload.sub).select('-passwordHash');
    if (!user) return res.status(401).json({ error: 'Invalid auth token' });

    req.user = user;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid auth token' });
  }
}

async function requireFamily(req, res, next) {
  const family = await Family.findOne({
    _id: req.params.familyId,
    'members.userId': req.user._id,
  });

  if (!family) {
    return res.status(404).json({ error: 'Family not found' });
  }

  req.family = family;
  next();
}

function publicUser(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    brandingName: user.brandingName,
    lastReadAt: user.lastReadAt,
    lastReadVerse: user.lastReadVerse,
  };
}

async function deleteAccountData(userId) {
  const id = userId.toString();
  const userObjectId = new mongoose.Types.ObjectId(id);
  const authoredNotes = await Note.find({ authorId: userObjectId })
    .select('_id familyId')
    .lean();
  const noteIds = authoredNotes.map((note) => note._id);

  await Comment.deleteMany({
    $or: [{ authorId: userObjectId }, { noteId: { $in: noteIds } }],
  });
  await Note.deleteMany({ authorId: userObjectId });
  await Activity.deleteMany({ userId: userObjectId });
  await Device.deleteMany({ userId: userObjectId });

  const families = await Family.find({ 'members.userId': userObjectId });
  for (const family of families) {
    family.members = family.members.filter(
      (member) => member.userId.toString() !== id,
    );

    if (family.members.length === 0) {
      await Comment.deleteMany({ familyId: family._id });
      await Note.deleteMany({ familyId: family._id });
      await Activity.deleteMany({ familyId: family._id });
      await Family.deleteOne({ _id: family._id });
      continue;
    }

    if (family.ownerId.toString() === id) {
      family.ownerId = family.members[0].userId;
      family.members[0].role = 'owner';
    }

    await family.save();
  }

  await User.deleteOne({ _id: userObjectId });
}

app.get('/', (req, res) => {
  res.json({
    ok: true,
    app: 'Family Bible API',
    brand: 'Leslie-23',
    message: 'Family Bible backend is reachable.',
    health: '/api/health',
  });
});

app.get('/api/health', async (req, res) => {
  let database = 'not_configured';

  try {
    await connect();
    database =
      mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
  } catch (error) {
    database = 'unavailable';
  }

  res.json({
    ok: true,
    app: 'Family Bible',
    brand: 'Leslie-23',
    database,
    time: new Date().toISOString(),
  });
});

app.post('/api/auth/register', async (req, res) => {
  await connect();
  const { name, email, password } = req.body;

  if (!name || !email || !password || password.length < 8) {
    return res.status(400).json({
      error: 'Name, email, and an 8+ character password are required',
    });
  }

  const existing = await User.findOne({ email: email.toLowerCase() });
  if (existing) return res.status(409).json({ error: 'Email already exists' });

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await User.create({
    name,
    email,
    passwordHash,
    brandingName: 'Leslie-23',
  });

  res.status(201).json({
    token: tokenFor(user),
    user: publicUser(user),
  });
});

app.post('/api/auth/login', async (req, res) => {
  await connect();
  const { email, password } = req.body;
  const user = await User.findOne({ email: String(email).toLowerCase() });

  if (!user || !(await bcrypt.compare(password || '', user.passwordHash))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  res.json({
    token: tokenFor(user),
    user: publicUser(user),
  });
});

app.get('/api/me', requireAuth, (req, res) => {
  res.json({ user: publicUser(req.user) });
});

app.delete('/api/me', requireAuth, async (req, res) => {
  await deleteAccountData(req.user._id);
  res.json({ ok: true, message: 'Account and associated data deleted' });
});

async function createDeletionRequest(req, res, fallbackType = 'account') {
  await connect();
  const email = String(req.body.email || '').trim().toLowerCase();
  const name = String(req.body.name || '').trim();
  const reason = String(req.body.reason || '').trim();
  const requestType =
    req.body.requestType === 'data' || fallbackType === 'data'
      ? 'data'
      : 'account';
  const allowedDataTypes = new Set([
    'notes',
    'highlights',
    'comments',
    'reading_activity',
    'devices',
  ]);
  const dataTypes = Array.isArray(req.body.dataTypes)
    ? req.body.dataTypes.filter((type) => allowedDataTypes.has(type))
    : [];

  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'A valid email is required' });
  }

  const user = await User.findOne({ email }).select('_id name email').lean();
  const request = await DeletionRequest.findOneAndUpdate(
    { email, requestType, status: 'requested' },
    {
      email,
      name: name || user?.name || '',
      reason,
      requestType,
      dataTypes,
      userId: user?._id,
      requestedAt: new Date(),
      status: 'requested',
    },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );

  res.status(202).json({
    ok: true,
    requestId: request._id,
    message:
      requestType === 'account'
        ? 'Account deletion request received. We will process associated account data for this email.'
        : 'Data deletion request received. We will process the requested data for this email.',
  });
}

app.post('/api/account-deletion-requests', async (req, res) => {
  return createDeletionRequest(req, res, 'account');
});

app.post('/api/data-deletion-requests', async (req, res) => {
  return createDeletionRequest(req, res, 'data');
});

app.post('/api/families', requireAuth, async (req, res) => {
  const name = req.body.name || 'My Family';
  const family = await Family.create({
    name,
    inviteCode: inviteCode(),
    ownerId: req.user._id,
    members: [{ userId: req.user._id, role: 'owner' }],
  });

  res.status(201).json({ family });
});

app.post('/api/families/join', requireAuth, async (req, res) => {
  const code = String(req.body.inviteCode || '').trim().toUpperCase();
  const family = await Family.findOne({ inviteCode: code });
  if (!family) return res.status(404).json({ error: 'Invite not found' });

  const alreadyMember = family.members.some(
    (member) => member.userId.toString() === req.user._id.toString(),
  );

  if (!alreadyMember) {
    family.members.push({ userId: req.user._id, role: 'member' });
    await family.save();
  }

  res.json({ family });
});

app.get('/api/families', requireAuth, async (req, res) => {
  const families = await Family.find({ 'members.userId': req.user._id }).lean();
  res.json({ families });
});

app.get(
  '/api/families/:familyId',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const family = await req.family.populate('members.userId', '-passwordHash');
    res.json({ family });
  },
);

app.get(
  '/api/families/:familyId/notes',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const notes = await Note.find({
      familyId: req.family._id,
      visibility: 'family',
    })
      .sort({ updatedAt: -1 })
      .populate('authorId', 'name email brandingName')
      .lean();

    res.json({ notes });
  },
);

app.post(
  '/api/families/:familyId/notes',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const {
      verseKey,
      versionTitle,
      book,
      chapter,
      verse,
      verseText,
      note,
      highlightColor,
      visibility,
    } = req.body;

    if (!verseKey || !versionTitle || !book || !chapter || !verse) {
      return res.status(400).json({ error: 'Verse details are required' });
    }

    const saved = await Note.findOneAndUpdate(
      {
        familyId: req.family._id,
        authorId: req.user._id,
        verseKey,
      },
      {
        familyId: req.family._id,
        authorId: req.user._id,
        verseKey,
        versionTitle,
        book,
        chapter,
        verse,
        verseText,
        note: note || '',
        highlightColor: highlightColor || 'none',
        visibility: visibility || 'family',
      },
      { new: true, upsert: true, setDefaultsOnInsert: true },
    );

    await Activity.create({
      familyId: req.family._id,
      userId: req.user._id,
      event: note ? 'note' : 'highlight',
      verseKey,
    });

    res.status(201).json({ note: saved });
  },
);

app.post(
  '/api/families/:familyId/notes/:noteId/comments',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const note = await Note.findOne({
      _id: req.params.noteId,
      familyId: req.family._id,
    });

    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (!req.body.body) {
      return res.status(400).json({ error: 'Comment body is required' });
    }

    const comment = await Comment.create({
      noteId: note._id,
      familyId: req.family._id,
      authorId: req.user._id,
      body: req.body.body,
    });

    await Activity.create({
      familyId: req.family._id,
      userId: req.user._id,
      event: 'comment',
      verseKey: note.verseKey,
    });

    res.status(201).json({ comment });
  },
);

app.get(
  '/api/families/:familyId/notes/:noteId/comments',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const comments = await Comment.find({
      familyId: req.family._id,
      noteId: req.params.noteId,
    })
      .sort({ createdAt: 1 })
      .populate('authorId', 'name email brandingName')
      .lean();

    res.json({ comments });
  },
);

app.post(
  '/api/families/:familyId/activity/read',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const { verseKey, versionTitle, book, chapter, verse } = req.body;

    await User.updateOne(
      { _id: req.user._id },
      {
        lastReadAt: new Date(),
        lastReadVerse: { versionTitle, book, chapter, verse },
      },
    );

    await Activity.create({
      familyId: req.family._id,
      userId: req.user._id,
      event: 'read',
      verseKey,
      metadata: { versionTitle, book, chapter, verse },
    });

    res.json({ ok: true });
  },
);

app.get(
  '/api/families/:familyId/activity',
  requireAuth,
  requireFamily,
  async (req, res) => {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const activity = await Activity.find({
      familyId: req.family._id,
      createdAt: { $gte: since },
    })
      .sort({ createdAt: -1 })
      .populate('userId', 'name email brandingName lastReadAt lastReadVerse')
      .lean();

    res.json({ activity });
  },
);

app.post('/api/devices', requireAuth, async (req, res) => {
  const { platform, pushToken } = req.body;

  if (!platform || !pushToken) {
    return res.status(400).json({ error: 'Platform and push token required' });
  }

  const device = await Device.findOneAndUpdate(
    { userId: req.user._id, pushToken },
    {
      userId: req.user._id,
      platform,
      pushToken,
      lastSeenAt: new Date(),
    },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );

  res.status(201).json({ device });
});

app.get('/api/cron/daily-checkins', async (req, res) => {
  if (
    env('CRON_SECRET') &&
    req.headers.authorization !== `Bearer ${env('CRON_SECRET')}` &&
    req.headers['user-agent'] !== 'vercel-cron/1.0'
  ) {
    return res.status(401).json({ error: 'Unauthorized cron request' });
  }

  await connect();
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const inactiveUsers = await User.find({
    $or: [{ lastReadAt: { $lt: since } }, { lastReadAt: { $exists: false } }],
  })
    .select('name email lastReadAt')
    .lean();

  // Next step: send FCM/APNs push notifications to family members here.
  res.json({
    ok: true,
    inactiveCount: inactiveUsers.length,
    inactiveUsers,
  });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Server error' });
});

export default app;

if (process.env.NODE_ENV !== 'production' && process.argv[1]?.endsWith('index.js')) {
  const port = process.env.PORT || 3001;
  app.listen(port, () => {
    console.log(`Family Bible API running on http://localhost:${port}`);
  });
}
