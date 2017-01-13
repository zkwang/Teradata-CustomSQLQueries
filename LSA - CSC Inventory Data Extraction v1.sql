select
	--product.prod_cd_9,
	--product.prod_cat_cd,
	--product.prod_subcat_cd,
	--consumer_grp.consm_grp_long_desc,
	--consumer_grp_ext.consm_grp_ext_long_desc,
	brand.brand_short_desc,
	srce_loc.srce_loc_name,
	srce_loc.srce_loc_id,
	sap_size_invty_daily_arcv.invty_erdat_dt,
	sum(sap_size_invty_daily_arcv.prod_size_onhand_qty) as onHandInv
	
from
	invty_recon.sap_size_invty_daily_arcv inner join 
	edward.product on (sap_size_invty_daily_arcv.prod_key = product.prod_key) inner join
	edward.srce_loc on (srce_loc.srce_loc_id = sap_size_invty_daily_arcv.srce_loc_id) inner join
	brand_ext_brand_asso on (product.brand_ext_id = brand_ext_brand_asso.brand_ext_id) inner join 
	brand on (brand_ext_brand_asso.brand_id = brand.brand_id) inner join
	consumer_grp_ext on (consumer_grp_ext.consm_grp_ext_id=product.consm_grp_ext_id) inner join
	consumer_grp on (consumer_grp.consm_grp_id = consumer_grp_ext.consm_grp_id)
	
where
	sap_size_invty_daily_arcv.invty_erdat_dt in (1151130,1160104,1160201,1160229,1160404,1160502,1160530,1160704,1160801,1160829,1161003,1161031,1161128,1170102)
	--and brand.brand_id = 'L'
	--and consumer_grp.consm_grp_id = '001'
	and prod_size_onhand_qty > 0

group by 1, 2, 3, 4
order by invty_erdat_dt desc

-- For Current Inventory data, please change SAP_SIZE_INVTY_DAILY_ARCV to SAP_SIZE_INVTY_DAILY
--Formula for creating a Teradata Number that references a date:  Teradata Date ID = (Year - 1900) * 10000 + Month * 100 + Day