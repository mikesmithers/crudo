rem
rem Grant permissions on application objects
rem 
rem
define app_owner = CRUDO
accept app_owner default &app_owner prompt 'Enter the the Application Owning Schema [&app_owner] :'
accept app_user prompt 'Enter the name of the user to grant access to : '


grant execute on &&app_owner..generate_matrices to &app_user;
grant select on &&app_owner..crud_matrices to &app_user;
grant select on &&app_owner..application_logs to &app_user;

prompt Grants completed.

