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
    name VARCHAR(255),
    subscription_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Handle kasus ketika name sudah ada (update valid period or do nothing)
    INSERT INTO "customer" ("name", "subscription_period") VALUES (name, subscription_period);
    COMMIT;
END;
$$;

CREATE PROCEDURE staff_insertion(
    name VARCHAR(255),
    employment_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Handle kasus ketika name sudah ada (update valid period or do nothing)
    INSERT INTO "staff" ("name", "employment_period") VALUES (name, employment_period);
    COMMIT;
END;
$$;

-- Temporal deletion
CREATE PROCEDURE customer_deletion(
    name VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "customer" WHERE "name" = name;
    COMMIT;
END;
$$;

CREATE PROCEDURE staff_deletion(
    name VARCHAR(255)
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "staff" WHERE "name" = name;
    COMMIT;
END;
$$;

-- Temporal modification
CREATE PROCEDURE customer_modification(
    name VARCHAR(255),
    subscription_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "customer" SET "subscription_period" = subscription_period WHERE "name" = name;
    COMMIT;
END;
$$;

CREATE PROCEDURE staff_modification(
    name VARCHAR(255),
    employment_period valid_period_domain
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "staff" SET "employment_period" = employment_period WHERE "name" = name;
    COMMIT;
END;
$$;

-- Add example relational algebra queries [8]

-- Temporal Projection: \pi_{name}^{B}(customer)
SELECT "customer"."name", temporal_coalesce("customer"."subscription_period")
FROM "customer"
GROUP BY "customer"."name";

-- Temporal Selection: \sigma_{name = 'Anca'}^{B}(staff)
SELECT "staff"."id", "staff"."name", temporal_coalesce("staff"."employment_period")
FROM "staff"
WHERE "staff"."name" = 'Anca'
GROUP BY "staff"."id";

-- Temporal Join: \pi_{name}^{B}(customer \bowtie^{B} staff)
SELECT "customer"."name" AS "customer_name", "staff"."name" AS "staff_name", temporal_coalesce(temporal_intersection("customer"."subscription_period", "staff"."employment_period"))
FROM "customer", "staff"
WHERE (
    NOT temporal_before_than("customer"."subscription_period", "staff"."employment_period")
    AND
    NOT temporal_after_than("customer"."subscription_period", "staff"."employment_period")
)
GROUP BY "customer"."name", "staff"."name";

-- Temporal Union (use coalesce): \pi_{name}^{B}(customer \cup^{B} staff)
WITH "union_data" AS (
    SELECT "customer"."name", "customer"."subscription_period" AS "period"
    FROM "customer"
    UNION
    SELECT "staff"."name", "staff"."employment_period" AS "period"
    FROM "staff"
)
SELECT "union_data"."name", temporal_coalesce("union_data"."period")
FROM "union_data"
GROUP BY "union_data"."name";

-- TODO: Temporary Set Difference (use difference)

-- Temporal Time Slice: \tau_{3}^{B}(staff)
SELECT "staff"."name"
FROM "staff"
WHERE temporal_slice("staff"."employment_period", 3)
GROUP BY "staff"."name";