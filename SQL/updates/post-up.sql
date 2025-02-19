do $BODY$
declare pid uuid;
begin
    if not exists(select * from system_settings where item = 'backend_brand_settings') then
        -- Put menus at top
        insert into system_settings(item, "value")
            values('backend_brand_settings', '{"app_name":"Winter CMS","app_tagline":"Getting back to basics","primary_color":"#34495e","secondary_color":"#e67e22","accent_color":"#3498db","default_colors":[{"color":"#1abc9c"},{"color":"#16a085"},{"color":"#2ecc71"},{"color":"#27ae60"},{"color":"#3498db"},{"color":"#2980b9"},{"color":"#9b59b6"},{"color":"#8e44ad"},{"color":"#34495e"},{"color":"#2b3e50"},{"color":"#f1c40f"},{"color":"#f39c12"},{"color":"#e67e22"},{"color":"#d35400"},{"color":"#e74c3c"},{"color":"#c0392b"},{"color":"#ecf0f1"},{"color":"#bdc3c7"},{"color":"#95a5a6"},{"color":"#7f8c8d"}],"menu_mode":"inline","auth_layout":"split","menu_location":"top","icon_location":"inline","custom_css":""}');
    end if;

    if not exists(select * from backend_users where login = 'demo') then
        -- Demo user
        INSERT INTO public.backend_users
            VALUES(2, 'Demo', '', 'demo', 'demo@example.com', '$2y$10$q1.JQJXcyXhNzyvl9ivi6eA28USyu1BycOA8qyPbOZFdiJJ6E0UFe', '', NULL, '', '{"cms.manage_content":-1,"cms.manage_assets":-1,"cms.manage_pages":-1,"cms.manage_layouts":-1,"cms.manage_partials":-1,"cms.manage_themes":-1,"cms.manage_theme_options":-1,"backend.access_dashboard":1,"backend.manage_default_dashboard":-1,"backend.manage_users":-1,"backend.impersonate_users":-1,"backend.manage_preferences":1,"backend.manage_editor":-1,"backend.manage_own_editor":-1,"backend.manage_branding":1,"media.manage_media":-1,"backend.allow_unsafe_markdown":-1,"system.manage_updates":-1,"system.access_logs":-1,"system.manage_mail_settings":-1,"system.manage_mail_templates":-1,"acorn.rtler.change_settings":1,"acorn.users.access_users":1,"acorn.users.access_groups":1,"acorn.users.access_settings":1,"acorn.users.impersonate_user":-1,"winter.location.access_settings":1,"winter.tailwindui.manage_own_appearance.dark_mode":1,"winter.tailwindui.manage_own_appearance.menu_location":1,"winter.tailwindui.manage_own_appearance.item_location":1,"winter.translate.manage_locales":1,"winter.translate.manage_messages":1,"acorn_location":1,"acorn_messaging":-1,"calendar_view":1,"change_the_past":1,"access_settings":1,"acorn.lojistiks.debug":-1}', true, NULL, NULL, '2024-09-26 09:04:14', NULL, '2024-09-26 16:43:53', NULL, false, '', '');
    end if;
end
$BODY$;
