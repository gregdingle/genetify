
/*
    TODO is ordering bad in views if later queries re-order?
*/
/*
    TODO limit to last X pageviews for speed
*/

drop view pageview_reward;
create view pageview_reward as 
    select pageview.*, 
        count(pageview_id) as 'count_goals', 
        sum(IFNULL(goal.value, 0)) as 'reward',
        avg(IFNULL(goal.value, 0)) as 'average_goal_value',
        avg(IFNULL(goal.value, 0) > 0) as 'conversion'
    from pageview 
    left join goal using(pageview_xid)
    group by pageview_id;

select * from pageview_reward order by pageview_id desc;
                               

/*TODO this is being used by graphs but it is too slow*/      
/* TODO change to materialized view */
drop view variant_reward;
create view variant_reward as
    select domain.name as 'domain_name', 
        page.name as 'page_name', 
        gene_id,
        gene.name as 'gene_name', 
        variant_id,
        variant.name as 'variant_name', 
        concat_ws(' -> ', gene.name, variant.name) as 'gene_variant',
        reward 
    from pageview_reward 
    inner join page using(page_id)
    inner join domain using(domain_id)
    inner join genome using(genome_id)
    inner join genome_variant_link using(genome_id)
    inner join variant using(variant_id)
    inner join gene using(gene_id);
                             
select * from variant_reward order by variant_id;


drop view gene_aggregate_reward;
create view gene_aggregate_reward as
    SELECT gene_id,
        COUNT(reward) as 'gene_count', 
        COUNT(reward/reward) as 'gene_nonzero', 
        SUM(reward) as 'gene_sum',
        AVG(reward) as 'gene_avg',
        COUNT(DISTINCT variant_id) as 'gene_distinct'
    FROM variant_reward 
    GROUP BY gene_id;

select * from gene_aggregate_reward;


-- variant weight is relative share softened by diminishing constant
-- constant controls amount of softening 
/*TODO parameterize constant*/
DROP PROCEDURE get_variant_relative_reward;
DELIMITER |
CREATE PROCEDURE get_variant_relative_reward(domain_value VARCHAR(255), page_value VARCHAR(255), gene_value VARCHAR(255)) 
BEGIN
    CALL get_variant_reward(domain_value, page_value, gene_value);
    SELECT 
        domain_name,
        page_name,
        gene_name, 
        variant_name,
    
        COUNT(variant_id) as 'variant_count', 
        SUM(reward) as 'variant_sum', 
        AVG(reward) as 'variant_avg', 
        STDDEV(reward) as 'variant_stddev', 

        SUM(reward)/agg.`gene_sum` as 'variant_share',
        (SUM(reward)/agg.`gene_sum` + 5/agg.`gene_nonzero`)
            / (1 + `gene_distinct`*5/agg.`gene_nonzero`) as 'variant_weight'
    FROM gene_aggregate_reward as agg 
        LEFT JOIN result as variant_reward USING(gene_id)     
    WHERE   
        domain_name = domain_value 
        AND page_name = page_value 
        AND gene_name LIKE IFNULL(gene_value, '%')
    GROUP BY variant_id
    ORDER BY variant_name = '__original__', variant_name DESC;
END; |
DELIMITER ;

CALL get_variant_relative_reward('localhost.com', '/genetify/', NULL);


DROP PROCEDURE get_improvement;
CREATE PROCEDURE get_improvement(domain_value VARCHAR(255), page_value VARCHAR(255), gene_value VARCHAR(255)) 
    SELECT gene_id,
        gene_name,
        gene_sum, 
        AVG(reward)*gene_count as 'original_baseline',
        gene_sum - AVG(reward)*gene_count as 'improvement_difference',
        gene_sum / (AVG(reward)*gene_count) as 'improvement_factor'
    FROM variant_reward 
        INNER JOIN gene_aggregate_reward USING(gene_id)
    WHERE variant_name = '__original__'
        AND domain_name = domain_value 
        AND page_name = page_value 
        AND gene_name LIKE IFNULL(gene_value, '%')
    GROUP BY gene_id;

CALL get_improvement('localhost.com', '/genetify/', NULL);


-----------------------6

--     TRUNCATE ALL
truncate table goal;
truncate table pageview;
truncate table genome_variant_link;
truncate table variant;
truncate table gene;
truncate table genome;
truncate table referrer;
truncate table error;
truncate table visitor;
truncate table page;
truncate table domain;
truncate table result;

