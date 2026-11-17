# Steam Games Market & Performance Analysis
## SQL Analysis Project | PostgreSQL

**Project Objective**

Analyze a dataset of 882 Steam games to understand game catalogue distribution, pricing strategies, discount patterns, review performance, estimated ownership and player engagement.

**Database:** PostgreSQL  
**Main Table:** `steam_games`  
**Analysis View:** `steam_games_clean`  
**Records Analyzed:** 882

---

# SECTION 01 — DATABASE SETUP

-- Remove the existing table if it needs to be recreated.
-- WARNING: DROP TABLE permanently removes the table and its data.

```sql
DROP TABLE IF EXISTS steam_games;

-- Create the main Steam games table.
CREATE TABLE steam_games (
    app_id BIGINT,
    name TEXT,
    release_date TEXT,
    primary_genre VARCHAR(100),
    all_tags TEXT,
    price_usd NUMERIC(10,2),
    discount_pct NUMERIC(5,2),
    review_score_pct NUMERIC(5,2),
    total_reviews BIGINT,
    steam_deck_status VARCHAR(100),
    estimated_owners BIGINT,
    peak_players_24h BIGINT,
    release_year INTEGER
);
```

# SECTION 02 — INITIAL DATA EXPLORATION

### 2.1 Total number of records

-- Check the number of records imported into the table.

```sql
SELECT COUNT(*) AS total_records
FROM steam_games;
```

### 2.2 Preview the dataset

-- Inspect the first 10 records to understand the dataset structure.

```sql
SELECT *
FROM steam_games
LIMIT 10;
```

### 2.3 Initial data-quality checks

-- Check total records, unique game IDs, missing names and negative prices.

```sql
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT app_id) AS unique_games,
    COUNT(*) FILTER (WHERE name IS NULL) AS missing_names,
    COUNT(*) FILTER (WHERE price_usd < 0) AS negative_prices
FROM steam_games;
```

# SECTION 03 — CATALOGUE AND GENRE ANALYSIS

### 3.1 Game distribution by genre

-- Identify which genres contribute the most games to the dataset.

```sql
SELECT
    primary_genre,
    COUNT(*) AS game_count
FROM steam_games
GROUP BY primary_genre
ORDER BY game_count DESC;
```

### 3.2 Pricing and discount performance by genre

-- Compare average, minimum and maximum game prices across genres.
-- Also examine average discount percentages.

```sql
SELECT
    primary_genre,
    COUNT(*) AS game_count,
    ROUND(AVG(price_usd), 2) AS avg_price,
    ROUND(MIN(price_usd), 2) AS min_price,
    ROUND(MAX(price_usd), 2) AS max_price,
    ROUND(AVG(discount_pct), 2) AS avg_discount
FROM steam_games
GROUP BY primary_genre
ORDER BY avg_price DESC;
```

# SECTION 04 — PRICING AND DISCOUNT ANALYSIS

### 4.1 Free vs paid games

-- Compare the proportion of free and paid games.
-- Evaluate their average review scores and discounts.

```sql
SELECT
    CASE
        WHEN price_usd = 0 THEN 'Free'
        ELSE 'Paid'
    END AS price_category,
    COUNT(*) AS game_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage,
    ROUND(AVG(review_score_pct), 2) AS avg_review_score,
    ROUND(AVG(discount_pct), 2) AS avg_discount
FROM steam_games
GROUP BY price_category
ORDER BY game_count DESC;
```

### 4.2 Price-band performance

-- Group games into price categories.
-- Compare game count, average price, review score, reviews and ownership.

```sql
SELECT
    CASE
        WHEN price_usd = 0 THEN 'Free'
        WHEN price_usd <= 10 THEN '$0-$10'
        WHEN price_usd <= 20 THEN '$10-$20'
        WHEN price_usd <= 40 THEN '$20-$40'
        ELSE '$40+'
    END AS price_band,
    COUNT(*) AS game_count,
    ROUND(AVG(price_usd), 2) AS avg_price,
    ROUND(AVG(review_score_pct), 2) AS avg_review_score,
    ROUND(AVG(total_reviews), 0) AS avg_reviews,
    ROUND(AVG(estimated_owners), 0) AS avg_owners
FROM steam_games
GROUP BY price_band
ORDER BY MIN(price_usd);
```

