-- for Postgres change int NOT NULL AUTO_INCREMENT to serial

-- for MySQL
SET storage_engine=INNODB;

drop table if exists result;
drop table if exists goal;
drop table if exists pageview;
drop table if exists genome_variant_link;
drop table if exists variant;
drop table if exists gene;
drop table if exists genome;
drop table if exists referrer;
drop table if exists error;
drop table if exists visitor;
drop table if exists page;
drop table if exists domain;
--
-- Table structure for table domain
--
CREATE TABLE domain (
  domain_id int NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  PRIMARY KEY  (domain_id),
  UNIQUE (name)
);


--
-- Table structure for table error
--
CREATE TABLE error (
  error_id int NOT NULL AUTO_INCREMENT,
  page_id int NOT NULL,
  visitor_id int NOT NULL,
  message varchar(255) NOT NULL,
  line_number int NOT NULL,
  timestamp timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (error_id)
);
CREATE INDEX page_id_error ON error (page_id);
CREATE INDEX visitor_id_error ON error (visitor_id);


--
-- Table structure for table gene
--
CREATE TABLE gene (
  gene_id int NOT NULL AUTO_INCREMENT,
  page_id int NOT NULL,
  name varchar(255),
  PRIMARY KEY  (gene_id),
  UNIQUE (page_id,name)
);


--
-- Table structure for table genome
--
CREATE TABLE genome (
  genome_id int NOT NULL AUTO_INCREMENT,
  page_id int NOT NULL, 
  hash varchar(255) NOT NULL,
  PRIMARY KEY  (genome_id),
  UNIQUE (page_id,hash)
);


--
-- Table structure for table genome_variant_link
--
CREATE TABLE genome_variant_link (
  genome_variant_link_id int NOT NULL AUTO_INCREMENT,
  genome_id int NOT NULL,
  variant_id int NOT NULL,
  PRIMARY KEY  (genome_variant_link_id),
  UNIQUE (genome_id,variant_id)
);


--
-- Table structure for table goal
--
CREATE TABLE goal (
  goal_id int NOT NULL AUTO_INCREMENT,
  name varchar(255) NOT NULL,
  value int NOT NULL,
  pageview_xid bigint NOT NULL,
  PRIMARY KEY  (goal_id)
);
CREATE INDEX pageview_xid_goal ON goal (pageview_xid);


--
-- Table structure for table page
--
CREATE TABLE page (
  page_id int NOT NULL AUTO_INCREMENT,
  domain_id int NOT NULL,
  name varchar(255),
  PRIMARY KEY  (page_id),
  UNIQUE (domain_id,name)
);


--
-- Table structure for table pageview
--
CREATE TABLE pageview (
  pageview_id int NOT NULL AUTO_INCREMENT,
  pageview_xid bigint NOT NULL,
  page_id int NOT NULL,
  visitor_id int NOT NULL,
  referrer_id int default NULL,
  genome_id int NOT NULL,
  vary_call varchar(255),
  load_time int NOT NULL,
  init_time int NOT NULL,
results_time int,
idle_time int,
vary_time int,
  timestamp timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (pageview_id),
  UNIQUE (pageview_xid)
);                       
CREATE INDEX page_id_pageview ON pageview (page_id);
CREATE INDEX visitor_id_pageview ON pageview (visitor_id);
CREATE INDEX referrer_id_pageview ON pageview (referrer_id);
CREATE INDEX genome_id_pageview ON pageview (genome_id);


-- Table structure for table referrer
--
CREATE TABLE referrer (
  referrer_id int NOT NULL AUTO_INCREMENT,
  hash varchar(255) NOT NULL,
  domain varchar(255) NOT NULL,
  path varchar(255) NOT NULL,
  external varchar(255) NOT NULL,
  search_engine varchar(255) NOT NULL,
  search_term varchar(255) NOT NULL,
  PRIMARY KEY  (referrer_id),
  UNIQUE (hash)
);

-- external varchar NOT NULL CHECK(external IN('true','false')) ,

--
-- Table structure for table variant
--
CREATE TABLE variant (
  variant_id int NOT NULL AUTO_INCREMENT,
  gene_id int NOT NULL,
  name varchar(255),
  PRIMARY KEY  (variant_id),
  UNIQUE (gene_id,name)
);                                   


