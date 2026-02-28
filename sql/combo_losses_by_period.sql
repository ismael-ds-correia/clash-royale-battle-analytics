-- Substituir :carta_ids, :inicio e :fim por valores reais

SELECT
    COUNT(*) AS derrotas
FROM participa p
JOIN batalha b ON b.id = p.batalha_id
WHERE p.e_vencedor = FALSE
  AND b.time BETWEEN :inicio AND :fim
  AND p.deck_id IN (
      SELECT u.deck_id
      FROM usa u
      WHERE u.carta_id IN (:carta_ids)  -- Ex: 1,2,3,4,5,6,7,8
      GROUP BY u.deck_id
      HAVING COUNT(DISTINCT u.carta_id) = :num_cartas -- Ex: 8 para combo de 8 cartas
  );