### 4.3 Discount-band performance

-- Evaluate how different discount levels relate to review performance
-- and estimated ownership.

```sql
SELECT
    CASE
        WHEN discount_pct = 0 THEN 'No Discount'
        WHEN discount_pct <= 25 THEN '1-25%'
        WHEN discount_pct <= 50 THEN '26-50%'
        WHEN discount_pct <= 75 THEN '51-75%'
        ELSE '76-100%'
    END AS discount_band,
    COUNT(*) AS game_count,
    ROUND(AVG(price_usd), 2) AS avg_price,
    ROUND(AVG(review_score_pct), 2) AS avg_review_score,
    ROUND(AVG(total_reviews), 0) AS avg_reviews,
    ROUND(AVG(estimated_owners), 0) AS avg_owners
FROM steam_games
GROUP BY discount_band
ORDER BY MIN(discount_pct);
```

# SECTION 05 — REVIEW AND RELEASE PERFORMANCE

### 5.1 Review performance by genre

-- Compare average review scores and review counts across genres.

```sql
SELECT
    primary_genre,
    COUNT(*) AS game_count,
    ROUND(AVG(review_score_pct), 2) AS avg_review_score,
    ROUND(MIN(review_score_pct), 2) AS min_review_score,
    ROUND(MAX(review_score_pct), 2) AS max_review_score,
    ROUND(AVG(total_reviews), 0) AS avg_total_reviews
FROM steam_games
GROUP BY primary_genre
ORDER BY avg_review_score DESC;
```

### 5.2 Year-wise release trends

-- Analyze the number of games released each year.
-- Compare average prices and review scores across release years.

```sql
SELECT
    release_year,
    COUNT(*) AS game_count,
    ROUND(AVG(price_usd), 2) AS avg_price,
    ROUND(AVG(review_score_pct), 2) AS avg_review_score
FROM steam_games
WHERE release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year;
```

# SECTION 06 — PLAYER ENGAGEMENT ANALYSIS

### 6.1 Player engagement by genre

-- Compare average estimated ownership, peak players and reviews.
-- Calculate a rough peak-player-to-ownership ratio.

```sql
SELECT
    primary_genre,
    COUNT(*) AS game_count,
    ROUND(AVG(estimated_owners), 0) AS avg_estimated_owners,
    ROUND(AVG(peak_players_24h), 0) AS avg_peak_players,
    ROUND(AVG(total_reviews), 0) AS avg_reviews,
    ROUND(
        AVG(peak_players_24h) * 100.0 /
        NULLIF(AVG(estimated_owners), 0),
        2
    ) AS avg_peak_to_owners_pct
FROM steam_games
GROUP BY primary_genre
ORDER BY avg_estimated_owners DESC;
```

### 6.2 Top 10 games by estimated ownership

-- Identify the 10 games with the highest estimated ownership.

```sql
SELECT
    app_id,
    name,
    primary_genre,
    price_usd,
    estimated_owners,
    peak_players_24h,
    review_score_pct,
    total_reviews
FROM steam_games
ORDER BY estimated_owners DESC
LIMIT 10;
```

### 6.3 Top 10 games by 24-hour peak players

-- Identify games with the highest reported 24-hour peak player counts.

```sql
SELECT
    app_id,
    name,
    primary_genre,
    price_usd,
    estimated_owners,
    peak_players_24h,
    review_score_pct,
    total_reviews
FROM steam_games
ORDER BY peak_players_24h DESC
LIMIT 10;
```

# SECTION 07 — DATA QUALITY ASSESSMENT

### 7.1 Identify missing and suspicious values

-- Check for missing or zero estimated ownership,
-- peak players exceeding estimated ownership,
-- zero review scores and missing release dates.

```sql
SELECT
    COUNT(*) AS total_games,
    COUNT(*) FILTER (
        WHERE estimated_owners IS NULL
    ) AS missing_owners,
    COUNT(*) FILTER (
        WHERE estimated_owners = 0
    ) AS zero_owners,
    COUNT(*) FILTER (
        WHERE peak_players_24h > estimated_owners
    ) AS peak_exceeds_owners,
    COUNT(*) FILTER (
        WHERE review_score_pct = 0
    ) AS zero_review_scores,
    COUNT(*) FILTER (
        WHERE release_date IS NULL
    ) AS missing_release_dates
FROM steam_games;
```

