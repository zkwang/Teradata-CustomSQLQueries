select cust_invty_loc_prod_wkly.*,
	product.prod_cd_9,
	product.prod_cat_cd,
	product.prod_subcat_cd,
	consumer_grp.consm_grp_long_desc,
	consumer_grp_ext.consm_grp_ext_long_desc,
	brand.brand_short_desc
from cust_invty_loc_prod_wkly inner join 
	product on (cust_invty_loc_prod_wkly.prod_key = product.prod_key) inner join 
	brand_ext_brand_asso on (product.brand_ext_id = brand_ext_brand_asso.brand_ext_id) inner join 
	brand on (brand_ext_brand_asso.brand_id = brand.brand_id) inner join
	consumer_grp_ext on (consumer_grp_ext.consm_grp_ext_id=product.consm_grp_ext_id) inner join
	consumer_grp on (consumer_grp.consm_grp_id = consumer_grp_ext.consm_grp_id)
where cust_invty_loc_prod_wkly.cust_invty_per_beg_dt between cast( '07/01/2015' as date format 'MM/DD/YYYY') and cast( '06/01/2016' as date format 'MM/DD/YYYY')
	and cust_invty_loc_prod_wkly.cust_id in ('00432','60377','52661')
	and cust_invty_loc_prod_wkly.cust_loc_id in ('185','133','148','172','181','183')
	and product.prod_subcat_cd = 'Long Bottoms'
	and brand.brand_id = 'L'
	and consumer_grp.consm_grp_id = '001'
	

