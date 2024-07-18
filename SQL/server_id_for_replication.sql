create function f_server_id
as
@@body@@
	declare pid bigint;
	select into pid, id from servers where hostname = hostname();
	if @@ROW_COUNT = 0 then
		insert into servers(hostname) values(hostname());
		set pid = @@INCREMENT;
	end if
	new.created_by_server_id = pid;
@@body@@;

create trigger for before insert on <every table>
for each row
execute function f_server_id(); 

