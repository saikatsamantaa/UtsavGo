-- UtsavGo: profiles, event history, organizer attribution and follows
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'UtsavGo User',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.profiles (id, display_name)
select id,
       coalesce(nullif(raw_user_meta_data->>'display_name',''),
                nullif(split_part(email,'@',1),''),
                'UtsavGo User')
from auth.users
on conflict (id) do nothing;

create or replace function public.handle_new_utsavgo_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'display_name',''),
             nullif(split_part(new.email,'@',1),''),
             'UtsavGo User')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_utsavgo_user_created on auth.users;
create trigger on_utsavgo_user_created
after insert on auth.users
for each row execute procedure public.handle_new_utsavgo_user();

alter table public.profiles enable row level security;
drop policy if exists "Profiles are visible to everyone" on public.profiles;
create policy "Profiles are visible to everyone"
on public.profiles for select to anon, authenticated using (true);
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update to authenticated
using (auth.uid() = id) with check (auth.uid() = id);

alter table public.events
  add column if not exists rejection_reason text;

-- Link event creators to their public profile for organizer display.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'events_created_by_fkey'
      and conrelid = 'public.events'::regclass
  ) then
    alter table public.events
      add constraint events_created_by_fkey
      foreign key (created_by) references public.profiles(id)
      on delete set null not valid;
  end if;
end $$;

create table if not exists public.user_follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint user_follows_no_self check (follower_id <> following_id)
);

alter table public.user_follows enable row level security;
drop policy if exists "Follow relationships are visible" on public.user_follows;
create policy "Follow relationships are visible"
on public.user_follows for select to authenticated using (true);
drop policy if exists "Users can follow as themselves" on public.user_follows;
create policy "Users can follow as themselves"
on public.user_follows for insert to authenticated
with check (auth.uid() = follower_id);
drop policy if exists "Users can unfollow as themselves" on public.user_follows;
create policy "Users can unfollow as themselves"
on public.user_follows for delete to authenticated
using (auth.uid() = follower_id);

-- Users can see only their own pending/rejected events in addition to public approved events.
drop policy if exists "Users can view own events" on public.events;
create policy "Users can view own events"
on public.events for select to authenticated
using (created_by = auth.uid());
