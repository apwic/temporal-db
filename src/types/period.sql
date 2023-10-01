-- TODO: Define the valid perid type to be used in the temporal model [1]
CREATE TYPE valid_period AS (
    start_timestamp BIGINT,
    end_timestamp BIGINT
);

-- TODO: Add Allen's 13 interval relations [2]
CREATE FUNCTION temporal_before_than(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.end_timestamp < p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_after_than(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_meets(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.end_timestamp = p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_meets_inverse(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_overlaps(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp AND p1.end_timestamp > p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_overlaps_inverse(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp AND p1.start_timestamp < p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_starts(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_starts_inverse(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_during(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_during_inverse(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_finishes(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_finishes_inverse(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_equal(p1 valid_period, p2 valid_period)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;

-- Add the coalesce addition function [3]
CREATE FUNCTION temporal_addition(p1 valid_period, p2 valid_period)
RETURNS valid_period
LANGUAGE plpgsql
AS $$
-- TODO: Implement the coalesce addition function
$$;

-- Add the coalesce aggregation function [4]
CREATE AGGREGATE temporal_coalesce(valid_period) (
    sfunc = temporal_addition,
    stype = valid_period
);