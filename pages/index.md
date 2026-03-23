---
title: Security Wait Times at GRR
---

<Tabs>

<Tab label="Wait Times">

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

```sql times
    select distinct time_bucket_label from system_phase_reference.delays
```

```sql weekdays
    select distinct weekday, weekday_name from system_phase_reference.delays
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

```sql longest_wait
    select weekday,
           weekday_name,
           time_bucket_label,
           max(greatest(precheck_minutes, standard_minutes)) as longest_wait
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

<Heatmap data={longest_wait}
    title = 'Longest Wait'
    subtitle = 'Wait Time in Minutes'
    x = weekday_name
    y = time_bucket_label
    value = longest_wait
    colorPalette = {'white','darkorange'}
    legend = false
/>

<LastRefreshed />

</Tab>

<Tab label="Trip Planner">

```sql latest_week_start
   select (current_date - interval '26 weeks')::date as week_start
```

```sql last_wait_over_5_mins
    with last_date as (
        select max(date) as last_occurrence_date
        from system_phase_reference.delays
        where greatest(precheck_minutes, standard_minutes) > 5
            and weekday = '${inputs.selected_weekday.value}'
            and time_bucket_label = '${inputs.selected_time_bucket.value}'
    )
    select
        d.weekday,
        d.weekday_name,
        d.time_bucket_label,
        ld.last_occurrence_date,
        max(greatest(d.precheck_minutes, d.standard_minutes)) as wait_length
    from system_phase_reference.delays d
    cross join last_date ld
    where d.date = ld.last_occurrence_date
        and d.weekday = '${inputs.selected_weekday.value}'
        and d.time_bucket_label = '${inputs.selected_time_bucket.value}'
    group by d.weekday, d.weekday_name, d.time_bucket_label, ld.last_occurrence_date
```

```sql longest_wait_in_slot
    select max(greatest(precheck_minutes, standard_minutes)) as longest_wait
    from system_phase_reference.delays
    where weekday = '${inputs.selected_weekday.value}'
        and time_bucket_label = '${inputs.selected_time_bucket.value}'
```

```sql max_wait_26_weeks
    select 
        date_trunc('day', date)::date as week,
        max(greatest(precheck_minutes, standard_minutes)) as max_wait
    from system_phase_reference.delays
    where weekday = '${inputs.selected_weekday.value}'
        and time_bucket_label = '${inputs.selected_time_bucket.value}'
        -- and date >= (current_date - interval '26 weeks')
    group by date_trunc('day', date)::date
    order by week
```

Select your travel day and time to see when you last would have encountered a wait:

<Grid cols=2>
    <Dropdown
        data={weekdays}
        name=selected_weekday
        title="Day of Week"
        value=weekday
        label=weekday_name
        order=weekday
    />
    
    <Dropdown
        data={times}
        name=selected_time_bucket
        title="Time Bucket"
        value=time_bucket_label
        label=time_bucket_label
    />
</Grid>

<Grid cols=4>
    <BigValue 
        data={last_wait_over_5_mins}
        value=last_occurrence_date
        fmt="ddd mmm d, yyyy"
        title="Last 5+ Min Wait"
        emptySet=pass
        emptyMessage="No waits over 5 minutes"
    />
    
    <BigValue 
        data={last_wait_over_5_mins}
        value=wait_length
        fmt=num0
        title="Last Wait Length"
        emptySet=pass
        emptyMessage="No waits over 5 minutes"
    />
    
    <BigValue 
        data={longest_wait_in_slot}
        value=longest_wait
        fmt=num0
        title="Longest Wait Ever"
    />
    
    <BigValue 
        data={max_wait_26_weeks}
        value=max_wait
        fmt=num0
        title="Max Wait (26 weeks)"
    />
</Grid>

<LineChart 
    data={max_wait_26_weeks}
    x=week
    y=max_wait
    title="Max Wait Time Over Last 26 Weeks"
    subtitle="For selected day and time"
    yAxisTitle="Max Wait (minutes)"
/>

</Tab>

</Tabs>