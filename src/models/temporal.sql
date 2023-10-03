-- Define the temporal model with "id" as primary key [6]
CREATE TABLE customer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    subscription_period valid_period_domain NOT NULL
);

CREATE TABLE staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    employment_period valid_period_domain NOT NULL
);

-- Add following procedures [7]

-- Temporal insertion
CREATE PROCEDURE customer_insertion(
    input_name VARCHAR(255),
    input_subscription_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
DECLARE
    found BOOLEAN;
    coalesced_period valid_period_domain;
BEGIN
    -- Check if the customer already exists
    SELECT EXISTS(
        SELECT 1
        FROM "customer"
        WHERE "customer"."name" = input_name
        AND temporal_can_merge("customer"."subscription_period", input_subscription_period)
    ) INTO found;

    IF found THEN
        -- Insert the new period
        INSERT INTO "customer" ("name", "subscription_period")
        VALUES (input_name, input_subscription_period);

        -- Get coalesced period
        WITH "temp_table" AS (
            SELECT temporal_coalesce_single("customer"."subscription_period") AS "period"
            FROM "customer"
            WHERE "customer"."name" = input_name
            AND temporal_can_merge("customer"."subscription_period", input_subscription_period)
        )
        SELECT ("temp_table"."period").start_timestamp, ("temp_table"."period").end_timestamp 
        INTO coalesced_period
        FROM "temp_table";

        -- Delete all the periods that overlap with the new one
        DELETE FROM "customer"
        WHERE "customer"."name" = input_name
        AND temporal_can_merge("customer"."subscription_period", input_subscription_period);

        -- Insert the new period
        INSERT INTO "customer" ("name", "subscription_period")
        VALUES (input_name, coalesced_period);
    ELSE
        -- If the customer does not exist, insert it
        INSERT INTO "customer" ("name", "subscription_period")
        VALUES (input_name, input_subscription_period);
    END IF;

    -- Commit the transaction
    COMMIT;
END;
$$;

CREATE PROCEDURE staff_insertion(
    input_name VARCHAR(255),
    input_employment_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Commit the transaction
    COMMIT;
END;
$$;

-- Temporal deletion
CREATE PROCEDURE customer_deletion(
    input_name VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "customer" WHERE "customer"."name" = input_name;
    COMMIT;
END;
$$;

CREATE PROCEDURE staff_deletion(
    input_name VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "staff" WHERE "staff"."name" = input_name;
    COMMIT;
END;
$$;

-- Temporal modification
CREATE PROCEDURE customer_modification(
    input_name VARCHAR(255),
    input_subscription_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Call the deletion and insertion procedures
    CALL customer_deletion(input_name);
    CALL customer_insertion(input_name, input_subscription_period);

    -- Commit the transaction
    COMMIT;
END;
$$;

CREATE PROCEDURE staff_modification(
    input_name VARCHAR(255),
    input_employment_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Call the deletion and insertion procedures
    CALL staff_deletion(input_name);
    CALL staff_insertion(input_name, input_employment_period);

    -- Commit the transaction
    COMMIT;
END;
$$;

-- Add example relational algebra queries [8]

-- Temporal Projection: \pi_{name}^{B}(customer)
SELECT "customer"."name", temporal_coalesce_multiple("customer"."subscription_period")
FROM "customer"
GROUP BY "customer"."name";

-- Temporal Selection: \sigma_{name = 'Anca'}^{B}(staff)
SELECT "staff"."id", "staff"."name", temporal_coalesce_multiple("staff"."employment_period")
FROM "staff"
WHERE "staff"."name" = 'Anca'
GROUP BY "staff"."id";

-- Temporal Join: \pi_{name}^{B}(customer \bowtie^{B} staff)
SELECT "customer"."name" AS "customer_name", "staff"."name" AS "staff_name", temporal_coalesce_multiple(temporal_intersection("customer"."subscription_period", "staff"."employment_period"))
FROM "customer", "staff"
WHERE temporal_can_intersect("customer"."subscription_period", "staff"."employment_period")
GROUP BY "customer"."name", "staff"."name";

-- Temporal Union (use coalesce): \pi_{name}^{B}(customer \cup^{B} staff)
WITH "union_data" AS (
    SELECT "customer"."name", "customer"."subscription_period" AS "period"
    FROM "customer"
    UNION
    SELECT "staff"."name", "staff"."employment_period" AS "period"
    FROM "staff"
)
SELECT "union_data"."name", temporal_coalesce_multiple("union_data"."period")
FROM "union_data"
GROUP BY "union_data"."name";

-- TODO: Temporary Set Difference (use difference)

-- Temporal Time Slice: \tau_{3}^{B}(staff)
SELECT "staff"."name"
FROM "staff"
WHERE temporal_slice("staff"."employment_period", 3)
GROUP BY "staff"."name";