### 7.2 Inspect suspicious records

-- Retrieve games with potentially inconsistent engagement data
-- or zero review scores.

```sql
SELECT
    app_id,
    name,
    estimated_owners,
    peak_players_24h,
    review_score_pct,
    total_reviews
FROM steam_games
WHERE peak_players_24h > estimated_owners
   OR review_score_pct = 0
ORDER BY name;
```

### 7.3 Investigate zero review scores

-- Identify games with existing reviews but a zero review score.
-- These values may represent missing or invalid review data.

```sql
SELECT
    name,
    review_score_pct,
    total_reviews,
    CASE
        WHEN total_reviews > 0 AND review_score_pct = 0
        THEN 'Potential missing/invalid review score'
        ELSE 'Valid'
    END AS data_quality_status
FROM steam_games
WHERE review_score_pct = 0;
```

# SECTION 08 — DATA CLEANING AND ANALYSIS VIEW

### 8.1 Create a cleaned analysis view

-- Preserve the original table.
-- Convert suspicious zero review scores to NULL in the analysis view.
-- Flag records where peak players exceed estimated ownership.

```sql
CREATE OR REPLACE VIEW steam_games_clean AS
SELECT
    *,
    CASE
        WHEN review_score_pct = 0
             AND total_reviews > 0
        THEN NULL
        ELSE review_score_pct
    END AS clean_review_score_pct,
    CASE
        WHEN peak_players_24h > estimated_owners
        THEN 'Check Required'
        ELSE 'Valid'
    END AS engagement_data_status
FROM steam_games;
```

### 8.2 Verify the cleaned view

-- Confirm the number of games, valid review scores
-- and flagged engagement records.

```sql
SELECT
    COUNT(*) AS total_games,
    COUNT(clean_review_score_pct) AS valid_review_scores,
    COUNT(*) FILTER (
        WHERE engagement_data_status = 'Check Required'
    ) AS flagged_engagement_records
FROM steam_games_clean;
```

# SECTION 09 — ADVANCED SQL ANALYSIS

### 9.1 Rank genres by average review score

-- Use RANK() to identify the best-performing genres
-- based on average valid review scores.

```sql
SELECT
    primary_genre,
    COUNT(clean_review_score_pct) AS games_with_valid_scores,
    ROUND(AVG(clean_review_score_pct), 2) AS avg_review_score,
    RANK() OVER (
        ORDER BY AVG(clean_review_score_pct) DESC
    ) AS genre_rank
FROM steam_games_clean
GROUP BY primary_genre
ORDER BY genre_rank;
```

### 9.2 Top 3 games by estimated ownership within each genre

-- Use PARTITION BY and RANK() to rank games independently
-- within each genre.

```sql
WITH ranked_games AS (
    SELECT
        name,
        primary_genre,
        estimated_owners,
        clean_review_score_pct,
        RANK() OVER (
            PARTITION BY primary_genre
            ORDER BY estimated_owners DESC
        ) AS genre_rank
    FROM steam_games_clean
)
SELECT
    primary_genre,
    name,
    estimated_owners,
    clean_review_score_pct,
    genre_rank
FROM ranked_games
WHERE genre_rank <= 3
ORDER BY primary_genre, genre_rank;
```

### 9.3 Compare game ownership against genre average

-- Use AVG() OVER(PARTITION BY) to calculate the average
-- estimated ownership for each genre.
-- Identify games that outperform their genre average.

```sql
SELECT
    name,
    primary_genre,
    estimated_owners,
    ROUND(
        AVG(estimated_owners) OVER (
            PARTITION BY primary_genre
        ), 0
    ) AS genre_avg_owners,
    ROUND(
        estimated_owners::NUMERIC /
        NULLIF(
            AVG(estimated_owners) OVER (
                PARTITION BY primary_genre
            ), 0
        ) * 100,
        2
    ) AS ownership_vs_genre_avg_pct
FROM steam_games_clean
ORDER BY ownership_vs_genre_avg_pct DESC
LIMIT 20;
```

### 9.4 Top 3 games by estimated ownership for each release year

