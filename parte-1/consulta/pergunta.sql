-- Pergunta de negocio (AV1, grupo g02): em quais estados de destino a promessa de prazo
-- foi mais descumprida entre jan/2017 e ago/2018, considerando a quantidade e a taxa
-- de pedidos entregues apos a data prevista?
SELECT
  uf_cliente,
  count(*)                                               AS pedidos_elegiveis,
  count_if(atrasado)                                     AS pedidos_atrasados,
  round(100.0 * count_if(atrasado) / count(*), 2)        AS taxa_atraso_pct,
  round(avg(CASE WHEN atrasado THEN dias_atraso END), 1) AS media_dias_atraso
FROM pedidos_entrega
WHERE elegivel
  AND data_hora_compra >= TIMESTAMP '2017-01-01 00:00:00'
  AND data_hora_compra <  TIMESTAMP '2018-09-01 00:00:00'
GROUP BY uf_cliente
ORDER BY pedidos_atrasados DESC, taxa_atraso_pct DESC
