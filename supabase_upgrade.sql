-- MY JOURNEYS V2 upgrade
-- Run once in Supabase SQL Editor AFTER the first database setup.

-- Private file bucket (20 MB per file; images and PDF accepted)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'trip-files',
  'trip-files',
  false,
  20971520,
  array['image/jpeg','image/png','image/webp','image/gif','application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 20971520,
  allowed_mime_types = excluded.allowed_mime_types;

-- Members can view files belonging to trips they joined.
create policy "Trip members can read trip files"
on storage.objects
for select to authenticated
using (
  bucket_id = 'trip-files'
  and public.is_trip_member(((storage.foldername(name))[1])::uuid)
);

-- Only trip owners/editors can upload files.
create policy "Trip editors can upload trip files"
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'trip-files'
  and public.has_trip_role(((storage.foldername(name))[1])::uuid, array['owner','editor'])
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

create policy "Trip editors can delete trip files"
on storage.objects
for delete to authenticated
using (
  bucket_id = 'trip-files'
  and public.has_trip_role(((storage.foldername(name))[1])::uuid, array['owner','editor'])
);

-- Accept an invitation using the raw token from the invite URL.
-- Only the SHA-256 hash is stored in trip_invites.
create or replace function public.accept_trip_invite(p_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_invite public.trip_invites%rowtype;
  v_email text;
begin
  if (select auth.uid()) is null then
    raise exception '請先登入後再接受邀請';
  end if;

  v_email := lower(coalesce((select auth.jwt())->>'email', ''));

  select * into v_invite
  from public.trip_invites i
  where i.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
    and i.accepted_at is null
    and i.expires_at > now()
  limit 1;

  if not found then
    raise exception '邀請連結無效、已使用或已過期';
  end if;

  if v_invite.email is not null and lower(v_invite.email) <> v_email then
    raise exception '此邀請指定給另一個 Email，請使用受邀帳號登入';
  end if;

  insert into public.trip_members (trip_id, user_id, role)
  values (v_invite.trip_id, (select auth.uid()), v_invite.role)
  on conflict (trip_id, user_id) do nothing;

  update public.trip_invites
  set accepted_at = now()
  where id = v_invite.id;

  return v_invite.trip_id;
end;
$$;

revoke all on function public.accept_trip_invite(text) from public;
grant execute on function public.accept_trip_invite(text) to authenticated;
