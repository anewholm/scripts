do
$do$
begin
	delete from transfers;
	delete from addresses;

	perform setval('public.addresses_id', 1, true);
	for i in 1..1000 loop
		insert into addresses(name) values(concat('address', i));
	end loop;

	for i in 1..150000 loop
		insert into transfers(source_address_id, destination_address_id) values(random() * 999 + 1, random() * 999 + 1);
	end loop;
end
$do$;