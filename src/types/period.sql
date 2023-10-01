-- TODO: Define the valid perid type to be used in the temporal model [1]
CREATE TYPE valid_period AS (
    start_timestamp BIGINT,
    end_timestamp BIGINT
);

CREATE DOMAIN valid_period_domain AS valid_period
CHECK (
    (VALUE).start_timestamp < (VALUE).end_timestamp
);

-- TODO: Add Allen's 13 interval relations [2]
CREATE FUNCTION temporal_before_than(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.end_timestamp < p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_after_than(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_meets(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.end_timestamp = p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_meets_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_overlaps(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp AND p1.end_timestamp > p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_overlaps_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp AND p1.start_timestamp < p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_starts(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_starts_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_during(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_during_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_finishes(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_finishes_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;

CREATE FUNCTION temporal_equal(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.start_timestamp AND p1.end_timestamp = p2.end_timestamp;
END;
$$;

-- Add the coalesce addition function [3]
CREATE FUNCTION temporal_merge(p1 valid_period_domain, p2 valid_period_domain)
RETURNS valid_period_domain
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (LEAST(p1.start_timestamp, p2.start_timestamp), GREATEST(p1.end_timestamp, p2.end_timestamp))::valid_period_domain;
END;
$$;

CREATE FUNCTION temporal_intersection(p1 valid_period_domain, p2 valid_period_domain)
RETURNS valid_period_domain
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (GREATEST(p1.start_timestamp, p2.start_timestamp), LEAST(p1.end_timestamp, p2.end_timestamp))::valid_period_domain;
END;
$$;

CREATE FUNCTION temporal_difference(p1 valid_period_domain, p2 valid_period_domain)
RETURNS valid_period_domain[]
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Implement the difference function
END;
$$;

CREATE FUNCTION temporal_addition(pArr valid_period_domain[], pNew valid_period_domain)
RETURNS valid_period_domain[]
LANGUAGE plpgsql
AS $$
DECLARE
    pArrResult valid_period_domain[] := '{}';
    pIter valid_period_domain;
BEGIN
    FOREACH pIter IN ARRAY pArr LOOP
        -- If the new period is not intersecting, then append the existing period to the result
        IF temporal_before_than(pIter, pNew) OR temporal_after_than(pIter, pNew) THEN
            pArrResult := pArrResult || pIter;
        ELSE -- Otherwise, merge the new period with the existing period
            pNew := temporal_merge(pIter, pNew);
        END IF;
    END LOOP;

    -- Append the new period to the result
    RETURN pArrResult || pNew;
END;
$$;

-- Add the coalesce aggregation function [4]
CREATE AGGREGATE temporal_coalesce(valid_period_domain) (
    sfunc = temporal_addition,
    stype = valid_period_domain[],
    initcond = '{}'
);