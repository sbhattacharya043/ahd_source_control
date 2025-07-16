/*
This code space contains the code to create the view of the captioned name */

{{ config(materialized='view') }}

WITH istat AS (
	SELECT *
	FROM (
		SELECT
			t.LANNUM_0 AS Item_status,
			t.LANMES_0 AS Item_status_desc,
			ROW_NUMBER() OVER (PARTITION BY t.LANNUM_0 ORDER BY t.LANMES_0) AS rn
		FROM FIVETRAN_DATABASE.SAGEX3_PROD.APLSTD t 
		WHERE t.LAN_0 = 'ENG' AND t.LANCHP_0 = 6004
	) AS sub
	WHERE rn = 1
),
it AS (
	SELECT *
	FROM (
		SELECT
			t.LANNUM_0 AS LineTypeCode,
			t.LANMES_0 AS LineTypeName,
			ROW_NUMBER() OVER (PARTITION BY t.LANNUM_0 ORDER BY t.LANMES_0) AS rn
		FROM FIVETRAN_DATABASE.SAGEX3_PROD.APLSTD t 
		WHERE t.LAN_0 = 'ENG' AND t.LANCHP_0 = 6008
	) AS sub
	WHERE rn = 1
)

SELECT 
  i.ITMREF_0 as ItemCode
, LEFT(i.TSICOD_0, 2) as Company
, z1.Y_STATUS_0 as Item_Status
, i.SAUSTUCOE_0 as Pack_Qty
, i.ITMDES2_0 as Product_code
 , istat.Item_status_desc as Status
, z1.Y_PROD_NAME_0 as Photo_Name
, z1.Y_FAMILY_0 as Family
, z1.Y_PROD_NAME_0 as Product_Name
, i.ITMDES3_0 as Description_3
 , it.LineTypeName as Marketing_Item_Type
, z1.Y_HEIGHT_0 as Height
, z1.Y_LENGTH_0 as WidthLength
, z1.Y_DEPTH_0 as Depth
, z1.Y_DIAMETER_0 as Diameter
, z1.Z_MKTHEIGHT2_0 as Height2
, z1.Y_LENGTH2_0 as WidthLeng2
, z1.Z_MKTDEPTH2_0 as Depth_2
, z1.Z_MKTDIAM2_0 as Diameter_2
, z1.Z_MKTHEIGHT3_0 as Height_3
, z1.Y_LENGTH3_0 as WidthLength3
, z1.Z_MKTDEPTH3_0 as Depth_3
, z1.Z_MKTDIAM3_0 as Diameter_3
, i.PURBASPRI_0 as Base_price_MSRP_pack
, z1.Z_IND_MSRP_0 as Unit_MSRP_if_pack
	 ,NULL as Pack_Qty2
	 -- Stocking customer price (based on pack MSRP), use logic according to brands.  i.e. MG, PP is 60% discount.  BP is 55% discount and TH is 50%. Diane Email Thursday, August 24, 2023 5:20 PM - RE: TSS - Excel Export - Inquiry
		,CAST(
    CASE LEFT(i.TSICOD_0, 2)
        WHEN 'MG' THEN z1.Z_IND_MSRP_0 * 0.40
        WHEN 'PP' THEN z1.Z_IND_MSRP_0 * 0.40
        WHEN 'BP' THEN z1.Z_IND_MSRP_0 * 0.45
        WHEN 'TH' THEN z1.Z_IND_MSRP_0 * 0.50
        ELSE NULL
    END AS DECIMAL(19,2)
) AS Stocking_Pack,

CAST(
    CASE LEFT(i.TSICOD_0, 2)
        WHEN 'MG' THEN z1.Z_IND_MSRP_0 * 0.35
        WHEN 'PP' THEN z1.Z_IND_MSRP_0 * 0.40
        WHEN 'BP' THEN z1.Z_IND_MSRP_0 * 0.35
        WHEN 'TH' THEN z1.Z_IND_MSRP_0 * 0.35
        ELSE NULL
    END AS DECIMAL(19,2)
) AS Wholesale_Pack
, i.ZFINISH_0 as Finish
, z1.Y_MATERIAL_0  as Material
, -- New
CASE z1.Y_NEW_0 
    WHEN 1 THEN 'NO' 
    WHEN 2 THEN 'YES' 
    ELSE NULL 
END AS New,

