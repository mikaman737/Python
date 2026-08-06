select * from tc_codea as 코드A;
select * from tc_codeb AS 코드B;
select * from tn_activity_consume_his AS 활동_소비내역;
select * from tn_activity_his AS 활동_이력;
select * from tn_adv_consume_his AS 사전_소비내역;
select * from tn_companion_info AS 동반자_정보;
select * from tn_lodge_consume_his AS 숙박_소비내역;
select * from tn_mvmn_consume_his AS 이동수단_소비내역;
select * from tn_tour_photo AS 여행_사진;
select * from tn_travel AS 여행;
select * from tn_traveller_master AS 여행자_마스터;
select * from tn_visit_area_info AS 방문지_정보;
select * from tc_column_dictionary AS 컬럼_사전;
select * from tn_move_his AS 이동_이력;
select * from tc_sgg AS 시군구_코드;

select count(*) from tc_codea tca;
select count(*) from tc_codeb tcb;
SELECT  count(*) from tn_activity_consume_his tach;
select count(*) from tn_activity_his tah ;
select count(*) from tn_adv_consume_his tach  ;
select count(*) from tn_companion_info tci ;
select count(*) from tn_lodge_consume_his tlch ;
select count(*) from tn_move_his tmh ;
select count(*) from tn_mvmn_consume_his tmch ;
select count(*) from tn_tour_photo ttp ;
select count(*) from tn_travel tt ;
select count(*) from tn_traveller_master ttm  ;
select count(*) from tn_visit_area_info tvai;

select * from tc_column_dictionary;
select * from tc_column_dictionary where table_nm = 'tn_travel';
select * from tc_column_dictionary where table_nm = 'tn_traveller_master';
select * from tc_column_dictionary where table_nm = 'tn_visit_area_info';
select * from tc_column_dictionary where table_nm = 'tn_move_his';
select * from tc_column_dictionary where table_nm = 'tn_activity_consume_his';
select * from tc_column_dictionary where table_nm = 'tn_activity_his';
select * from tc_column_dictionary where table_nm = 'tn_adv_consume_his';
select * from tc_column_dictionary where table_nm = 'tn_companion_info';
select * from tc_column_dictionary where table_nm = 'tn_lodge_consume_his';
select * from tc_column_dictionary where table_nm = 'tn_mvmn_consume_his';
select * from tc_column_dictionary where table_nm = 'tn_tour_photo';
select * from tc_column_dictionary where table_nm = 'tc_codea';
select * from tc_column_dictionary where table_nm = 'tc_codeb';
select * from tc_column_dictionary where table_nm = 'tc_column_dictionary';



