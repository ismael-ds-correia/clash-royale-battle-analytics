# Clash Royale Battle Analytics

> **Projeto Acadêmico** - Modelagem Conceitual de Dados 2025.2  
> Sistema de análise de dados de batalhas do Clash Royale para auxiliar no balanceamento do jogo

![Python](https://img.shields.io/badge/Python-3.8+-blue?style=flat-square&logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?style=flat-square&logo=postgresql)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebooks-orange?style=flat-square&logo=jupyter)

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Objetivos](#objetivos)
- [Tecnologias](#tecnologias)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Instalação e Configuração](#instalação-e-configuração)
- [Pipeline de Coleta de Dados](#pipeline-de-coleta-de-dados)
- [Modelo de Dados](#modelo-de-dados)
- [Consultas Implementadas](#consultas-implementadas)
- [Exemplos de Uso](#exemplos-de-uso)

---

## Sobre o Projeto

Este projeto foi desenvolvido para a disciplina de **Modelagem Conceitual de Dados**, com o objetivo de modelar e carregar dados de batalhas do jogo Clash Royale em um banco de dados relacional, viabilizando consultas analíticas que permitam analisar estatísticas de vitórias e derrotas associadas ao uso de cartas.

### Contexto

Clash Royale é um jogo de estratégia em tempo real onde jogadores montam **decks com 8 cartas únicas** para batalhar contra outros jogadores. O balanceamento do jogo é realizado baseado nas estatísticas de vitórias e derrotas que as cartas produzem ao longo do tempo.

---

## Objetivos

1. **Modelar** um banco de dados relacional para armazenar:
   - Informações dos jogadores (nickname, troféus, nível)
   - Detalhes das batalhas (timestamp, arena, modo de jogo, vencedor)
   - Decks utilizados (composição de 8 cartas)
   - Estatísticas de cada participação (troféus antes/depois, resultado)

2. **Coletar dados reais** via API oficial do Clash Royale

3. **Implementar consultas analíticas** para:
   - Calcular win rate de cartas específicas por período
   - Identificar decks com alta taxa de vitória
   - Analisar performance de combos de cartas
   - Gerar insights para balanceamento do jogo

4. **Visualizar resultados** em ferramentas de BI (Tableau/PowerBI)

---

## Tecnologias

| Tecnologia           | Descrição                      |
| -------------------- | ------------------------------ |
| **Python 3.8+**      | Linguagem principal            |
| **Pandas**           | Manipulação e análise de dados |
| **PostgreSQL**       | Banco de dados relacional      |
| **pg8000**           | Driver Python para PostgreSQL  |
| **Jupyter**          | Notebooks interativos          |
| **Requests**         | Requisições HTTP para API      |
| **Clash Royale API** | Fonte de dados oficial         |

---

## 📁 Estrutura do Projeto

```
clash-royale-battle-analytics/
│
├── notebooks/                           # Pipeline de coleta de dados
│   ├── 01_seeding_seasons.ipynb        # Coleta IDs de temporadas
│   ├── 02_seeding_top_players.ipynb    # Coleta top 5000 jogadores
│   ├── 03_seeding_clan_members.ipynb   # Coleta membros de clãs
│   ├── 04_seeding_battles.ipynb        # Coleta histórico de batalhas
│   └── 05_seeding_cards.ipynb          # Coleta catálogo de cartas
│
├── sql/                                 # Consultas SQL
│   ├── schema.sql                       # Schema do banco de dados
│   ├── card_winrate_by_period.sql      # Consulta 1: Win rate por carta
│   ├── top_decks_by_winrate_and_period.sql  # Consulta 2: Top decks
│   ├── combo_losses_by_period.sql      # Consulta 3: Combos perdedores
│   ├── card_usage_vs_winrate.sql       # Consulta 4: Taxa de uso vs WR
│   ├── card_winrate_by_arena.sql       # Consulta 5: WR por arena/troféus
│   └── card_synergy_analysis.sql       # Consulta 6: Sinergia entre cartas
│
├── project/
│   └── load_to_db.py                    # Script ETL para carga no BD
│
├── visualizer.ipynb                     # Análises e visualizações
├── requirements.txt                     # Dependências Python
└── docs/                                # Documentação do projeto
```

---

## Instalação e Configuração

### Pré-requisitos

- Python 3.8 ou superior
- PostgreSQL 12 ou superior
- Token de acesso à [Clash Royale API](https://developer.clashroyale.com/)

### Passo a Passo

1. **Clone o repositório**

   ```bash
   git clone https://github.com/seu-usuario/clash-royale-battle-analytics.git
   cd clash-royale-battle-analytics
   ```

2. **Instale as dependências**

   ```bash
   pip install -r requirements.txt
   ```

3. **Configure o PostgreSQL**

   ```bash
   # Crie o banco de dados
   createdb clash_analytics

   # Execute o schema
   psql -d clash_analytics -f sql/schema.sql
   ```

4. **Configure as credenciais**

   Edite o arquivo [project/load_to_db.py](project/load_to_db.py) com suas credenciais:

   ```python
   DB_CONFIG = {
       "host": "localhost",
       "database": "clash_analytics",
       "user": "seu_usuario",
       "password": "sua_senha"
   }
   ```

5. **Configure o Token da API**

   Obtenha seu token em [developer.clashroyale.com](https://developer.clashroyale.com/) e atualize nos notebooks.

---

## 🔄 Pipeline de Coleta de Dados

O processo de coleta segue uma sequência organizada de notebooks:

| Etapa | Notebook                        | Descrição                                             | Output                      |
| ----- | ------------------------------- | ----------------------------------------------------- | --------------------------- |
| 1     | `01_seeding_seasons.ipynb`      | Lista IDs de temporadas disponíveis                   | `data/season_ids.csv`       |
| 2     | `02_seeding_top_players.ipynb`  | Coleta top 5000 jogadores por temporada               | `data/pathoflegend_*.json`  |
| 3     | `03_seeding_clan_members.ipynb` | Coleta membros de clãs específicos                    | `data/clan_member_tags.csv` |
| 4     | `04_seeding_battles.ipynb`      | Coleta histórico de batalhas (últimas 25 por jogador) | `data/battles_raw_batches/` |
| 5     | `05_seeding_cards.ipynb`        | Obtém catálogo completo de cartas                     | `data/cards.csv`            |
| 6     | `project/load_to_db.py`         | Normaliza e carrega dados no PostgreSQL               | Database                    |

### Características do Pipeline

- **Sistema de Batches**: Processa grandes volumes em lotes para otimizar memória
- **Checkpointing**: Salva progresso permitindo retomada após interrupções
- **Tratamento de Duplicatas**: Hash SHA256 para identificar decks únicos
- **Retry Logic**: Tratamento de erros de API com tentativas automáticas

## 🗃️ Modelo de Dados

### Diagrama ER

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   JOGADOR   │         │  PARTICIPA   │         │   BATALHA   │
├─────────────┤         ├──────────────┤         ├─────────────┤
│ id (PK)     │◄───────┤ jogador_id   │        ┌┤ id (PK)     │
│ nick        │         │ batalha_id   ├───────►│ time        │
│ nivel       │         │ deck_id      │         │ arena       │
└─────────────┘         │ trofeus_antes│         │ game_mode   │
                        │ trofeus_depo.│         └─────────────┘
                        │ e_vencedor   │
                        └──────┬───────┘
                               │
                               ▼
                        ┌─────────────┐
                        │    DECK     │
                        ├─────────────┤
                        │ id (PK)     │
                        │ id_hash     │
                        └──────┬──────┘
                               │
                        ┌──────▼───────┐
                        │     USA      │
                        ├──────────────┤
                        │ deck_id      │
                        │ carta_id     │
                        └──────┬───────┘
                               │
                               ▼
                        ┌─────────────┐
                        │    CARTA    │
                        ├─────────────┤
                        │ id (PK)     │
                        │ nome        │
                        │ raridade    │
                        └─────────────┘
```

### Entidades Principais

#### **JOGADOR**

- Armazena informações dos jogadores
- Chave primária: Tag do jogador

#### **BATALHA**

- Registra cada partida única
- Inclui timestamp, arena e modo de jogo

#### **DECK**

- Representa uma combinação única de 8 cartas
- Usa hash SHA256 para identificação

#### **CARTA**

- Catálogo de todas as cartas do jogo
- Informações de raridade

#### **PARTICIPA** (Relacionamento N:N)

- Conecta Jogador, Batalha e Deck
- Armazena resultado e estatísticas da participação

#### **USA** (Relacionamento N:N)

- Conecta Deck e Carta
- Define a composição dos decks

---

## 📊 Análises Disponíveis

### 1. Win Rate de Cartas por Período

**Arquivo:** `sql/card_winrate_by_period.sql`

Calcula a taxa de vitória de uma carta específica em um intervalo de tempo.

```sql
-- Parâmetros: :carta_id, :inicio, :fim
SELECT
    SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
    COUNT(*) AS total,
    ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias
FROM participa p
JOIN usa u ON u.deck_id = p.deck_id
WHERE u.carta_id = :carta_id
  AND b.time BETWEEN :inicio AND :fim;
```

**Uso:** Identifique cartas dominantes no meta atual

### 2. Top Decks por Win Rate

**Arquivo:** `sql/top_decks_by_winrate_and_period.sql`

Lista os decks com maior taxa de vitória acima de um limite definido.

```sql
-- Parâmetros: :percentual, :inicio, :fim
-- Retorna decks com win rate > :percentual
```

Consultas Implementadas

### Consultas Obrigatórias

#### 1. Win Rate de Carta por Período

**Arquivo:** [card_winrate_by_period.sql](sql/card_winrate_by_period.sql)

Calcula a porcentagem de vitórias e derrotas utilizando uma carta específica em um intervalo de timestamps.

```sql
-- Parâmetros: :carta_id, :inicio, :fim
SELECT
    SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
    SUM(CASE WHEN NOT p.e_vencedor THEN 1 ELSE 0 END) AS derrotas,
    COUNT(*) AS total,
    ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias
FROM participa p
JOIN usa u ON u.deck_id = p.deck_id
JOIN batalha b ON b.id = p.batalha_id
WHERE u.carta_id = :carta_id
  AND b.time BETWEEN :inicio AND :fim;
```

#### 2. Top Decks por Win Rate

**Arquivo:** [top_decks_by_winrate_and_period.sql](sql/top_decks_by_winrate_and_period.sql)

Lista os decks completos que produziram mais de X% de vitórias em um intervalo de timestamps.

```sql
-- Parâmetros: :percentual, :inicio, :fim
-- Retorna: deck_id, total_partidas, vitorias, pct_vitorias, array de cartas
```

#### 3. Derrotas com Combo de Cartas

**Arquivo:** [combo_losses_by_period.sql](sql/combo_losses_by_period.sql)

Calcula a quantidade de derrotas utilizando um combo específico de cartas em um intervalo de timestamps.

```sql
-- Parâmetros: :carta_ids (array), :inicio, :fim, :num_cartas
-- Conta derrotas de decks que contêm exatamente o combo especificado
```

### Consultas Adicionais

#### 4. Taxa de Uso vs Win Rate

**Arquivo:** [card_usage_vs_winrate.sql](sql/card_usage_vs_winrate.sql)

Identifica desequilíbrios entre popularidade e efetividade das cartas. Classifica cartas em categorias:

- **OVERUSED_STRONG**: Dominam o meta (>20% uso, >55% WR) - Candidatas a nerf
- **OVERUSED_WEAK**: Muito usadas mas fracas (<45% WR) - Percepção vs realidade
- **UNDERUSED_STRONG**: Pouco usadas mas fortes (>55% WR) - "Cartas escondidas"
- **UNDERUSED_WEAK**: Pouco usadas e fracas (<45% WR) - Candidatas a buff

```sql
-- Parâmetros: :inicio, :fim, :min_uso
-- Retorna: nome, raridade, total_uso, pct_uso, pct_vitorias, status_balanceamento
```

#### 5. Win Rate por Arena/Nível de Troféus

**Arquivo:** [card_winrate_by_arena.sql](sql/card_winrate_by_arena.sql)

Analisa performance de cartas em diferentes níveis de habilidade. Identifica:

- **Pub Stompers**: Dominam arenas baixas mas fracas em alto nível
- **Cartas Técnicas**: Baixo WR em arenas baixas, alto em arenas altas
- **Consistentes**: Performance estável em todos os níveis

```sql
-- Parâmetros: :carta_id, :inicio, :fim
-- Retorna: arena, media_trofeus, total_partidas, pct_vitorias, status_arena
```

#### 6. Análise de Sinergia entre Cartas

**Arquivo:** [card_synergy_analysis.sql](sql/card_synergy_analysis.sql)

Calcula o "bônus de sinergia" ao usar duas cartas juntas. Compara o win rate do par contra a média dos win rates individuais.

- **Bônus > 10%**: Sinergia forte - Combo pode estar muito poderoso
- **Bônus < -5%**: Anti-sinergia - Cartas se anulam quando usadas juntas

```sql
-- Parâmetros: :inicio, :fim, :min_partidas
-- Retorna: par de cartas, wr_combo, wr_individuais, bonus_sinergia, tipo_relacao
```

---

## 📈 Aplicações para Balanceamento

As consultas implementadas permitem:

1. **Identificar cartas dominantes** (Consultas 1, 4) → Candidatas a nerf
2. **Detectar cartas fracas** (Consultas 1, 4) → Candidatas a buff
3. **Encontrar combos problemáticos** (Consultas 3, 6) → Ajustar sinergias
4. **Equilibrar por skill level** (Consulta 5) → Balanceamento diferenciado
5. **Monitorar meta shifts** (Consulta 2) → Rastrear evolução do jogo
   LIMIT 10;
   """

df = pd.read_sql(query, conn)
print(df)

````

### Exemplo 2: Analisar evolução de um jogador

```python
query = """
SELECT
    b.time::date as data,
    AVG(p.trofeAnalisar win rate de uma carta específica

```python
import pg8000
import pandas as pd

conn = pg8000.connect(
    host="localhost",
    database="clash_analytics",
    user="postgres",
    password="sua_senha"
)

# Substituir :carta_id por um ID real (ex: 26000000 para "Knight")
query = """
SELECT
    c.nome,
    SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
    SUM(CASE WHEN NOT p.e_vencedor THEN 1 ELSE 0 END) AS derrotas,
    COUNT(*) AS total,
    ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias
FROM participa p
JOIN usa u ON u.deck_id = p.deck_id
JOIN carta c ON c.id = u.carta_id
JOIN batalha b ON b.id = p.batalha_id
WHERE u.carta_id = 26000000
  AND b.time BETWEEN '2026-01-01' AND '2026-02-28'
GROUP BY c.nome;
"""

df = pd.read_sql(query, conn)
print(df)
````

### Exemplo 2: Identificar melhores decks do período

```python
# Buscar decks com mais de 60% de vitórias
query = """
WITH deck_stats AS (
    SELECT
        d.id AS deck_id,
        COUNT(*) AS total_partidas,
        SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) AS vitorias,
        ROUND(100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_vitorias
    FROM participa p
    JOIN batalha b ON b.id = p.batalha_id
    JOIN deck d ON d.id = p.deck_id
    WHERE b.time BETWEEN '2026-01-01' AND '2026-02-28'
    GROUP BY d.id
    HAVING COUNT(*) >= 10
       AND (100.0 * SUM(CASE WHEN p.e_vencedor THEN 1 ELSE 0 END) / COUNT(*)) > 60
)
SELECT * FROM deck_stats
ORDER BY pct_vitorias DESC
LIMIT 10;
"""

df = pd.read_sql(query, conn)
print(df)
```

---

## 📌 Notas Técnicas

### Limitações da API

- **Rate Limits**: Token Silver permite ~1000 requisições/segundo
- **Dados Históricos**: Battlelog limitado às últimas 25 batalhas por jogador
- **Timeout**: Requisições podem falhar em períodos de alta carga

### Escala de Dados

- **Meta**: Atingir 1 milhão de partidas coletadas
- **Estratégia**: Coleta distribuída ao longo de múltiplas temporadas
- **Storage**: ~500MB para 1M de batalhas (estimativa)

---

## 👥 Equipe

**Claudierio Baltazar** - Modelagem Conceitual de Dados 2025.2

---

**Projeto desenvolvido como parte da disciplina de Modelagem Conceitual de Dados**
