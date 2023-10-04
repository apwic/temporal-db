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

-- Temporal customer insertion
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

-- Temporal staff insertion
CREATE PROCEDURE staff_insertion(
    input_name VARCHAR(255),
    input_employment_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
DECLARE
    found BOOLEAN;
    coalesced_period valid_period_domain;
BEGIN
    -- Check if the staff already exists
    SELECT EXISTS(
        SELECT 1
        FROM "staff"
        WHERE "staff"."name" = input_name
        AND temporal_can_merge("staff"."employment_period", input_employment_period)
    ) INTO found;

    IF found THEN
        -- Insert the new period
        INSERT INTO "staff" ("name", "employment_period")
        VALUES (input_name, input_employment_period);

        -- Get coalesced period
        WITH "temp_table" AS (
            SELECT temporal_coalesce_single("staff"."employment_period") AS "period"
            FROM "staff"
            WHERE "staff"."name" = input_name
            AND temporal_can_merge("staff"."employment_period", input_employment_period)
        )
        SELECT ("temp_table"."period").start_timestamp, ("temp_table"."period").end_timestamp
        INTO coalesced_period
        FROM "temp_table";

        -- Delete all the periods that overlap with the new one
        DELETE FROM "staff"
        WHERE "staff"."name" = input_name
        AND temporal_can_merge("staff"."employment_period", input_employment_period);

        -- Insert the new period
        INSERT INTO "staff" ("name", "employment_period")
        VALUES (input_name, coalesced_period);
    ELSE
        -- If the staff does not exist, insert it
        INSERT INTO "staff" ("name", "employment_period")
        VALUES (input_name, input_employment_period);
    END IF;

    -- Commit the transaction
    COMMIT;
END;
$$;

-- Temporal customer deletion
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

-- Temporal staff deletion
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

-- Temporal customer modification
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

-- Temporal staff modification
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
FROM "customer" 
JOIN "staff" ON temporal_can_intersect("customer"."subscription_period", "staff"."employment_period")
GROUP BY "customer"."name", "staff"."name";

-- Temporal Union: \pi_{name}^{B}(customer \cup^{B} staff)
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

-- Temporal Set Difference: \pi_{name}^{B}(staff) -^{B} \pi_{name}^{B}(customer)
WITH "difference_data" AS (
    SELECT "staff"."name"
    FROM "staff"
    EXCEPT
    SELECT "customer"."name"
    FROM "customer"
)
SELECT "staff"."name", temporal_coalesce_multiple("staff"."employment_period")
FROM "staff"
JOIN "difference_data" ON "staff"."name" = "difference_data"."name"
GROUP BY "staff"."name"
UNION
SELECT "staff"."name", temporal_section_multiple(temporal_difference("staff"."employment_period", "customer"."subscription_period"))
FROM "staff"
JOIN "customer" ON "staff"."name" = "customer"."name"
GROUP BY "staff"."name";

-- Temporal Time Slice: \tau_{3}^{B}(staff)
SELECT "staff"."name"
FROM "staff"
WHERE temporal_slice("staff"."employment_period", 3)
GROUP BY "staff"."name";