-----------------------



CREATE TABLE IF NOT EXISTS result2 AS 
SELECT variant_id, domain_name, page_name, gene_name, variant_name, COUNT(variant_id) as 'variant_count', SUM(reward) as 'variant_sum', AVG(reward) as 'variant_avg', STDDEV(reward) as 'variant_stddev', SUM(reward)/agg.`gene_sum` as 'variant_share', (SUM(reward)/agg.`gene_sum` + 5/agg.`gene_nonzero`) / (1 + `gene_distinct`*5/agg.`gene_nonzero`) as 'variant_weight' FROM (SELECT gene_id, COUNT(reward) as 'gene_count', COUNT(reward/reward) as 'gene_nonzero', SUM(reward) as 'gene_sum', AVG(reward) as 'gene_avg', COUNT(DISTINCT variant_id) as 'gene_distinct' from (SELECT domain_name, page_name, gene_id, gene.name as 'gene_name', variant_id, variant.name as 'variant_name', concat_ws(' -> ', gene.name, variant.name) as 'gene_variant', reward from (SELECT domain.name as 'domain_name', page.name as 'page_name', genome_id, count(pageview_id) as 'count_goals', sum(IFNULL(goal.value, 0)) as 'reward', avg(IFNULL(goal.value, 0)) as 'average_goal_value', avg(IFNULL(goal.value, 0) > 0) as 'conversion' from pageview left join goal using(pageview_xid) inner join page using(page_id) inner join domain using(domain_id) WHERE domain.name = 'localhost.com' AND page.name = '/genetify/' group by pageview_id) as pageview_reward inner join genome using(genome_id) inner join genome_variant_link using(genome_id) inner join variant using(variant_id) inner join gene using(gene_id)) as variant_reward GROUP BY gene_id) as agg LEFT JOIN (SELECT domain_name, page_name, gene_id, gene.name as 'gene_name', variant_id, variant.name as 'variant_name', concat_ws(' -> ', gene.name, variant.name) as 'gene_variant', reward from (SELECT domain.name as 'domain_name', page.name as 'page_name', genome_id, count(pageview_id) as 'count_goals', sum(IFNULL(goal.value, 0)) as 'reward', avg(IFNULL(goal.value, 0)) as 'average_goal_value', avg(IFNULL(goal.value, 0) > 0) as 'conversion' from pageview left join goal using(pageview_xid) inner join page using(page_id) inner join domain using(domain_id) WHERE domain.name = 'localhost.com' AND page.name = '/genetify/' group by pageview_id) as pageview_reward inner join genome using(genome_id) inner join genome_variant_link using(genome_id) inner join variant using(variant_id) inner join gene using(gene_id)) as variant_reward USING(gene_id) GROUP BY variant_id ORDER BY variant_name = '__original__', variant_name DESC

alter table result2 add unique key (variant_id)
------


select * from error_and_page_and_visitor
    where message like '%Genetify: %'
    order by timestamp desc

select * from error_and_page_and_visitor
    where message like 'http://genetify.com%'
    order by timestamp desc
    
select vary_call, browser, version, count(browser) as b, 
    avg(load_time), avg(init_time), avg(results_time), avg(idle_time), avg(vary_time),
    min(load_time), min(init_time), min(results_time), min(idle_time), min(vary_time),
    stddev(load_time)/avg(load_time), stddev(init_time)/avg(init_time), stddev(results_time)/avg(results_time), stddev(idle_time)/avg(idle_time), stddev(vary_time)/avg(vary_time)
    
    from visitor
    inner join pageview using(visitor_id)
    inner join page using(page_id)
    inner join domain using(domain_id)
    where vary_time != 0
        and abs(load_time) < 4000
        and abs(init_time) < 4000
        and abs(results_time) < 4000
        and abs(vary_time) < 4000
        and domain.name LIKE '%meaningoflife%'
        and timestamp > '2008-02-09'
    group by browser, version, timestamp > '2008-02-11'
    having b > 10
    order by browser, version desc
    
    
---------

select domain.name, page.name, count(pageview_id) from domain join page using(domain_id) join pageview using(page_id)
    group by page_id
    order by count(pageview_id) DESC
