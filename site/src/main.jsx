import React, { useState, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import {
  ArrowRight,
  Bell,
  BookOpenText,
  ChevronDown,
  Download,
  HeartHandshake,
  Highlighter,
  Menu,
  MessageCircle,
  Search,
  Shield,
  UsersRound,
  WifiOff,
  X,
} from 'lucide-react';
import './styles.css';

const updatedDate = 'June 18, 2026';
const apiBaseUrl = 'https://server-pi-five-58.vercel.app';
const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.family_bible';
const testerOptInUrl = 'https://play.google.com/apps/testing/com.family_bible';

function App() {
  const path = window.location.pathname;

  if (path === '/privacy') {
    return <PrivacyPolicy />;
  }

  if (path === '/delete-account') {
    return <DeleteAccountPage />;
  }

  return <Home />;
}

function Header() {
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    if (mobileOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [mobileOpen]);

  return (
    <header className="site-header">
      <a className="brand" href="/" aria-label="Family Bible home">
        <img
          src="/brand/family-bible-mark-gold.png"
          alt=""
          className="brand-mark"
        />
        <span className="brand-name">Family Bible</span>
      </a>
      <nav className={mobileOpen ? 'open' : ''} aria-label="Main navigation">
        <a href="/#features" onClick={() => setMobileOpen(false)}>Features</a>
        <a href="/#family" onClick={() => setMobileOpen(false)}>Family</a>
        <a href="/privacy" onClick={() => setMobileOpen(false)}>Privacy</a>
        <a className="nav-cta" href={testerOptInUrl} onClick={() => setMobileOpen(false)}>
          <Download size={15} />
          Get the app
        </a>
      </nav>
      <button
        className="mobile-toggle"
        onClick={() => setMobileOpen(!mobileOpen)}
        aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
      >
        {mobileOpen ? <X size={22} /> : <Menu size={22} />}
      </button>
      {mobileOpen && <div className="mobile-backdrop" onClick={() => setMobileOpen(false)} />}
    </header>
  );
}

function Home() {
  return (
    <main>
      <Header />

      <section className="hero">
        <div className="hero-copy">
          <h1>Scripture for the whole family.</h1>
          <p className="lede">
            Read the Bible together, keep meaningful notes, share highlights,
            and help your family stay rooted in the Word.
          </p>
          <div className="hero-actions" id="download">
            <a className="button primary" href={playStoreUrl}>
              <Download size={18} />
              Download for Android
            </a>
            <a className="button secondary" href={testerOptInUrl}>
              <Download size={18} />
              Join the test
            </a>
          </div>
          <div className="trust-row" aria-label="Key features">
            <span>7 translations</span>
            <span>Offline reading</span>
            <span>Family sharing</span>
            <span>No ads</span>
          </div>
        </div>
        <div className="hero-visual">
          <div className="phone-frame">
            <div className="phone-notch" />
            <div className="phone-screen">
              <div className="phone-status">
                <span>9:41</span>
              </div>
              <div className="phone-header">
                <div>
                  <span className="phone-label">Verse of the Day</span>
                  <h2>John 1</h2>
                </div>
                <BookOpenText size={20} />
              </div>
              <div className="verse-card">
                <span className="phone-label">The Word Became Flesh</span>
                <p>
                  In the beginning was the Word, and the Word was with God, and
                  the Word was God.
                </p>
                <div className="verse-pills">
                  <span>Highlight</span>
                  <span>Note</span>
                  <span>Share</span>
                </div>
              </div>
              <div className="family-pill">
                <UsersRound size={18} />
                <div>
                  <strong>Family reading</strong>
                  <span>3 members active today</span>
                </div>
              </div>
              <div className="phone-tab-bar">
                <BookOpenText size={17} />
                <Highlighter size={17} />
                <Search size={17} />
                <UsersRound size={17} />
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="stats-band">
        <div className="stat">
          <strong>7</strong>
          <span>Bible translations</span>
        </div>
        <div className="stat">
          <strong>100%</strong>
          <span>Offline capable</span>
        </div>
        <div className="stat">
          <strong>0</strong>
          <span>Ads, ever</span>
        </div>
      </section>

      <section className="features-section" id="features">
        <div className="section-header">
          <span className="tag">Features</span>
          <h2>Everything your family needs. Nothing it doesn't.</h2>
        </div>
        <div className="features-grid">
          <Feature
            icon={<BookOpenText />}
            title="Beautiful reading"
            body="Distraction-free scripture with carefully chosen serif typography designed for long reading sessions."
          />
          <Feature
            icon={<Search />}
            title="Instant search"
            body="Find any verse across all 7 translations. Results are grouped by book with highlighted matches."
          />
          <Feature
            icon={<HeartHandshake />}
            title="Family sharing"
            body="Create a family space where members share notes, see reading activity, and encourage each other."
          />
          <Feature
            icon={<Highlighter />}
            title="Notes & highlights"
            body="Capture reflections and mark important verses. Your annotations sync across your family group."
          />
          <Feature
            icon={<WifiOff />}
            title="Fully offline"
            body="Every translation is stored on your device. Read anywhere — no internet connection needed."
          />
          <Feature
            icon={<Shield />}
            title="Privacy first"
            body="No ads, no tracking, no account required for solo reading. Your reading life is yours."
          />
        </div>
      </section>

      <section className="family-section" id="family">
        <div className="family-content">
          <span className="tag">Family</span>
          <h2>Read as one household.</h2>
          <p>
            Family Bible gives every member a place to reflect, respond, and
            notice when someone needs encouragement. Built for quiet daily use,
            not noise.
          </p>
        </div>
        <div className="family-cards">
          <div className="family-hero-card">
            <img src="/brand/family-bible-icon.png" alt="" />
            <div>
              <strong>Family Bible</strong>
              <span>Warm, calm, built for daily reading.</span>
            </div>
          </div>
          <FamilyStep
            icon={<Bell />}
            title="Check in"
            body="See who's been reading and gently encourage members who've been away."
          />
          <FamilyStep
            icon={<Highlighter />}
            title="Reflect"
            body="Save highlights and notes around the verses that matter to your family."
          />
          <FamilyStep
            icon={<MessageCircle />}
            title="Discuss"
            body="Comment on shared notes and keep faith conversations going."
          />
        </div>
      </section>

      <section className="cta-section">
        <div className="cta-inner">
          <h2>Start reading together.</h2>
          <p>Download Family Bible free on Android, or join the testing track.</p>
          <div className="hero-actions">
            <a className="button primary inverted" href={testerOptInUrl}>
              <Download size={18} />
              Join testing
            </a>
            <a className="button secondary inverted" href={playStoreUrl}>
              View Play Store
            </a>
          </div>
        </div>
      </section>

      <footer>
        <div className="footer-inner">
          <div className="footer-brand">
            <img src="/brand/family-bible-mark-gold.png" alt="" />
            <span>Family Bible</span>
          </div>
          <div className="footer-links">
            <a href="/privacy">Privacy</a>
            <a href="/delete-account">Delete account</a>
            <a href="mailto:seunpaul003@gmail.com">Contact</a>
          </div>
          <p className="footer-copy">&copy; 2026 Family Bible. All rights reserved.</p>
        </div>
      </footer>
    </main>
  );
}

function Feature({ icon, title, body }) {
  return (
    <article className="feature-card">
      <span className="feature-icon">{icon}</span>
      <h3>{title}</h3>
      <p>{body}</p>
    </article>
  );
}

function FamilyStep({ icon, title, body }) {
  return (
    <article className="family-step">
      <span className="step-icon">{icon}</span>
      <div>
        <h3>{title}</h3>
        <p>{body}</p>
      </div>
    </article>
  );
}

function PrivacyPolicy() {
  return (
    <main>
      <Header />
      <article className="policy">
        <a className="back-link" href="/">
          <ArrowRight size={14} style={{ transform: 'rotate(180deg)' }} />
          Back to home
        </a>
        <h1>Privacy Policy</h1>
        <p className="updated">Last updated: {updatedDate}</p>

        <section>
          <h2>Overview</h2>
          <p>
            Family Bible is a scripture reading app that helps users read the Bible,
            create notes and highlights, and share family reading activity with
            members they choose to join.
          </p>
        </section>

        <section>
          <h2>Information We Collect</h2>
          <p>
            We may collect account details such as name, email address, and
            password credentials when you create or sign into an account. We may
            also store Bible notes, highlights, comments, family groups, invite
            codes, reading activity, settings, and device notification
            registration data.
          </p>
        </section>

        <section>
          <h2>How We Use Information</h2>
          <p>
            We use information to provide app features, sync notes, support
            family sharing, show reading progress, manage accounts, improve app
            reliability, and send reminders or notifications when enabled.
          </p>
        </section>

        <section>
          <h2>Family Sharing</h2>
          <p>
            If you join or create a family group, notes, comments, and reading
            activity intended for family sharing may be visible to other members
            of that family group. Do not add private information to shared notes
            unless you want family members to see it.
          </p>
        </section>

        <section>
          <h2>Third-Party Services</h2>
          <p>
            Family Bible may use hosting, database, authentication,
            notification, analytics, or app-store services to operate the app.
            These providers process data only as needed to provide their
            services.
          </p>
        </section>

        <section>
          <h2>Data Retention and Deletion</h2>
          <p>
            We keep account and app data for as long as needed to provide the
            app or comply with legal obligations. You may request deletion of
            your account or selected app data using the Family Bible deletion
            request page.
          </p>
          <p>
            <a className="inline-link" href="/delete-account">
              Request account or data deletion &rarr;
            </a>
          </p>
        </section>

        <section>
          <h2>Children</h2>
          <p>
            Family Bible is intended for family use, but children should use the
            app with permission and guidance from a parent or guardian. We do
            not knowingly collect personal information from children without
            appropriate consent.
          </p>
        </section>

        <section>
          <h2>Security</h2>
          <p>
            We use reasonable technical and organizational safeguards to protect
            app data. No method of transmission or storage is completely secure,
            so we cannot guarantee absolute security.
          </p>
        </section>

        <section>
          <h2>Changes</h2>
          <p>
            We may update this policy as Family Bible changes. The updated date
            above will reflect the latest version.
          </p>
        </section>

        <section>
          <h2>Contact</h2>
          <p>
            For privacy questions or deletion requests, email us at{' '}
            <a className="inline-link" href="mailto:seunpaul003@gmail.com">
              seunpaul003@gmail.com
            </a>.
          </p>
        </section>
      </article>
    </main>
  );
}

function DeleteAccountPage() {
  const [requestType, setRequestType] = useState('account');
  const [form, setForm] = useState({
    name: '',
    email: '',
    reason: '',
    dataTypes: ['notes', 'highlights', 'comments', 'reading_activity', 'devices'],
  });
  const [status, setStatus] = useState({ type: 'idle', message: '' });

  const dataOptions = [
    ['notes', 'Notes'],
    ['highlights', 'Highlights'],
    ['comments', 'Comments'],
    ['reading_activity', 'Reading activity'],
    ['devices', 'Device notification data'],
  ];

  function updateField(event) {
    const { name, value } = event.target;
    setForm((current) => ({ ...current, [name]: value }));
  }

  function toggleDataType(value) {
    setForm((current) => {
      const exists = current.dataTypes.includes(value);
      return {
        ...current,
        dataTypes: exists
          ? current.dataTypes.filter((item) => item !== value)
          : [...current.dataTypes, value],
      };
    });
  }

  async function submitRequest(event) {
    event.preventDefault();
    setStatus({ type: 'loading', message: 'Sending request...' });

    const endpoint =
      requestType === 'account'
        ? '/api/account-deletion-requests'
        : '/api/data-deletion-requests';

    try {
      const response = await fetch(`${apiBaseUrl}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: form.name,
          email: form.email,
          reason: form.reason,
          requestType,
          dataTypes: requestType === 'data' ? form.dataTypes : [],
        }),
      });
      const payload = await response.json();

      if (!response.ok) {
        throw new Error(payload.error || 'Unable to submit request');
      }

      setStatus({
        type: 'success',
        message:
          requestType === 'account'
            ? 'Your account deletion request was received. We\'ll process it within 30 days.'
            : 'Your data deletion request was received. We\'ll process it within 30 days.',
      });
      setForm((current) => ({ ...current, reason: '' }));
    } catch (error) {
      setStatus({
        type: 'error',
        message: error.message || 'Unable to submit request',
      });
    }
  }

  return (
    <main>
      <Header />
      <article className="policy">
        <a className="back-link" href="/">
          <ArrowRight size={14} style={{ transform: 'rotate(180deg)' }} />
          Back to home
        </a>
        <h1>Delete Account or Data</h1>
        <p className="updated">
          Use this form to request deletion of your Family Bible account or
          selected app data.
        </p>

        <form className="delete-form" onSubmit={submitRequest}>
          <fieldset>
            <legend>What do you want deleted?</legend>
            <label className="radio-row">
              <input
                type="radio"
                name="requestType"
                value="account"
                checked={requestType === 'account'}
                onChange={() => setRequestType('account')}
              />
              <span>Delete my account and all associated data</span>
            </label>
            <label className="radio-row">
              <input
                type="radio"
                name="requestType"
                value="data"
                checked={requestType === 'data'}
                onChange={() => setRequestType('data')}
              />
              <span>Delete selected data only</span>
            </label>
          </fieldset>

          {requestType === 'data' && (
            <fieldset>
              <legend>Select data to delete</legend>
              <div className="check-grid">
                {dataOptions.map(([value, label]) => (
                  <label className="check-row" key={value}>
                    <input
                      type="checkbox"
                      checked={form.dataTypes.includes(value)}
                      onChange={() => toggleDataType(value)}
                    />
                    <span>{label}</span>
                  </label>
                ))}
              </div>
            </fieldset>
          )}

          <label>
            Name
            <input
              name="name"
              value={form.name}
              onChange={updateField}
              placeholder="Your name"
            />
          </label>

          <label>
            Account email
            <input
              name="email"
              type="email"
              value={form.email}
              onChange={updateField}
              placeholder="you@example.com"
              required
            />
          </label>

          <label>
            Reason (optional)
            <textarea
              name="reason"
              value={form.reason}
              onChange={updateField}
              placeholder="Tell us anything we should know about this request."
              rows="4"
            />
          </label>

          <button
            className="button primary"
            type="submit"
            disabled={status.type === 'loading'}
          >
            {status.type === 'loading' ? 'Sending...' : 'Submit request'}
          </button>

          {status.message && (
            <p className={`form-status ${status.type}`}>{status.message}</p>
          )}
        </form>
      </article>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<App />);
