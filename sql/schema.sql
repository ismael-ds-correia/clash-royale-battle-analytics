-- Jogador
CREATE TABLE jogador (
    id SERIAL PRIMARY KEY,
    nick VARCHAR(50),
    nivel INTEGER
);

-- Batalha
CREATE TABLE batalha (
    id SERIAL PRIMARY KEY,
    time TIMESTAMP,
    arena VARCHAR(50),
    game_mode VARCHAR(50)
);

-- Deck
CREATE TABLE deck (
    id SERIAL PRIMARY KEY,
    id_hash VARCHAR(100) UNIQUE
);

-- Carta
CREATE TABLE carta (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50),
    raridade VARCHAR(20),
    tipo VARCHAR(20)
);

-- Usa (Deck-Carta: N:N)
CREATE TABLE usa (
    deck_id INTEGER REFERENCES deck(id) ON DELETE CASCADE,
    carta_id INTEGER REFERENCES carta(id) ON DELETE CASCADE,
    PRIMARY KEY (deck_id, carta_id)
);

-- Participa (Jogador-Batalha-Deck: N:N)
CREATE TABLE participa (
    jogador_id INTEGER REFERENCES jogador(id) ON DELETE CASCADE,
    batalha_id INTEGER REFERENCES batalha(id) ON DELETE CASCADE,
    deck_id INTEGER REFERENCES deck(id) ON DELETE CASCADE,
    trofeus_antes INTEGER,
    trofeus_depois INTEGER,
    e_vencedor BOOLEAN,
    PRIMARY KEY (jogador_id, batalha_id)
);