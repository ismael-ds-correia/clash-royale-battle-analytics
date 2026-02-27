-- Substituir :carta_id, :inicio e :fim por valores reais

SELECT
    SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
    SUM(CASE WHEN NOT p.e_vencedor THEN 1 ELSE 0 END) AS derrotas,
    COUNT(*) AS total,
    ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias,
    ROUND(100.0 * SUM(CASE WHEN NOT p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_derrotas
FROM participa p
JOIN batalha b ON b.id = p.batalha_id
JOIN usa u ON u.deck_id = p.deck_id
WHERE u.carta_id = :carta_id
  AND b.time BETWEEN :inicio AND :fim;