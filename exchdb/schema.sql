DROP DATABASE IF EXISTS plato;
CREATE DATABASE plato;
USE plato;
GRANT ALL PRIVILEGES ON plato.* TO 'ec2-user'@'localhost';
set GLOBAL sql_mode='ALLOW_INVALID_DATES';

CREATE TABLE Exch (
    XID BIGINT NOT NULL AUTO_INCREMENT,                     -- unique id for this record
    Dt DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',     -- point in time when these values are valid
    Ticker VARCHAR(10) NOT NULL DEFAULT '',                 -- the two currencies involved in this exchange rate
    Open DECIMAL(19,4) NOT NULL DEFAULT 0,                  -- Opening value for this minute
    High DECIMAL(19,4) NOT NULL DEFAULT 0,                  -- High value during this minute
    Low DECIMAL(19,4) NOT NULL DEFAULT 0,                   -- Low value during this minute
    Close DECIMAL(19,4) NOT NULL DEFAULT 0,                 -- Closing value for this minute
    PRIMARY KEY(XID)
);

CREATE TABLE Item (
    IID BIGINT NOT NULL AUTO_INCREMENT,                     -- unique id for this record
    Title VARCHAR(128) NOT NULL DEFAULT '',                 -- Article title
    Description VARCHAR(1024) NOT NULL DEFAULT '',          -- Article description
    PubDt DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',  -- point in time when these values are valid
    Link VARCHAR(256) NOT NULL DEFAULT '',                  -- link to full article
    PRIMARY KEY(IID),                                       --
    UNIQUE (Link)                                           -- can't have multiple records with the same Link value
);
