-- Menor e maior data coletadas pelos focos de calor
SELECT
	(SELECT min(datahora::timestamp)
	FROM foco_calor fc
	WHERE satelite IN ('NOAA-12', 'AQUA_M-T')),
	(SELECT max(datahora::timestamp)
	FROM foco_calor fc
	WHERE satelite IN ('NOAA-12', 'AQUA_M-T'))
FROM foco_calor fc 
LIMIT 1

-- Análise
SELECT 
	*,
	-- Pegando a data do ultimo foco de calor que intersectou a parcela
	list_data_foco[array_length(list_data_foco, 1)] AS data_ultimo_foco,
	-- Dias pós ultimo foco detectado na parcela. Isso pode influenciar a comunidade
	DATE_PART('day', data_coleta::timestamp - list_data_foco[array_length(list_data_foco, 1)]::timestamp) diff_dias_data_ultimo_foco_data_coleta
FROM (
	SELECT 
		nome_parcela,
		data_coleta,
		-- Quantidade de focos por parcela
		count(nome_parcela) AS num_focos, 
		-- Data dos focos que ocorreram nas parcelas em ordem crescente
		array_agg(data_foco ORDER BY data_foco ASC) as list_data_foco
	FROM (
		-- Intersectando o buffer das parcelas com os focos de calor
		SELECT 
			pp.nome AS nome_parcela,
			pp.data_coleta,
			fc.datahora::date AS data_foco,
			fc.satelite
		FROM (
			-- Criando o buffer em torno dos pontos coletados
			SELECT
				nome, data AS data_coleta, 
				ST_BUFFER(st_transform(geom, 31982), 2000) AS geom
			FROM ponto_parcela AS pp
		) AS pp
		JOIN foco_calor AS fc 
		ON ST_INTERSECTS(st_transform(fc.geom, 31982), pp.geom)
		WHERE 
			-- Selecionando o satelite NOAA-12 para o período de 
			-- 01/junho/1998 a 03/julho/2002
			-- como é orientado pela documentação do INPE: 
			-- http://queimadas.dgi.inpe.br/queimadas/portal/informacoes/perguntas-frequentes#p7 
			((fc.satelite = 'NOAA-12' AND datahora::date < '2002-07-03') OR 
			-- Pós NOAA-12 o INPE esta utilizando o AQUA-M-T
			(fc.satelite = 'AQUA_M-T' AND datahora::date > '2002-07-03')) AND
			-- Os focos de calor para cada parcela são aqueles que foram coletados antes 
			-- do levantamento levantamento da parcela.
			pp.data_coleta::date > fc.datahora::date
	) AS t1
	GROUP BY nome_parcela, data_coleta
) t2