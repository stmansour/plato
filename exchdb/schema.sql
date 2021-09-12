DROP DATABASE IF EXISTS exch;
CREATE DATABASE exch;
USE exch;
GRANT ALL PRIVILEGES ON exch.* TO 'ec2-user'@'localhost';
set GLOBAL sql_mode='ALLOW_INVALID_DATES';

CREATE TABLE Exch (
    XID BIGINT NOT NULL DEFAULT 0,                          -- unique id for this record
    Dt DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',     -- point in time when these values are valid
    Ticker VARCHAR(10) NOT NULL DEFAULT '',                 -- the two currencies involved in this exchange rate
    Open DECIMAL(19,4) NOT NULL DEFAULT 0,                  -- Opening value for this minute
    High DECIMAL(19,4) NOT NULL DEFAULT 0,                  -- High value during this minute
    Low DECIMAL(19,4) NOT NULL DEFAULT 0,                   -- Low value during this minute
    Close DECIMAL(19,4) NOT NULL DEFAULT 0,                 -- Closing value for this minute
    PRIMARY KEY(XID)
);
