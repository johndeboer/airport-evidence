---
title: Security Wait Times at GRR
---

<Details title='Definitions'>

    Definitions of metrics used in this dashboard

    ### Wait

    A wait is logged for any time the TSA Precheck or Standard security line reports having a wait time of more than 5 minutes.  Unless specified, a wait is logged when one or both security lines have a wait.

    *Calculation:* Sum of the observations that have a wait time greater than 5

    *Source:* grr.org

</Details>

```sql days
    select distinct date from system_phase_reference.delays
```

```sql delays
    select weekday,
           weekday_name,
           time_bucket_label,
           sum(case when precheck_minutes > 5 or standard_minutes > 5 then 1 else 0 end) as waits
            from system_phase_reference.delays
            where date between '${inputs.observation_range.start}' and '${inputs.observation_range.end}'
           group by weekday, time_bucket_label, weekday_name
           order by weekday, time_bucket_label
```

```sql delay_days
   select date,
   sum(case when precheck_minutes > 5 or standard_minutes > 5 then 1 else 0 end) as waits
   from system_phase_reference.delays
   where date between '${inputs.observation_range.start}' and '${inputs.observation_range.end}'
   group by date,
   order by date
```

```sql last_delay
   with ld as (select max(date) as last_wait
   from system_phase_reference.delays
   where standard_minutes > 5 
   or precheck_minutes > 5)
   select last_wait,
          today() - date(last_wait) as days_since_last_wait
   from ld
```

```sql delays_with_comparison
   with cm as (
    select sum(case when precheck_minutes > 5 or standard_minutes > 5 then 1 else 0 end) waits
    from system_phase_reference.delays
    where extract(YEAR from date) = extract(YEAR from today())
      and extract(MONTH from date) = extract(MONTH from today())
   ),
   lm as (
    select sum(case when precheck_minutes > 5 or standard_minutes > 5 then 1 else 0 end) waits
    from system_phase_reference.delays
    where extract(YEAR from date) = extract(YEAR from today() - interval '1 month')
      and extract(MONTH from date) = extract(MONTH from today() - interval '1 month')
   ),
   cy as (
    select sum(case when precheck_minutes > 5 or standard_minutes > 5 then 1 else 0 end) waits
    from system_phase_reference.delays
    where extract(YEAR from date) = extract(YEAR from today())
   ),
   ly as (
    select sum(case when precheck_minutes > 5 or standard_minutes > 5 then 1 else 0 end) waits
    from system_phase_reference.delays
    where extract(YEAR from date) = extract(YEAR from today() - interval '1 year')
   )
   select cm.waits as waits_in_current_month,
          lm.waits as last_month,
          cm.waits / lm.waits as over_last_month,
          cy.waits as waits_in_current_year,
          ly.waits as last_year,
          cy.waits / ly.waits as over_last_year
   from cm, lm, cy, ly

```

<Grid cols=2>
    <BigValue 
        data = {last_delay}
        value = last_wait
        fmt= fulldate
    />

    <BigValue 
        data = {last_delay}
        value = days_since_last_wait
        fmt= num0
    />

    <BigValue
        data = {delays_with_comparison}
        value = waits_in_current_month
        fmt = num0
        comparison=over_last_month
        comparisonFmt=pct0
        comparisonTitle='MoM'
        downIsGood=true
        
    />

    <BigValue
        data = {delays_with_comparison}
        value = waits_in_current_year
        fmt = num0
        comparison=over_last_year
        comparisonFmt=pct0
        comparisonTitle='YoY'
        downIsGood=true
    />
</Grid>
<LineBreak lines=3/>

<DateRange
    name=observation_range
    data={days}
    dates=date
/>

<Heatmap data={delays}
    title = 'Wait Frequency'
    subtitle = 'By Day and Time'
    x = weekday_name
    y = time_bucket_label
    value = waits
    valueLabels=false
    colorPalette={'white','darkorange'}
    legend=false
/>

<CalendarHeatmap data={delay_days}
    date = date
    value = waits
    title = 'Waits by Day'
    colorPalette={'white','darkorange'}
    dayLabel=false
    legend=false
/>

<LastRefreshed />