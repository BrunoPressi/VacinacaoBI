# Projeto: Data Warehouse e BI — Vacinação COVID-19 no Rio Grande do Sul

* **Curso:** Análise e Desenvolvimento de Sistemas
* **Objetivo:** Construir um data warehouse a partir de dados públicos da campanha de vacinação contra a COVID-19 no estado do Rio Grande do Sul, aplicar conceitos de ETL e desenvolver painéis analíticos para monitoramento e tomada de decisão em saúde pública.

---

## 1. Contexto e Objetivos de Aprendizagem

### 1.1 Contexto do negócio (cenário)

Secretarias de Saúde e pesquisadores precisam monitorar o avanço da campanha de vacinação contra a COVID-19. Os dados brutos de imunização (geralmente extraídos do OpenDataSUS ou bases estaduais) contêm milhões de registros detalhando quem foi vacinado, quando, com qual imunizante e em qual localidade. O time de BI precisa construir um **data warehouse** alimentado por um processo **ETL** para viabilizar análises demográficas, geográficas e temporais, avaliando o ritmo da imunização no estado do Rio Grande do Sul.

### 1.2 Objetivos de aprendizagem

Ao final do projeto, espera-se ser capaz de:

* **Modelar** um data warehouse (modelo dimensional) focado em dados de saúde pública e epidemiologia.
* **Implementar** um pipeline ETL (Extract, Transform, Load) lidando com grande volume de dados, limpeza de inconsistências e padronização.
* **Carregar** dados estruturados em um repositório analítico relacional (PostgreSQL).
* **Explorar** os dados com consultas analíticas voltadas para saúde (contagem de doses, estratificação por idade/raça/grupo prioritário).
* **Desenvolver ou acoplar** ferramentas de análise para criação de boletins epidemiológicos e dashboards.

## 2. Conjunto de Dados (Dataset)

### 2.1 Descrição

* **Fonte:** Arquivos de microdados de vacinação (ex: extrações em formato CSV do portal OpenDataSUS filtradas para a UF "RS").
* **Nomenclatura Sugerida:** `dados_vacinacao_covid_rs_parteX.csv`.
* **Período coberto:** Início da campanha de vacinação (ex: Jan/2021) até a data da extração mais recente.
* **Separador:** Ponto e vírgula (;) ou vírgula (,), a depender da extração.
* **Codificação:** UTF-8.

### 2.2 Estrutura do arquivo (exemplo das principais colunas mapeadas)

| Coluna | Descrição | Exemplo / Observação |
| :---: | :---: | :---: |
| **Data de Aplicação** | Data em que a vacina foi administrada | `DD/MM/AAAA` ou `AAAA-MM-DD` |
| **Documento Paciente** | ID anonimizado do paciente | Hash alfanumérico |
| **Idade** | Idade do paciente no momento da vacina | Numérico |
| **Sexo / Raça** | Demografia do paciente | "M", "F" / "BRANCA", "PARDA" |
| **Grupo / Categoria** | Grupo prioritário do cidadão | "Trabalhadores de Saúde", "Comorbidades" |
| **Vacina / Fabricante** | Qual vacina foi aplicada | "PFIZER", "ASTRAZENECA/FIOCRUZ" |
| **Dose** | Qual a dose administrada | "1ª Dose", "Reforço", "Dose Única" |
| **Município** | Localidade onde ocorreu a vacinação | "Porto Alegre", "Pelotas" |
| **Estabelecimento** | Nome fantasia/Razão Social do posto | "UBS CENTRO", "HOSPITAL CLINICAS" |

### 2.3 Observações para ETL

* **Volume de Dados:** As bases de vacinação costumam ter milhões de linhas. Pode ser necessário processar em lotes (chunks).
* **Qualidade dos Dados:** Demografia (raça, sexo, idade) pode vir com campos vazios ou preenchimento inconsistente. Definir regra de tratamento (ex: "Não Informado").
* **Datas:** Padronizar para o formato nativo de data (`DATE`) no Banco de Dados.
* **Consistência:** Múltiplas grafias para o mesmo fabricante de vacina (ex: "PFIZER", "PFIZER/BIONTECH") devem ser padronizadas durante a transformação.

## 3. Projeto do Data Warehouse

O modelo adotado é o **Modelo em Estrela (*Star Schema*)**, composto por **uma tabela fato** centralizando os eventos de vacinação e **sete dimensões** de contexto.

### 3.1 Modelo dimensional (Star Schema)

**Tabela Fato: `FATO_ATENDIMENTO`**
Representa o evento da vacinação (a injeção no braço do paciente).

* `id_atendimento` (PK)
* `dose` (Degenerate Dimension, ex: "1ª Dose")
* `id_paciente` (FK para `DIM_PACIENTE`)
* `id_vacina` (FK para `DIM_VACINA`)
* `id_data` (FK para `DIM_DATA`)
* `id_estabelecimento` (FK para `DIM_ESTABELECIMENTO`)
* `id_grupo_atendimento` (FK para `DIM_GRUPO_ATENDIMENTO`)
* `id_localidade` (FK para `DIM_LOCALIDADE`)
* `id_categoria` (FK para `DIM_CATEGORIA`)

**Dimensões**

