CREATE DATABASE IF NOT EXISTS MonReseauSocial;
USE MonReseauSocial;

DROP TABLE IF EXISTS user_competence;
DROP TABLE IF EXISTS Follow;
DROP TABLE IF EXISTS report;
DROP TABLE IF EXISTS Message;
DROP TABLE IF EXISTS Evaluation;
DROP TABLE IF EXISTS Competence;
DROP TABLE IF EXISTS Supervision;
DROP TABLE IF EXISTS Parent;
DROP TABLE IF EXISTS User;


-- SELECT * from Evaluation ;
-- SELECT * from message  ;

-- Table des utilisateurs
CREATE TABLE user (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    date_naissance DATE,
    sexe ENUM('H', 'F', 'Autre'),
    bio TEXT,
    telephone VARCHAR(15),
    localisation VARCHAR(100),
    statut ENUM('actif', 'desactive') DEFAULT 'actif',
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP 
);
-- SELECT * from user  ;

-- Table des compétences
CREATE TABLE competence (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nom VARCHAR(50) NOT NULL,
    description TEXT,
    categorie VARCHAR(50),
    niveau ENUM('debutant', 'intermediaire', 'avance') NOT NULL
);

-- SELECT * from competence  ;
-- Relation entre utilisateur et compétence (possède une compétence)
CREATE TABLE user_competence (
    user_id INT,
    competence_id INT,
    PRIMARY KEY (user_id, competence_id),
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (competence_id) REFERENCES competence(id) ON DELETE CASCADE
);

-- SELECT * from user_competence  ;
-- Table des évaluations des utilisateurs
CREATE TABLE evaluation (
    id INT PRIMARY KEY AUTO_INCREMENT,
    utilisateur_evalue INT NOT NULL,
    evaluateur INT NOT NULL,
    note INT CHECK (note BETWEEN 1 AND 5),
    commentaire TEXT,
    date_evaluation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_evalue) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (evaluateur) REFERENCES user(id) ON DELETE CASCADE
);

-- SELECT * from evaluation  ;
-- Table des abonnements (follow)
CREATE TABLE follow (
    id_suiveur INT NOT NULL,
    id_suivi INT NOT NULL,
    PRIMARY KEY (id_suiveur, id_suivi),
    FOREIGN KEY (id_suiveur) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (id_suivi) REFERENCES user(id) ON DELETE CASCADE
);
-- SELECT * from follow  ;
-- Table des messages (write)
CREATE TABLE message (
    id INT PRIMARY KEY AUTO_INCREMENT,
    expediteur INT NOT NULL,
    destinataire INT NOT NULL,
    contenu TEXT NOT NULL,
    statut ENUM('lu', 'non lu') DEFAULT 'non lu',
    date_envoi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expediteur) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (destinataire) REFERENCES user(id) ON DELETE CASCADE
);

-- SELECT * from message  ;
-- Table des signalements (report)
CREATE TABLE report (
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_signaleur INT NOT NULL,
    id_destinataire INT NOT NULL,
    id_message INT,
    raison TEXT NOT NULL,
    date_signalement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_signaleur) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (id_destinataire) REFERENCES user(id) ON DELETE CASCADE,
    FOREIGN KEY (id_message) REFERENCES message(id) ON DELETE CASCADE
);

