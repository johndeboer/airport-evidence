with fact as (
    select precheck_minutes,
        standard_minutes,
        date_key,
        time_bucket_key
    from `system-phase-reference`.`gold`.`fact_wait_times`
),
dim_date as (
    select date_key,
           weekday,
           date
    from `system-phase-reference`.`gold`.`dim_date`
),
dim_time_bucket as (
    select time_bucket_key,
           time_bucket_label,
           start_hour,
           end_hour
    from `system-phase-reference`.`gold`.`dim_time_bucket`
),
weekdays as (
    select 1 as weekday_id, 'Sunday' as weekday_name
    union all
    select 2, 'Monday'
    union all
    select 3, 'Tuesday'
    union all
    select 4, 'Wednesday'
    union all
    select 5, 'Thursday'
    union all
    select 6, 'Friday'
    union all
    select 7, 'Saturday'
)
select weekday,
       weekday_name,
       date,
        time_bucket_label,
        precheck_minutes,
        standard_minutes
from fact
join dim_date on (fact.date_key = dim_date.date_key)
join dim_time_bucket on (fact.time_bucket_key = dim_time_bucket.time_bucket_key)
join weekdays on (dim_date.weekday = weekdays.weekday_id)