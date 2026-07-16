-- Métodos biométricos: 4=facial, 5=huella (idempotente).
INSERT INTO tab_metodos_aut (id_metodo_aut, nom_metodo_aut, usr_insert, fec_insert)
VALUES
    (4, 'Biometría facial', 'seed', CURRENT_TIMESTAMP),
    (5, 'Biometría huella', 'seed', CURRENT_TIMESTAMP)
ON CONFLICT (id_metodo_aut) DO NOTHING;
