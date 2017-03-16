
SELECT
--  CAST(NULL AS CHAR(10)) AS SalesOrg,
    CAST("/BIC/AZGSNPD0100".APO_LOCNO AS CHAR(4)) AS Plant,
    CAST(NULL AS CHAR(10)) AS Season,
    "/BIC/AZGSNPD0100".MATERIAL AS PC9,
/*  CASE
        WHEN POSITION('-' IN "/BIC/AZGSNPD0100".AF_GRDVAL) > 0 
            THEN SUBSTR("/BIC/AZGSNPD0100".AF_GRDVAL, 1, POSITION('-' IN "/BIC/AZGSNPD0100".AF_GRDVAL)  -1) || SUBSTR("/BIC/AZGSNPD0100".AF_GRDVAL, POSITION('-' IN "/BIC/AZGSNPD0100".AF_GRDVAL) + 1, CHARACTER_LENGTH("/BIC/AZGSNPD0100".AF_GRDVAL))
        ELSE "/BIC/AZGSNPD0100".AF_GRDVAL
    END AS Size, */    
    CASE
        WHEN SV_CAL_MTH.MTH_KEY <= #start_date_vl1.sel_fiscmnth_1
            THEN #start_date_vl1.sel_fiscmnth_1
        WHEN SV_CAL_MTH.MTH_KEY >= #start_date_vl1.sel_fiscmnth_10
            THEN #start_date_vl1.sel_fiscmnth_10
        ELSE SV_CAL_MTH.MTH_KEY
    END AS fiscmnth,
    CAST('1' AS CHAR(16)) AS Quality,
    CAST(0 AS DECIMAL(10,0)) AS BegInvQty,
    CAST(0 AS DECIMAL(10,0)) AS OpenOrdQty,
    CAST(0 AS DECIMAL(10,0)) AS DueInQty,
    CAST(SUM(
        CASE 
            WHEN "/BIC/ZKDFCST" <= 0 
                THEN 0 
            ELSE "/BIC/ZKDFCST"
        END) AS DECIMAL(10,0)) AS ForecastQty,

FROM
    SAPPW1DB."/BIC/AZGSNPD0100" INNER JOIN 
        (
            SELECT 
                MAX("/BIC/ZCVERSSNP") AS "/BIC/ZCVERSSNP"
            
            FROM 
                SAPPW1DB."/BIC/AZGSNPD0100"
            
            WHERE 
                CAST("/BIC/AZGSNPD0100".APO_LOCNO AS CHAR(4)) IN ('1018', '3002', '3003', '3045')
                AND MATERIAL  like '00501-0101'
                AND AF_GRDVAL <> ' '
                AND VERSION = '000'
        ) AS CurrentSnap ON ("/BIC/AZGSNPD0100"."/BIC/ZCVERSSNP" = CurrentSnap."/BIC/ZCVERSSNP")

    INNER JOIN PROD_EDW_VIEWS.SV_CAL_MTH
        ON ("/BIC/AZGSNPD0100".FISCPER = SV_CAL_MTH.FISCPER AND SV_CAL_MTH.CAL_TYPE_CD = 'LS'),

    #start_date_vl1

WHERE
    CAST("/BIC/AZGSNPD0100".APO_LOCNO AS CHAR(4)) IN ('1018', '3002', '3003', '3045')
    AND MATERIAL like '00501-0101'
    AND AF_GRDVAL <> ' '
    AND VERSION = '000'

GROUP BY
    CAST("/BIC/AZGSNPD0100".APO_LOCNO AS CHAR(4)),
    "/BIC/AZGSNPD0100".Material,
/*  CASE 
        WHEN POSITION('-' IN "/BIC/AZGSNPD0100".AF_GRDVAL) > 0 
            THEN SUBSTR("/BIC/AZGSNPD0100".AF_GRDVAL, 1, POSITION('-' IN "/BIC/AZGSNPD0100".AF_GRDVAL)  -1) || SUBSTR("/BIC/AZGSNPD0100".AF_GRDVAL, POSITION('-' IN "/BIC/AZGSNPD0100".AF_GRDVAL) + 1, CHARACTER_LENGTH("/BIC/AZGSNPD0100".AF_GRDVAL))
        ELSE "/BIC/AZGSNPD0100".AF_GRDVAL   
    END,
*/  CASE
        WHEN SV_CAL_MTH.MTH_KEY <= #start_date_vl1.sel_fiscmnth_1
            THEN #start_date_vl1.sel_fiscmnth_1
        WHEN SV_CAL_MTH.MTH_KEY >= #start_date_vl1.sel_fiscmnth_10 
            THEN #start_date_vl1.sel_fiscmnth_10
        ELSE SV_CAL_MTH.MTH_KEY
    END

HAVING 
    SUM(
        CASE 
            WHEN "/BIC/ZKDFCST" <= 0
                THEN 0 
            ELSE "/BIC/ZKDFCST"
        END) > 0

