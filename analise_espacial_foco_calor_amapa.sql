--SELECT count(*) FROM ponto_parcela pp;

SELECT 
	DISTINCT(nome_parcela), 
	count(nome_parcela) AS num_focos, 
	array_agg(data_foco ORDER BY data_foco ASC) as list_data_foco
FROM (
	SELECT 
		pp.nome AS nome_parcela,
		pp.data_coleta,
		fc.datahora::date AS data_foco,
		fc.satelite
	FROM (
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
		(fc.satelite = 'NOAA-12' AND datahora::date < '2002-07-03') OR 
		-- Pós NOAA-12 o INPE esta utilizando o AQUA-M-T
		(fc.satelite = 'AQUA_M-T' AND datahora::date > '2002-07-03') OR
		-- Os focos de calor para cada parcela são aqueles que foram coletados antes 
		-- do levantamento levantamento da parcela.
		pp.data_coleta::date < datahora::date
) AS t1
GROUP BY nome_parcela