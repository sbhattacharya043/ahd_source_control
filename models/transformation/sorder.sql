
{{ config(
    materialized='table'
) }}

select
    *
from {{ source('fivetran_raw', 'sorder') }}