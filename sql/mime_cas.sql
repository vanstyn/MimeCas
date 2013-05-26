/*
  2013-05-18 bu Henry Van Styn
  
  This is an idea I had for a Schema/Data Model for storing
  MIME entities/E-Mail messages in a CAS (Content-addressed storage)
  
  In progress/brainstorming...
*/

/* MimeCas::Schema ? */

/* CAS table for raw data storage of MIME objects */
DROP TABLE IF EXISTS `mime_object`;
CREATE TABLE IF NOT EXISTS `mime_object` (
  `sha1` char(40) NOT NULL,
  `content` longtext NOT NULL,
  
  /* bool if the content was parsed as valid MIME */
  `parsed` tinyint(1) NOT NULL DEFAULT 0,
  
  /* Email::MIME error message if it couldn't be parsed */
  `parse_error` text DEFAULT NULL,
  
  /* children is a cache column - should be set according to 
   the `parent_sha1` count in mime_graph below. A value of 0
   means this object is like a git 'blob' while a value of 1
   or more means it is like a git 'tree'. Like in git, the tree
   content will be a list list of sha1s of child objects */
  `direct_children` tinyint unsigned NOT NULL DEFAULT 0,
  `all_children` tinyint unsigned NOT NULL DEFAULT 0,
  
  /* the size including all parts and the size actually stored in this row */
  `virtual_size` int DEFAULT NULL,
  `actual_size` int DEFAULT NULL,
  
  /* TEMP FOR DEBUG ONLY! REMOVE (or the whole de-duplication feature is gone) */
  /* `original` longtext DEFAULT NULL, */
  
  PRIMARY KEY  (`sha1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* In addition to the 1-way refs (DAG) like in Git, as stored in the
 `mime_object`.`content` column above, we'll also index both directions of refs.
 This is how we will walk the graph; the sha1s in `content` will only
 be used to calculate the 'tree' object sha1 (sha1 based on child sha1s, just
 like in Git). */
DROP TABLE IF EXISTS `mime_graph`;
CREATE TABLE IF NOT EXISTS `mime_graph` (
  `child_sha1` char(40) NOT NULL,
  `parent_sha1` char(40) NOT NULL,
  `order` tinyint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY  (`child_sha1`,`parent_sha1`),
  FOREIGN KEY (`child_sha1`) REFERENCES `mime_object` (`sha1`),
  FOREIGN KEY (`parent_sha1`) REFERENCES `mime_object` (`sha1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* Every table from here on is essentially cache that can be calculated
 from the data stored above, or extra overlays/refs that use the above 
 tables as storage (for instance, a mailbox folder tree)
 */
 
 
/* These are the 1-to-1 attributes that we consider important enough 
 to have their own column/indexes. These may come directly from the headers
 (which are stored as property/value *rows*) or may be any transformed datapoint
 extracted from the mime data
*/
DROP TABLE IF EXISTS `mime_attribute`;
CREATE TABLE IF NOT EXISTS `mime_attribute` (
  `sha1` char(40) NOT NULL,
  
  /* TODO: lookup the real max length should be for MIME type/subtype */
  `type` varchar(64) DEFAULT NULL,
  `subtype` varchar(128) DEFAULT NULL,
  
  `message_id` varchar(255) default NULL,
  
  /* This is the date that we'll normalize out of headers 
   (sent, received, converted time format) */
  `date` datetime default NULL,
  
  /* This is the extracted/normalized e-mail address, not the full from header which
   can contain display name string. Should be lowercased */
  `from_addr` varchar(255) default NULL,
  
  `subject` varchar(512) default NULL,
  
  `debug_structure` text,
  
  /* TODO: add more attributes as I think of them */

  /* The timestamp the MySQL row was updated/created (not from the MIME object) */
  `row_ts` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY  (`sha1`),
  KEY (`message_id`),
  KEY (`date`),
  KEY (`from_addr`),
  KEY (`subject`),
  FOREIGN KEY (`sha1`) REFERENCES `mime_object` (`sha1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 

/* MIME Headers */
DROP TABLE IF EXISTS `mime_header`;
CREATE TABLE IF NOT EXISTS `mime_header` (
  `sha1` char(40) NOT NULL,
  `order` tinyint unsigned NOT NULL DEFAULT 0,
  
  /* name should be normalized/lowercased. This is just an index; the original
   headers can always be retrieved from the original MIME content */
  `name` varchar(255) NOT NULL,
  `value` varchar(1024) NOT NULL,
  
  /* Since there can be multiple headers of the same name, our primary key 
   is the sha1 + order which is essentially an array/list instead of a
   hash/object */
  PRIMARY KEY  (`sha1`,`order`),
  
  KEY (`name`),
  FOREIGN KEY (`sha1`) REFERENCES `mime_object` (`sha1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* tracking/indexing of message recipients */
DROP TABLE IF EXISTS `mime_recipient`;
CREATE TABLE IF NOT EXISTS `mime_recipient` (
  `sha1` char(40) NOT NULL,
  `order` tinyint unsigned NOT NULL DEFAULT 0,
  
  /* normalized/lowercased  */
  `addr` varchar(255) NOT NULL,
  
  /* Bool if this was in the CC field rather than To field */
  `cc` tinyint(1) unsigned NOT NULL default 0,
  
  /* This is a normalized map, so there won't be duplicate addresses even
   though there could be in the actual headers*/
  PRIMARY KEY  (`sha1`,`addr`),
  KEY (`addr`),
  FOREIGN KEY (`sha1`) REFERENCES `mime_object` (`sha1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/* Now we'll define some tables that use the above as storage. 
 These are optional */
 
DROP TABLE IF EXISTS `mailbox`;
CREATE TABLE IF NOT EXISTS `mailbox` (
  `id` int(11) unsigned NOT NULL auto_increment,
  
  /* generic/conceptual ... could be server name, username, uri, etc */
  `realm` varchar(255) NOT NULL DEFAULT '(default)',
  
  /* TODO: add other desired mailbox attributes/info */
  
  `name` varchar(255) NOT NULL,
  
  PRIMARY KEY (`id`),
  UNIQUE KEY (`realm`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
DROP TABLE IF EXISTS `mail_folder`;
CREATE TABLE IF NOT EXISTS `mail_folder` (
  `id` int(11) unsigned NOT NULL auto_increment,
  
  /* parent folder. Only root folders should be null */
  `parent_id` int(11) unsigned DEFAULT NULL,
  `order` tinyint unsigned NOT NULL DEFAULT 0,
  
  /* This could also be an ID to a mailbox table with 
   addition realm/context infp */
  `mailbox_id` int(11) unsigned NOT NULL,
  
  `name` varchar(255) NOT NULL,

  PRIMARY KEY  (`id`),
  UNIQUE KEY(`mailbox_id`,`parent_id`,`name`),
  FOREIGN KEY (`mailbox_id`) REFERENCES `mailbox` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE `mail_folder` ADD FOREIGN KEY (`parent_id`) REFERENCES `mail_folder` (`id`);

/* This is basically like a hard-link on a Linux filsystem. But
 instead of pointing to an inode address we point to a CAS (sha1) address */
DROP TABLE IF EXISTS `mail_message`;
CREATE TABLE IF NOT EXISTS `mail_message` (
  `id` int(11) unsigned NOT NULL auto_increment,
  
  /* parent folder */
  `folder_id` int(11) unsigned NOT NULL,
  `order` tinyint unsigned NOT NULL DEFAULT 0,
  
  /* CAS address of the content */
  `sha1` char(40) NOT NULL,

  PRIMARY KEY  (`id`),
  FOREIGN KEY (`folder_id`) REFERENCES `mail_folder` (`id`),
  FOREIGN KEY (`sha1`) REFERENCES `mime_object` (`sha1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


