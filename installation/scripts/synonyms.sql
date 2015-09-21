rem
rem Script to create synonyms on user-facing application objects
rem

define app_owner = 'CRUDO'
accept app_owner default &app_owner prompt 'Enter the the Application Owning Schema [&app_owner] : '

create or replace synonym generate_matrices for &app_owner..generate_matrices;
create or replace synonym crud_matrices for &app_owner..crud_matrices; 
create or replace synonym application_logs for &app_owner..application_logs;


