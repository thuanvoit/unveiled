-- Active: 1780193086436@@192.168.50.127@5432@unveiled
-- ==========================================
-- UNVEILED PROJECT - DATABASE SCHEMA SCRIPT
-- PostgreSQL Dialect
-- ==========================================

-- Drop tables if they exist (ordered to respect foreign key constraints)
DROP TABLE IF EXISTS sizing_rosetta_stone CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS wear_logs CASCADE;
DROP TABLE IF EXISTS garment_fabrics CASCADE;
DROP TABLE IF EXISTS garments CASCADE;
DROP TABLE IF EXISTS brands CASCADE;
DROP TABLE IF EXISTS drawers CASCADE;
DROP TABLE IF EXISTS user_sizing CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Enable UUID extension if not already active
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. USER & PROFILE MANAGEMENT
-- ==========================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    default_privacy_tier VARCHAR(20) DEFAULT 'private' CHECK (default_privacy_tier IN ('private', 'anonymous', 'public')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_sizing (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    garment_type VARCHAR(50) NOT NULL, -- e.g., 'bra', 'briefs', 'socks'
    size_value VARCHAR(20) NOT NULL,    -- e.g., '34C', 'M', 'O/S'
    system VARCHAR(10) DEFAULT 'US',   -- e.g., 'US', 'UK', 'EU'
    UNIQUE(user_id, garment_type)
);

-- ==========================================
-- 2. ORGANIZATION & COLLECTIONS
-- ==========================================

CREATE TABLE drawers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,        -- e.g., 'Everyday Essentials', 'Luxury Lingerie'
    description TEXT,
    privacy_tier VARCHAR(20) DEFAULT 'private' CHECK (privacy_tier IN ('private', 'anonymous', 'public')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. THE GARMENT INVENTORY
-- ==========================================

CREATE TABLE brands (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    is_verified BOOLEAN DEFAULT false
);

CREATE TABLE garments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    drawer_id UUID REFERENCES drawers(id) ON DELETE SET NULL,
    brand_id INT REFERENCES brands(id),
    style_name VARCHAR(150),
    garment_type VARCHAR(50) NOT NULL, -- e.g., 'boxer_brief', 'bralette', 'thong'
    color VARCHAR(50),
    pattern VARCHAR(50),
    size_worn VARCHAR(20) NOT NULL,
    purchase_date DATE,
    cost NUMERIC(6, 2),
    current_condition VARCHAR(20) DEFAULT 'new' CHECK (current_condition IN ('new', 'excellent', 'worn', 'stretched_out')),
    laundry_status VARCHAR(20) DEFAULT 'clean' CHECK (laundry_status IN ('clean', 'dirty', 'washing')),
    wash_count INT DEFAULT 0,
    wear_count INT DEFAULT 0,
    image_url TEXT,                     
    image_type VARCHAR(10) DEFAULT 'stock' CHECK (image_type IN ('stock', 'personal')),
    privacy_tier VARCHAR(20) DEFAULT 'private' CHECK (privacy_tier IN ('private', 'anonymous', 'public')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE garment_fabrics (
    garment_id UUID REFERENCES garments(id) ON DELETE CASCADE,
    fabric_name VARCHAR(50) NOT NULL, -- e.g., 'Modal', 'Silk', 'Cotton', 'Elastane'
    percentage INT NOT NULL CHECK (percentage BETWEEN 1 AND 100),
    PRIMARY KEY (garment_id, fabric_name)
);

-- ==========================================
-- 4. CARE & LOGGING HISTORY
-- ==========================================

CREATE TABLE wear_logs (
    id BIGSERIAL PRIMARY KEY,
    garment_id UUID REFERENCES garments(id) ON DELETE CASCADE,
    worn_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    washed_at TIMESTAMP WITH TIME ZONE
);

-- ==========================================
-- 5. COMMUNITY & SOCIAL FEATURES
-- ==========================================

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    garment_id UUID REFERENCES garments(id) ON DELETE SET NULL, 
    brand_id INT REFERENCES brands(id) NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    fit_feedback VARCHAR(20) CHECK (fit_feedback IN ('runs_small', 'true_to_size', 'runs_large')),
    waistband_roll BOOLEAN DEFAULT false,
    fabric_pilling BOOLEAN DEFAULT false,
    review_text TEXT,
    is_anonymous BOOLEAN DEFAULT false, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sizing_rosetta_stone (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    brand_a_id INT REFERENCES brands(id),
    brand_a_size VARCHAR(20),
    brand_b_id INT REFERENCES brands(id),
    brand_b_size VARCHAR(20),
    garment_type VARCHAR(50), 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 6. PERFORMANCE & OPTIMIZATION INDEXES
-- ==========================================

-- Indexing lookups on core inventory items
CREATE INDEX idx_garments_user_id ON garments(user_id);
CREATE INDEX idx_garments_drawer_id ON garments(drawer_id);
CREATE INDEX idx_garments_brand_id ON garments(brand_id);

-- Indexing laundry and history items for speedier app actions
CREATE INDEX idx_garments_laundry_status ON garments(laundry_status);
CREATE INDEX idx_wear_logs_garment_id ON wear_logs(garment_id);

-- Indexing for community queries
CREATE INDEX idx_reviews_brand_id ON reviews(brand_id);
CREATE INDEX idx_rosetta_brands ON sizing_rosetta_stone(brand_a_id, brand_b_id);