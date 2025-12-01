USE wind_turbine;
drop TABLE wind_turbine;
select * from wind_turbine;

With flattened AS (
    SELECT 'Wind_speed' AS metric, Wind_speed AS value FROM wind_turbine
    UNION ALL SELECT 'Power', Power FROM wind_turbine
    UNION ALL SELECT 'Nacelle_ambient_temperature', Nacelle_ambient_temperature FROM wind_turbine
    UNION ALL SELECT 'Generator_bearing_temperature', Generator_bearing_temperature FROM wind_turbine
    UNION ALL SELECT 'Gear_oil_temperature', Gear_oil_temperature FROM wind_turbine
    UNION ALL SELECT 'Ambient_temperature', Ambient_temperature FROM wind_turbine
    UNION ALL SELECT 'Rotor_Speed', Rotor_Speed FROM wind_turbine
    UNION ALL SELECT 'Nacelle_temperature', Nacelle_temperature FROM wind_turbine
    UNION ALL SELECT 'Bearing_temperature', Bearing_temperature FROM wind_turbine
    UNION ALL SELECT 'Generator_speed', Generator_speed FROM wind_turbine
    UNION ALL SELECT 'Yaw_angle', Yaw_angle FROM wind_turbine
    UNION ALL SELECT 'Wind_direction', Wind_direction FROM wind_turbine
    UNION ALL SELECT 'Wheel_hub_temperature', Wheel_hub_temperature FROM wind_turbine
    UNION ALL SELECT 'Gear_box_inlet_temperature', Gear_box_inlet_temperature FROM wind_turbine
)

SELECT 
    f.metric AS column_name,
    ROUND(AVG(f.value), 2) AS mean_value,

    -- Median
    ROUND((
        SELECT AVG(sub.value)
        FROM (
            SELECT value,
                   ROW_NUMBER() OVER (ORDER BY value) AS row_num,
                   COUNT(*) OVER () AS total_count
            FROM flattened
            WHERE metric = f.metric AND value IS NOT NULL
        ) sub
        WHERE row_num IN (FLOOR((total_count + 1)/2), CEIL((total_count + 1)/2))
    ), 2) AS median_value,

    -- Mode (most frequent value)
    (
        SELECT sub2.value
        FROM (
            SELECT value, COUNT(*) AS freq
            FROM flattened
            WHERE metric = f.metric AND value IS NOT NULL
            GROUP BY value
            ORDER BY freq DESC, value ASC
            LIMIT 1
        ) AS sub2
    ) AS mode_value,

    ROUND(STDDEV(f.value), 2) AS std_dev,
    ROUND(MAX(f.value) - MIN(f.value), 2) AS range_value,
    SUM(CASE WHEN f.value IS NULL THEN 1 ELSE 0 END) AS missing_count

FROM flattened f
GROUP BY f.metric;


-- PREPROCESSING
SET SQL_SAFE_UPDATES = 0;

-- WIND SPEED (Missing Value Imputation using Median)
UPDATE wind_turbine
SET Wind_speed = (
  SELECT AVG(Wind_speed)
  FROM (
    SELECT Wind_speed,
           ROW_NUMBER() OVER (ORDER BY Wind_speed) AS row_num,
           COUNT(*) OVER () AS total_count
    FROM wind_turbine
    WHERE Wind_speed IS NOT NULL
  ) AS sub
  WHERE row_num IN (
    FLOOR((total_count + 1) / 2),
    CEIL((total_count + 1) / 2)
  )
)
WHERE Wind_speed IS NULL;

-- Check missing values
SELECT COUNT(*) AS Missing_Wind_speed FROM wind_turbine WHERE Wind_speed IS NULL;

-- OUTLIER TREATMENT -----------------------------------------------------

-- Step 1: Calculate lower & upper limits
SELECT 
  AVG(Wind_speed) - 3 * STDDEV(Wind_speed),
  AVG(Wind_speed) + 3 * STDDEV(Wind_speed)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

-- Step 2: Check number of outliers
SELECT COUNT(*) AS Wind_speed_outliers
FROM wind_turbine
WHERE Wind_speed < @lower_limit OR Wind_speed > @upper_limit;