--
-- Table structure for table result
--
CREATE TABLE result (
  variant_id int NOT NULL,
  domain_name varchar(255) NOT NULL,
  page_name varchar(255) NOT NULL,
  gene_name varchar(255) NOT NULL,
  variant_name varchar(255) NOT NULL,
  variant_count bigint,
  variant_sum double precision,
  variant_avg double precision,
  variant_stddev double precision,
  variant_share double precision,
  variant_weight double precision,
  UNIQUE (variant_id)
);


--
-- Table structure for table visitor
--
CREATE TABLE visitor (
  visitor_id int NOT NULL AUTO_INCREMENT,
  hash varchar(255) NOT NULL,
  ip_address varchar(255) NOT NULL,
  Parent varchar(255) NOT NULL,
  Platform varchar(255) NOT NULL,
  Browser varchar(255) NOT NULL,
  Version varchar(255) NOT NULL,
  MajorVer varchar(255) NOT NULL,
  Frames varchar(255) NOT NULL,
  IFrames varchar(255) NOT NULL,
  Tables varchar(255) NOT NULL,
  Cookies varchar(255) NOT NULL,
  JavaApplets varchar(255) NOT NULL,
  JavaScript varchar(255) NOT NULL,
  CSS varchar(255) NOT NULL,
  CssVersion varchar(255) NOT NULL,
  supportsCSS varchar(255) NOT NULL,
  MinorVer varchar(255) NOT NULL,
  Alpha varchar(255) NOT NULL,
  Beta varchar(255) NOT NULL,
  Win16 varchar(255) NOT NULL,
  Win32 varchar(255) NOT NULL,
  Win64 varchar(255) NOT NULL,
  BackgroundSounds varchar(255) NOT NULL,
  AuthenticodeUpdate varchar(255) NOT NULL,
  CDF varchar(255) NOT NULL,
  VBScript varchar(255) NOT NULL,
  ActiveXControls varchar(255) NOT NULL,
  Stripper varchar(255) NOT NULL,
  isBanned varchar(255) NOT NULL,
  WAP varchar(255) NOT NULL,
  isMobileDevice varchar(255) NOT NULL,
  isSyndicationReader varchar(255) NOT NULL,
  Crawler varchar(255) NOT NULL,
  AOL varchar(255) NOT NULL,
  aolVersion varchar(255) NOT NULL,
  netCLR varchar(255) NOT NULL,
  ClrVersion varchar(255) NOT NULL,
  PRIMARY KEY  (visitor_id),
  UNIQUE (hash)
);


ALTER TABLE variant ADD CONSTRAINT variant_ibfk_2 FOREIGN KEY (gene_id) REFERENCES gene (gene_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE page ADD CONSTRAINT page_ibfk_1 FOREIGN KEY (domain_id) REFERENCES domain (domain_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE genome_variant_link ADD CONSTRAINT genome_variant_link_ibfk_1 FOREIGN KEY (variant_id) REFERENCES variant (variant_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE genome_variant_link ADD CONSTRAINT genome_variant_link_ibfk_2 FOREIGN KEY (genome_id) REFERENCES genome (genome_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE genome ADD CONSTRAINT genome_ibfk_1 FOREIGN KEY (page_id) REFERENCES page (page_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE gene ADD CONSTRAINT gene_ibfk_1 FOREIGN KEY (page_id) REFERENCES page (page_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE error ADD CONSTRAINT error_ibfk_1 FOREIGN KEY (page_id) REFERENCES page (page_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE error ADD CONSTRAINT error_ibfk_2 FOREIGN KEY (visitor_id) REFERENCES visitor (visitor_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE pageview ADD CONSTRAINT pageview_ibfk_1 FOREIGN KEY (visitor_id) REFERENCES visitor (visitor_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE pageview ADD CONSTRAINT pageview_ibfk_2 FOREIGN KEY (referrer_id) REFERENCES referrer (referrer_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE pageview ADD CONSTRAINT pageview_ibfk_3 FOREIGN KEY (page_id) REFERENCES page (page_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE pageview ADD CONSTRAINT pageview_ibfk_4 FOREIGN KEY (genome_id) REFERENCES genome (genome_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE goal ADD CONSTRAINT goal_ibfk_1 FOREIGN KEY (pageview_xid) REFERENCES pageview (pageview_xid) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE result ADD CONSTRAINT result_ibfk_1 FOREIGN KEY (variant_id) REFERENCES variant (variant_id) ON DELETE CASCADE ON UPDATE CASCADE;