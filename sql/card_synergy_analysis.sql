-- Consulta 6: Análise de sinergia entre pares de cartas
--
-- Objetivo: Identificar combinações de 2 cartas que têm alta taxa de vitória quando usadas juntas.
-- Sinergias fortes podem indicar combos que dominam o meta e precisam de ajuste.
-- Exemplo: Se Hog Rider + Freeze tem 70% de win rate juntos, pode indicar um combo muito forte.
--
-- Parâmetros: :inicio, :fim, :min_partidas (mínimo de jogos para considerar)

WITH pares_cartas AS (
    SELECT
        u1.carta_id AS carta1_id,
        u2.carta_id AS carta2_id,
        u1.deck_id
    FROM usa u1
    JOIN usa u2 ON u1.deck_id = u2.deck_id AND u1.carta_id < u2.carta_id
),
stats_pares AS (
    SELECT
        pc.carta1_id,
        pc.carta2_id,
        COUNT(DISTINCT p.batalha_id) AS total_partidas,
        SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
        ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(DISTINCT p.batalha_id), 2) AS pct_vitorias
    FROM pares_cartas pc
    JOIN participa p ON p.deck_id = pc.deck_id
    JOIN batalha b ON b.id = p.batalha_id
    WHERE b.time BETWEEN :inicio AND :fim
    GROUP BY pc.carta1_id, pc.carta2_id
    HAVING COUNT(DISTINCT p.batalha_id) >= :min_partidas
),
win_rate_individuais AS (
    SELECT
        c.id,
        ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS wr_individual
    FROM carta c
    JOIN usa u ON u.carta_id = c.id
    JOIN participa p ON p.deck_id = u.deck_id
    JOIN batalha b ON b.id = p.batalha_id
    WHERE b.time BETWEEN :inicio AND :fim
    GROUP BY c.id
)
SELECT
    c1.nome AS carta1,
    c2.nome AS carta2,
    sp.total_partidas,
    sp.pct_vitorias AS wr_combo,
    wr1.wr_individual AS wr_carta1_solo,
    wr2.wr_individual AS wr_carta2_solo,
    ROUND(sp.pct_vitorias - ((wr1.wr_individual + wr2.wr_individual) / 2.0), 2) AS bonus_sinergia,
    CASE
        WHEN sp.pct_vitorias - ((wr1.wr_individual + wr2.wr_individual) / 2.0) > 10 THEN 'SINERGIA_FORTE'
        WHEN sp.pct_vitorias - ((wr1.wr_individual + wr2.wr_individual) / 2.0) > 5 THEN 'SINERGIA_MODERADA'
        WHEN sp.pct_vitorias - ((wr1.wr_individual + wr2.wr_individual) / 2.0) < -5 THEN 'ANTI_SINERGIA'
        ELSE 'NEUTRO'
    END AS tipo_relacao
FROM stats_pares sp
JOIN carta c1 ON c1.id = sp.carta1_id
JOIN carta c2 ON c2.id = sp.carta2_id
JOIN win_rate_individuais wr1 ON wr1.id = sp.carta1_id
JOIN win_rate_individuais wr2 ON wr2.id = sp.carta2_id
WHERE sp.pct_vitorias - ((wr1.wr_individual + wr2.wr_individual) / 2.0) > 5  -- Apenas sinergias significativas
ORDER BY bonus_sinergia DESC
LIMIT 20;
