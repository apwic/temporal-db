-- Define the valid perid type to be used in the temporal model [1]
CREATE TYPE valid_period AS (
    start_timestamp BIGINT,
    end_timestamp BIGINT
);

CREATE DOMAIN valid_period_domain AS valid_period
CHECK (
    (VALUE).start_timestamp <= (VALUE).end_timestamp
);

-- Add Allen's 13 interval relations [2]
CREATE FUNCTION temporal_before_than(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.end_timestamp + 1 < p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_after_than(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.end_timestamp + 1;
END;
$$;

CREATE FUNCTION temporal_meets(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.end_timestamp + 1 = p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_meets_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp = p2.end_timestamp + 1;
END;
$$;

CREATE FUNCTION temporal_overlaps(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp < p2.start_timestamp AND p1.end_timestamp < p2.end_timestamp AND p1.end_timestamp >= p2.start_timestamp;
END;
$$;

CREATE FUNCTION temporal_overlaps_inverse(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p1.start_timestamp > p2.start_timestamp AND p1.end_timestamp > p2.end_timestamp AND p1.start_timestamp <= p2.end_timestamp;
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
CREATE FUNCTION temporal_can_merge(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN NOT temporal_before_than(p1, p2) AND NOT temporal_after_than(p1, p2);
END;
$$;

CREATE FUNCTION temporal_merge(p1 valid_period_domain, p2 valid_period_domain)
RETURNS valid_period_domain
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN (LEAST(p1.start_timestamp, p2.start_timestamp), GREATEST(p1.end_timestamp, p2.end_timestamp))::valid_period_domain;
END;
$$;

CREATE FUNCTION temporal_can_intersect(p1 valid_period_domain, p2 valid_period_domain)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN NOT temporal_before_than(p1, p2)
    AND NOT temporal_after_than(p1, p2)
    AND NOT temporal_meets(p1, p2)
    AND NOT temporal_meets_inverse(p1, p2);
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
    IF temporal_can_intersect(p1, p2) THEN
        IF temporal_overlaps(p1, p2) THEN
            RETURN ARRAY[(p1.start_timestamp, p2.start_timestamp - 1)::valid_period_domain];
        ELSIF temporal_overlaps_inverse(p1, p2) THEN
            RETURN ARRAY[(p2.end_timestamp + 1, p1.end_timestamp)::valid_period_domain];
        ELSIF temporal_starts_inverse(p1, p2) THEN
            RETURN ARRAY[(p2.end_timestamp + 1, p1.end_timestamp)::valid_period_domain];
        ELSIF temporal_during_inverse(p1, p2) THEN
            RETURN ARRAY[(p1.start_timestamp, p2.start_timestamp - 1)::valid_period_domain, (p2.end_timestamp + 1, p1.end_timestamp)::valid_period_domain];
        ELSIF temporal_finishes_inverse(p1, p2) THEN
            RETURN ARRAY[(p1.start_timestamp, p2.start_timestamp - 1)::valid_period_domain];
        ELSE
            RETURN ARRAY[]::valid_period_domain[];
        END IF;
    ELSE
        RETURN ARRAY[p1];
    END IF;
END;
$$;

CREATE FUNCTION temporal_merge_to_array(pArr valid_period_domain[], pNew valid_period_domain)
RETURNS valid_period_domain[]
LANGUAGE plpgsql
AS $$
DECLARE
    pArrResult valid_period_domain[] := '{}';
    pIter valid_period_domain;
BEGIN
    FOREACH pIter IN ARRAY pArr LOOP
        -- If the new period can be merged with the current one, merge them
        IF temporal_can_merge(pIter, pNew) THEN
            pNew := temporal_merge(pIter, pNew);
        ELSE -- If not, append the current period to the result
            pArrResult := pArrResult || pIter;
        END IF;
    END LOOP;

    -- Append the new period to the result
    RETURN pArrResult || pNew;
END;
$$;

CREATE FUNCTION temporal_merge_to_array(pArr valid_period_domain[], pArrNew valid_period_domain[])
RETURNS valid_period_domain[]
LANGUAGE plpgsql
AS $$
DECLARE
    pArrResult valid_period_domain[];
    pIter valid_period_domain;
BEGIN
    -- Initialize the result array
    pArrResult := pArr;

    -- Merge the new periods with the current ones
    FOREACH pIter IN ARRAY pArrNew LOOP
        pArrResult := temporal_merge_to_array(pArrResult, pIter);
    END LOOP;

    -- Return the result
    RETURN pArrResult;
END;
$$;

CREATE FUNCTION temporal_intersect_to_array(pArr valid_period_domain[], pNew valid_period_domain)
RETURNS valid_period_domain[]
LANGUAGE plpgsql
AS $$
DECLARE
    pArrResult valid_period_domain[] := '{}';
    pIter valid_period_domain;
BEGIN
    -- If the current array is empty, return the new period
    IF pArr IS NULL THEN
        RETURN ARRAY[pNew];
    END IF;

    FOREACH pIter IN ARRAY pArr LOOP
        -- If the new period can be intersected with the current one, intersect them
        IF temporal_can_intersect(pIter, pNew) THEN
            pArrResult := pArrResult || temporal_intersection(pIter, pNew);
        END IF;
    END LOOP;

    -- Return the result
    RETURN pArrResult;
END;
$$;

CREATE FUNCTION temporal_intersect_to_array(pArr valid_period_domain[], pArrNew valid_period_domain[])
RETURNS valid_period_domain[]
LANGUAGE plpgsql
AS $$
DECLARE
    pArrResult valid_period_domain[] = '{}';
    pIter valid_period_domain;
BEGIN
    -- If the current array is empty, return the new period
    IF pArr IS NULL THEN
        RETURN pArrNew;
    END IF;

    -- Intersect the new periods with the current ones
    FOREACH pIter IN ARRAY pArrNew LOOP
        pArrResult := pArrResult || temporal_intersect_to_array(pArr, pIter);
    END LOOP;

    -- Return the result
    RETURN pArrResult;
END;
$$;

-- Add the coalesce aggregation function [4]
CREATE AGGREGATE temporal_coalesce_single(valid_period_domain) (
    sfunc = temporal_merge,
    stype = valid_period_domain
);

CREATE AGGREGATE temporal_coalesce_multiple(valid_period_domain) (
    sfunc = temporal_merge_to_array,
    stype = valid_period_domain[],
    initcond = '{}'
);

CREATE AGGREGATE temporal_coalesce_multiple(valid_period_domain[]) (
    sfunc = temporal_merge_to_array,
    stype = valid_period_domain[],
    initcond = '{}'
);

CREATE AGGREGATE temporal_section_single(valid_period_domain) (
    sfunc = temporal_intersection,
    stype = valid_period_domain
);

CREATE AGGREGATE temporal_section_multiple(valid_period_domain) (
    sfunc = temporal_intersect_to_array,
    stype = valid_period_domain[]
);

CREATE AGGREGATE temporal_section_multiple(valid_period_domain[]) (
    sfunc = temporal_intersect_to_array,
    stype = valid_period_domain[]
);

-- Add the slice function [5]
CREATE FUNCTION temporal_slice(p valid_period_domain, input_timestamp BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p.start_timestamp <= input_timestamp AND p.end_timestamp >= input_timestamp;
END;
$$;