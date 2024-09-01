# 1. Quantos chamados foram abertos no dia 01/04/2023?

SELECT COUNT(id_chamado) as chamados 
FROM `datario.adm_central_atendimento_1746.chamado` 
WHERE DATE(data_inicio) = '2023-04-01'

# Resposta: 1756

# 2. Qual o tipo de chamado que teve mais teve chamados abertos no dia 01/04/2023?

SELECT tipo, COUNT(id_chamado) as chamados 
FROM `datario.adm_central_atendimento_1746.chamado` 
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY tipo 
ORDER BY chamados DESC
LIMIT 1

# Resposta: Estacionamento irregular

# 3. Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?

SELECT bairroDB.nome, COUNT(chamadoDB.id_chamado) as chamados
FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
LEFT JOIN `datario.dados_mestres.bairro` AS bairroDB
ON chamadoDB.id_bairro = bairroDB.id_bairro
WHERE DATE(chamadoDB.data_inicio) = '2023-04-01'
GROUP BY bairroDB.nome
ORDER BY chamados DESC
LIMIT 3

# Resposta: Os bairros foram: Campo Grande, com 113 chamados. Tijuca, com 89 chamados e o terceiro foi nulo, teve 73 chamados.

# 4. Qual o nome da subprefeitura com mais chamados abertos nesse dia?

SELECT bairroDB.subprefeitura, COUNT(chamadoDB.id_chamado) as chamados
FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
LEFT JOIN `datario.dados_mestres.bairro` AS bairroDB
ON chamadoDB.id_bairro = bairroDB.id_bairro
WHERE DATE(chamadoDB.data_inicio) = '2023-04-01'
GROUP BY bairroDB.subprefeitura
ORDER BY chamados DESC
LIMIT 1

# Resposta: Zona Norte, com 510 chamados.

# 5. Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?

SELECT COUNT(chamadoDB.id_chamado) as chamados
FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
LEFT JOIN `datario.dados_mestres.bairro` AS bairroDB
ON chamadoDB.id_bairro = bairroDB.id_bairro
WHERE DATE(chamadoDB.data_inicio) = '2023-04-01'
AND chamadoDB.id_bairro is NULL

# Resposta: Sim. Aconteceu porque há dados nulos na variável id_bairro, há 73 chamados assim.

# 6. Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?

SELECT COUNT(chamadoDB.id_chamado) as chamados
FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
WHERE subtipo = "Perturbação do sossego"
  AND DATE(chamadoDB.data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'

# Resposta: Foram abertos 42830 chamados.

# 7. Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).

SELECT chamadoDB.*, turismoDB.evento
FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
INNER JOIN `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS turismoDB
ON chamadoDB.data_inicio <= turismoDB.data_final
    AND chamadoDB.data_fim >= turismoDB.data_inicial
WHERE chamadoDB.subtipo = "Perturbação do sossego"
    AND DATE(chamadoDB.data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'

# 8. Quantos chamados desse subtipo foram abertos em cada evento?

SELECT COUNT(chamadoDB.id_chamado) AS chamados, CONCAT(turismoDB.evento, ' ', turismoDB.ano) AS evento_ajuste
FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
INNER JOIN `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS turismoDB
ON chamadoDB.data_inicio <= turismoDB.data_final
    AND chamadoDB.data_fim >= turismoDB.data_inicial
WHERE chamadoDB.subtipo = "Perturbação do sossego"
    AND DATE(chamadoDB.data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY evento_ajuste
ORDER BY chamados DESC

# Resposta: Quando olhei os eventos, percebi que o Rock in Rio é dividido em duas datas no mesmo ano, então achei que seria ideal diferenciar um do outro para calcular o total de chamados. Caso contrário, estaria comparando um evento de 7 dias com um de 3 e um de 4, então o total de chamados provavelmente seria muito maior. O Rock in Rio de 08/09 a 11/09 teve 4289 chamados, o de 02/09 a 04/09 teve 4182, o Reveillon teve 857 e o Carnaval 721.

# 9. Qual evento teve a maior média diária de chamados abertos desse subtipo?

WITH chamados_por_evento AS (
    SELECT CONCAT(turismoDB.evento, ' ', turismoDB.ano) AS evento_ajuste,
        COUNT(chamadoDB.id_chamado) AS total_chamados,
        TIMESTAMP_DIFF(turismoDB.data_final, turismoDB.data_inicial, DAY) + 1 AS duracao_dias
    FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
    INNER JOIN `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS turismoDB
    ON chamadoDB.data_inicio <= turismoDB.data_final
        AND chamadoDB.data_fim >= turismoDB.data_inicial
    WHERE chamadoDB.subtipo = "Perturbação do sossego"
        AND DATE(chamadoDB.data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY evento_ajuste, duracao_dias
)
SELECT evento_ajuste AS evento,
    total_chamados,
    duracao_dias,
    ROUND(total_chamados / duracao_dias, 2) AS media_diaria_chamados
FROM chamados_por_evento
ORDER BY media_diaria_chamados DESC
LIMIT 1

# Resposta: A primeira parte do Rock in Rio (02/09 a 04/09) teve a maior média diária de chamados (1394).

# 10. Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.

WITH chamados_por_evento AS (
    SELECT CONCAT(turismoDB.evento, ' ', turismoDB.ano) AS evento_ajuste,
        COUNT(chamadoDB.id_chamado) AS total_chamados,
        TIMESTAMP_DIFF(turismoDB.data_final, turismoDB.data_inicial, DAY) + 1 AS duracao_dias
    FROM `datario.adm_central_atendimento_1746.chamado` AS chamadoDB
    INNER JOIN `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS turismoDB
    ON chamadoDB.data_inicio <= turismoDB.data_final
        AND chamadoDB.data_fim >= turismoDB.data_inicial
    WHERE chamadoDB.subtipo = "Perturbação do sossego"
        AND DATE(chamadoDB.data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY evento_ajuste, duracao_dias
),

media_diaria_geral AS (
    SELECT COUNT(id_chamado) AS total_chamados_geral,
      TIMESTAMP_DIFF(DATE('2023-12-31'), DATE('2022-01-01'), DAY) + 1 AS dias_totais
    FROM `datario.adm_central_atendimento_1746.chamado`
    WHERE subtipo = "Perturbação do sossego"
      AND DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
)

SELECT evento_ajuste AS evento,
    total_chamados,
    duracao_dias,
    ROUND(total_chamados / duracao_dias, 2) AS media_diaria_chamados,
    (SELECT ROUND(total_chamados_geral / dias_totais, 2) FROM media_diaria_geral) AS media_diaria_geral,
    (ROUND(total_chamados / duracao_dias, 2)-(SELECT ROUND(total_chamados_geral / dias_totais, 2) FROM media_diaria_geral)) AS diff,
    (ROUND(ROUND(total_chamados / duracao_dias, 2)/(SELECT ROUND(total_chamados_geral / dias_totais, 2) FROM media_diaria_geral),2)*100) AS percent,

FROM chamados_por_evento
ORDER BY media_diaria_chamados DESC

# Resposta: A média diária geral é 58.67, bem menor que a dos eventos (1394 na primeira parte do Rock in Rio, 1072.25 na segunda parte, 285.67 no Reveillon e 180.25 no Carnaval). Também calculei a diferença numérica entre a média geral e a média dos chamados (1335.33 a mais na primeira parte do Rock in Rio, 1013.58 na segunda parte, 227.0 no Reveillon e 121.58 no Carnaval) e a diferença percentual (2376% a mais na primeira parte do Rock in Rio, 1828% na segunda parte, 487% no Reveillon e 307% no Carnaval).
