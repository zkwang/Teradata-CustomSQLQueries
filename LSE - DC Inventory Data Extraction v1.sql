SELECT 
MAT_PLANT MATERIAL
,AF_GRDVAL
,PLANT
,CALWEEK
,max(calday) as LastDayOfWeek
,SUM(ZLABSECC) UNRESTRICTED_STOCK_QTY 
,SUM(ZSPEMECC) BLOCKED_STOCK_QTY 
,SUM(ZINSMECC) QUAL_INP_STOCK_QTY
,SUM(ZLABSECC + ZSPEMECC + ZINSMECC) STOCK_IN_DC_QTY
FROM 
	PROD_EDW_VIEWS.BVB_AZGIM_D0300 inner join
	product on (cust_invty_loc_prod_wkly.prod_key = product.prod_key) inner join 
	brand_ext_brand_asso on (product.brand_ext_id = brand_ext_brand_asso.brand_ext_id) inner join 
	brand on (brand_ext_brand_asso.brand_id = brand.brand_id)
where 
	calweek > 201645
GROUP BY
1,2,3,4