* **`DIM_PACIENTE`:** Perfil do cidadão (`id_paciente`, `document_id`, `data_nascimento`, `idade`, `sexo`, `raca`).
* **`DIM_DATA`:** Calendário da aplicação (`id_data`, `data`, `dia`, `mes`, `ano`, `trimestre`, `dia_semana`).
* **`DIM_VACINA`:** Dados do imunizante (`id_vacina`, `nome_vacina`, `fabricante_vacina`, `codigo_vacina`).
* **`DIM_LOCALIDADE`:** Geografia da aplicação (`id_localidade`, `nome_municipio`, `codigo_municipio`).
* **`DIM_ESTABELECIMENTO`:** Ponto de saúde (`id_estabelecimento`, `razao_social`, `nome_fantasia`).
* **`DIM_GRUPO_ATENDIMENTO`:** Perfil de prioridade detalhado (`id_grupo_atendimento`, `nome_grupo`, `codigo_grupo`).
* **`DIM_CATEGORIA`:** Agrupamento macro da prioridade (`id_categoria`, `nome_categoria`, `codigo_categoria`).

### 3.2 Decisões de modelagem

* **Granularidade:** Cada linha na `FATO_ATENDIMENTO` representa **uma dose aplicada** a um indivíduo em um determinado dia e local.
* **Métricas:** Diferente de vendas (onde somamos valores financeiros), neste modelo métricas são predominantemente **contagens** (COUNT de registros da fato) para descobrir o "Total de Doses".
* **Dimensão Paciente:** Como os pacientes mudam de idade e os dados vêm desnormalizados, `DIM_PACIENTE` guarda o retrato do paciente.

## 4. Pipeline ETL

### 4.1 Extract (E)

* **Entrada:** Arquivos CSV brutos extraídos das bases governamentais.
* **Atividade:** Leitura particionada (devido ao alto volume) com especificação correta de tipos de dados básicos para evitar alto consumo de memória.
* **Ferramentas possíveis:** Python (Pandas/Polars/Dask), Apache Spark, Pentaho.

### 4.2 Transform (T)

* **Datas:** Desmembrar a data de vacinação em `dia`, `mes`, `ano`, `trimestre` e `dia_semana` para alimentar a `DIM_DATA`.
* **Geração de Chaves Substitutas (Surrogate Keys - SK):** Criar identificadores únicos inteiros (`bigint`) para as dimensões para garantir alta performance de Join no banco (ex: `id_paciente`, `id_vacina`).
* **Limpeza Textual:** Padronização (uppercase/lowercase) e remoção de espaços em branco em nomes de municípios e estabelecimentos. Tratamento de valores nulos (NaN/Null -> "Não Informado").
* **Modelagem:** Separação do dataframe gigante original nos dataframes menores correspondentes às Tabelas Dimensão (usando deduplicação, como o `drop_duplicates` do Pandas) e na Tabela Fato (preservando apenas chaves e a coluna `dose`).

### 4.3 Load (L)

* **Destino:** Banco de Dados Relacional **PostgreSQL**.
* **Ordem Exigida (Integridade Referencial):**
  1. Carregar todas as tabelas `DIM_*` (Paciente, Vacina, Localidade, Estabelecimento, Grupo, Categoria e Data).
  2. Carregar a tabela central `FATO_ATENDIMENTO` utilizando as chaves estrangeiras.

### 4.4 Ferramentas Utilizadas

* **Scripts ETL:** Python (Bibliotecas `pandas` para dados em memória e `sqlalchemy`/`psycopg2` para conexão ao banco).
* **Armazenamento:** PostgreSQL (Schema implementado a partir de `script.sql`).

## 5. Análise dos Dados e Ferramentas

### 5.1 Perguntas de negócio (Exemplos para Relatórios/Dashboards)

1. **Volume de Imunização:** Qual é o total de doses aplicadas ao longo do tempo (evolução diária/mensal)?
2. **Ciclo Vacinal:** Como está a distribuição entre "1ª Dose", "2ª Dose" e "Doses de Reforço"?
3. **Distribuição Geográfica:** Quais municípios (`DIM_LOCALIDADE`) possuem os maiores volumes de aplicação?
4. **Demografia:** Qual o percentual de vacinados distribuídos por sexo e faixa etária (`DIM_PACIENTE`)?
5. **Share de Imunizantes:** Qual é o imunizante/fabricante (`DIM_VACINA`) mais utilizado na campanha do estado?
6. **Grupos Prioritários:** Qual foi o volume de vacinação dedicado aos Trabalhadores de Saúde vs. Idosos vs. População em Geral (`DIM_GRUPO_ATENDIMENTO` / `DIM_CATEGORIA`)?
7. **Engajamento nos Postos:** Quais estabelecimentos de saúde (`DIM_ESTABELECIMENTO`) foram responsáveis por aplicar o maior número de vacinas?

### 5.2 Ferramenta de análise

* Análises exploratórias documentadas via **Jupyter Notebooks (Python + Matplotlib / Seaborn / Plotly)**.
* *(Opcional)* Conexão do banco PostgreSQL a uma ferramenta de BI visualização como **Metabase**, **Power BI** ou **Apache Superset** para a construção de um Boletim Epidemiológico interativo.
