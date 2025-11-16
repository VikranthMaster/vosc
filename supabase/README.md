# Supabase Migrations

This directory contains Supabase CLI migration files.

## Migration Files

1. **20251116000001_initial_schema.sql** - Creates all core tables
2. **20251116000002_add_indexes.sql** - Adds performance indexes
3. **20251116000003_add_rls_policies.sql** - Sets up Row Level Security policies
4. **20251116000004_add_functions_triggers.sql** - Creates helper functions and triggers

## How to Run Migrations

### Using Supabase CLI

1. **Link your project** :
   ```bash
   supabase link --project-ref your-project-ref
   ```

2. **Push migrations to Supabase**:
   ```bash
   supabase db push
   ```
   
   Or use the migration command:
   ```bash
   supabase migration up
   ```

### Verify Migrations

Check which migrations have been applied:
```bash
supabase migration list
```

##  Notes

- All migration files have been pushed into db ( no need to do above steps unless you want to use ur own supabase account )
- If you feel any column or table is redundant, Tell me i will make changes
- I will Share the .env file with all required details in whatsapp
- If you want to view the database in your pc - send me your email in whatsapp i will invite you as a team member 


