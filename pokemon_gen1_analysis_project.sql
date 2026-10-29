USE playground;

-- checking our dataset
SELECT * FROM pokemon_data;
SELECT DISTINCT * FROM pokemon_data;

-- Data Cleaning Section
-- create or replace view was created so that its modular and clean for our analysis later
CREATE OR REPLACE VIEW pokemon_cleaned AS 
SELECT 
	No AS id,
    
    -- changing text to a cleaner format as well as standardizing text
	LOWER(TRIM(REPLACE(REPLACE(Name,'Nidoranâ™€','nidoran-f'),'Nidoranâ™‚', 'nidoran-m'))) AS name_clean,
    UPPER(TRIM(Type1)) AS type1_clean,
    
-- catching all the empty and blank spaces in the dataset
CASE 
	WHEN Type2 IS NULL OR UPPER(TRIM(Type2)) IN ('', ' ') THEN 'NONE'
    ELSE UPPER(TRIM(Type2))
END AS type2_clean,

Height AS height,
Weight AS weight,

-- converting boolean values to text
CASE 
	WHEN Legendary = 1 THEN 'legendary'
    WHEN Legendary = 0 THEN 'standard'
    ELSE NULL
END AS legendary_clean,

-- checking for weight class logic
CASE
	WHEN weight <= 10 THEN 'featherweight'
    WHEN weight > 10 AND weight <= 100 THEN 'midweight'
    ELSE 'heavyweight'
END AS weight_class,

-- same process as type2_clean but used to check for its status
CASE 
    WHEN Type2 IS NULL OR UPPER(TRIM(Type2)) IN ('', ' ') THEN 'single type'
    ELSE 'dual type'
END AS dual_type_status,

-- computing for bmi index as our metric
ROUND(Weight / POWER(Height,2),2) AS bmi

FROM pokemon_data;

SELECT * FROM pokemon_cleaned;

-- Analysis Section

-- What is the average physical profile (weight, height, and BMI) across different primary Pokémon types?
SELECT type1_clean, ROUND(AVG(weight),2) AS average_weight, ROUND(AVG(height),2) AS average_height, ROUND(AVG(bmi),2) AS average_bmi -- rounded by two decimal places
FROM pokemon_cleaned
GROUP BY type1_clean
ORDER BY average_weight DESC; -- sorted by heaviest to lightest

-- How are Pokémon distributed across weight classes and legendary statuses?
SELECT weight_class, COUNT(*) AS pokemon_count FROM pokemon_cleaned
WHERE legendary_clean = 'legendary'
GROUP BY weight_class;


-- What are the extreme physical outliers in the dataset based on BMI?
-- top 5 highest pokemon bmi
SELECT * FROM pokemon_cleaned
ORDER BY bmi DESC
LIMIT 5;

-- top 5 lowest pokemon bmi
SELECT * FROM pokemon_cleaned
ORDER BY bmi ASC
LIMIT 5;

-- What subset of single-type Water Pokémon exceed 50 kg?
SELECT name_clean, weight, bmi FROM pokemon_cleaned
WHERE weight > 50 AND (type1_clean = 'WATER' AND dual_type_status = 'single type');

-- Who is the tallest Pokémon within each primary type category?
WITH ranked_pokemon AS (
    SELECT
        name_clean, 
        type1_clean,
        height,
        RANK() OVER(PARTITION BY type1_clean ORDER BY height DESC) AS height_rank
    FROM pokemon_cleaned
)
SELECT name_clean, type1_clean, height
FROM ranked_pokemon
WHERE height_rank = 1;