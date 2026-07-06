/* 
=================================================
CREATE Database and Schemas 
=================================================
Script purpose:
  This script create a new database named "olist". In this project we use postgress so we need to run this script in two phases.
  In 1st phase we create a database in a default database query editor and then 2nd fase we need to shift query editor to new database
  and run 2nd phase query.
*/

-- Phase 1:
CREATE DATABASE olist;

-- Phase 2:
CREATE SCHEMAS bronze;
CREATE SCHEMAS silver;
CREATE SCHEMAS gold;