-- Step 3: Cap outliers
UPDATE wind_turbine
SET Wind_speed = 
  CASE 
    WHEN Wind_speed < @lower_limit THEN @lower_limit
    WHEN Wind_speed > @upper_limit THEN @upper_limit
    ELSE Wind_speed
  END;

-- Step 4: Verify
SELECT COUNT(*) AS Wind_speed_outliers_after
FROM wind_turbine
WHERE Wind_speed < @lower_limit OR Wind_speed > @upper_limit;


-- POWER ----------------------------------------------------------------
SELECT 
  AVG(Power) - 3 * STDDEV(Power),
  AVG(Power) + 3 * STDDEV(Power)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Power_outliers
FROM wind_turbine
WHERE Power < @lower_limit OR Power > @upper_limit;

UPDATE wind_turbine
SET Power = 
  CASE 
    WHEN Power < @lower_limit THEN @lower_limit
    WHEN Power > @upper_limit THEN @upper_limit
    ELSE Power
  END;

SELECT COUNT(*) AS Power_outliers_after
FROM wind_turbine
WHERE Power < @lower_limit OR Power > @upper_limit;


-- NACELLE AMBIENT TEMPERATURE ------------------------------------------
SELECT 
  AVG(Nacelle_ambient_temperature) - 3 * STDDEV(Nacelle_ambient_temperature),
  AVG(Nacelle_ambient_temperature) + 3 * STDDEV(Nacelle_ambient_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Nacelle_ambient_temperature_outliers
FROM wind_turbine
WHERE Nacelle_ambient_temperature < @lower_limit OR Nacelle_ambient_temperature > @upper_limit;


-- GENERATOR BEARING TEMPERATURE ----------------------------------------
SELECT 
  AVG(Generator_bearing_temperature) - 3 * STDDEV(Generator_bearing_temperature),
  AVG(Generator_bearing_temperature) + 3 * STDDEV(Generator_bearing_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Generator_bearing_temperature_outliers
FROM wind_turbine
WHERE Generator_bearing_temperature < @lower_limit OR Generator_bearing_temperature > @upper_limit;


-- GEAR OIL TEMPERATURE --------------------------------------------------
SELECT 
  AVG(Gear_oil_temperature) - 3 * STDDEV(Gear_oil_temperature),
  AVG(Gear_oil_temperature) + 3 * STDDEV(Gear_oil_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Gear_oil_temperature_outliers
FROM wind_turbine
WHERE Gear_oil_temperature < @lower_limit OR Gear_oil_temperature > @upper_limit;

UPDATE wind_turbine
SET Gear_oil_temperature = 
  CASE 
    WHEN Gear_oil_temperature < @lower_limit THEN @lower_limit
    WHEN Gear_oil_temperature > @upper_limit THEN @upper_limit
    ELSE Gear_oil_temperature
  END;

SELECT COUNT(*) AS Gear_oil_temperature_outliers_after
FROM wind_turbine
WHERE Gear_oil_temperature < @lower_limit OR Gear_oil_temperature > @upper_limit;


-- AMBIENT TEMPERATURE ---------------------------------------------------
SELECT 
  AVG(Ambient_temperature) - 3 * STDDEV(Ambient_temperature),
  AVG(Ambient_temperature) + 3 * STDDEV(Ambient_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Ambient_temperature_outliers
FROM wind_turbine
WHERE Ambient_temperature < @lower_limit OR Ambient_temperature > @upper_limit;

UPDATE wind_turbine
SET Ambient_temperature = 
  CASE 
    WHEN Ambient_temperature < @lower_limit THEN @lower_limit
    WHEN Ambient_temperature > @upper_limit THEN @upper_limit
    ELSE Ambient_temperature
  END;

SELECT COUNT(*) AS Ambient_temperature_outliers_after
FROM wind_turbine
WHERE Ambient_temperature < @lower_limit OR Ambient_temperature > @upper_limit;


-- ROTOR SPEED -----------------------------------------------------------
SELECT 
  AVG(Rotor_Speed) - 3 * STDDEV(Rotor_Speed),
  AVG(Rotor_Speed) + 3 * STDDEV(Rotor_Speed)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Rotor_Speed_outliers
FROM wind_turbine
WHERE Rotor_Speed < @lower_limit OR Rotor_Speed > @upper_limit;

UPDATE wind_turbine
SET Rotor_Speed = 
  CASE 
    WHEN Rotor_Speed < @lower_limit THEN @lower_limit
    WHEN Rotor_Speed > @upper_limit THEN @upper_limit
    ELSE Rotor_Speed
  END;

SELECT COUNT(*) AS Rotor_Speed_outliers_after
FROM wind_turbine
WHERE Rotor_Speed < @lower_limit OR Rotor_Speed > @upper_limit;


-- NACELLE TEMPERATURE ---------------------------------------------------
SELECT 
  AVG(Nacelle_temperature) - 3 * STDDEV(Nacelle_temperature),
  AVG(Nacelle_temperature) + 3 * STDDEV(Nacelle_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Nacelle_temperature_outliers
FROM wind_turbine
WHERE Nacelle_temperature < @lower_limit OR Nacelle_temperature > @upper_limit;


-- BEARING TEMPERATURE ---------------------------------------------------
SELECT 
  AVG(Bearing_temperature) - 3 * STDDEV(Bearing_temperature),
  AVG(Bearing_temperature) + 3 * STDDEV(Bearing_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Bearing_temperature_outliers
FROM wind_turbine
WHERE Bearing_temperature < @lower_limit OR Bearing_temperature > @upper_limit;


-- GENERATOR SPEED -------------------------------------------------------
SELECT 
  AVG(Generator_speed) - 3 * STDDEV(Generator_speed),
  AVG(Generator_speed) + 3 * STDDEV(Generator_speed)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Generator_speed_outliers
FROM wind_turbine
WHERE Generator_speed < @lower_limit OR Generator_speed > @upper_limit;

UPDATE wind_turbine
SET Generator_speed = 
  CASE 
    WHEN Generator_speed < @lower_limit THEN @lower_limit
    WHEN Generator_speed > @upper_limit THEN @upper_limit
    ELSE Generator_speed
  END;

SELECT COUNT(*) AS Generator_speed_outliers_after
FROM wind_turbine
WHERE Generator_speed < @lower_limit OR Generator_speed > @upper_limit;


-- YAW ANGLE -------------------------------------------------------------
SELECT 
  AVG(Yaw_angle) - 3 * STDDEV(Yaw_angle),
  AVG(Yaw_angle) + 3 * STDDEV(Yaw_angle)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Yaw_angle_outliers
FROM wind_turbine
WHERE Yaw_angle < @lower_limit OR Yaw_angle > @upper_limit;


-- WIND DIRECTION --------------------------------------------------------
SELECT 
  AVG(Wind_direction) - 3 * STDDEV(Wind_direction),
  AVG(Wind_direction) + 3 * STDDEV(Wind_direction)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Wind_direction_outliers
FROM wind_turbine
WHERE Wind_direction < @lower_limit OR Wind_direction > @upper_limit;


-- WHEEL HUB TEMPERATURE -------------------------------------------------
SELECT 
  AVG(Wheel_hub_temperature) - 3 * STDDEV(Wheel_hub_temperature),
  AVG(Wheel_hub_temperature) + 3 * STDDEV(Wheel_hub_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Wheel_hub_temperature_outliers
FROM wind_turbine
WHERE Wheel_hub_temperature < @lower_limit OR Wheel_hub_temperature > @upper_limit;


-- GEAR BOX INLET TEMPERATURE --------------------------------------------
SELECT 
  AVG(Gear_box_inlet_temperature) - 3 * STDDEV(Gear_box_inlet_temperature),
  AVG(Gear_box_inlet_temperature) + 3 * STDDEV(Gear_box_inlet_temperature)
INTO @lower_limit, @upper_limit
FROM wind_turbine;

SELECT COUNT(*) AS Gear_box_inlet_temperature_outliers
FROM wind_turbine
WHERE Gear_box_inlet_temperature < @lower_limit OR Gear_box_inlet_temperature > @upper_limit;
