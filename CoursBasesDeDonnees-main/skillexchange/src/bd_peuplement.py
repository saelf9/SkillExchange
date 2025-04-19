import mysql.connector
from mysql.connector import Error
import random
from datetime import datetime, timedelta
import hashlib
from faker import Faker
import os
from dotenv import load_dotenv

load_dotenv()

# Initialiser Faker (avec localisation française)
fake = Faker(['fr_FR'])

# Fonction pour générer un mot de passe hashé
def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

# Listes pour générer des données aléatoires
categories_competences = ["Programmation", "Design", "Marketing", "Communication", "Finance", "Langues", "Management", "Musique", "Sport", "Cuisine"]
competences = {
    "Programmation": ["Python", "Java", "C++", "JavaScript", "PHP", "SQL", "Ruby", "Swift", "Go", "Rust"],
    "Design": ["Photoshop", "Illustrator", "InDesign", "Figma", "Sketch", "UX/UI", "3D Modeling", "Motion Design", "Typography", "Color Theory"],
    "Marketing": ["SEO", "SEM", "Content Marketing", "Social Media", "Email Marketing", "Growth Hacking", "Analytics", "Branding", "CRM", "Copywriting"],
    "Communication": ["Public Speaking", "Writing", "Negotiation", "Presentation", "Networking", "Conflict Resolution", "Leadership", "Team Building", "Listening", "Empathy"],
    "Finance": ["Accounting", "Budgeting", "Financial Analysis", "Investment", "Taxation", "Risk Management", "Banking", "Insurance", "Stock Market", "Cryptocurrency"],
    "Langues": ["Anglais", "Espagnol", "Allemand", "Italien", "Chinois", "Russe", "Japonais", "Arabe", "Portugais", "Néerlandais"],
    "Management": ["Project Management", "Team Management", "Strategic Planning", "Decision Making", "Problem Solving", "Time Management", "Delegation", "Coaching", "Mentoring", "Performance Review"],
    "Musique": ["Piano", "Guitare", "Chant", "Batterie", "Violon", "Composition", "Production", "DJing", "Théorie Musicale", "Harmonie"],
    "Sport": ["Football", "Tennis", "Natation", "Basketball", "Yoga", "Running", "Cyclisme", "Fitness", "Arts Martiaux", "Golf"],
    "Cuisine": ["Pâtisserie", "Cuisine Française", "Cuisine Italienne", "Cuisine Asiatique", "Cuisine Végétarienne", "Boulangerie", "Cocktails", "Cuisine Moléculaire", "Cuisine Fusion", "BBQ"]
}

niveaux = ['debutant', 'intermediaire', 'avance']
raisons_signalement = ["Contenu inapproprié", "Harcèlement", "Spam", "Information trompeuse", "Discours haineux", 
                     "Usurpation d'identité", "Contenu violent", "Fraude", "Violation de la vie privée", "Autre"]

