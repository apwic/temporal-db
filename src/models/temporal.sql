-- Define the temporal model with "id" as primary key [5]
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

-- Add following procedures [6]

-- TODO: Temporal insertion
-- TODO: Temporal deletion
-- TODO: Temporal modification

-- Add example relational algebra queries [7]

-- Temporal Projection: \pi_{name}^{B}(customer)
SELECT "customer"."name", temporal_coalesce("customer"."subscription_period")
FROM "customer"
GROUP BY "customer"."name";

-- Temporal Selection: \sigma_{name = 'Anca'}^{B}(staff)
SELECT "staff"."id", "staff"."name", temporal_coalesce("staff"."employment_period")
FROM "staff"
WHERE "staff"."name" = 'Anca'
GROUP BY "staff"."id";

-- Temporal Join: customer \bowtie^{B} staff
SELECT "customer"."id" AS "customer_id", "customer"."name" AS "customer_name", "staff"."id" AS "staff_id", "staff"."name" AS "staff_name", temporal_coalesce(temporal_intersection("customer"."subscription_period", "staff"."employment_period"))
FROM "customer", "staff"
WHERE (
    NOT temporal_before_than("customer"."subscription_period", "staff"."employment_period")
    AND
    NOT temporal_after_than("customer"."subscription_period", "staff"."employment_period")
)
GROUP BY "customer"."id", "staff"."id";

-- TODO: Temporal union (use coalesce)
-- TODO: Temporary set difference (use difference)
-- TODO: Temporal time slice (use slice function)