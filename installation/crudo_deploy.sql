spool crudo_deploy.log
--
-- Script to deploy the CRUDO schema and objects
-- This script should be run as the Application Owner.
--

prompt Creating tables
prompt ===============

prompt APPLICATION_LOGS

@tables/application_logs.sql

prompt CRUD_MATRICES

@tables/crud_matrices.sql

prompt Creating Packages
prompt =================


prompt LOGS

@packages/logs.pks
@packages/logs.pkb

prompt SEARCH_CODE

@packages/search_code.pks
@packages/search_code.pkb

prompt GENERATE_MATRICES

@packages/generate_matrices.pks
@packages/generate_matrices.pkb

prompt Deployment completed. 

spool off
