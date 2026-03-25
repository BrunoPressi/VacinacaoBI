create table DIM_PACIENTE (
	id_paciente bigint primary key,
    document_id text,
	data_nascimento date,
	idade integer,
	sexo char,
	raca text
);

create table DIM_GRUPO_ATENDIMENTO (
	id_grupo_atendimento bigint primary key,
	nome_grupo text,
	codigo_grupo int
);

create table DIM_CATEGORIA (
	id_categoria bigint primary key,
    nome_categoria text,
    codigo_categoria int
);

create table DIM_DATA (
	id_data bigint primary key,
	dia integer,
	mes integer,
	ano integer,
	trimestre integer,
	dia_semana text,
	data date
);

create table DIM_VACINA (
	id_vacina bigint primary key,
	nome_vacina text,
	fabricante_vacina text,
    codigo_vacina int
);

create table DIM_LOCALIDADE (
	id_localidade bigint primary key,
	nome_municipio text,
    codigo_municipio int
);

create table DIM_ESTABELECIMENTO (
	id_estabelecimento bigint primary key,
	razao_social text,
	nome_fantasia text
);

create table FATO_ATENDIMENTO (
	id_atendimento bigint primary key,
    dose text,
	id_paciente bigint,
	id_vacina bigint,
	id_data bigint,
	id_estabelecimento bigint,
	id_grupo_atendimento bigint,
	id_localidade bigint,
    id_categoria bigint,
	foreign key (id_paciente) references DIM_PACIENTE(id_paciente),
	foreign key (id_vacina) references DIM_VACINA(id_vacina),
	foreign key (id_data) references DIM_DATA(id_data),
	foreign key (id_estabelecimento) references DIM_ESTABELECIMENTO(id_estabelecimento),
	foreign key (id_grupo_atendimento) references DIM_GRUPO_ATENDIMENTO(id_grupo_atendimento),
	foreign key (id_localidade) references DIM_LOCALIDADE(id_localidade),
	foreign key (id_categoria) references DIM_CATEGORIA(id_categoria)
);
