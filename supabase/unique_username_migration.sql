-- UtsavGo unique username migration
-- Run this entire file once in Supabase SQL Editor.

alter table public.profiles
  add column if not exists username text;

-- Usernames are stored lowercase and compared case-insensitively.
update public.profiles
set username = lower(regexp_replace(coalesce(username, ''), '^@', ''))
where username is not null;

create unique index if not exists profiles_username_unique_lower
  on public.profiles (lower(username))
  where username is not null and btrim(username) <> '';

alter table public.profiles
  drop constraint if exists profiles_username_format;

alter table public.profiles
  add constraint profiles_username_format
  check (
    username is null
    or username ~ '^[a-z0-9_]{3,20}$'
  );

-- Public profiles are visible when users tap an event organizer.
alter table public.profiles enable row level security;

drop policy if exists "Profiles are publicly viewable" on public.profiles;
create policy "Profiles are publicly viewable"
  on public.profiles
  for select
  to anon, authenticated
  using (true);

-- Users can create/update only their own profile row.
drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles
  for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);
