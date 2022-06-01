-- Create table for dataset 
CREATE TABLE DATASET_MELI(
    event_name TEXT,
    item_id BIGINT,
    timestamp TIMESTAMPTZ,
    site TEXT,
    experiments TEXT,
    user_id INT
);

-- Copy csv values inside table
-- The second argument inside 'WITH' is to replace all empty values for NULL datatype
COPY DATASET_MELI
FROM '/temp/dataset.csv' 
WITH (FORMAT CSV, NULL '', HEADER);