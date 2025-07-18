/* This will create a view in my dev environment on snowflake */

with cte as (
Select 
SalesOrderNo,
COMPANYCODE,
SALESLOCATIONCODE,
ORDERTYPE,
ordertypecode,
ORDERSTATUS,
PAYMENTTERM,
CUSTOMERNO,
CUSTOMERNAME,
QTYORDER,
QTYSHIP,
TOTALAMOUNTLINE,
TOTALAMOUNTTAX,
TOTALAMOUNTFREIGHT,
TOTALAMOUNTDISCOUNTADDITIONAL,
TOTALAMOUNTORDER,
AMOUNTDEPOSITRECEIVE,
CARRIERCODE,
DATEORDER,
DATESHIPMENT,
AllocationStatusCode,
CUSTOMERPONO,
CUSTOMERREFERENCE,
designerspecifier,
designerspecifiersalesrepcode,
SALESREPCODE,
ACCOUNTMANAGERCODE,
SHIPSTATECODE,
SHIPCOUNTRYCODE,
CSRORDERINITIALS,
APPORDERWRITER,
AMOUNTFREIGHTSURCHARGE,
TOTALAMOUNTWHITEGLOVE,
IsUpholstery,
HoldCode,
case 

when 
      isupholstery = FALSE
  AND allocationstatuscode = 3
  AND holdcode NOT IN ('SHIPPING','')
  AND (amountdepositreceive < 0 OR paymentterm LIKE 'NET%')
then 'Fully Allocated, Fully Paid, On-hold, With Terms'

when
      isupholstery = FALSE
  AND allocationstatuscode = 3
  AND holdcode NOT IN ('SHIPPING', '')
  AND (amountdepositreceive > 0 OR paymentterm NOT LIKE 'NET%')
then 'Fully Allocated, Not Fully Paid, Hold-Code, No Terms'

when 
      isupholstery = FALSE
  AND allocationstatuscode = 2
  AND holdcode NOT IN ('SHIPPING', '')
  AND (amountdepositreceive != 0 OR paymentterm LIKE '%NET%')
then 'Partially Allocated, Any Payment or Terms, Hold-Code'


when 
      isupholstery = FALSE
  AND allocationstatuscode = 2
  AND holdcode NOT IN ('SHIPPING','')
  AND (amountdepositreceive = 0 AND paymentterm NOT LIKE 'NET%')
then 'Partially Allocated, No Payment, No Terms, Hold-Code'

when  
      isupholstery = FALSE
  AND allocationstatuscode = 1
  AND holdcode NOT IN ('SHIPPING', 'RESERVEEXP','')
  AND (amountdepositreceive = 0 AND paymentterm NOT LIKE 'NET%')
then 'Not allocated, No Payment, No Terms, Hold-Code'

when 
      isupholstery = FALSE
  AND allocationstatuscode = 1
  AND holdcode NOT IN ('SHIPPING','RESERVEEXP','')
  AND (amountdepositreceive < 0 OR paymentterm LIKE 'NET%')
then 'Not Allocated, Any Payments or Terms, Hold-Code'

when isupholstery = TRUE and holdcode not in ('SHIPPING') then 'UPH'

when holdcode IN ('SHIPPING','') then 'SHIPPING'

else 'Undef' end as ORDERSUMMARYSTATUS

from FIVETRAN_DATABASE.SAGEX3_PROD.VW_SALESORDER_TRIAL

)

select * from cte

