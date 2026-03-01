-- Consulta 5: Win Rate de cartas por arena/nível de troféus
--
-- Objetivo: Identificar se cartas performam diferentemente em diferentes níveis de habilidade.
-- O meta varia significativamente entre jogadores iniciantes e avançados.
-- Cartas "pub stompers" dominam em arenas baixas mas são fracas em alto nível.
-- Cartas técnicas podem ter baixo win rate em arenas baixas mas alto em arenas altas.
--
-- Parâmetros: :carta_id, :inicio, :fim

WITH arena_stats AS (
    SELECT
        b.arena,
        COUNT(*) AS total_partidas,
        SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
        ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias,
        ROUND(AVG(p.trofeus_antes), 0) AS media_trofeus
    FROM participa p
    JOIN usa u ON u.deck_id = p.deck_id
    JOIN batalha b ON b.id = p.batalha_id
    WHERE u.carta_id = :carta_id
      AND b.time BETWEEN :inicio AND :fim
      AND b.arena IS NOT NULL
    GROUP BY b.arena
    HAVING COUNT(*) >= 10  -- Mínimo de partidas para considerar
),
carta_info AS (
    SELECT nome, raridade
    FROM carta
    WHERE id = :carta_id
)
SELECT
    ci.nome AS carta,
    ci.raridade,
    a.arena,
    a.media_trofeus,
    a.total_partidas,
    a.vitorias,
    a.pct_vitorias,
    CASE
        WHEN a.pct_vitorias > 55 THEN 'FORTE'
        WHEN a.pct_vitorias < 45 THEN 'FRACA'
        ELSE 'EQUILIBRADA'
    END AS status_arena
FROM arena_stats a
CROSS JOIN carta_info ci
ORDER BY a.media_trofeus DESC;
