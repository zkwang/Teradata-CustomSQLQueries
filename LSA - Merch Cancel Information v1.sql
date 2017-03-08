-- 1st query takes ~15 mins to execute and save within a volatile table
create volatile table tmp_ALL_CANCEL_DATA as
(
    select
        EDWARD.ORDER_HEADER.CUST_XREF_ID,
        EDWARD.CALENDAR_DAY.FISC_WK_KEY,
        EDWARD.CALENDAR_DAY.FISC_MTH_KEY as FISC_MTH_ACTUAL,
        XTRA_FISCAL_WK_FLAG.FISC_MTH_KEY as FISC_MTH_FOR_WINDOW,
        XTRA_FISCAL_WK_FLAG.EXTRA_WK_FLAG,
        EDWARD.PRODUCT.PROD_CD_9,
        EDWARD.ORD_ITEM_SIZE.SIZE_DIM_1_CD,
        EDWARD.ORD_ITEM_SIZE.SIZE_DIM_2_CD,
        sum(EDWARD.ORD_ITEM_SIZE.WMENG_ORDERED_QTY) as WMENG_ORDERED_QTY,
        sum(EDWARD.ORD_ITEM_SIZE.ORD_SIZE_SHIP_QTY) as ORD_SIZE_SHIP_QTY,
        sum(EDWARD.ORD_ITEM_SIZE.ORD_SIZE_CANCEL_QTY) as ORD_SIZE_CANCEL_QTY,
        sum(case when EDWARD.CANCEL_DELETE_CD.CANCEL_DELETE_CD = 'MER' then EDWARD.ORD_ITEM_SIZE.ORD_SIZE_CANCEL_QTY else 0 end) as ORD_SIZE_MER_CANCEL_QTY,
        sum(case when EDWARD.CANCEL_DELETE_CD.CANCEL_DELETE_CD = 'SLS' then EDWARD.ORD_ITEM_SIZE.ORD_SIZE_CANCEL_QTY else 0 end) as ORD_SIZE_SLS_CANCEL_QTY,
        sum(case when EDWARD.CANCEL_DELETE_CD.CANCEL_DELETE_CD = 'OTH' then EDWARD.ORD_ITEM_SIZE.ORD_SIZE_CANCEL_QTY else 0 end) as ORD_SIZE_OTH_CANCEL_QTY

    from
        -- Foundation Tables for Order Information
        EDWARD.ORDER_HEADER 
        inner join EDWARD.ORD_ITEM on 
            (EDWARD.ORDER_HEADER.ORD_CNTL_NUM = EDWARD.ORD_ITEM.ORD_CNTL_NUM and EDWARD.ORDER_HEADER.ORD_ENTRY_DT = EDWARD.ORD_ITEM.ORD_ENTRY_DT and EDWARD.ORDER_HEADER.ORD_SRCE_CD = EDWARD.ORD_ITEM.ORD_SRCE_CD)
        inner join EDWARD.ORD_ITEM_SIZE on
            (EDWARD.ORD_ITEM_SIZE.POSNR_SLS_DOC_ITEM_NUM = EDWARD.ORD_ITEM.POSNR_SLS_DOC_ITEM_NUM and EDWARD.ORD_ITEM_SIZE.PROD_KEY = EDWARD.ORD_ITEM.PROD_KEY and EDWARD.ORD_ITEM_SIZE.ORD_CNTL_NUM = EDWARD.ORD_ITEM.ORD_CNTL_NUM and EDWARD.ORD_ITEM_SIZE.ORD_ENTRY_DT = EDWARD.ORD_ITEM.ORD_ENTRY_DT and EDWARD.ORD_ITEM_SIZE.ORD_SRCE_CD = EDWARD.ORD_ITEM.ORD_SRCE_CD)

        -- Calendar Table
        left join EDWARD.CALENDAR_DAY on
            (EDWARD.ORDER_HEADER.ORD_ROG_DT = EDWARD.CALENDAR_DAY.CAL_DAY_KEY)
        inner join 
            (select 
                FISC_MTH_KEY, FISC_WK_KEY, 'N' as EXTRA_WK_FLAG, WK_OF_FISC_MTH_NUM
             from 
                EDWARD.FISCAL_WK
             union
             select 
                PREV_FISC_MTH_KEY, FISC_WK_KEY, 'Y' as EXTRA_WK_FLAG, null as WK_OF_FISC_MTH_NUM
             from 
                EDWARD.FISCAL_WK 
                inner join EDWARD.FISCAL_MTH on
                    (EDWARD.FISCAL_WK.FISC_MTH_KEY = EDWARD.FISCAL_MTH.FISC_MTH_KEY)
            ) XTRA_FISCAL_WK_FLAG on
                (EDWARD.CALENDAR_DAY.FISC_WK_KEY = XTRA_FISCAL_WK_FLAG.FISC_WK_KEY)

        -- Cancel Codes Information
        left join EDWARD.CANCEL_DELETE_CD on
            (EDWARD.ORD_ITEM.CANCEL_DELETE_CD = EDWARD.CANCEL_DELETE_CD.CANCEL_DELETE_CD)

        -- Product Information
        left join EDWARD.PRODUCT on
            (ORD_ITEM.PROD_KEY = PRODUCT.PROD_KEY)
        left join EDWARD.BRAND_EXT_BRAND_ASSO on
            (PRODUCT.BRAND_EXT_ID = BRAND_EXT_BRAND_ASSO.BRAND_EXT_ID)
        left join EDWARD.BRAND on
            (BRAND_EXT_BRAND_ASSO.BRAND_ID = BRAND.BRAND_ID)
        left join EDWARD.CONSUMER_GRP_EXT on
            (PRODUCT.CONSM_GRP_EXT_ID = CONSUMER_GRP_EXT.CONSM_GRP_EXT_ID)
        left join EDWARD.CONSUMER_GRP on
            (CONSUMER_GRP_EXT.CONSM_GRP_ID = CONSUMER_GRP.CONSM_GRP_ID)

    where
        -- Filter for specific fiscal years
        EDWARD.CALENDAR_DAY.FISC_YR_KEY in (2013, 2014, 2015, 2016, 2017)

        -- Pull only cancel related orders
        and (EDWARD.ORD_ITEM_SIZE.J_3AABGRU_REJECT_RSN_CD is null 
            or EDWARD.ORD_ITEM_SIZE.J_3AABGRU_REJECT_RSN_CD not in ('B6','B2','C2','C4','C6','C7','C8','E1','E2','E3','E4','J2'))
        
        -- Filter for specific product attributes
        and EDWARD.BRAND.BRAND_ID like '%L%'
        and EDWARD.CONSUMER_GRP.CONSM_GRP_ID in ('MEN','001')
        and EDWARD.PRODUCT.PROD_CAT_CD like '%Bottom%'

    group by 1, 2, 3, 4, 5, 6, 7, 8
) with data primary index (CUST_XREF_ID, FISC_WK_KEY, PROD_CD_9, SIZE_DIM_1_CD, SIZE_DIM_2_CD, FISC_MTH_ACTUAL, FISC_MTH_FOR_WINDOW) on commit preserve rows;

