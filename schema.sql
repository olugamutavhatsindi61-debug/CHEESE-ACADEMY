-- Big Cheese Academy database (PostgreSQL / Supabase)
-- Run this whole file once in the Supabase SQL Editor.

-- ---------- Reference data (publicly readable) ----------
create table public.subjects (
  id smallint generated always as identity primary key,
  name text not null,
  level text not null check (level in ('high_school','university')),
  active boolean not null default true,
  unique (level, name)
);

create table public.offerings (            -- which subject is taught in which grade
  grade smallint not null check (grade between 10 and 12),
  subject_id smallint not null references public.subjects(id) on delete cascade,
  primary key (grade, subject_id)
);

create table public.packages (
  id smallint generated always as identity primary key,
  slug text not null unique,
  name text not null,
  price_cents integer not null check (price_cents >= 0),   -- R75 = 7500
  unit text not null check (unit in ('hour','month','subject')),
  price_note text,
  features text[] not null default '{}',
  sort smallint not null default 0,
  active boolean not null default true
);

create table public.tutors (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  education text,
  bio text,
  photo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.tutor_subjects (
  tutor_id uuid not null references public.tutors(id) on delete cascade,
  subject_id smallint not null references public.subjects(id) on delete cascade,
  primary key (tutor_id, subject_id)
);

-- ---------- Form submissions (public can add, only you can read) ----------
create table public.enrolments (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null check (char_length(full_name) between 1 and 120),
  phone text check (char_length(phone) <= 30),
  grade smallint check (grade between 10 and 12),
  package_name text check (char_length(package_name) <= 80),
  subjects text check (char_length(subjects) <= 300),
  message text check (char_length(message) <= 2000),
  status text not null default 'new' check (status in ('new','contacted','enrolled','declined')),
  notes text
);

create table public.tutor_applications (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null check (char_length(full_name) between 1 and 120),
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 200),
  phone text not null check (char_length(phone) <= 30),
  qualification text not null check (char_length(qualification) <= 200),
  institution text not null check (char_length(institution) <= 200),
  grades text check (char_length(grades) <= 40),
  subjects text not null check (char_length(subjects) <= 300),
  experience text check (char_length(experience) <= 2000),
  availability text check (char_length(availability) <= 300),
  motivation text check (char_length(motivation) <= 2000),   -- may be empty if a motivation letter is uploaded
  transcript_path text not null check (char_length(transcript_path) <= 300),  -- proof of registration / transcript
  matric_path text not null check (char_length(matric_path) <= 300),          -- matric results
  motivation_path text check (char_length(motivation_path) <= 300),           -- optional motivation letter
  cv_path text check (char_length(cv_path) <= 300),                           -- optional CV
  -- paths point to files in the private "applications" storage bucket
  status text not null default 'new' check (status in ('new','reviewing','interview','accepted','rejected')),
  notes text
);
create index on public.enrolments (created_at desc);
create index on public.tutor_applications (created_at desc);

-- ---------- Security (Row Level Security) ----------
alter table public.subjects enable row level security;
alter table public.offerings enable row level security;
alter table public.packages enable row level security;
alter table public.tutors enable row level security;
alter table public.tutor_subjects enable row level security;
alter table public.enrolments enable row level security;
alter table public.tutor_applications enable row level security;

revoke all on all tables in schema public from anon, authenticated;
grant select on public.subjects, public.offerings, public.packages, public.tutors, public.tutor_subjects to anon;
grant insert on public.enrolments, public.tutor_applications to anon;

create policy "public read" on public.subjects for select to anon using (active);
create policy "public read" on public.offerings for select to anon using (true);
create policy "public read" on public.packages for select to anon using (active);
create policy "public read" on public.tutors for select to anon using (active);
create policy "public read" on public.tutor_subjects for select to anon using (true);
create policy "public can apply" on public.enrolments for insert to anon
  with check (status = 'new' and notes is null);
create policy "public can apply" on public.tutor_applications for insert to anon
  with check (status = 'new' and notes is null);
-- No select/update/delete policy for anon: visitors can never read submissions.
-- You read them in the Supabase dashboard (Table Editor), which bypasses these rules.

-- ---------- Private bucket for applicant documents ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('applications','applications',false,5242880,
  array['application/pdf','image/jpeg','image/png','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do nothing;
create policy "public can upload documents" on storage.objects for insert to anon with check (bucket_id = 'applications');

-- ---------- Starting data (from the website) ----------
insert into public.subjects (name, level) values
  ('Mathematics','high_school'),('Physical Sciences','high_school'),('Accounting','high_school'),('Economics','high_school'),
  ('EECF 1614','university'),('EECF 1624','university'),('EMAC2724','university'),('MATM1534','university');

insert into public.offerings (grade, subject_id)
select g, id from public.subjects, (values (10),(11),(12)) v(g)
where level = 'high_school' and (
  (g = 10 and name = 'Mathematics') or
  (g = 11 and name in ('Mathematics','Physical Sciences','Accounting')) or
  (g = 12));

insert into public.packages (slug, name, price_cents, unit, price_note, features, sort) values
 ('one-on-one','One-on-one consultation',7500,'hour',null,
   array['Personalized learning','Flexible scheduling','Expert guidance','Focused support'],1),
 ('group','Group sessions',20000,'month','2 subjects: R350/month (save R50). 3 subjects: R510/month (save 15%).',
   array['Weekly online classes','Recorded sessions','Comprehensive notes','Ongoing mentorship'],2),
 ('bootcamp','Bootcamp sessions',10000,'subject',null,
   array['Online','Recorded sessions','Comprehensive notes','Intensive exam revision'],3);
