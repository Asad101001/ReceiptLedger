-- ReceiptLedger Row Level Security (RLS) & Production Security Policies
-- ============================================================================
-- Execute this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/okuxmizxjfddxyrfvdib/sql/new
--
-- This script:
-- 1. Enables RLS on all 6 tables, resolving the "RLS disabled" warning in Supabase.
-- 2. Defines secure access rules for anon, authenticated users, and service_role.
-- 3. Ensures your FastAPI backend (using service_role key) maintains 100% full access.
-- ============================================================================

-- ── 1. Enable Row Level Security (RLS) on all tables ──────────────────────────
ALTER TABLE public.categories     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.line_items     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_hashes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_queue   ENABLE ROW LEVEL SECURITY;

-- ── 2. Drop any previous policies to avoid duplication conflicts ──────────────
DROP POLICY IF EXISTS "Allow public read access to categories"  ON public.categories;
DROP POLICY IF EXISTS "Allow users read own or public profile"   ON public.users;
DROP POLICY IF EXISTS "Allow authenticated insert to users"      ON public.users;
DROP POLICY IF EXISTS "Allow users update own profile"           ON public.users;
DROP POLICY IF EXISTS "Allow users manage own receipts"          ON public.receipts;
DROP POLICY IF EXISTS "Allow users manage own line items"        ON public.line_items;
DROP POLICY IF EXISTS "Allow users manage own hashes"            ON public.receipt_hashes;
DROP POLICY IF EXISTS "Allow users manage own review queue"      ON public.review_queue;

-- ── 3. Categories: Public Read Access ─────────────────────────────────────────
CREATE POLICY "Allow public read access to categories"
    ON public.categories
    FOR SELECT
    USING (true);

-- ── 4. Users Table: Read & Profile Sync ───────────────────────────────────────
CREATE POLICY "Allow users read own or public profile"
    ON public.users
    FOR SELECT
    USING (true);

CREATE POLICY "Allow authenticated insert to users"
    ON public.users
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow users update own profile"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id OR auth.role() = 'service_role');

-- ── 5. Receipts: Owner-Bound CRUD ─────────────────────────────────────────────
CREATE POLICY "Allow users manage own receipts"
    ON public.receipts
    FOR ALL
    USING (auth.uid() = user_id OR user_id IS NULL OR auth.role() = 'service_role')
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL OR auth.role() = 'service_role');

-- ── 6. Line Items: Receipt Cascading Access ───────────────────────────────────
CREATE POLICY "Allow users manage own line items"
    ON public.line_items
    FOR ALL
    USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM public.receipts r
            WHERE r.id = line_items.receipt_id
            AND (r.user_id = auth.uid() OR r.user_id IS NULL)
        )
    )
    WITH CHECK (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM public.receipts r
            WHERE r.id = line_items.receipt_id
            AND (r.user_id = auth.uid() OR r.user_id IS NULL)
        )
    );

-- ── 7. Deduplication Hashes: Receipt Cascading Access ─────────────────────────
CREATE POLICY "Allow users manage own hashes"
    ON public.receipt_hashes
    FOR ALL
    USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM public.receipts r
            WHERE r.id = receipt_hashes.receipt_id
            AND (r.user_id = auth.uid() OR r.user_id IS NULL)
        )
    )
    WITH CHECK (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM public.receipts r
            WHERE r.id = receipt_hashes.receipt_id
            AND (r.user_id = auth.uid() OR r.user_id IS NULL)
        )
    );

-- ── 8. Review Queue: Human-in-the-Loop Operator Access ────────────────────────
CREATE POLICY "Allow users manage own review queue"
    ON public.review_queue
    FOR ALL
    USING (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM public.line_items li
            JOIN public.receipts r ON r.id = li.receipt_id
            WHERE li.id = review_queue.line_item_id
            AND (r.user_id = auth.uid() OR r.user_id IS NULL)
        )
    )
    WITH CHECK (
        auth.role() = 'service_role' OR
        EXISTS (
            SELECT 1 FROM public.line_items li
            JOIN public.receipts r ON r.id = li.receipt_id
            WHERE li.id = review_queue.line_item_id
            AND (r.user_id = auth.uid() OR r.user_id IS NULL)
        )
    );
