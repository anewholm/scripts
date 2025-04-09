-- POLICY: IsInOwnerGroup

DROP POLICY IF EXISTS "IsInOwnerGroup" ON public.acornassociated_criminal_legalcases;

CREATE POLICY "IsInOwnerGroup"
    ON public.acornassociated_criminal_legalcases
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT jc.id
   FROM ((acornassociated_justice_legalcases jc
     JOIN acornassociated_user_user_group uug ON ((uug.user_group_id = jc.owner_user_group_id)))
     JOIN backend_users bu ON ((uug.user_id = bu.acornassociated_user_user_id)))
  WHERE ((jc.id = acornassociated_criminal_legalcases.legalcase_id) AND ((bu.login)::text = CURRENT_USER)))));