-- Use ROW_NUMBER() and PARTITION BY to rank games
-- within their respective release years.

```sql
WITH yearly_ranked_games AS (
    SELECT
        name,
        release_year,
        primary_genre,
        estimated_owners,
        clean_review_score_pct,
        ROW_NUMBER() OVER (
            PARTITION BY release_year
            ORDER BY estimated_owners DESC
        ) AS year_rank
    FROM steam_games_clean
)
SELECT
    release_year,
    name,
    primary_genre,
    estimated_owners,
    clean_review_score_pct,
    year_rank
FROM yearly_ranked_games
WHERE year_rank <= 3
ORDER BY release_year, year_rank;
```

### 9.5 Ownership quartile analysis

-- Use NTILE(4) to divide games into four groups
-- based on estimated ownership.
-- Compare average ownership, discount and price across quartiles.
-- Quartile 1 represents the highest ownership group.

```sql
WITH ownership_groups AS (
    SELECT
        name,
        price_usd,
        discount_pct,
        estimated_owners,
        NTILE(4) OVER (
            ORDER BY estimated_owners DESC
        ) AS ownership_quartile
    FROM steam_games_clean
)
SELECT
    ownership_quartile,
    COUNT(*) AS game_count,
    ROUND(AVG(estimated_owners), 0) AS avg_owners,
    ROUND(AVG(discount_pct), 2) AS avg_discount_pct,
    ROUND(AVG(price_usd), 2) AS avg_price_usd
FROM ownership_groups
GROUP BY ownership_quartile
ORDER BY ownership_quartile;
```

### 9.6 Price and ownership correlation

-- Calculate Pearson correlation to measure the linear
-- relationship between game price and estimated ownership.

```sql
SELECT
    ROUND(
        CORR(price_usd, estimated_owners)::NUMERIC,
        3
    ) AS price_ownership_correlation
FROM steam_games_clean;
```

### 9.7 Discount and ownership correlation

-- Calculate Pearson correlation to measure the linear
-- relationship between discount percentage and estimated ownership.

```sql
SELECT
    ROUND(
        CORR(discount_pct, estimated_owners)::NUMERIC,
        3
    ) AS discount_ownership_correlation
FROM steam_games_clean;
```

### 9.8 Pearson and Spearman correlation comparison

-- Compare Pearson correlation with Spearman rank correlation.
-- Use RANK() to convert discount and ownership into ranked values.
-- This helps assess whether the relationship is monotonic.

```sql
WITH ranked_data AS (
    SELECT
        discount_pct,
        estimated_owners,
        RANK() OVER (
            ORDER BY discount_pct
        ) AS discount_rank,
        RANK() OVER (
            ORDER BY estimated_owners
        ) AS owners_rank
    FROM steam_games_clean
    WHERE discount_pct IS NOT NULL
      AND estimated_owners IS NOT NULL
)
SELECT
    COUNT(*) AS games_analyzed,
    ROUND(
        CORR(discount_pct, estimated_owners)::NUMERIC,
        3
    ) AS pearson_correlation,
    ROUND(
        CORR(discount_rank, owners_rank)::NUMERIC,
        3
    ) AS spearman_correlation
FROM ranked_data;
```

---

# SECTION 10 — PROJECT COMPLETION NOTES

**SQL concepts demonstrated**

- Database and table creation
- Data exploration and validation
- Aggregate functions: COUNT, AVG, MIN, MAX
- Conditional aggregation using FILTER
- CASE statements
- GROUP BY and ORDER BY
- Common Table Expressions (CTEs)
- Window functions: RANK, ROW_NUMBER, NTILE
- PARTITION BY
- Window-based averages
- Pearson correlation using CORR()
- Spearman rank correlation
- Views for reusable data cleaning

**Important analytical limitations**

1. Estimated ownership is not confirmed sales or revenue.
2. Peak-player counts and estimated ownership may use different periods or estimation methods.
3. Zero review scores have been treated as potentially invalid, not proven missing values.
4. Correlation does not establish causation.
5. Results represent this 882-game dataset, not the entire Steam catalogue.
6. The 2026 release-year results may represent an incomplete year.

**Next project stage:** Business insights documentation and Power BI dashboard development.