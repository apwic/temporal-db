-- Define the temporal model with "id" as primary key [5]
CREATE TABLE temporal_model (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    temporal_data valid_period NOT NULL
);

-- Add temporal projection, selection (possibly same with relational), union, set difference, join, and time slice functions [6]
-- TODO: Implement all of those functions