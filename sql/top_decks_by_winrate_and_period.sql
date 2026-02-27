-- Substituir :percentual, :inicio e :fim por valores reais

WITH deck_stats AS (
    SELECT
        d.id AS deck_id,
        d.id_hash,
        COUNT(*) AS total_partidas,
        SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
        ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias
    FROM participa p
    JOIN batalha b ON b.id = p.batalha_id
    JOIN deck d ON d.id = p.deck_id
    WHERE b.time BETWEEN :inicio AND :fim
    GROUP BY d.id, d.id_hash
    HAVING (100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*)) > :percentual
),
deck_cartas AS (
    SELECT
        d.id AS deck_id,
        ARRAY_AGG(c.nome ORDER BY c.nome) AS cartas,
        ARRAY_AGG(c.id ORDER BY c.nome) AS cartas_ids
    FROM deck d
    JOIN usa u ON u.deck_id = d.id
    JOIN carta c ON c.id = u.carta_id
    GROUP BY d.id
)
SELECT
    s.deck_id,
    s.total_partidas,
    s.vitorias,
    s.pct_vitorias,
    c.cartas
FROM deck_stats s
JOIN deck_cartas c ON c.deck_id = s.deck_id
ORDER BY s.total_partidas DESC;