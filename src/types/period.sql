-- TODO: Define the valid perid type to be used in the temporal model [1]
CREATE TYPE valid_period AS (
    start_timestamp TIMESTAMP,
    end_timestamp TIMESTAMP
);