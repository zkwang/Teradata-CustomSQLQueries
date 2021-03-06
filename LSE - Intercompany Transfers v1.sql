
SELECT 
--  CAST(BVB_PPLANT.COUNTRY || '01'  AS CHAR(10)) AS SalesOrg,
    BVB_AZGPUR_D0500.SUPP_PLANT AS Plant,
    CAST(NULL AS CHAR(10)) AS Season,
    BVB_AZGPUR_D0500.MATERIAL AS PC9,
/*  CASE
        WHEN POSITION('-' IN BVB_AZGPUR_D0500.AF_GRDVAL) > 0 
            THEN SUBSTR(BVB_AZGPUR_D0500.AF_GRDVAL, 1, POSITION('-' IN BVB_AZGPUR_D0500.AF_GRDVAL)  -1) || SUBSTR(BVB_AZGPUR_D0500.AF_GRDVAL, POSITION('-' IN BVB_AZGPUR_D0500.AF_GRDVAL) + 1, CHARACTER_LENGTH(BVB_AZGPUR_D0500.AF_GRDVAL))
        ELSE BVB_AZGPUR_D0500.AF_GRDVAL
    END AS Size, */
    fiscmnths.fiscmnth AS fiscmnth,
    BVB_AZGPUR_D0500.AF_STCAT AS Quality,
    CAST(0 AS DECIMAL(10,0)) AS BegInvQty,
    CAST(SUM(
        CASE 
            WHEN BVB_AZGPUR_D0500.CPQUAOU - BVB_AZGPUR_D0500.CURR_GRQTY > 0
                THEN BVB_AZGPUR_D0500.CPQUAOU - BVB_AZGPUR_D0500.CURR_GRQTY
            ELSE 0
        END ) AS DECIMAL(10,0)) AS OpenOrdQty,
    CAST(0 AS DECIMAL(10,0)) AS DueInQty,
    CAST(0 AS DECIMAL(10,0)) AS ForecastQty

FROM
    PROD_EDW_VIEWS.BVB_AZGPUR_D0500

    INNER JOIN #ATS_Month_Calendar fiscmnths
        ON (BVB_AZGPUR_D0500.SCL_DELDAT = fiscmnths.cal_day_char)
    INNER JOIN PROD_EDW_VIEWS.BVB_PPLANT
        ON (BVB_AZGPUR_D0500.SUPP_PLANT = BVB_PPLANT.PLANT)

WHERE 
    BVB_AZGPUR_D0500.SUPP_PLANT IN ('1018', '3002', '3003', '3045')
    AND BVB_AZGPUR_D0500.DOCTYPE IN ('ZITS', 'UB')
    AND BVB_AZGPUR_D0500.VENDOR IN ('0081001018', '0081003002', '0081003003', '0081003045')
    AND BVB_AZGPUR_D0500."/BIC/ZSHPSTAT" <> 'SHIPMENT'
    AND BVB_AZGPUR_D0500.COMPL_DEL <> 'X'
    AND BVB_AZGPUR_D0500.MATERIAL like '00501-0101'
    AND BVB_AZGPUR_D0500.AF_GRDVAL <> ' '

GROUP BY
--  CAST(BVB_PPLANT.COUNTRY || '01'  AS CHAR(10)),
    BVB_AZGPUR_D0500.SUPP_PLANT,
    CAST(NULL AS CHAR(10)),
    BVB_AZGPUR_D0500.MATERIAL,
/*  CASE
        WHEN POSITION('-' IN BVB_AZGPUR_D0500.AF_GRDVAL) > 0 
            THEN SUBSTR(BVB_AZGPUR_D0500.AF_GRDVAL, 1, POSITION('-' IN BVB_AZGPUR_D0500.AF_GRDVAL)  -1) || SUBSTR(BVB_AZGPUR_D0500.AF_GRDVAL, POSITION('-' IN BVB_AZGPUR_D0500.AF_GRDVAL) + 1, CHARACTER_LENGTH(BVB_AZGPUR_D0500.AF_GRDVAL))
        ELSE BVB_AZGPUR_D0500.AF_GRDVAL
    END, */
    fiscmnths.fiscmnth,
    BVB_AZGPUR_D0500.AF_STCAT

HAVING
    SUM(
        CASE 
            WHEN BVB_AZGPUR_D0500.CPQUAOU - BVB_AZGPUR_D0500.CURR_GRQTY > 0
                THEN BVB_AZGPUR_D0500.CPQUAOU - BVB_AZGPUR_D0500.CURR_GRQTY
            ELSE 0
        END) > 0

