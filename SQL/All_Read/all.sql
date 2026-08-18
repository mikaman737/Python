SELECT tt.traveler_id, ttm.residence_sgg_cd, ttm.GENDER, ttm.AGE_GRP FROM tn_travel tt
JOIN tn_traveller_master ttm
ON tt.traveler_id = ttm.traveler_id;

select * from tn_traveller_master ttm;

SELECT * FROM tn_visit_area_info;
SELECT * FROM tn_lodge_consume_his;
SELECT * FROM tn_activity_consume_his;








