-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ─────────────────────────────────────────────
-- Clipboards table
-- ─────────────────────────────────────────────
create table public.clipboards (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  content_type  text not null check (content_type in ('text', 'html', 'image')),
  text_content  text,
  storage_path  text,
  copied_at     timestamptz not null default now(),
  device_id     text not null
);

-- ─────────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────────
alter table public.clipboards enable row level security;

create policy "Users can read their own clipboard items"
  on public.clipboards for select
  using (auth.uid() = user_id);

create policy "Users can insert their own clipboard items"
  on public.clipboards for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own clipboard items"
  on public.clipboards for delete
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- Enable Realtime on this table
-- ─────────────────────────────────────────────
alter publication supabase_realtime add table public.clipboards;

-- ─────────────────────────────────────────────
-- Index for faster history queries
-- ─────────────────────────────────────────────
create index idx_clipboards_user_copied
  on public.clipboards(user_id, copied_at desc);
