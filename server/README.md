# Family Bible API

Small Vercel-ready backend for Family Bible.

## What It Handles

- Email/password auth
- Family creation and invite-code joining
- Shared notes on verses
- Comments on family notes
- Reading activity tracking
- Device push-token registration for future remote notifications
- Cron endpoint for daily family check-in jobs

## Local Setup

```powershell
cd server
npm install
copy .env.example .env
npm run dev
```

Set `MONGODB_URI`, `JWT_SECRET`, and `CRON_SECRET` before deploy.

## Deploy On Vercel

Use `server/` as the Vercel project root. Required environment variables:

- `MONGODB_URI`
- `JWT_SECRET`
- `CRON_SECRET`
- `APP_ORIGIN`

## Realtime Notes

This API is HTTP-first. For production realtime comments/presence, add a hosted realtime service such as Ably, Pusher, Supabase Realtime, or Firebase. Vercel cron is suitable for scheduled check-in work, but long-lived socket servers are not the right fit for normal Vercel serverless functions.
