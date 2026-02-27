import pandas as pd
import pg8000
from pathlib import Path
import hashlib

# Configurações do banco
DB_CONFIG = {
    "host": "localhost",
    "database": "clash_analytics",
    "user": "postgres",
    "password": ""
}

def connect_db():
    return pg8000.connect(**DB_CONFIG)

def hash_deck(card_ids):
    """Gera um hash único para um deck a partir dos ids das cartas."""
    card_ids_sorted = sorted([str(cid) for cid in card_ids])
    deck_str = ",".join(card_ids_sorted)
    return hashlib.sha256(deck_str.encode()).hexdigest()

def normalize_jogador(player):
    """Extrai dados do jogador."""
    return {
        "id": player.get("tag"),
        "nick": player.get("name")
    }

def normalize_batalha(battle):
    """Extrai dados da batalha."""
    # Cria um id único para a batalha
    battle_id = f"{battle['battleTime']}_{battle['team'][0]['tag']}_{battle['opponent'][0]['tag']}"
    return {
        "id": battle_id,
        "time": battle.get("battleTime"),
        "arena": battle.get("arena.name") or battle.get("arena", {}).get("name"),
        "game_mode": battle.get("gameMode.name") or battle.get("gameMode", {}).get("name"),
    }

def normalize_deck(cards):
    """Gera hash e retorna lista de ids das cartas do deck."""
    card_ids = sorted([str(card["id"]) for card in cards])
    deck_hash = hashlib.sha256(",".join(card_ids).encode()).hexdigest()
    return {
        "id_hash": deck_hash,
        "card_ids": card_ids
    }

def normalize_carta(card):
    """Extrai dados da carta."""
    return {
        "id": int(card.get("id")),
        "nome": card.get("name"),
        "raridade": card.get("rarity")
    }

def normalize_participa(player, battle, deck_hash, is_team, crowns_team, crowns_opponent):
    """Extrai dados do relacionamento Participa."""
    trofeus_antes = player.get("startingTrophies")
    trophy_change = player.get("trophyChange") or 0
    # Força inteiro se não for None
    trofeus_antes = int(trofeus_antes) if trofeus_antes is not None else None
    trophy_change = int(trophy_change) if trophy_change is not None else 0
    trofeus_depois = trofeus_antes + trophy_change if trofeus_antes is not None else None
    # Vencedor: quem fez mais coroas
    e_vencedor = crowns_team > crowns_opponent if is_team else crowns_opponent > crowns_team
    return {
        "jogador_id": player.get("tag"),
        "batalha_id": f"{battle['battleTime']}_{battle['team'][0]['tag']}_{battle['opponent'][0]['tag']}",
        "deck_id_hash": deck_hash,
        "trofeus_antes": trofeus_antes,
        "trofeus_depois": trofeus_depois,
        "e_vencedor": e_vencedor
    }

def normalize_usa(deck_hash, card_ids):
    """Relacionamento deck-carta."""
    return [
        {"deck_id_hash": deck_hash, "carta_id": cid}
        for cid in card_ids
    ]

def insert_jogador(cur, jogador):
    cur.execute(
        """
        INSERT INTO jogador (id, nick)
        VALUES (%s, %s)
        ON CONFLICT (id) DO NOTHING
        """,
        (jogador["id"], jogador["nick"])
    )

def insert_batalha(cur, batalha):
    cur.execute(
        """
        INSERT INTO batalha (id, time, arena, game_mode)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (id) DO NOTHING
        """,
        (batalha["id"], batalha["time"], batalha["arena"], batalha["game_mode"])
    )

def insert_deck(cur, deck):
    cur.execute(
        """
        INSERT INTO deck (id_hash)
        VALUES (%s)
        ON CONFLICT (id_hash) DO NOTHING
        """,
        (deck["id_hash"],)
    )

def insert_carta(cur, carta):
    cur.execute(
        """
        INSERT INTO carta (id, nome, raridade)
        VALUES (%s, %s, %s)
        ON CONFLICT (id) DO NOTHING
        """,
        (carta["id"], carta["nome"], carta["raridade"])
    )

def insert_participa(cur, participa):
    cur.execute(
        """
        INSERT INTO participa (jogador_id, batalha_id, deck_id, trofeus_antes, trofeus_depois, e_vencedor)
        VALUES (
            %s,
            %s,
            (SELECT id FROM deck WHERE id_hash = %s),
            %s, %s, %s
        )
        ON CONFLICT (jogador_id, batalha_id) DO NOTHING
        """,
        (
            participa["jogador_id"],
            participa["batalha_id"],
            participa["deck_id_hash"],
            participa["trofeus_antes"],
            participa["trofeus_depois"],
            participa["e_vencedor"]
        )
    )

def insert_usa(cur, deck_hash, carta_id):
    cur.execute(
        """
        INSERT INTO usa (deck_id, carta_id)
        VALUES (
            (SELECT id FROM deck WHERE id_hash = %s),
            %s
        )
        ON CONFLICT (deck_id, carta_id) DO NOTHING
        """,
        (deck_hash, carta_id)
    )

def main():
    parquet_dir = Path("data/battles_raw_batches")
    parquet_files = sorted(parquet_dir.glob("*.parquet"))
    if not parquet_files:
        print("Nenhum arquivo Parquet encontrado.")
        return

    conn = connect_db()
    cur = conn.cursor()

    total_batalhas = 0
    for parquet_file in parquet_files:
        if parquet_file.name.endswith(".parquet"):
            df = pd.read_parquet(parquet_file)
            print(f"Lidas {len(df)} batalhas do arquivo {parquet_file}.")
            for idx, row in df.iterrows():
                battle = row.to_dict()
                try:
                    batalha_norm = normalize_batalha(battle)
                    insert_batalha(cur, batalha_norm)

                    # Team e Opponent (pode ser 2v2, mas aqui só pega o primeiro de cada lado)
                    for is_team, player_key in [(True, "team"), (False, "opponent")]:
                        player = battle[player_key][0]
                        jogador_norm = normalize_jogador(player)
                        insert_jogador(cur, jogador_norm)

                        deck_norm = normalize_deck(player["cards"])
                        insert_deck(cur, deck_norm)

                        # Cartas do deck
                        for card in player["cards"]:
                            carta_norm = normalize_carta(card)
                            insert_carta(cur, carta_norm)
                            insert_usa(cur, deck_norm["id_hash"], carta_norm["id"])

                        # Participa
                        crowns_team = battle["team"][0].get("crowns", 0)
                        crowns_opponent = battle["opponent"][0].get("crowns", 0)
                        participa_norm = normalize_participa(
                            player, battle, deck_norm["id_hash"], is_team, crowns_team, crowns_opponent
                        )
                        insert_participa(cur, participa_norm)
                    total_batalhas += 1
                    if total_batalhas % 100 == 0:
                        print(f"{total_batalhas} batalhas processadas...")
                        conn.commit()
                except Exception as e:
                    print(f"Erro na batalha {total_batalhas}: {e}")
                    conn.rollback()
            conn.commit()

    cur.close()
    conn.close()
    print("Carga finalizada.")

if __name__ == "__main__":
    main()