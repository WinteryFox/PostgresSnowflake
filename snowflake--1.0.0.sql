\echo Use "CREATE EXTENSION snowflake" to load this file. \quit
CREATE OR REPLACE FUNCTION next_snowflake(nodeId BIGINT, epoch TIMESTAMP)
    RETURNS BIGINT
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS
$$
DECLARE
    -- Constants
    sequenceBits CONSTANT SMALLINT := 10;
    nodeIdBits   CONSTANT SMALLINT := 12;
    maxNodeId    CONSTANT BIGINT   := (1::BIT(64) << nodeIdBits)::BIT(64)::BIGINT - 1;
    stamp        CONSTANT BIGINT   := extract(EPOCH FROM (CURRENT_TIMESTAMP - epoch))::BIGINT * 1000;
    --maxSequence  CONSTANT BIGINT := 1::BIGINT::BIT(64) << 12;
BEGIN
    -- TODO: Does not keep track of sequence or time skipping backwards
    IF (nodeId < 0 OR nodeId > maxNodeId) THEN
        RAISE EXCEPTION 'nodeId cannot be less than 0 or greater than %', maxNodeId;
    END IF;

    RETURN (stamp::BIT(64) << (nodeIdBits + sequenceBits) |
            (nodeId::BIT(64) << sequenceBits)::BIT(64))::BIT(64)::BIGINT;
END;
$$;

CREATE OR REPLACE FUNCTION snowflake_node_id(snowflake BIGINT)
    RETURNS BIGINT
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS
$$
DECLARE
    -- Constants
    sequenceBits CONSTANT SMALLINT := 10;
    nodeIdBits   CONSTANT SMALLINT := 12;
    maskNodeId   CONSTANT BIT(64)  := ((1::BIGINT::BIT(64) << nodeIdBits)::BIGINT - 1)::BIGINT::BIT(64) << sequenceBits;
BEGIN
    RETURN ((snowflake::BIT(64) & maskNodeId) >> sequenceBits)::BIGINT;
END;
$$;

CREATE OR REPLACE FUNCTION snowflake_timestamp(snowflake BIGINT, epoch TIMESTAMP)
    RETURNS TIMESTAMP
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS
$$
DECLARE
    -- Constants
    sequenceBits CONSTANT SMALLINT := 10;
    nodeIdBits   CONSTANT SMALLINT := 12;
BEGIN
    RETURN epoch + ((snowflake::BIT(64) >> (nodeIdBits + sequenceBits))::BIGINT / 1000)::BIGINT::TEXT::INTERVAL;
END;
$$;