-- 2nd Query to be run only after 1st query has been finished
select 
    CUST_XREF_ID,
    FISC_WK_KEY,
    FISC_MTH_FOR_WINDOW as FISC_MTH_KEY,
    EXTRA_WK_FLAG,
    PROD_CD_9,
    SIZE_DIM_1_CD,
    SIZE_DIM_2_CD,
    WMENG_ORDERED_QTY,
    ORD_SIZE_SHIP_QTY,
    ORD_SIZE_CANCEL_QTY,
    sum(ORD_SIZE_CANCEL_QTY) over (partition by CUST_XREF_ID, PROD_CD_9, SIZE_DIM_1_CD, SIZE_DIM_2_CD, FISC_MTH_FOR_WINDOW order by FISC_WK_KEY rows between 1 preceding and 1 preceding) as PREV_WK_CANCEL_QTY,
    case when WMENG_ORDERED_QTY - coalesce(PREV_WK_CANCEL_QTY, 0) > 0 then WMENG_ORDERED_QTY - coalesce(PREV_WK_CANCEL_QTY, 0) else 0 end as ADJ_ORDERED_QTY,
    case when ORD_SIZE_CANCEL_QTY < ADJ_ORDERED_QTY then ORD_SIZE_CANCEL_QTY else ADJ_ORDERED_QTY end as ADJ_CANCEL_QTY,
    case when ORD_SIZE_MER_CANCEL_QTY < ADJ_ORDERED_QTY then ORD_SIZE_MER_CANCEL_QTY else ADJ_ORDERED_QTY end as ADJ_MER_CANCEL_QTY,
    case when ORD_SIZE_SLS_CANCEL_QTY < ADJ_ORDERED_QTY then ORD_SIZE_SLS_CANCEL_QTY else ADJ_ORDERED_QTY end as ADJ_SLS_CANCEL_QTY,
    case when ORD_SIZE_OTH_CANCEL_QTY < ADJ_ORDERED_QTY then ORD_SIZE_OTH_CANCEL_QTY else ADJ_ORDERED_QTY end as ADJ_OTH_CANCEL_QTY,
    case when WMENG_ORDERED_QTY - ADJ_ORDERED_QTY > 0 then WMENG_ORDERED_QTY - ADJ_ORDERED_QTY else 0 end as DUPLICATIVE_DEMAND_QTY,
    sum(WMENG_ORDERED_QTY) over (partition by CUST_XREF_ID, PROD_CD_9, SIZE_DIM_1_CD, SIZE_DIM_2_CD, FISC_MTH_FOR_WINDOW order by FISC_WK_KEY rows between 1 following and 1 following) as NEXT_WK_ORDERED_QTY,
    case 
        when PREV_WK_CANCEL_QTY is null or EXTRA_WK_FLAG = 'Y' then 
        case 
            when WK_OF_FISC_MTH_NUM = 1 or EXTRA_WK_FLAG = 'Y' then 0 else
            case
                when NEXT_WK_ORDERED_QTY is not null then 0 else ORD_SIZE_CANCEL_QTY
            end
        end else
        case
            when NEXT_WK_ORDERED_QTY is not null then
            case
                when PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY > 0 then PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY else 0
            end else
            case
                when PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY + ORD_SIZE_CANCEL_QTY > 0 then PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY + ORD_SIZE_CANCEL_QTY else 0
            end
        end
    end as LOST_SALES_QTY,
    min(EXTRA_WK_FLAG) over (partition by CUST_XREF_ID, PROD_CD_9, SIZE_DIM_1_CD, SIZE_DIM_2_CD, FISC_MTH_FOR_WINDOW order by FISC_WK_KEY rows between 1 following and 1 following) as EXTRA_WK_FLAG_NEXT_WK,
    case when PREV_WK_CANCEL_QTY is null or EXTRA_WK_FLAG = 'Y'
        then case when EXTRA_WK_FLAG = 'Y' 
            then case when NEXT_WK_ORDERED_QTY is not null and EXTRA_WK_FLAG_NEXT_WK = 'N' 
                then 0 
                else ORD_SIZE_CANCEL_QTY 
                end 
            else case when NEXT_WK_ORDERED_QTY is not null 
                then case when EXTRA_WK_FLAG_NEXT_WK = 'Y' 
                    then ORD_SIZE_CANCEL_QTY
                    else 0 
                    end 
                else ORD_SIZE_CANCEL_QTY 
                end
            end
        else case when NEXT_WK_ORDERED_QTY is not null
            then case when EXTRA_WK_FLAG_NEXT_WK = 'Y'
                then case when PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY + ORD_SIZE_CANCEL_QTY > 0
                    then PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY + ORD_SIZE_CANCEL_QTY
                    else 0 
                    end
                else case when PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY > 0
                    then PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY
                    else 0 
                    end
                end
            else case when PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY + ORD_SIZE_CANCEL_QTY > 0
                then PREV_WK_CANCEL_QTY - WMENG_ORDERED_QTY + ORD_SIZE_CANCEL_QTY
                else 0 
                end
            end
        end
    end as LOST_SALES_STRICT_QTY
from 
    tmp_ALL_CANCEL_DATA

    -- Product Attribute History Data
    left join tmp_PC9_DA_MONTH on
        (tmp_ALL_CANCEL_DATA.PROD_CD_9 = tmp_PC9_DA_MONTH.PC9 and tmp_ALL_CANCEL_DATA.FISC_MTH_KEY = tmp_PC9_DA_MONTH.FISC_MTH_KEY)