try:
    # Connexion à la base de données
    connection = mysql.connector.connect(
        host=os.getenv("HOST"),
        database=os.getenv("DATABASE"),
        user=os.getenv("USER"),
        password=os.getenv("PASSWORD")
    )
    
    if connection.is_connected():
        cursor = connection.cursor()
        print("Connexion établie à la base de données")
        
        # Désactiver les contraintes de clé étrangère temporairement
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        
        # Vider les tables existantes
        tables = ["supervision", "parent", "report", "message", "follow", "evaluation", 
                 "user_competence", "competence", "user"]
        
        for table in tables:
            cursor.execute(f"TRUNCATE TABLE {table}")
            print(f"Table {table} vidée")
        
        # Réactiver les contraintes de clé étrangère
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        # 1. Insérer des utilisateurs (adultes) - MINIMUM 100 UTILISATEURS
        users_data = []
        
        for i in range(150):  # Créer 150 utilisateurs pour assurer plus de 100 tuples
            nom = fake.last_name()
            prenom = fake.first_name()
            email = fake.email()
            mot_de_passe = hash_password(fake.password())
            # Générer une date de naissance pour un adulte (entre 18 et 70 ans)
            date_naissance = fake.date_of_birth(minimum_age=18, maximum_age=70).strftime('%Y-%m-%d')
            sexe = random.choice(['H', 'F', 'Autre'])
            bio = fake.paragraph(nb_sentences=3)
            telephone = fake.phone_number().replace(' ', '')[:15]  # Limite à 15 caractères
            localisation = fake.city()
            
            users_data.append((f"{prenom} {nom}", email, mot_de_passe, date_naissance, sexe, bio, telephone, localisation))
        
        query = """
        INSERT INTO user (nom, email, mot_de_passe, date_naissance, sexe, bio, telephone, localisation)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.executemany(query, users_data)
        connection.commit()
        print(f"{cursor.rowcount} utilisateurs insérés")
        
        # Récupérer les IDs des utilisateurs insérés
        cursor.execute("SELECT id FROM user")
        user_ids = [row[0] for row in cursor.fetchall()]
        
        # 2. Insérer des compétences
        competences_data = []
        
        for categorie, comp_list in competences.items():
            for comp in comp_list:
                niveau = random.choice(niveaux).strip().lower()
                description = fake.paragraph(nb_sentences=2)
                competences_data.append((comp, description, categorie, niveau))
        
        query = """
        INSERT INTO competence (nom, description, categorie, niveau)
        VALUES (%s, %s, %s, %s)
        """
        
        cursor.executemany(query, competences_data)
        connection.commit()
        print(f"{cursor.rowcount} compétences insérées")
        
        # Récupérer les IDs des compétences insérées
        cursor.execute("SELECT id FROM competence")
        competence_ids = [row[0] for row in cursor.fetchall()]
        
        # 3. Associer les compétences aux utilisateurs
        user_competences_data = []
        
        for user_id in user_ids:
            # Chaque utilisateur a entre 2 et 5 compétences
            for _ in range(random.randint(2, 5)):
                competence_id = random.choice(competence_ids)
                user_competences_data.append((user_id, competence_id))
        
        # Supprimer les doublons (un utilisateur ne peut pas avoir deux fois la même compétence)
        user_competences_data = list(set(user_competences_data))
        
        query = """
        INSERT INTO user_competence (user_id, competence_id)
        VALUES (%s, %s)
        """
        
        cursor.executemany(query, user_competences_data)
        connection.commit()
        print(f"{cursor.rowcount} relations utilisateur-compétence insérées")
        
        # 4. Créer des relations de suivi (follow) - MINIMUM 100 TUPLES
        follow_data = []
        
        # Assurer au moins 300 relations de suivi pour dépasser les 100 tuples
        while len(follow_data) < 300:
            suiveur = random.choice(user_ids)
            suivi = random.choice(user_ids)
            
            # Éviter de se suivre soi-même
            if suiveur != suivi:
                follow_data.append((suiveur, suivi))
        
        # Supprimer les doublons
        follow_data = list(set(follow_data))
        
        query = """
        INSERT INTO follow (id_suiveur, id_suivi)
        VALUES (%s, %s)
        """
        
        cursor.executemany(query, follow_data)
        connection.commit()
        print(f"{cursor.rowcount} relations de suivi insérées")
        
        # 5. Ajouter des messages entre utilisateurs - MINIMUM 100 TUPLES
        messages_data = []
        
        for _ in range(350):  # 350 messages aléatoires pour assurer plus de 100 tuples
            expediteur = random.choice(user_ids)
            destinataire = random.choice(user_ids)
            
            # Éviter d'envoyer des messages à soi-même (pour respecter le trigger)
            if expediteur != destinataire:
                contenu = fake.paragraph(nb_sentences=random.randint(1, 5))
                statut = random.choice(['lu', 'non lu'])
                date_envoi = fake.date_time_between(start_date='-30d', end_date='now')
                
                messages_data.append((expediteur, destinataire, contenu, statut, date_envoi))
        
        query = """
        INSERT INTO message (expediteur, destinataire, contenu, statut, date_envoi)
        VALUES (%s, %s, %s, %s, %s)
        """
        
        cursor.executemany(query, messages_data)
        connection.commit()
        print(f"{cursor.rowcount} messages insérés")
        
        # Récupérer les IDs des messages insérés
        cursor.execute("SELECT id FROM message")
        message_ids = [row[0] for row in cursor.fetchall()]
        
        # 6. Ajouter des évaluations entre utilisateurs
        evaluations_data = []
        
        for _ in range(200):  # 200 évaluations aléatoires
            utilisateur_evalue = random.choice(user_ids)
            evaluateur = random.choice(user_ids)
            
            # Éviter l'auto-évaluation (pour respecter le trigger)
            if utilisateur_evalue != evaluateur:
                note = random.randint(1, 5)
                commentaire = fake.paragraph(nb_sentences=2)
                
                evaluations_data.append((utilisateur_evalue, evaluateur, note, commentaire))
        
        query = """
        INSERT INTO evaluation (utilisateur_evalue, evaluateur, note, commentaire)
        VALUES (%s, %s, %s, %s)
        """
        
        cursor.executemany(query, evaluations_data)
        connection.commit()
        print(f"{cursor.rowcount} évaluations insérées")
        
        # 7. Ajouter des signalements (reports) avec précaution
        # Ne pas ajouter plus de 5 signalements par utilisateur pour éviter la désactivation automatique
        reports_data = []
        signalement_count = {}  # Pour suivre le nombre de signalements par utilisateur
        
        for _ in range(100):  # 100 signalements potentiels
            signaleur = random.choice(user_ids)
            destinataire = random.choice(user_ids)
            
            # Éviter de se signaler soi-même et limiter à 4 signalements par utilisateur
            if signaleur != destinataire:
                # Initialiser le compteur si nécessaire
                if destinataire not in signalement_count:
                    signalement_count[destinataire] = 0
                
                # Vérifier si l'utilisateur a moins de 5 signalements
                if signalement_count[destinataire] < 4:  # Limite à 4 pour éviter le seuil de 5
                    signalement_count[destinataire] += 1
                    
                    # 50% des signalements concernent un message, 50% un utilisateur directement
                    if random.random() < 0.5 and message_ids:
                        message_id = random.choice(message_ids)
                        raison = random.choice(raisons_signalement)
                        reports_data.append((signaleur, destinataire, message_id, raison))
                    else:
                        raison = random.choice(raisons_signalement)
                        reports_data.append((signaleur, destinataire, None, raison))
        
        query = """
        INSERT INTO report (id_signaleur, id_destinataire, id_message, raison)
        VALUES (%s, %s, %s, %s)
        """
        
        cursor.executemany(query, reports_data)
        connection.commit()
        print(f"{cursor.rowcount} signalements insérés")
        
        # 8. Ajouter des parents
        parents_data = []
        
        for i in range(40):  # 40 parents
            email = fake.email()
            parents_data.append((email,))
        
        query = """
        INSERT INTO parent (email)
        VALUES (%s)
        """
        
        cursor.executemany(query, parents_data)
        connection.commit()
        print(f"{cursor.rowcount} parents insérés")
        
        # Récupérer les IDs des parents insérés
        cursor.execute("SELECT id FROM parent")
        parent_ids = [row[0] for row in cursor.fetchall()]
        
        # 9. Associer des parents à des utilisateurs (supervision)
        supervision_data = []
        
        for parent_id in parent_ids:
            # Chaque parent supervise entre 1 et 3 utilisateurs
            for _ in range(random.randint(1, 3)):
                user_id = random.choice(user_ids)
                supervision_data.append((parent_id, user_id))
        
        # Supprimer les doublons
        supervision_data = list(set(supervision_data))
        
        query = """
        INSERT INTO supervision (parent_id, user_id)
        VALUES (%s, %s)
        """
        
        cursor.executemany(query, supervision_data)
        connection.commit()
        print(f"{cursor.rowcount} relations de supervision insérées")
        
        # Vérifier les cardinalités des relations pour s'assurer qu'au moins deux ont plus de 100 tuples
        cursor.execute("SELECT COUNT(*) FROM user")
        user_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM message")
        message_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM follow")
        follow_count = cursor.fetchone()[0]
        
        print("\nCardinalités finales:")
        print(f"Table user: {user_count} tuples")
        print(f"Table message: {message_count} tuples")
        print(f"Table follow: {follow_count} tuples")
        
        if user_count >= 100 and message_count >= 100 and follow_count >= 100:
            print("SUCCÈS: Au moins deux relations ont une cardinalité d'au moins 100 tuples!")
        else:
            print("ATTENTION: La condition de cardinalité n'est peut-être pas respectée.")
        
        print("Population de la base de données terminée avec succès!")

except Error as e:
    print(f"Erreur lors de la connexion à MySQL: {e}")

finally:
    if connection.is_connected():
        cursor.close()
        connection.close()
        print("Connexion à MySQL fermée")