select
	--product.prod_cd_9,
	--product.prod_cat_cd,
	--product.prod_subcat_cd,
	--consumer_grp.consm_grp_long_desc,
	--consumer_grp_ext.consm_grp_ext_long_desc,
	brand.brand_short_desc,
	srce_loc.srce_loc_name,
	sap_size_invty_daily.invty_erdat_dt,
	sum(sap_size_invty_daily.prod_size_onhand_qty) as onHandInv
	
from
	invty_recon.sap_size_invty_daily inner join 
	edward.product on (sap_size_invty_daily.prod_key = product.prod_key) inner join
	edward.srce_loc on (srce_loc.srce_loc_id = sap_size_invty_daily.srce_loc_id) inner join
	brand_ext_brand_asso on (product.brand_ext_id = brand_ext_brand_asso.brand_ext_id) inner join 
	brand on (brand_ext_brand_asso.brand_id = brand.brand_id) inner join
	consumer_grp_ext on (consumer_grp_ext.consm_grp_ext_id=product.consm_grp_ext_id) inner join
	consumer_grp on (consumer_grp.consm_grp_id = consumer_grp_ext.consm_grp_id)
	
where
	sap_size_invty_daily.invty_erdat_dt in (1170102)
	and brand.brand_id = 'L'
	--and consumer_grp.consm_grp_id = '001'
	and prod_size_onhand_qty > 0

group by 1, 2, 3
order by invty_erdat_dt desc