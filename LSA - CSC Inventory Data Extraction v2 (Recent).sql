
select
	EDWARD.BRAND.BRAND_SHORT_DESC,
	EDWARD.CONSUMER_GRP.CONSM_GRP_LONG_DESC,
	INVTY_RECON.SAP_SIZE_INVTY_DAILY.INVTY_ERDAT_DT,
	EDWARD.CALENDAR_DAY.FISC_MTH_KEY,
	EDWARD.PRODUCT.PROD_CAT_CD,
	tmp_PC9_DA_MONTH.DMD_ATTR_DESC as HISTORIC_DMD_ATTR,
	EDWARD.PROD_SAP_MORE.DMD_ATTR_DESC as CURRENT_DMD_ATTR,
	sum(INVTY_RECON.SAP_SIZE_INVTY_DAILY.PROD_SIZE_ONHAND_QTY) as ON_HAND_INV

from
	-- Foundation Table
	INVTY_RECON.SAP_SIZE_INVTY_DAILY

	-- To Pull Item Size Information
	left join EDWARD.SIZE on
        (INVTY_RECON.SAP_SIZE_INVTY_DAILY.SIZE_DIM_1_CD = EDWARD.SIZE.SIZE_DIM_1_CD and INVTY_RECON.SAP_SIZE_INVTY_DAILY.SIZE_DIM_2_CD = EDWARD.SIZE.SIZE_DIM_2_CD)

	-- To Pull Brand, Consumer Group, and Category Information
	left join EDWARD.PRODUCT on
        (INVTY_RECON.SAP_SIZE_INVTY_DAILY.PROD_KEY = EDWARD.PRODUCT.PROD_KEY)
	left join EDWARD.BRAND_EXT_BRAND_ASSO on
        (EDWARD.PRODUCT.BRAND_EXT_ID = EDWARD.BRAND_EXT_BRAND_ASSO.BRAND_EXT_ID)
	left join EDWARD.BRAND on
        (EDWARD.BRAND_EXT_BRAND_ASSO.BRAND_ID = EDWARD.BRAND.BRAND_ID)
	left join EDWARD.CONSUMER_GRP_EXT on
        (EDWARD.PRODUCT.CONSM_GRP_EXT_ID = EDWARD.CONSUMER_GRP_EXT.CONSM_GRP_EXT_ID)
	left join EDWARD.CONSUMER_GRP on
        (EDWARD.CONSUMER_GRP_EXT.CONSM_GRP_ID = EDWARD.CONSUMER_GRP.CONSM_GRP_ID)
   	left join EDWARD.PROD_SAP_MORE on
    	(EDWARD.PRODUCT.PROD_KEY = EDWARD.PROD_SAP_MORE.PROD_KEY)

	-- To Pull CSC Names
	left join EDWARD.SRCE_LOC on 
		(INVTY_RECON.SAP_SIZE_INVTY_DAILY.SRCE_LOC_ID = EDWARD.SRCE_LOC.SRCE_LOC_ID)

	-- To Aggregate To Fiscal Month Level
	left join EDWARD.CALENDAR_DAY on 
        (INVTY_RECON.SAP_SIZE_INVTY_DAILY.INVTY_ERDAT_DT = EDWARD.CALENDAR_DAY.CAL_DAY_KEY)

where 
    INVTY_RECON.SAP_SIZE_INVTY_DAILY_ARCV.INVTY_ERDAT_DT > 1121120
    and BRAND.BRAND_ID like 'L'

group by
        1, 2, 3, 4, 5, 6, 7
