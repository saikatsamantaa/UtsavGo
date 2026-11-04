-- UtsavGo: allow users to edit and delete only their own event posts
alter table public.events enable row level security;

drop policy if exists "Users can update own events" on public.events;
create policy "Users can update own events"
on public.events for update to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists "Users can delete own events" on public.events;
create policy "Users can delete own events"
on public.events for delete to authenticated
using (created_by = auth.uid());
