-- Consulta 4: Taxa de uso vs Win Rate de cartas por período
-- 
-- Objetivo: Identificar desequilíbrios entre popularidade e efetividade das cartas.
-- Cartas muito usadas com baixo win rate indicam que jogadores estão usando cartas ineficazes.
-- Cartas pouco usadas com alto win rate podem estar "escondidas" e precisam ser balanceadas.
--
-- Parâmetros: :inicio, :fim, :min_uso (mínimo de aparições para considerar)

WITH stats_cartas AS (
    SELECT
        c.id,
        c.nome,
        c.raridade,
        COUNT(*) AS total_uso,
        SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
        ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM participa p2 JOIN batalha b2 ON b2.id = p2.batalha_id WHERE b2.time BETWEEN :inicio AND :fim), 2) AS pct_uso
    FROM carta c
    JOIN usa u ON u.carta_id = c.id
    JOIN participa p ON p.deck_id = u.deck_id
    JOIN batalha b ON b.id = p.batalha_id
    WHERE b.time BETWEEN :inicio AND :fim
    GROUP BY c.id, c.nome, c.raridade
    HAVING COUNT(*) >= :min_uso
)
SELECT
    nome,
    raridade,
    total_uso,
    pct_uso,
    pct_vitorias,
    CASE
        WHEN pct_uso > 20 AND pct_vitorias < 45 THEN 'OVERUSED_WEAK'
        WHEN pct_uso > 20 AND pct_vitorias > 55 THEN 'OVERUSED_STRONG'
        WHEN pct_uso < 5 AND pct_vitorias > 55 THEN 'UNDERUSED_STRONG'
        WHEN pct_uso < 5 AND pct_vitorias < 45 THEN 'UNDERUSED_WEAK'
        ELSE 'BALANCED'
    END AS status_balanceamento
FROM stats_cartas
ORDER BY pct_uso DESC, pct_vitorias DESC;