-- SELECT * from report  ;
-- Table des parents (supervision)
CREATE TABLE parent (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- SELECT * from report  ;
-- Relation supervision entre un parent et un utilisateur
CREATE TABLE supervision (
    parent_id INT,
    user_id INT,
    PRIMARY KEY (parent_id, user_id),
    FOREIGN KEY (parent_id) REFERENCES parent(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);

-- les declencheures 

DELIMITER $$

CREATE TRIGGER verif_age_utilisateur
BEFORE INSERT ON user
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.date_naissance, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : L\'utilisateur est mineur';
    END IF;
END $$

DELIMITER ;
-- test du dclencheur 
INSERT INTO user (nom, email, mot_de_passe, date_naissance, sexe, bio, telephone, localisation)
VALUES ('Jean Dupont', 'jean.dupont@email.com', 'motdepasse123', '1990-05-15', 'H', 'Développeur passionné', '1234567890', 'Paris');
SELECT * from user ;

INSERT INTO user (nom, email, mot_de_passe, date_naissance, sexe, bio, telephone, localisation)
VALUES ('Petit Pierre', 'pierre@email.com', 'motdepasse456', '2010-08-22', 'H', 'Collégien intéressé par l\'informatique', '0987654321', 'Lyon');

-- Empêcher la mise à jour de la date de naissance d'un utilisateur pour devenir mineur

DELIMITER //
CREATE TRIGGER before_update_user_age
BEFORE UPDATE ON user
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.date_naissance, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Impossible de rendre un utilisateur mineur';
    END IF;
END;
//
DELIMITER ;

-- Mettre à jour automatiquement le statut d’un utilisateur en "désactivé" s'il est signalé plus de 5 fois

DELIMITER //
CREATE TRIGGER after_insert_report
AFTER INSERT ON report
FOR EACH ROW
BEGIN
    DECLARE signalements INT;
    
    -- Compter le nombre de signalements de l'utilisateur signalé
    SELECT COUNT(*) INTO signalements FROM report WHERE id_destinataire = NEW.id_destinataire;
    
    -- Désactiver l'utilisateur si le nombre de signalements dépasse 5
    IF signalements > 5 THEN
        UPDATE user SET statut = 'desactive' WHERE id = NEW.id_destinataire;
    END IF;
END;
//
DELIMITER ;

-- Empêcher l'auto-évaluation (un utilisateur ne peut pas s’évaluer lui-même)
DELIMITER //
CREATE TRIGGER before_insert_evaluation
BEFORE INSERT ON evaluation
FOR EACH ROW
BEGIN
    IF NEW.utilisateur_evalue = NEW.evaluateur THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Un utilisateur ne peut pas s\'évaluer lui-même';
    END IF;
END;
//
DELIMITER ;

-- Empêcher l'envoi de messages à soi-même

DELIMITER //
CREATE TRIGGER before_insert_message
BEFORE INSERT ON message
FOR EACH ROW
BEGIN
    IF NEW.expediteur = NEW.destinataire THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Impossible de s\'envoyer un message à soi-même';
    END IF;
END;
//
DELIMITER ;

-- Vérifier que la note donnée dans une évaluation est entre 1 et 5

DELIMITER //
CREATE TRIGGER before_insert_note
BEFORE INSERT ON evaluation
FOR EACH ROW
BEGIN
    IF NEW.note < 1 OR NEW.note > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : La note doit être entre 1 et 5';
    END IF;
END;
//
DELIMITER ;

-- Supprimer automatiquement les compétences d’un utilisateur lorsqu’il est supprimé
DELIMITER //
CREATE TRIGGER after_delete_user
AFTER DELETE ON user
FOR EACH ROW
BEGIN
    DELETE FROM user_competence WHERE user_id = OLD.id;
END;
//
DELIMITER ;

-- Supprimer les abonnements (follow) quand un utilisateur est supprimé

DELIMITER //
CREATE TRIGGER after_delete_follow
AFTER DELETE ON user
FOR EACH ROW
BEGIN
    DELETE FROM follow WHERE id_suiveur = OLD.id OR id_suivi = OLD.id;
END;
//
DELIMITER ;

-- Empêcher la suppression d'un utilisateur qui a encore des abonnés

DELIMITER //
CREATE TRIGGER before_delete_user
BEFORE DELETE ON user
FOR EACH ROW
BEGIN
    DECLARE nb_abonnes INT;
    
    -- Compter le nombre d'abonnés
    SELECT COUNT(*) INTO nb_abonnes FROM follow WHERE id_suivi = OLD.id;
    
    -- Si l'utilisateur a des abonnés, empêcher la suppression
    IF nb_abonnes > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erreur : Impossible de supprimer un utilisateur qui a encore des abonnés';
    END IF;
END;
//
DELIMITER ;

-- Tente de s’auto-évaluer
INSERT INTO evaluation (utilisateur_evalue, evaluateur, note) 
VALUES (1, 1, 4);
-- Tester l'interdiction de modification de la date de naissance pour devenir mineur
UPDATE user 
SET date_naissance = '2010-01-01' 
WHERE id = 1;
-- Tester la désactivation automatique d'un utilisateur après 5 signalements
-- Ajouter un utilisateur (victime de signalements)
INSERT INTO user (nom, email, mot_de_passe, date_naissance) 
VALUES ('Victime', 'victime@email.com', 'test123', '1995-05-15');
-- Ajouter des utilisateurs (signaleurs)
INSERT INTO user (nom, email, mot_de_passe, date_naissance) 
VALUES ('Signaleur1', 'signaleur1@email.com', 'test123', '1990-01-01'),
       ('Signaleur2', 'signaleur2@email.com', 'test123', '1990-02-02'),
       ('Signaleur3', 'signaleur3@email.com', 'test123', '1990-03-03'),
       ('Signaleur4', 'signaleur4@email.com', 'test123', '1990-04-04'),
       ('Signaleur5', 'signaleur5@email.com', 'test123', '1990-05-05'),
       ('Signaleur6', 'signaleur6@email.com', 'test123', '1990-06-06');

-- Ajouter des signalements (5 premiers)

INSERT INTO report (id_signaleur, id_destinataire, raison) 
VALUES (2, 1, 'Comportement inapproprié'),
       (3, 1, 'Spam'),
       (4, 1, 'Harcèlement'),
       (5, 1, 'Langage offensant'),
       (6, 1, 'Fraude');
--  Vérifier le statut de la victime (doit être toujours actif)
SELECT statut FROM user WHERE id = 1; -- resultat attendu actif

-- Ajouter un 6ème signalement
INSERT INTO report (id_signaleur, id_destinataire, raison) 
VALUES (7, 1, 'Arnaque');
-- Vérifier le statut de la victime (doit être désactivé)
SELECT statut FROM user WHERE id = 1; -- le resultat cest desactives 

-- Tester l'interdiction d'auto-évaluation

INSERT INTO evaluation (utilisateur_evalue, evaluateur, note) 
VALUES (1, 1, 4);

-- Tester l'interdiction d'envoyer un message à soi-même
INSERT INTO message (expediteur, destinataire, contenu) 
VALUES (1, 1, 'bonjour a moi  !');
-- Tester la validation de la note entre 1 et 5
-- Cas 1 : Note correcte (devrait passer)

INSERT INTO evaluation (utilisateur_evalue, evaluateur, note) 
VALUES (2, 1, 5);
-- Cas 2 : Note incorrecte (< 1)
INSERT INTO evaluation (utilisateur_evalue, evaluateur, note) 
VALUES (2, 1, 0);
-- Cas 3 : Note incorrecte (> 5)
INSERT INTO evaluation (utilisateur_evalue, evaluateur, note) 
VALUES (2, 1, 6);
-- Tester la suppression des compétences d’un utilisateur supprimé
-- Ajouter un utilisateur et une compétence
INSERT INTO user (nom, email, mot_de_passe, date_naissance) 
VALUES ('Utilisateur Test', 'test@email.com', 'test123', '1990-05-15');

INSERT INTO competence (nom, description, categorie, niveau) 
VALUES ('Python', 'Langage de programmation', 'Programmation', 'avancé');

INSERT INTO user_competence (user_id, competence_id) 
VALUES (1, 1);
-- Vérifions  que la compétence est bien associée
SELECT * FROM user_competence WHERE user_id = 1;
--  Supprimer l'utilisateur
DELETE FROM user WHERE id = 1;
-- Vérifier si les compétences associées sont supprimées
SELECT * FROM user_competence WHERE user_id = 1;


--  Tester l'interdiction de suppression d'un utilisateur ayant des abonnés

-- Ajouter un abonnement
INSERT INTO follow (id_suiveur, id_suivi) 
VALUES (2, 1);
-- Tenter de supprimer l’utilisateur suivi
DELETE FROM user WHERE id = 1; -- impossible de supprimer un utilisateur qui a encore des abonnes

-- ******************************************************************************
-- REQUÊTES AVANCÉES POUR LE RÉSEAU SOCIAL
-- ******************************************************************************

-- 1. Requête pour trouver les utilisateurs les plus influents 
-- (avec le plus grand nombre d'abonnés, leurs compétences principales et leur note moyenne)
SELECT 
    u.id, 
    u.nom, 
    u.email,
    COUNT(DISTINCT f.id_suiveur) AS nombre_abonnes,
    AVG(e.note) AS note_moyenne,
    GROUP_CONCAT(DISTINCT c.nom ORDER BY c.nom SEPARATOR ', ') AS competences
FROM 
    user u
LEFT JOIN 
    follow f ON u.id = f.id_suivi
LEFT JOIN 
    evaluation e ON u.id = e.utilisateur_evalue
LEFT JOIN 
    user_competence uc ON u.id = uc.user_id
LEFT JOIN 
    competence c ON uc.competence_id = c.id
GROUP BY 
    u.id, u.nom, u.email
HAVING 
    COUNT(DISTINCT f.id_suiveur) > 0
ORDER BY 
    nombre_abonnes DESC, note_moyenne DESC
LIMIT 10;

-- 2. Requête pour identifier les utilisateurs similaires 
-- (ayant des compétences communes et qui se suivent mutuellement)
SELECT 
    u1.id AS user1_id, 
    u1.nom AS user1_nom, 
    u2.id AS user2_id, 
    u2.nom AS user2_nom,
    COUNT(DISTINCT c1.id) AS competences_communes,
    GROUP_CONCAT(DISTINCT c1.nom ORDER BY c1.nom SEPARATOR ', ') AS liste_competences_communes
FROM 
    user u1
JOIN 
    user_competence uc1 ON u1.id = uc1.user_id
JOIN 
    competence c1 ON uc1.competence_id = c1.id
JOIN 
    user_competence uc2 ON c1.id = uc2.competence_id AND uc1.user_id != uc2.user_id
JOIN 
    user u2 ON uc2.user_id = u2.id
JOIN 
    follow f1 ON u1.id = f1.id_suiveur AND u2.id = f1.id_suivi
JOIN 
    follow f2 ON u2.id = f2.id_suiveur AND u1.id = f2.id_suivi
GROUP BY 
    u1.id, u1.nom, u2.id, u2.nom
HAVING 
    competences_communes >= 2
ORDER BY 
    competences_communes DESC;

-- 3. Requête pour analyser la répartition des compétences par niveau et par catégorie
SELECT 
    c.categorie,
    c.niveau,
    COUNT(uc.user_id) AS nombre_utilisateurs,
    COUNT(DISTINCT uc.user_id) AS utilisateurs_uniques,
    GROUP_CONCAT(DISTINCT u.nom ORDER BY u.nom SEPARATOR ', ') AS liste_utilisateurs
FROM 
    competence c
LEFT JOIN 
    user_competence uc ON c.id = uc.competence_id
LEFT JOIN 
    user u ON uc.user_id = u.id
GROUP BY 
    c.categorie, c.niveau
ORDER BY 
    c.categorie, 
    CASE c.niveau
        WHEN 'débutant' THEN 1
        WHEN 'intermédiaire' THEN 2
        WHEN 'avancé' THEN 3
    END;

-- 4. Requête pour identifier les conversations les plus actives entre utilisateurs
SELECT 
    LEAST(m.expediteur, m.destinataire) AS user1_id,
    GREATEST(m.expediteur, m.destinataire) AS user2_id,
    u1.nom AS nom_user1,
    u2.nom AS nom_user2,
    COUNT(m.id) AS nombre_messages,
    MIN(m.date_envoi) AS debut_conversation,
    MAX(m.date_envoi) AS dernier_message,
    DATEDIFF(MAX(m.date_envoi), MIN(m.date_envoi)) AS duree_jours
FROM 
    message m
JOIN 
    user u1 ON u1.id = LEAST(m.expediteur, m.destinataire)
JOIN 
    user u2 ON u2.id = GREATEST(m.expediteur, m.destinataire)
GROUP BY 
    user1_id, user2_id, u1.nom, u2.nom
HAVING 
    nombre_messages > 5
ORDER BY 
    nombre_messages DESC, dernier_message DESC;

-- 5. Requête pour identifier les utilisateurs problématiques 
-- (avec des signalements multiples mais pas encore désactivés)
SELECT 
    u.id,
    u.nom,
    u.email,
    u.statut,
    COUNT(r.id) AS nombre_signalements,
    GROUP_CONCAT(DISTINCT r.raison SEPARATOR ' | ') AS raisons,
    COUNT(DISTINCT r.id_signaleur) AS signaleurs_uniques
FROM 
    user u
JOIN 
    report r ON u.id = r.id_destinataire
WHERE 
    u.statut = 'actif'
GROUP BY 
    u.id, u.nom, u.email, u.statut
HAVING 
    COUNT(r.id) >= 3
ORDER BY 
    nombre_signalements DESC;

-- ******************************************************************************
-- PROCÉDURES STOCKÉES ET FONCTIONS
-- ******************************************************************************

-- 1. Procédure pour recommander des utilisateurs à suivre
-- (basée sur les compétences communes et les abonnements des personnes suivies)
DELIMITER //
CREATE PROCEDURE recommander_utilisateurs(IN p_user_id INT, IN p_limit INT)
BEGIN
    -- Déclaration pour gestion d'erreurs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Une erreur s\'est produite lors de la génération des recommandations' AS error_message;
    END;
    
    -- Début de la transaction
    START TRANSACTION;
    
    -- Table temporaire pour stocker les résultats
    DROP TEMPORARY TABLE IF EXISTS temp_recommendations;
    CREATE TEMPORARY TABLE temp_recommendations (
        user_id INT,
        nom VARCHAR(50),
        email VARCHAR(100),
        score INT,
        raison VARCHAR(255)
    );
    
    -- 1. Recommandations basées sur les compétences communes
    INSERT INTO temp_recommendations
    SELECT 
        u2.id,
        u2.nom,
        u2.email,
        COUNT(DISTINCT c1.id) * 10 AS score,
        CONCAT('Partage ', COUNT(DISTINCT c1.id), ' compétences avec vous') AS raison
    FROM 
        user_competence uc1
    JOIN 
        competence c1 ON uc1.competence_id = c1.id
    JOIN 
        user_competence uc2 ON c1.id = uc2.competence_id
    JOIN 
        user u2 ON uc2.user_id = u2.id
    WHERE 
        uc1.user_id = p_user_id
        AND uc2.user_id != p_user_id
        AND NOT EXISTS (SELECT 1 FROM follow WHERE id_suiveur = p_user_id AND id_suivi = u2.id)
        AND u2.statut = 'actif'
    GROUP BY 
        u2.id, u2.nom, u2.email
    HAVING 
        COUNT(DISTINCT c1.id) > 0;
    
    -- 2. Recommandations basées sur les amis de mes amis
    INSERT INTO temp_recommendations
    SELECT 
        u3.id,
        u3.nom,
        u3.email,
        COUNT(DISTINCT u2.id) * 5 AS score,
        CONCAT('Suivi par ', COUNT(DISTINCT u2.id), ' personne(s) que vous suivez') AS raison
    FROM 
        follow f1
    JOIN 
        user u2 ON f1.id_suivi = u2.id
    JOIN 
        follow f2 ON f2.id_suiveur = u2.id
    JOIN 
        user u3 ON f2.id_suivi = u3.id
    WHERE 
        f1.id_suiveur = p_user_id
        AND u3.id != p_user_id
        AND NOT EXISTS (SELECT 1 FROM follow WHERE id_suiveur = p_user_id AND id_suivi = u3.id)
        AND u3.statut = 'actif'
    GROUP BY 
        u3.id, u3.nom, u3.email;
    
    -- Afficher les recommandations finales en supprimant les doublons et en triant par score
    SELECT 
        user_id,
        nom,
        email,
        MAX(score) AS score,
        GROUP_CONCAT(DISTINCT raison SEPARATOR ' et ') AS raisons
    FROM 
        temp_recommendations
    GROUP BY 
        user_id, nom, email
    ORDER BY 
        score DESC
    LIMIT p_limit;
    
    -- Nettoyer la table temporaire
    DROP TEMPORARY TABLE IF EXISTS temp_recommendations;
    
    -- Valider la transaction
    COMMIT;
END //
DELIMITER ;

-- 2. Fonction pour calculer le score d'influence d'un utilisateur
-- (basé sur nombre d'abonnés, évaluations, compétences et activité)
DELIMITER //
CREATE FUNCTION calculer_score_influence(p_user_id INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE nb_abonnes INT DEFAULT 0;
    DECLARE note_moyenne DECIMAL(3,2) DEFAULT 0;
    DECLARE nb_competences INT DEFAULT 0;
    DECLARE nb_messages INT DEFAULT 0;
    DECLARE score_final DECIMAL(10,2) DEFAULT 0;
    
    -- Récupérer le nombre d'abonnés
    SELECT COUNT(*) INTO nb_abonnes
    FROM follow
    WHERE id_suivi = p_user_id;
    
    -- Récupérer la note moyenne
    SELECT COALESCE(AVG(note), 3) INTO note_moyenne
    FROM evaluation
    WHERE utilisateur_evalue = p_user_id;
    
    -- Récupérer le nombre de compétences
    SELECT COUNT(*) INTO nb_competences
    FROM user_competence
    WHERE user_id = p_user_id;
    
    -- Récupérer le nombre de messages envoyés
    SELECT COUNT(*) INTO nb_messages
    FROM message
    WHERE expediteur = p_user_id;
    
    -- Calculer le score final (formule personnalisable)
    SET score_final = (nb_abonnes * 5) + (note_moyenne * 15) + (nb_competences * 3) + (nb_messages * 0.5);
    
    RETURN score_final;
END //
DELIMITER ;

-- 3. Procédure pour analyser l'activité d'un utilisateur
-- (statistiques détaillées sur l'activité et les interactions)
DELIMITER //
CREATE PROCEDURE analyser_activite_utilisateur(IN p_user_id INT)
BEGIN
    DECLARE user_existe INT DEFAULT 0;
    
    -- Vérifier si l'utilisateur existe
    SELECT COUNT(*) INTO user_existe FROM user WHERE id = p_user_id;
    
    IF user_existe = 0 THEN
        SELECT 'Utilisateur introuvable' AS message;
    ELSE
        -- Informations générales sur l'utilisateur
        SELECT 
            u.id,
            u.nom,
            u.email,
            u.date_creation,
            u.statut,
            TIMESTAMPDIFF(YEAR, u.date_naissance, CURDATE()) AS age,
            calculer_score_influence(u.id) AS score_influence
        FROM 
            user u
        WHERE 
            u.id = p_user_id;
        
        -- Statistiques sur les abonnements
        SELECT 
            COUNT(DISTINCT f1.id_suivi) AS nombre_abonnements,
            COUNT(DISTINCT f2.id_suiveur) AS nombre_abonnes,
            (SELECT COUNT(*) FROM follow f3 JOIN follow f4 ON f3.id_suivi = f4.id_suiveur AND f3.id_suiveur = f4.id_suivi 
             WHERE f3.id_suiveur = p_user_id) AS relations_mutuelles
        FROM 
            follow f1
        LEFT JOIN 
            follow f2 ON f2.id_suivi = p_user_id
        WHERE 
            f1.id_suiveur = p_user_id;
        
        -- Statistiques sur les messages
        SELECT 
            COUNT(CASE WHEN m.expediteur = p_user_id THEN 1 END) AS messages_envoyes,
            COUNT(CASE WHEN m.destinataire = p_user_id THEN 1 END) AS messages_recus,
            COUNT(DISTINCT CASE WHEN m.expediteur = p_user_id THEN m.destinataire ELSE NULL END) AS destinataires_uniques,
            COUNT(DISTINCT CASE WHEN m.destinataire = p_user_id THEN m.expediteur ELSE NULL END) AS expediteurs_uniques,
            DATEDIFF(NOW(), MAX(m.date_envoi)) AS jours_depuis_dernier_message
        FROM 
            message m
        WHERE 
            m.expediteur = p_user_id OR m.destinataire = p_user_id;
        
        -- Top 5 des contacts les plus fréquents
        SELECT 
            u2.id,
            u2.nom,
            COUNT(m.id) AS nombre_messages,
            MAX(m.date_envoi) AS dernier_message
        FROM 
            message m
        JOIN 
            user u2 ON (u2.id = m.expediteur OR u2.id = m.destinataire) AND u2.id != p_user_id
        WHERE 
            m.expediteur = p_user_id OR m.destinataire = p_user_id
        GROUP BY 
            u2.id, u2.nom
        ORDER BY 
            COUNT(m.id) DESC
        LIMIT 5;
        
        -- Évaluations reçues
        SELECT 
            AVG(e.note) AS moyenne_evaluations,
            COUNT(e.id) AS nombre_evaluations,
            MIN(e.note) AS note_min,
            MAX(e.note) AS note_max
        FROM 
            evaluation e
        WHERE 
            e.utilisateur_evalue = p_user_id;
        
        -- Signalements
        SELECT 
            COUNT(CASE WHEN r.id_signaleur = p_user_id THEN 1 END) AS signalements_envoyes,
            COUNT(CASE WHEN r.id_destinataire = p_user_id THEN 1 END) AS signalements_recus
        FROM 
            report r
        WHERE 
            r.id_signaleur = p_user_id OR r.id_destinataire = p_user_id;
    END IF;
END //
DELIMITER ;

-- 4. Procédure pour exporter les données d'un utilisateur (RGPD)
-- (Génère un résumé complet des données personnelles de l'utilisateur)
DELIMITER //
CREATE PROCEDURE exporter_donnees_utilisateur(IN p_user_id INT)
BEGIN
    DECLARE user_existe INT DEFAULT 0;
    
    -- Vérifier si l'utilisateur existe
    SELECT COUNT(*) INTO user_existe FROM user WHERE id = p_user_id;
    
    IF user_existe = 0 THEN
        SELECT 'Utilisateur introuvable' AS message;
    ELSE
        -- Données personnelles
        SELECT 
            u.id,
            u.nom,
            u.email,
            u.date_naissance,
            u.sexe,
            u.bio,
            u.telephone,
            u.localisation,
            u.statut,
            u.date_creation
        FROM 
            user u
        WHERE 
            u.id = p_user_id;
        
        -- Compétences
        SELECT 
            c.id AS competence_id,
            c.nom AS competence_nom,
            c.description,
            c.categorie,
            c.niveau
        FROM 
            user_competence uc
        JOIN 
            competence c ON uc.competence_id = c.id
        WHERE 
            uc.user_id = p_user_id;
        
        -- Abonnements (personnes que l'utilisateur suit)
        SELECT 
            u2.id AS suivi_id,
            u2.nom AS suivi_nom,
            u2.email AS suivi_email
        FROM 
            follow f
        JOIN 
            user u2 ON f.id_suivi = u2.id
        WHERE 
            f.id_suiveur = p_user_id;
        
        -- Abonnés (personnes qui suivent l'utilisateur)
        SELECT 
            u3.id AS abonne_id,
            u3.nom AS abonne_nom,
            u3.email AS abonne_email
        FROM 
            follow f
        JOIN 
            user u3 ON f.id_suiveur = u3.id
        WHERE 
            f.id_suivi = p_user_id;
        
        -- Messages envoyés
        SELECT 
            m.id AS message_id,
            m.destinataire,
            u4.nom AS destinataire_nom,
            m.contenu,
            m.statut,
            m.date_envoi
        FROM 
            message m
        JOIN 
            user u4 ON m.destinataire = u4.id
        WHERE 
            m.expediteur = p_user_id;
        
        -- Messages reçus
        SELECT 
            m.id AS message_id,
            m.expediteur,
            u5.nom AS expediteur_nom,
            m.contenu,
            m.statut,
            m.date_envoi
        FROM 
            message m
        JOIN 
            user u5 ON m.expediteur = u5.id
        WHERE 
            m.destinataire = p_user_id;
        
        -- Évaluations données
        SELECT 
            e.id AS evaluation_id,
            e.utilisateur_evalue,
            u6.nom AS evalue_nom,
            e.note,
            e.commentaire,
            e.date_evaluation
        FROM 
            evaluation e
        JOIN 
            user u6 ON e.utilisateur_evalue = u6.id
        WHERE 
            e.evaluateur = p_user_id;
        
        -- Évaluations reçues
        SELECT 
            e.id AS evaluation_id,
            e.evaluateur,
            u7.nom AS evaluateur_nom,
            e.note,
            e.commentaire,
            e.date_evaluation
        FROM 
            evaluation e
        JOIN 
            user u7 ON e.evaluateur = u7.id
        WHERE 
            e.utilisateur_evalue = p_user_id;
        
        -- Signalements envoyés
        SELECT 
            r.id AS signalement_id,
            r.id_destinataire,
            u8.nom AS destinataire_nom,
            r.id_message,
            r.raison,
            r.date_signalement
        FROM 
            report r
        JOIN 
            user u8 ON r.id_destinataire = u8.id
        WHERE 
            r.id_signaleur = p_user_id;
        
        -- Signalements reçus
        SELECT 
            r.id AS signalement_id,
            r.id_signaleur,
            u9.nom AS signaleur_nom,
            r.id_message,
            r.raison,
            r.date_signalement
        FROM 
            report r
        JOIN 
            user u9 ON r.id_signaleur = u9.id
        WHERE 
            r.id_destinataire = p_user_id;
        
        -- Supervision (parents)
        SELECT 
            p.id AS parent_id,
            p.email AS parent_email
        FROM 
            supervision s
        JOIN 
            parent p ON s.parent_id = p.id
        WHERE 
            s.user_id = p_user_id;
    END IF;
END //
DELIMITER ;

-- 5. Procédure pour nettoyer les données inactives
-- (Supprime ou anonymise les données des utilisateurs inactifs depuis longtemps)
DELIMITER //
CREATE PROCEDURE nettoyer_donnees_inactives(IN p_mois_inactivite INT)
BEGIN
    DECLARE exit_handler BOOLEAN DEFAULT FALSE;
    DECLARE v_user_id INT;
    DECLARE v_user_name VARCHAR(50);
    
    -- Déclarer le curseur pour les utilisateurs inactifs
    DECLARE cur_users CURSOR FOR
        SELECT DISTINCT u.id, u.nom
        FROM user u
        LEFT JOIN message m ON u.id = m.expediteur OR u.id = m.destinataire
        GROUP BY u.id, u.nom
        HAVING MAX(m.date_envoi) IS NULL OR 
               MAX(m.date_envoi) < DATE_SUB(NOW(), INTERVAL p_mois_inactivite MONTH);
    
    -- Gestionnaire d'erreurs
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET exit_handler = TRUE;
    
    -- Créer une table de log pour journaliser les opérations
    DROP TABLE IF EXISTS nettoyage_log;
    CREATE TABLE nettoyage_log (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        user_name VARCHAR(50),
        operation VARCHAR(50),
        date_operation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- Démarrer la transaction
    START TRANSACTION;
    
    -- Ouvrir le curseur
    OPEN cur_users;
    
    -- Boucle de traitement
    read_loop: LOOP
        FETCH cur_users INTO v_user_id, v_user_name;
        
        IF exit_handler THEN
            LEAVE read_loop;
        END IF;
        
        -- Anonymiser les données de l'utilisateur
        -- 1. Anonymiser les informations personnelles
        UPDATE user
        SET 
            nom = CONCAT('Ancien_utilisateur_', v_user_id),
            email = CONCAT('anonyme_', v_user_id, '@anonyme.com'),
            mot_de_passe = MD5(RAND()),
            bio = NULL,
            telephone = NULL,
            localisation = NULL,
            statut = 'desactive'
        WHERE id = v_user_id;
        
        -- 2. Supprimer les compétences
        DELETE FROM user_competence WHERE user_id = v_user_id;
        
        -- 3. Anonymiser les messages
        UPDATE message
        SET contenu = 'Ce message a été anonymisé suite à une longue période d\'inactivité.'
        WHERE expediteur = v_user_id;
        
        -- 4. Journaliser l'opération
        INSERT INTO nettoyage_log (user_id, user_name, operation)
        VALUES (v_user_id, v_user_name, 'Anonymisation pour inactivité');
        
    END LOOP;
    
    -- Fermer le curseur
    CLOSE cur_users;
    
    -- Valider la transaction
    COMMIT;
    
    -- Afficher un résumé des opérations
    SELECT 
        COUNT(*) AS total_utilisateurs_nettoyes,
        MIN(date_operation) AS debut_operation,
        MAX(date_operation) AS fin_operation
    FROM 
        nettoyage_log;
    
END //
DELIMITER ;

-- 6. Procédure pour gérer la supervision parentale
-- (Active/désactive certaines fonctionnalités selon l'âge)
DELIMITER //
CREATE PROCEDURE mettre_a_jour_supervision(IN p_parent_email VARCHAR(100), IN p_user_email VARCHAR(100), IN p_action VARCHAR(10))
BEGIN
    DECLARE v_parent_id INT;
    DECLARE v_user_id INT;
    DECLARE v_user_age INT;
    DECLARE v_relation_exists INT DEFAULT 0;
    
    -- Vérifier si le parent existe, sinon le créer
    SELECT id INTO v_parent_id FROM parent WHERE email = p_parent_email;
    
    IF v_parent_id IS NULL THEN
        IF p_action = 'AJOUTER' THEN
            INSERT INTO parent (email) VALUES (p_parent_email);
            SET v_parent_id = LAST_INSERT_ID();
        ELSE
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parent inexistant';
            LEAVE this_proc;
        END IF;
    END IF;
    
    -- Vérifier si l'utilisateur existe
    SELECT id, TIMESTAMPDIFF(YEAR, date_naissance, CURDATE()) 
    INTO v_user_id, v_user_age
    FROM user WHERE email = p_user_email;
    
    IF v_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Utilisateur inexistant';
        LEAVE this_proc;
    END IF;
    
    -- Vérifier si la relation existe déjà
    SELECT COUNT(*) INTO v_relation_exists
    FROM supervision
    WHERE parent_id = v_parent_id AND user_id = v_user_id;
    
    -- Traiter selon l'action demandée
    IF p_action = 'AJOUTER' THEN
        IF v_relation_exists > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Relation de supervision déjà existante';
        ELSE
            INSERT INTO supervision (parent_id, user_id)
            VALUES (v_parent_id, v_user_id);
            
            SELECT 'Relation de supervision ajoutée avec succès' AS message;
        END IF;
    ELSEIF p_action = 'RETIRER' THEN
        IF v_relation_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Relation de supervision inexistante';
        ELSE
            DELETE FROM supervision
            WHERE parent_id = v_parent_id AND user_id = v_user_id;
            
            SELECT 'Relation de supervision supprimée avec succès' AS message;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Action non reconnue (utilisez AJOUTER ou RETIRER)';
    END IF;
END //
DELIMITER ;

-- 7. Fonction pour calculer le niveau de confiance d'un utilisateur
-- (Basé sur son ancienneté, ses évaluations, son activité et ses signalements)
DELIMITER //
CREATE FUNCTION calculer_niveau_confiance(p_user_id INT) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_anciennete INT;
    DECLARE v_moyenne_evaluations DECIMAL(3,2);
    DECLARE v_nb_evaluations INT;
    DECLARE v_nb_signalements INT;
    DECLARE v_nb_competences INT;
    DECLARE v_nb_messages INT;
    DECLARE v_nb_contacts BIGINT;
    DECLARE v_score_confiance DECIMAL(5,2);
    
    -- Calcul de l'ancienneté en mois
    SELECT TIMESTAMPDIFF(MONTH, date_creation, CURDATE()) INTO v_anciennete
    FROM user WHERE id = p_user_id;
    
    -- Moyenne des évaluations et nombre d'évaluations
    SELECT AVG(note), COUNT(*) INTO v_moyenne_evaluations, v_nb_evaluations
    FROM evaluation WHERE utilisateur_evalue = p_user_id;
    
    -- Nombre de signalements reçus
    SELECT COUNT(*) INTO v_nb_signalements
    FROM report WHERE id_destinataire = p_user_id;
    
    -- Nombre de compétences
    SELECT COUNT(*) INTO v_nb_competences
    FROM user_competence WHERE user_id = p_user_id;
    
    -- Nombre de messages envoyés
    SELECT COUNT(*) INTO v_nb_messages
    FROM message WHERE expediteur = p_user_id;
    
    -- Nombre de contacts uniques (personnes avec qui l'utilisateur a échangé)
    SELECT COUNT(DISTINCT 
        CASE 
            WHEN expediteur = p_user_id THEN destinataire 
            ELSE expediteur 
        END) INTO v_nb_contacts
    FROM message
    WHERE expediteur = p_user_id OR destinataire = p_user_id;
    
    -- Calcul du score de confiance (formule paramétrable)
    -- Base sur 100 points
    SET v_score_confiance = 50; -- Score de base
    
    -- Ajout pour l'ancienneté (max +20)
    SET v_score_confiance = v_score_confiance + LEAST(v_anciennete * 0.5, 20);
    
    -- Ajout pour les évaluations (max +25)
    IF v_nb_evaluations > 0 THEN
        SET v_score_confiance = v_score_confiance + LEAST((v_moyenne_evaluations - 1) * 5, 20);
        SET v_score_confiance = v_score_confiance + LEAST(v_nb_evaluations * 0.5, 5);
    END IF;
    
    -- Déduction pour les signalements (max -40)
    SET v_score_confiance = v_score_confiance - LEAST(v_nb_signalements * 8, 40);
    
    -- Ajout pour l'activité (max +15)
    SET v_score_confiance = v_score_confiance + LEAST(v_nb_messages * 0.01, 10);
    SET v_score_confiance = v_score_confiance + LEAST(v_nb_contacts * 0.5, 5);
    
    -- Ajout pour les compétences (max +10)
    SET v_score_confiance = v_score_confiance + LEAST(v_nb_competences * 2, 10);
    
    -- Limitation du score entre 0 et 100
    SET v_score_confiance = GREATEST(0, LEAST(v_score_confiance, 100));
    
    RETURN v_score_confiance;
END //
DELIMITER ;

-- 8. Procédure pour générer des suggestions de compétences à développer
-- (Basée sur les compétences des utilisateurs similaires)
-- Continuation de la procédure suggerer_competences
DELIMITER //
CREATE PROCEDURE suggerer_competences(IN p_user_id INT)
BEGIN
    -- Vérifier si l'utilisateur existe
    DECLARE user_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO user_existe FROM user WHERE id = p_user_id;
    
    IF user_existe = 0 THEN
        SELECT 'Utilisateur introuvable' AS message;
    ELSE
        -- Créer une table temporaire pour stocker les compétences suggérées
        DROP TEMPORARY TABLE IF EXISTS temp_competences_suggerees;
        CREATE TEMPORARY TABLE temp_competences_suggerees (
            competence_id INT,
            nom_competence VARCHAR(100),
            categorie VARCHAR(50),
            niveau VARCHAR(20),
            score INT,
            raison VARCHAR(255)
        );
        
        -- 1. Suggérer des compétences basées sur les utilisateurs similaires
        INSERT INTO temp_competences_suggerees
        SELECT 
            c.id,
            c.nom,
            c.categorie,
            c.niveau,
            COUNT(DISTINCT uc2.user_id) * 5 AS score,
            'Possédée par des utilisateurs ayant des compétences similaires' AS raison
        FROM 
            user_competence uc1
        JOIN 
            competence c1 ON uc1.competence_id = c1.id
        JOIN 
            user_competence uc2 ON uc2.user_id != p_user_id
        JOIN 
            competence c ON uc2.competence_id = c.id
        JOIN 
            user_competence uc3 ON uc3.competence_id = c1.id AND uc3.user_id = uc2.user_id
        WHERE 
            uc1.user_id = p_user_id
            AND NOT EXISTS (
                SELECT 1 FROM user_competence uc4 
                WHERE uc4.user_id = p_user_id AND uc4.competence_id = c.id
            )
        GROUP BY 
            c.id, c.nom, c.categorie, c.niveau
        HAVING 
            COUNT(DISTINCT uc2.user_id) > 0;
        
        -- 2. Suggérer des compétences basées sur la catégorie
        INSERT INTO temp_competences_suggerees
        SELECT 
            c.id,
            c.nom,
            c.categorie,
            c.niveau,
            COUNT(DISTINCT c1.id) * 3 AS score,
            'De la même catégorie que vos compétences actuelles' AS raison
        FROM 
            user_competence uc1
        JOIN 
            competence c1 ON uc1.competence_id = c1.id
        JOIN 
            competence c ON c1.categorie = c.categorie AND c1.id != c.id
        WHERE 
            uc1.user_id = p_user_id
            AND NOT EXISTS (
                SELECT 1 FROM user_competence uc4 
                WHERE uc4.user_id = p_user_id AND uc4.competence_id = c.id
            )
        GROUP BY 
            c.id, c.nom, c.categorie, c.niveau;
        
        -- 3. Suggérer des compétences basées sur le niveau de progression
        INSERT INTO temp_competences_suggerees
        SELECT 
            c.id,
            c.nom,
            c.categorie,
            c.niveau,
            CASE
                WHEN c.niveau = 'intermédiaire' THEN 8
                WHEN c.niveau = 'avancé' THEN 5
                ELSE 3
            END AS score,
            CONCAT('Évolution naturelle de votre compétence en ', c1.nom) AS raison
        FROM 
            user_competence uc1
        JOIN 
            competence c1 ON uc1.competence_id = c1.id
        JOIN 
            competence c ON c.categorie = c1.categorie 
            AND ((c1.niveau = 'débutant' AND c.niveau = 'intermédiaire')
            OR (c1.niveau = 'intermédiaire' AND c.niveau = 'avancé'))
        WHERE 
            uc1.user_id = p_user_id
            AND NOT EXISTS (
                SELECT 1 FROM user_competence uc4 
                WHERE uc4.user_id = p_user_id AND uc4.competence_id = c.id
            );
        
        -- Afficher les résultats finaux
        SELECT 
            competence_id,
            nom_competence,
            categorie,
            niveau,
            MAX(score) AS pertinence,
            GROUP_CONCAT(DISTINCT raison SEPARATOR ' et ') AS raisons
        FROM 
            temp_competences_suggerees
        GROUP BY 
            competence_id, nom_competence, categorie, niveau
        ORDER BY 
            pertinence DESC, categorie, niveau
        LIMIT 10;
        
        -- Nettoyer la table temporaire
        DROP TEMPORARY TABLE IF EXISTS temp_competences_suggerees;
    END IF;
END //
DELIMITER ;

-- 9. Procédure pour détecter les anomalies dans les interactions
-- (Identifie les comportements potentiellement problématiques)
DELIMITER //
CREATE PROCEDURE detecter_anomalies_interactions()
BEGIN
    -- Tableau pour stocker les résultats
    DROP TEMPORARY TABLE IF EXISTS temp_anomalies;
    CREATE TEMPORARY TABLE temp_anomalies (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        nom_utilisateur VARCHAR(50),
        email_utilisateur VARCHAR(100),
        type_anomalie VARCHAR(100),
        description TEXT,
        niveau_gravite INT, -- 1 (faible) à 5 (élevé)
        date_detection TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    -- 1. Utilisateurs avec un nombre anormalement élevé de messages envoyés en peu de temps
    INSERT INTO temp_anomalies (user_id, nom_utilisateur, email_utilisateur, type_anomalie, description, niveau_gravite)
    SELECT 
        u.id,
        u.nom,
        u.email,
        'Envoi massif de messages',
        CONCAT('A envoyé ', COUNT(m.id), ' messages dans les dernières 24 heures'),
        CASE 
            WHEN COUNT(m.id) > 200 THEN 5
            WHEN COUNT(m.id) > 100 THEN 4
            WHEN COUNT(m.id) > 50 THEN 3
            ELSE 2
        END
    FROM 
        user u
    JOIN 
        message m ON u.id = m.expediteur
    WHERE 
        m.date_envoi > DATE_SUB(NOW(), INTERVAL 24 HOUR)
    GROUP BY 
        u.id, u.nom, u.email
    HAVING 
        COUNT(m.id) > 30;
    
    -- 2. Utilisateurs avec un taux anormalement élevé de signalements reçus récemment
    INSERT INTO temp_anomalies (user_id, nom_utilisateur, email_utilisateur, type_anomalie, description, niveau_gravite)
    SELECT 
        u.id,
        u.nom,
        u.email,
        'Signalements multiples',
        CONCAT('A reçu ', COUNT(r.id), ' signalements dans les 7 derniers jours'),
        CASE 
            WHEN COUNT(r.id) > 10 THEN 5
            WHEN COUNT(r.id) > 5 THEN 4
            ELSE 3
        END
    FROM 
        user u
    JOIN 
        report r ON u.id = r.id_destinataire
    WHERE 
        r.date_signalement > DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY 
        u.id, u.nom, u.email
    HAVING 
        COUNT(r.id) > 3;
    
    -- 3. Utilisateurs avec un taux anormalement bas de réponse aux messages
    INSERT INTO temp_anomalies (user_id, nom_utilisateur, email_utilisateur, type_anomalie, description, niveau_gravite)
    SELECT 
        u.id,
        u.nom,
        u.email,
        'Faible taux de réponse',
        CONCAT('Taux de réponse de ', ROUND((reponses_envoyees / messages_recus) * 100, 2), '%'),
        2
    FROM 
        user u
    JOIN (
        SELECT 
            destinataire,
            COUNT(*) AS messages_recus
        FROM 
            message
        WHERE 
            date_envoi > DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY 
            destinataire
    ) AS messages_recus ON u.id = messages_recus.destinataire
    JOIN (
        SELECT 
            expediteur,
            COUNT(*) AS reponses_envoyees
        FROM 
            message
        WHERE 
            date_envoi > DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY 
            expediteur
    ) AS reponses_envoyees ON u.id = reponses_envoyees.expediteur
    WHERE 
        messages_recus > 20 AND (reponses_envoyees / messages_recus) < 0.2;
    
    -- 4. Comptes créés récemment avec activité anormalement élevée
    INSERT INTO temp_anomalies (user_id, nom_utilisateur, email_utilisateur, type_anomalie, description, niveau_gravite)
    SELECT 
        u.id,
        u.nom,
        u.email,
        'Activité suspecte sur nouveau compte',
        CONCAT('Compte créé il y a ', DATEDIFF(NOW(), u.date_creation), ' jours avec ', COUNT(m.id), ' messages envoyés'),
        4
    FROM 
        user u
    JOIN 
        message m ON u.id = m.expediteur
    WHERE 
        u.date_creation > DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY 
        u.id, u.nom, u.email, u.date_creation
    HAVING 
        COUNT(m.id) > 50;
    
    -- Afficher les résultats par ordre de gravité
    SELECT 
        user_id,
        nom_utilisateur,
        email_utilisateur,
        type_anomalie,
        description,
        niveau_gravite,
        date_detection
    FROM 
        temp_anomalies
    ORDER BY 
        niveau_gravite DESC, date_detection DESC;
    
    -- Nettoyer la table temporaire
    DROP TEMPORARY TABLE IF EXISTS temp_anomalies;
END //
DELIMITER ;

-- 10. Procédure pour générer des statistiques de la plateforme
-- (Fournit des statistiques globales et des tendances)
DELIMITER //
CREATE PROCEDURE generer_statistiques_plateforme(IN p_periode VARCHAR(10))
BEGIN
    DECLARE v_date_debut DATE;
    DECLARE v_date_fin DATE;
    
    -- Définir la période d'analyse
    SET v_date_fin = CURDATE();
    
    CASE p_periode
        WHEN 'JOUR' THEN SET v_date_debut = DATE_SUB(v_date_fin, INTERVAL 1 DAY);
        WHEN 'SEMAINE' THEN SET v_date_debut = DATE_SUB(v_date_fin, INTERVAL 1 WEEK);
        WHEN 'MOIS' THEN SET v_date_debut = DATE_SUB(v_date_fin, INTERVAL 1 MONTH);
        WHEN 'TRIMESTRE' THEN SET v_date_debut = DATE_SUB(v_date_fin, INTERVAL 3 MONTH);
        WHEN 'ANNEE' THEN SET v_date_debut = DATE_SUB(v_date_fin, INTERVAL 1 YEAR);
        ELSE SET v_date_debut = DATE_SUB(v_date_fin, INTERVAL 1 MONTH); -- Par défaut: 1 mois
    END CASE;
    
    -- Statistiques globales des utilisateurs
    SELECT 
        'Utilisateurs' AS categorie,
        COUNT(*) AS total,
        SUM(CASE WHEN date_creation BETWEEN v_date_debut AND v_date_fin THEN 1 ELSE 0 END) AS nouveaux,
        SUM(CASE WHEN statut = 'actif' THEN 1 ELSE 0 END) AS actifs,
        SUM(CASE WHEN statut = 'inactif' THEN 1 ELSE 0 END) AS inactifs,
        SUM(CASE WHEN statut = 'desactive' THEN 1 ELSE 0 END) AS desactives,
        ROUND(AVG(TIMESTAMPDIFF(YEAR, date_naissance, CURDATE())), 2) AS age_moyen
    FROM 
        user;
    
    -- Statistiques des messages
    SELECT 
        'Messages' AS categorie,
        COUNT(*) AS total_messages,
        COUNT(DISTINCT expediteur) AS expediteurs_uniques,
        COUNT(DISTINCT destinataire) AS destinataires_uniques,
        COUNT(CASE WHEN date_envoi BETWEEN v_date_debut AND v_date_fin THEN 1 END) AS messages_periode,
        ROUND(AVG(LENGTH(contenu)), 2) AS longueur_moyenne
    FROM 
        message;
    
    -- Statistiques des compétences
    SELECT 
        'Compétences' AS categorie,
        COUNT(DISTINCT c.id) AS total_competences,
        COUNT(DISTINCT uc.user_id) AS utilisateurs_avec_competences,
        ROUND(AVG(sub.nb_competences), 2) AS moyenne_competences_par_utilisateur,
        COUNT(DISTINCT c.categorie) AS categories_distinctes
    FROM 
        competence c
    LEFT JOIN 
        user_competence uc ON c.id = uc.competence_id
    LEFT JOIN (
        SELECT 
            user_id, 
            COUNT(*) AS nb_competences
        FROM 
            user_competence
        GROUP BY 
            user_id
    ) AS sub ON 1=1;
    
    -- Évolution des inscriptions par jour sur la période
    SELECT 
        DATE(date_creation) AS jour,
        COUNT(*) AS nouveaux_utilisateurs
    FROM 
        user
    WHERE 
        date_creation BETWEEN v_date_debut AND v_date_fin
    GROUP BY 
        DATE(date_creation)
    ORDER BY 
        jour;
    
    -- Évolution des messages par jour sur la période
    SELECT 
        DATE(date_envoi) AS jour,
        COUNT(*) AS nouveaux_messages,
        COUNT(DISTINCT expediteur) AS expediteurs_actifs
    FROM 
        message
    WHERE 
        date_envoi BETWEEN v_date_debut AND v_date_fin
    GROUP BY 
        DATE(date_envoi)
    ORDER BY 
        jour;
    
    -- Top 10 des compétences les plus populaires
    SELECT 
        c.nom AS competence,
        c.categorie,
        c.niveau,
        COUNT(uc.user_id) AS nombre_utilisateurs
    FROM 
        competence c
    JOIN 
        user_competence uc ON c.id = uc.competence_id
    GROUP BY 
        c.id, c.nom, c.categorie, c.niveau
    ORDER BY 
        nombre_utilisateurs DESC
    LIMIT 10;
    
    -- Distribution des évaluations
    SELECT 
        FLOOR(note) AS note_arrondie,
        COUNT(*) AS nombre_evaluations,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM evaluation), 2) AS pourcentage
    FROM 
        evaluation
    GROUP BY 
        FLOOR(note)
    ORDER BY 
        note_arrondie;
    
    -- Statistiques de signalements
    SELECT 
        'Signalements' AS categorie,
        COUNT(*) AS total_signalements,
        COUNT(DISTINCT id_signaleur) AS signaleurs_uniques,
        COUNT(DISTINCT id_destinataire) AS destinataires_uniques,
        COUNT(CASE WHEN date_signalement BETWEEN v_date_debut AND v_date_fin THEN 1 END) AS signalements_periode
    FROM 
        report;
END //
DELIMITER ;

-- 11. Procédure pour recommander des connections à double sens
-- (Suggère des utilisateurs qui pourraient être intéressés par une relation mutuelle)
DELIMITER //
CREATE PROCEDURE recommander_connections_mutuelles(IN p_user_id INT, IN p_limit INT)
BEGIN
    -- Vérifier si l'utilisateur existe
    DECLARE user_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO user_existe FROM user WHERE id = p_user_id;
    
    IF user_existe = 0 THEN
        SELECT 'Utilisateur introuvable' AS message;
    ELSE
        -- Trouver les utilisateurs qui suivent l'utilisateur mais que l'utilisateur ne suit pas
        SELECT 
            u.id,
            u.nom,
            u.email,
            (SELECT COUNT(*) FROM user_competence uc1 
             JOIN user_competence uc2 ON uc1.competence_id = uc2.competence_id 
             WHERE uc1.user_id = p_user_id AND uc2.user_id = u.id) AS competences_communes,
            (SELECT GROUP_CONCAT(DISTINCT c.nom ORDER BY c.nom SEPARATOR ', ') 
             FROM competence c 
             JOIN user_competence uc1 ON c.id = uc1.competence_id 
             JOIN user_competence uc2 ON c.id = uc2.competence_id 
             WHERE uc1.user_id = p_user_id AND uc2.user_id = u.id) AS liste_competences_communes,
            'Vous suit déjà' AS raison
        FROM 
            user u
        JOIN 
            follow f ON u.id = f.id_suiveur AND f.id_suivi = p_user_id
        WHERE 
            NOT EXISTS (SELECT 1 FROM follow WHERE id_suiveur = p_user_id AND id_suivi = u.id)
            AND u.statut = 'actif'
        ORDER BY 
            competences_communes DESC
        LIMIT p_limit;
    END IF;
END //
DELIMITER ;

-- 12. Procédure pour analyser la qualité des interactions
-- (Évalue la qualité des échanges entre utilisateurs)
DELIMITER //
CREATE PROCEDURE analyser_qualite_interactions(IN p_user_id INT)
BEGIN
    -- Vérifier si l'utilisateur existe
    DECLARE user_existe INT DEFAULT 0;
    SELECT COUNT(*) INTO user_existe FROM user WHERE id = p_user_id;
    
    IF user_existe = 0 THEN
        SELECT 'Utilisateur introuvable' AS message;
    ELSE
        -- Analyser la qualité des interactions
        SELECT 
            u2.id AS contact_id,
            u2.nom AS contact_nom,
            COUNT(m.id) AS nb_messages_total,
            SUM(CASE WHEN m.expediteur = p_user_id THEN 1 ELSE 0 END) AS messages_envoyes,
            SUM(CASE WHEN m.destinataire = p_user_id THEN 1 ELSE 0 END) AS messages_recus,
            ROUND(AVG(LENGTH(m.contenu)), 2) AS longueur_moyenne_message,
            ROUND(SUM(CASE WHEN m.expediteur = p_user_id THEN LENGTH(m.contenu) ELSE 0 END) / 
                  SUM(CASE WHEN m.expediteur = p_user_id THEN 1 ELSE 0 END), 2) AS longueur_messages_envoyes,
            ROUND(SUM(CASE WHEN m.destinataire = p_user_id THEN LENGTH(m.contenu) ELSE 0 END) / 
                  SUM(CASE WHEN m.destinataire = p_user_id THEN 1 ELSE 0 END), 2) AS longueur_messages_recus,
            ROUND(ABS(SUM(CASE WHEN m.expediteur = p_user_id THEN 1 ELSE 0 END) - 
                      SUM(CASE WHEN m.destinataire = p_user_id THEN 1 ELSE 0 END)) / 
                  COUNT(m.id) * 100, 2) AS desequilibre_pct,
            DATEDIFF(MAX(m.date_envoi), MIN(m.date_envoi)) AS duree_relation_jours,
            ROUND(COUNT(m.id) / NULLIF(DATEDIFF(MAX(m.date_envoi), MIN(m.date_envoi)), 0), 2) AS frequence_messages_par_jour,
            CASE 
                WHEN COUNT(m.id) > 100 THEN 'Relation établie'
                WHEN COUNT(m.id) > 50 THEN 'Relation en développement'
                WHEN COUNT(m.id) > 10 THEN 'Relation occasionnelle'
                ELSE 'Contact récent'
            END AS type_relation
        FROM 
            message m
        JOIN 
            user u2 ON (m.expediteur = u2.id OR m.destinataire = u2.id) AND u2.id != p_user_id
        WHERE 
            (m.expediteur = p_user_id AND m.destinataire = u2.id) OR 
            (m.destinataire = p_user_id AND m.expediteur = u2.id)
        GROUP BY 
            u2.id, u2.nom
        HAVING 
            nb_messages_total > 5
        ORDER BY 
            nb_messages_total DESC;
    END IF;
END //
DELIMITER ;
