-- Queries need to be run separately inorder to properly estimate what the Demand Attribute should for each historic month
-- There are still error instances that cannot be accounted for yet (aka ... Core 1 Demand Attribute is applied if no Demand Attribute was given until it is changed)

create volatile table tmp_PC9_CUR_PLUS_CHANGE as 
(
	select
		tmp_CUR_PC9_DA.PC9,
		tmp_CUR_PC9_DA.FISC_YR_KEY, 
		tmp_CUR_PC9_DA.FISC_MTH_KEY,
		tmp_PC9_MONTHLY_DA.DMD_ATTR_DESC,
		max(tmp_PC9_MONTHLY_DA.FISC_MTH_KEY) as MOST_RECENT_CHANGE_MONTH

	from
		-- Derived Table #1.0
		(select distinct
			EDWARD.PRODUCT.PROD_CD_9 as PC9,
			EDWARD.CALENDAR_DAY.FISC_YR_KEY,
			EDWARD.CALENDAR_DAY.FISC_MTH_KEY,
			EDWARD.PROD_SAP_MORE.DMD_ATTR_DESC

		from
			-- Foundation Table
			EDWARD.PRODUCT

			-- Additional Product Attributes
			inner join EDWARD.PROD_SAP_MORE on
	        	(EDWARD.PRODUCT.PROD_KEY = EDWARD.PROD_SAP_MORE.PROD_KEY)
	        left join EDWARD.BRAND_EXT_BRAND_ASSO on
		        (PRODUCT.BRAND_EXT_ID = BRAND_EXT_BRAND_ASSO.BRAND_EXT_ID)
			left join EDWARD.BRAND on
		        (BRAND_EXT_BRAND_ASSO.BRAND_ID = BRAND.BRAND_ID)
			left join EDWARD.CONSUMER_GRP_EXT on
		        (PRODUCT.CONSM_GRP_EXT_ID = CONSUMER_GRP_EXT.CONSM_GRP_EXT_ID)
			left join EDWARD.CONSUMER_GRP on
		        (CONSUMER_GRP_EXT.CONSM_GRP_ID = CONSUMER_GRP.CONSM_GRP_ID),

		    -- 2nd Foundation Table for Fiscal Calendar
	        EDWARD.CALENDAR_DAY

		where
			EDWARD.BRAND.BRAND_ID like '%L%'
			and EDWARD.CONSUMER_GRP.CONSM_GRP_ID in ('MEN','001')
			and EDWARD.PRODUCT.PROD_CAT_CD like '%Bottom%'
			and EDWARD.CALENDAR_DAY.FISC_YR_KEY in (2013, 2014, 2015, 2016, 2017)) tmp_CUR_PC9_DA

		left join 
			-- Derived Table #2.0
			(select
				tmp_MAX_CHANGE_DATE.PC9,
				tmp_MAX_CHANGE_DATE.FISC_MTH_KEY,
				tmp_MAX_CHANGE_DATE.FISC_YR_KEY,
				EDWARD_LOAD.PRODUCT_SB.DMD_ATTR_DESC

			from
				-- Foundation Table
				EDWARD_LOAD.PRODUCT_SB
				inner join 

					-- Derived Table #2.1
					(select
						EDWARD_LOAD.PRODUCT_SB.J_3APGNR_MASTER_GRID_ID as PC9,
						EDWARD.CALENDAR_DAY.FISC_YR_KEY,
						EDWARD.CALENDAR_DAY.FISC_MTH_KEY,
						max(EDWARD_LOAD.PRODUCT_SB.ETL_PROCESSED_TMS) as CHANGE_DATE_MAX

					from				
						EDWARD_LOAD.PRODUCT_SB 
						left join EDWARD.CALENDAR_DAY on 
							(CALENDAR_DAY.CAL_DAY_KEY = PRODUCT_SB.ETL_PROCESSED_TMS)

					group by 1, 2, 3) tmp_MAX_CHANGE_DATE on
					(EDWARD_LOAD.PRODUCT_SB.J_3APGNR_MASTER_GRID_ID = tmp_MAX_CHANGE_DATE.PC9 and EDWARD_LOAD.PRODUCT_SB.ETL_PROCESSED_TMS = tmp_MAX_CHANGE_DATE.CHANGE_DATE_MAX)

				-- Product Attribute Tables
				left join EDWARD.PRODUCT on
		        	(EDWARD_LOAD.PRODUCT_SB.J_3APGNR_MASTER_GRID_ID = PRODUCT.PROD_CD_9)
				left join EDWARD.BRAND_EXT_BRAND_ASSO on
			        (PRODUCT.BRAND_EXT_ID = BRAND_EXT_BRAND_ASSO.BRAND_EXT_ID)
				left join EDWARD.BRAND on
			        (BRAND_EXT_BRAND_ASSO.BRAND_ID = BRAND.BRAND_ID)
				left join EDWARD.CONSUMER_GRP_EXT on
			        (PRODUCT.CONSM_GRP_EXT_ID = CONSUMER_GRP_EXT.CONSM_GRP_EXT_ID)
				left join EDWARD.CONSUMER_GRP on
			        (CONSUMER_GRP_EXT.CONSM_GRP_ID = CONSUMER_GRP.CONSM_GRP_ID)

		    where
		    	EDWARD.BRAND.BRAND_ID like '%L%'
				and EDWARD.CONSUMER_GRP.CONSM_GRP_ID in ('MEN','001')
				and EDWARD.PRODUCT.PROD_CAT_CD like '%Bottom%'
				and tmp_MAX_CHANGE_DATE.FISC_YR_KEY in (2013, 2014, 2015, 2016, 2017)) tmp_PC9_MONTHLY_DA on
			(tmp_PC9_MONTHLY_DA.PC9 = tmp_CUR_PC9_DA.PC9 and tmp_PC9_MONTHLY_DA.FISC_YR_KEY <= tmp_CUR_PC9_DA.FISC_YR_KEY and tmp_PC9_MONTHLY_DA.FISC_MTH_KEY <= tmp_CUR_PC9_DA.FISC_MTH_KEY)
	group by 1, 2, 3, 4

) with data primary index (PC9, FISC_MTH_KEY, MOST_RECENT_CHANGE_MONTH) on commit preserve rows;

create volatile table tmp_PC9_DA_MONTH as 
(
	select 
		tmp_PC9_CUR_PLUS_CHANGE.PC9,
		tmp_PC9_CUR_PLUS_CHANGE.FISC_YR_KEY,
		tmp_PC9_CUR_PLUS_CHANGE.FISC_MTH_KEY,
		tmp_PC9_CUR_PLUS_CHANGE.DMD_ATTR_DESC
	from
		-- Foundation Table
		tmp_PC9_CUR_PLUS_CHANGE
		inner join 
			-- Derived Table #3
			(select 
				PC9,
				FISC_YR_KEY,
				FISC_MTH_KEY,
				max(MOST_RECENT_CHANGE_MONTH) as MOST_RECENT_CHANGE_MONTH
			from
				tmp_PC9_CUR_PLUS_CHANGE
			group by 1, 2, 3) tmp_CORRECT_MONTH_COMBO on
			(tmp_PC9_CUR_PLUS_CHANGE.PC9 = tmp_CORRECT_MONTH_COMBO.PC9 and tmp_PC9_CUR_PLUS_CHANGE.FISC_MTH_KEY = tmp_CORRECT_MONTH_COMBO.FISC_MTH_KEY and tmp_PC9_CUR_PLUS_CHANGE.MOST_RECENT_CHANGE_MONTH = tmp_CORRECT_MONTH_COMBO.MOST_RECENT_CHANGE_MONTH)
)
