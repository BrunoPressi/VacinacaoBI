--- Volume de Imunização: Qual é o total de doses aplicadas ao longo do tempo?
select count(id_atendimento) as total_atendimentos, dim_data.ano
from fato_atendimento 
inner join dim_data on fato_atendimento.id_data = dim_data.id_data
group by dim_data.ano;

--- Ciclo Vacinal: Como está a distribuição entre "1ª Dose", "2ª Dose" e "Doses de Reforço"?
select dose, count(id_atendimento) as total_atendimentos
from fato_atendimento
where dose like '1a dose' 
	or dose like '2a dose' 
	or dose like 'reforco'
group by dose
order by total_atendimentos desc;

--- Distribuição Geográfica: Quais municípios possuem os maiores volumes de aplicação?
select count(id_atendimento) as total_atendimentos, dim_localidade.nome_municipio
from fato_atendimento
inner join dim_localidade on fato_atendimento.id_localidade = dim_localidade.id_localidade
group by dim_localidade.nome_municipio
order by total_atendimentos desc
limit 10;

--- Demografia: Qual o percentual de vacinados distribuídos por sexo?
select count(id_atendimento) as total_atendimentos, dim_paciente.sexo,
	CASE 
	    WHEN dim_paciente.sexo = 'm' THEN 'Masculino'
	    WHEN dim_paciente.sexo = 'f' THEN 'Feminino'
	    WHEN dim_paciente.sexo = 'i' THEN 'Indeterminado'
		WHEN dim_paciente.sexo = 'nao informado' THEN 'Não informado'
	END
from fato_atendimento
inner join dim_paciente on fato_atendimento.id_paciente = dim_paciente.id_paciente
group by dim_paciente.sexo
order by total_atendimentos desc;

--- Demografia: Qual o percentual de vacinados distribuídos por faixa etária?
select count(id_atendimento) as total_atendimentos, dim_grupo_atendimento.nome_grupo
from dim_grupo_atendimento
inner join fato_atendimento on dim_grupo_atendimento.id_grupo_atendimento = fato_atendimento.id_grupo_atendimento
inner join dim_categoria on dim_categoria.id_categoria = fato_atendimento.id_categoria
where dim_grupo_atendimento.nome_grupo ilike '%pessoas de%' and dim_categoria.nome_categoria = 'faixa etaria'
group by dim_grupo_atendimento.nome_grupo, dim_categoria.nome_categoria
order by total_atendimentos desc;

--- Share de Imunizantes: Qual é o imunizante/fabricante mais utilizado na campanha do estado?
select count(id_atendimento) as total_atendimentos, dim_vacina.fabricante_vacina
from fato_atendimento
inner join dim_vacina on fato_atendimento.id_vacina = dim_vacina.id_vacina
where dim_vacina.fabricante_vacina not ilike '%pendente%'
group by dim_vacina.fabricante_vacina
order by total_atendimentos desc;

--- Grupos Prioritários: Qual foi o volume de vacinação dedicado aos 
--- Trabalhadores de Saúde vs. Idosos vs. População em Geral?
select count(id_atendimento) as total_atendimentos,
	case 
        when dim_categoria.nome_categoria ilike '%trabalhadores de saude%'
            then 'Trabalhadores da Saúde'
		when dim_grupo_atendimento.nome_grupo ilike '%pessoas de 65 a 69 anos%'
			or dim_grupo_atendimento.nome_grupo ilike '%pessoas de 70 a 74 anos%'
			or dim_grupo_atendimento.nome_grupo ilike '%pessoas de 75 a 79 anos%'
			or dim_grupo_atendimento.nome_grupo ilike '%pessoas de 80 anos ou mais%'
			then 'Idosos'
        else 'População em Geral'
    end as grupo
from fato_atendimento
inner join dim_categoria on dim_categoria.id_categoria = fato_atendimento.id_categoria
inner join dim_grupo_atendimento on dim_grupo_atendimento.id_grupo_atendimento = fato_atendimento.id_grupo_atendimento
group by grupo
order by total_atendimentos desc;

--- Engajamento nos Postos: Quais estabelecimentos de saúde foram responsáveis por aplicar o maior número de vacinas?
select count(id_atendimento) as total_atendimentos, dim_estabelecimento.nome_fantasia as nome_estabelecimento, dim_localidade.nome_municipio
from fato_atendimento
inner join dim_estabelecimento on fato_atendimento.id_estabelecimento = dim_estabelecimento.id_estabelecimento
inner join dim_localidade on fato_atendimento.id_localidade = dim_localidade.id_localidade
group by dim_estabelecimento.nome_fantasia, dim_localidade.nome_municipio
order by total_atendimentos desc
limit 5;