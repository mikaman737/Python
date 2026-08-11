SELECT tt.traveler_id, ttm.residence_sgg_cd, ttm.GENDER, ttm.AGE_GRP FROM tn_travel tt
JOIN tn_traveller_master ttm
ON tt.traveler_id = ttm.traveler_id;

select * from tn_traveller_master ttm;

-- 여행 횟수를 어떻게 파악할지?

-- 총 여행 일수




