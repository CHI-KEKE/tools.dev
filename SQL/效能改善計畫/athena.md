SELECT * FROM "hk_prod_osm"."osm_api_nlog"
where controller = 'LocationMember'
and action = 'GetOmoKeyPromptsFromMemberDimension'
and date = '2026/07/22'
and longdate > '2026-07-22 12:15'
and longdate < '2026-07-22 12:20'
limit 1000;