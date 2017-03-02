select cust_invty_loc_prod_wkly.*,
from cust_invty_loc_prod_wkly inner join 
	product on (cust_invty_loc_prod_wkly.prod_key = product.prod_key) inner join 
	brand_ext_brand_asso on (product.brand_ext_id = brand_ext_brand_asso.brand_ext_id) inner join 
	brand on (brand_ext_brand_asso.brand_id = brand.brand_id) inner join
	consumer_grp_ext on (consumer_grp_ext.consm_grp_ext_id=product.consm_grp_ext_id) inner join
	consumer_grp on (consumer_grp.consm_grp_id = consumer_grp_ext.consm_grp_id)
where cust_invty_loc_prod_wkly.cust_invty_per_beg_dt between cast( '11/28/2016' as date format 'MM/DD/YYYY') and cast( '01/01/2017' as date format 'MM/DD/YYYY')
	and cust_invty_loc_prod_wkly.cust_id in ('00459','04444','00444','52272','00432','52661','00719','60377','60587')
	

