create table application_logs
(
    username varchar2(30),
    log_ts timestamp,
    package_name varchar2(30),
    member_name varchar2(30),
    location number,
    message_type varchar2(10),
    message varchar2(4000)
)
/

comment on table application_logs is
    'Messages logged by the application'
/
    
comment on column application_logs.username is
    'Database user running this job'
/

comment on column application_logs.log_ts is
    'Timestamp of the log entry'
/

comment on column application_logs.package_name is
    'Name of the package from which the message has been generated'
/

comment on column application_logs.member_name is
    'Name of the package member from which the message has been generated'
/

comment on column application_logs.location is
    'The line number in the package where this message was triggered.'
/

comment on column application_logs.message_type is
    'Type of message - ERROR, INFO or DEBUG'
/

comment on column application_logs.message is
    'The log message itself'
/
