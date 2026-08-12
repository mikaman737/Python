SELECT tt.traveler_id, ttm.residence_sgg_cd, ttm.GENDER, ttm.AGE_GRP FROM tn_travel tt
JOIN tn_traveller_master ttm
ON tt.traveler_id = ttm.traveler_id;

select * from tn_traveller_master ttm;

-- 여행 횟수를 어떻게 파악할지?
-- 총 여행 일수

SELECT * FROM tn_visit_area_info;
SELECT * FROM tn_lodge_consume_his;
SELECT * FROM tn_activity_consume_his;







