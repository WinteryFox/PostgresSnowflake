\echo Use "CREATE EXTENSION snowflake" TO LOAD THIS FILE. \quit
CREATE FUNCTION next_snowflake(nodeId BIGINT, epoch TIMESTAMP)
    RETURNS BIGINT
    LANGUAGE plpgsql
    IMMUTABLE STRICT
AS
$$
DECLARE
    -- Constants
    nodeIdBits   CONSTANT INT    := 10;
    sequenceBits CONSTANT INT    := 12;
    --maxNodeId    CONSTANT BIGINT := (1::BIGINT::BIT << nodeIdBits) - 1;
    --maxSequence  CONSTANT BIGINT := 1::BIGINT::BIT << 12;
BEGIN
    -- TODO: Does not keep track of sequence or time skipping backwards
    RETURN (extract(MILLISECONDS FROM epoch)::BIT << (nodeIdBits + sequenceBits) || (nodeId << sequenceBits));
END;
$$;