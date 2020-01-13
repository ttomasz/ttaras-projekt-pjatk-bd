import os
import time
from datetime import timedelta, datetime
from multiprocessing import Process
import psycopg2 as pg


batch_query = '''
insert into terrain
select
    a.lokalnyid,
    min(st_z(b.geom)) min_z,
    max(st_z(b.geom)) max_z,
    percentile_cont(0.5) within group(order by st_z(b.geom)) median_z
from dedup2 a
join nmt b on ST_DWithin(a.gml, b.geom, 10000)
where rn > %s and rn < %s
GROUP BY lokalnyid
on conflict do nothing;
'''

dsn = 'host=... port=... user=... dbname=... password=...'
step = 1000


def export_batches(proc_name:str, predicate_list: list, dsn: str) -> None:
    total = len(predicate_list)
    cumulative_time = 0
    batch_counter = 0

    with pg.connect(dsn=dsn) as local_conn:
        local_cur = local_conn.cursor()
        local_cur.execute('''
        set work_mem='5GB';
        set max_parallel_workers_per_gather=1;
        ''')
        for x in predicate_list:
            sts = time.perf_counter()
            local_cur.execute(batch_query, (x, x+step+1))
            local_conn.commit()
            batch_counter += 1
            ets = time.perf_counter()
            delta = ets - sts
            cumulative_time += delta
            print(f'{proc_name} - {batch_counter}/{total} - ids range: {x}-{x+step+1}',
                  'time:', str(timedelta(seconds=delta)),
                  '- cumulative time:', str(timedelta(seconds=cumulative_time)))

if __name__ == '__main__':
    print('START:', datetime.now().isoformat())
    
    # check if there is any progress and continue from last id
    with pg.connect(dsn=dsn) as conn:
        cur = conn.cursor()
        cur.execute('''
            select min(rn)
            from dedup2
            left join terrain on dedup2.lokalnyid = terrain.lokalnyid
            where terrain.lokalnyid is null
        ''')
        res = cur.fetchall()[0][0]
    number_of_processes = 8
    start = 0 if res is None else res-1
    print('starting point:', res)

    # prepare Processes
    data = list(range(start,7500000,step))
    data = [data[i::number_of_processes] for i in range(number_of_processes)]
    print(len(data), [len(data[x]) for x in range(number_of_processes)])
    processes = [
        Process(
            group=None,
            target=export_batches,
            name='Exporter' + str(x),
            args=('Exporter' + str(x), data[x], dsn)
        )
        for x in range(number_of_processes)
    ]

    for p in processes:
        p.start()

    while any([p.is_alive() for p in processes]):
        time.sleep(0.001)

    for p in processes:
        p.join()
        p.close()

    print('END:', datetime.now().isoformat())
