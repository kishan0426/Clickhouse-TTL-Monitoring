SELECT
    t.database,
    t.name AS table_name,
    if(positionCaseInsensitive(t.create_table_query,'TTL') > 0,'YES','NO') AS ttl_enabled,

    ifNull(p.active_parts,0) AS active_parts,
    ifNull(p.rows,0) AS rows,
    formatReadableSize(ifNull(p.bytes_on_disk,0)) AS disk_size,

    ifNull(m.running_merges,0) AS running_merges,
    ifNull(mu.pending_mutations,0) AS pending_mutations,
    ifNull(r.queue_size,0) AS replication_queue

FROM system.tables t

LEFT JOIN
(
    SELECT
        database,
        table,
        count() AS active_parts,
        sum(rows) AS rows,
        sum(bytes_on_disk) AS bytes_on_disk
    FROM system.parts
    WHERE active = 1
    GROUP BY database, table
) p
ON t.database = p.database
AND t.name = p.table

LEFT JOIN
(
    SELECT
        database,
        table,
        count() AS running_merges
    FROM system.merges
    GROUP BY database, table
) m
ON t.database = m.database
AND t.name = m.table

LEFT JOIN
(
    SELECT
        database,
        table,
        countIf(is_done = 0) AS pending_mutations
    FROM system.mutations
    GROUP BY database, table
) mu
ON t.database = mu.database
AND t.name = mu.table

LEFT JOIN
(
    SELECT
        database,
        table,
        max(queue_size) AS queue_size
    FROM system.replicas
    GROUP BY database, table
) r
ON t.database = r.database
AND t.name = r.table

WHERE t.database NOT IN ('system','information_schema')

ORDER BY p.bytes_on_disk DESC;
