--     Database:  plato
--
--     Field names are camel case
--     Money values are all stored as DECIMAL(19,4)

DROP DATABASE IF EXISTS plato;
CREATE DATABASE plato;
USE plato;
-- GRANT ALL PRIVILEGES ON plato.* TO 'ec2-user'@'localhost';
-- GRANT ALL PRIVILEGES ON plato.* TO 'adbuser'@'%';
set GLOBAL sql_mode='ALLOW_INVALID_DATES';


CREATE TABLE Exch (
    XID BIGINT NOT NULL AUTO_INCREMENT,                     -- unique id for this record
    Dt DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',     -- point in time when these values are valid
    Ticker VARCHAR(10) NOT NULL DEFAULT '',                 -- the two currencies involved in this exchange rate
    Open DECIMAL(19,4) NOT NULL DEFAULT 0,                  -- Opening value for this minute
    High DECIMAL(19,4) NOT NULL DEFAULT 0,                  -- High value during this minute
    Low DECIMAL(19,4) NOT NULL DEFAULT 0,                   -- Low value during this minute
    Close DECIMAL(19,4) NOT NULL DEFAULT 0,                 -- Closing value for this minute
    LastModTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- when was this record last written
    LastModBy BIGINT NOT NULL DEFAULT 0,                        -- employee UID (from phonebook) that modified it
    CreateTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,    -- when was this record created
    CreateBy BIGINT NOT NULL DEFAULT 0,                         -- employee UID (from phonebook) that created this record
    CONSTRAINT Alpha UNIQUE(Dt,Ticker),                     -- ensure we don't save more than one of these
    PRIMARY KEY(XID)
);

CREATE TABLE Item (
    IID BIGINT NOT NULL AUTO_INCREMENT,                     -- unique id for this record
    Title VARCHAR(128) NOT NULL DEFAULT '',                 -- Article title
    Description VARCHAR(1024) NOT NULL DEFAULT '',          -- Article description
    PubDt DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',  -- point in time when these values are valid
    Link VARCHAR(256) NOT NULL DEFAULT '',                  -- link to full article
    LastModTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- when was this record last written
    LastModBy BIGINT NOT NULL DEFAULT 0,                    -- employee UID (from phonebook) that modified it
    CreateTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,-- when was this record created
    CreateBy BIGINT NOT NULL DEFAULT 0,                     -- employee UID (from phonebook) that created this record
    PRIMARY KEY(IID),                                       --
    UNIQUE (Link)                                           -- can't have multiple records with the same Link value
);

CREATE TABLE RSSFeed (
    RSSID BIGINT NOT NULL AUTO_INCREMENT,                   -- unique id for this record
    URL VARCHAR(512) NOT NULL DEFAULT '',                  -- link to the RSS Feed
    FLAGS BIGINT NOT NULL DEFAULT 0,                        -- no flags defined yet
    LastModTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- when was this record last written
    LastModBy BIGINT NOT NULL DEFAULT 0,                    -- employee UID (from phonebook) that modified it
    CreateTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,-- when was this record created
    CreateBy BIGINT NOT NULL DEFAULT 0,                     -- employee UID (from phonebook) that created this record
    PRIMARY KEY(RSSID),                                     --
    UNIQUE (URL)                                            -- can't have multiple records with the same Link value
);

CREATE TABLE ItemFeed (
    IFID BIGINT NOT NULL AUTO_INCREMENT,                    -- unique id for this record
    IID BIGINT NOT NULL DEFAULT 0,                          -- The Item
    RSSID BIGINT NOT NULL DEFAULT 0,                        -- The RSSFeed that called it out
    PRIMARY KEY(IFID),
    CONSTRAINT Beta UNIQUE(IID,RSSID)                       -- can't have multiple records with the same IID and RSSID value
);