-- Outdoor
CASE z1.Y_OUTDOOR_0 
    WHEN 1 THEN 'NO' 
    WHEN 2 THEN 'YES' 
    ELSE NULL 
END AS Outdoor,

-- Category and Subcategories
z1.Y_MRK_CAT_0 AS Category,
z1.Y_MRK_SUBC_1_0 AS SUBCAT_CODE1,
z1.Y_MRK_SUBC_2_0 AS SUBCAT_CODE2,
z1.Y_MRK_SUBC_3_0 AS SUBCAT_CODE3,
z1.Y_MRK_SUBC_4_0 AS SUBCAT_CODE4,

-- Sold As (Case sensitive logic)
CASE 
    WHEN LEFT(i.TSICOD_0, 2) = 'MG' THEN 
        CASE UPPER(TRIM(z1.Y_OBJ_SOLDAS_0))
            WHEN 'BY SQFT' THEN 'By Sqft'
            WHEN 'BY THE HIDE' THEN 'By the hide'
            WHEN 'BY THE YARD' THEN 'By the yard'
            WHEN 'INDIVIDUAL' THEN 'IND'
            WHEN 'INDIVDUAL' THEN 'IND'
            WHEN 'INDIVIDUAL,' THEN 'IND'
            WHEN 'INDIVUDAL' THEN 'IND'
            WHEN 'MULTIPLE OF 12' THEN 'M/12'
            WHEN 'MULTIPLE OF 2' THEN 'M/2'
            WHEN 'MULTIPLE OF 4' THEN 'M/4'
            WHEN 'MULTIPLE OF 6' THEN 'M/6'
            WHEN 'MULTIPLE OF 8' THEN 'M/8'
            WHEN 'MULTIPLES OF 2' THEN 'M/2'
            WHEN 'MULTIPLES OF 3' THEN 'M/3'
            WHEN 'S/2' THEN 'S/2'
            WHEN 'SET OF 2' THEN 'S/2'
            WHEN 'SET OF 3' THEN 'S/3'
            WHEN 'SET OF 4' THEN 'S/4'
            WHEN 'SET OF 6' THEN 'S/6'
            WHEN 'TWO SETS OF 3' THEN 'Two sets of 3'
            ELSE z1.Y_OBJ_SOLDAS_0
        END
    ELSE z1.Y_OBJ_SOLDAS_0
END AS Sold_As_Case_sensitive,

z2.Z_SHORTDES_0 as Short_Description,
z2.Z_TAG_SIZE_0 as Tag_Size,
-- Introduced Date (string formatted)
CASE
    WHEN TRY_TO_DATE('1-' || LEFT(TRIM(z1.Y_INTRO_DATE_0), 3) || '-20' || RIGHT(TRIM(z1.Y_INTRO_DATE_0), 2), 'DD-MON-YYYY') IS NOT NULL
    THEN RIGHT(TRIM(z1.Y_INTRO_DATE_0), 2) || '-' || LEFT(TRIM(z1.Y_INTRO_DATE_0), 3)
    ELSE NULL
END AS Introduced_Date,

-- Introduced Date2 (actual date)
CASE
    WHEN TRY_TO_DATE('1-' || LEFT(TRIM(z1.Y_INTRO_DATE_0), 3) || '-20' || RIGHT(TRIM(z1.Y_INTRO_DATE_0), 2), 'DD-MON-YYYY') IS NOT NULL
    THEN TO_DATE('1-' || LEFT(TRIM(z1.Y_INTRO_DATE_0), 3) || '-20' || RIGHT(TRIM(z1.Y_INTRO_DATE_0), 2), 'DD-MON-YYYY')
    ELSE NULL
END AS Introduced_Date2

FROM 
		  FIVETRAN_DATABASE.SAGEX3_PROD.ITMMASTER AS i
LEFT JOIN FIVETRAN_DATABASE.SAGEX3_PROD.ZITMMASTER1 AS z1 ON z1.ITMREF_0 = i.ITMREF_0
LEFT JOIN FIVETRAN_DATABASE.SAGEX3_PROD.ZITMMASTER2 AS z2 ON z2.ITMREF_0 = i.ITMREF_0
INNER JOIN istat ON z1.Y_STATUS_0 = istat.Item_status
INNER JOIN it ON z1.Y_MRK_ITM_TY_0 = it.LineTypeCode
where i._fivetran_deleted = FALSE
and z1._fivetran_deleted = FALSE
and z2._fivetran_deleted = FALSE