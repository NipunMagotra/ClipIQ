-- Create storage bucket if not exists
insert into storage.buckets (id, name, public)
values ('clipboards', 'clipboards', true)
on conflict (id) do nothing;

-- Storage policies for 'clipboards' bucket
create policy "Users can upload clipboard images"
  on storage.objects for insert
  with check (bucket_id = 'clipboards' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can read clipboard images"
  on storage.objects for select
  using (bucket_id = 'clipboards' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can delete clipboard images"
  on storage.objects for delete
  using (bucket_id = 'clipboards' and auth.uid()::text = (storage.foldername(name))[1]);
