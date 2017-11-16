

-- phpMyAdmin SQL Dump
-- version 4.7.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 14, 2017 at 02:47 PM
-- Server version: 5.6.35
-- PHP Version: 7.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

--
-- Database: `MSQ`
--

-- --------------------------------------------------------

--
-- Table structure for table `commandes`
--

SET FOREIGN_KEY_CHECKS=0; 
drop table if exists societes;
drop table if exists produits ;
drop table if exists contacts;
drop table if exists contrats;
drop table if exists types_utilisateur ;
drop table if exists messages ;
drop table if exists services ;
drop table if exists fonctions ;
drop table if exists contact_projet ;
drop table if exists projets ;
drop table if exists points_livres ;
drop table if exists interventions;
drop table if exists interventions_produits;
drop table if exists installations;
drop table if exists installations_produits;
drop table if exists commandes;
drop table if exists factures;
drop table if exists types_action;
drop procedure if exists solar_panel.logme;
SET FOREIGN_KEY_CHECKS=1; 
CREATE TABLE `commandes` (
  `id` int(11) NOT NULL,
  `id_societe` int(11) NOT NULL,
  `id_installation` int(11) DEFAULT NULL,
  `id_intervention` int(11) DEFAULT NULL,
  `id_fournisseur` int(11) DEFAULT NULL,
  `id_produit` int(11) DEFAULT NULL,
  `quantite` int(11) DEFAULT '0',
  `prix_total_ht` decimal(6,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `contacts`
--

CREATE TABLE `contacts` (
  `id` int(11) NOT NULL,
  `nom` varchar(255) NOT NULL,
  `prenom` varchar(128) NOT NULL,
  `email` varchar(128) NOT NULL,
  `telephone` varchar(16) NOT NULL,
  `id_societe` int(11) DEFAULT NULL,
  `id_fonction` int(11) DEFAULT NULL,
  `id_type_utilisateur` int(11) DEFAULT NULL,
  `archive` tinyint(1) NOT NULL DEFAULT '0',
  primary key (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `contact_projet`
--

CREATE TABLE `contact_projet` (
  `id_contact` int(11) DEFAULT NULL,
  `id_projet` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `contrats`
--

CREATE TABLE `contrats` (
  `id` int(11) NOT NULL,
  `id_societe` int(11) DEFAULT NULL,
  `id_commercial` int(11) DEFAULT NULL,
  `id_point_livre` int(11) DEFAULT NULL,
  `date_signature` date DEFAULT '0000-00-00',
  `montat_total_ht` decimal(6,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Triggers `contrats`
--
DELIMITER $$
CREATE TRIGGER `contrats_BEFORE_INSERT` BEFORE INSERT ON `contrats` FOR EACH ROW BEGIN
    DECLARE nb INT;
    DECLARE dateajout DATE;
    SET dateajout = NOW();
    SET nb = (SELECT COUNT(id) from contrats where id_point_livre=NEW.id_point_livre and date_signature<>'0000-00-00');
    IF NEW.date_signature!='000-00-00' 
    THEN
        SET NEW.date_signature:='000-00-00';
        SET NEW.montat_total_ht := 0;
    END IF;
    INSERT INTO messages (date_creation,titre,message) values (dateajout,'Trigger contrats BEFORE INSERT',CONCAT('Compteur bd: ', nb));
    IF nb > 0 
    THEN
        INSERT INTO messages (date_creation,titre,message) values (dateajout,'Trigger contrats BEFORE INSERT','Réinitialiser date_signature et id_contact');
        SET NEW.date_signature := '0000-00-00';
        SET NEW.montat_total_ht := 0;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `contrats_BEFORE_UPDATE` BEFORE UPDATE ON `contrats` FOR EACH ROW BEGIN
    DECLARE nb INT;
    DECLARE nbprod INT;
    DECLARE dateajout DATE;
    SET dateajout = NOW();
    SET nb = (SELECT COUNT(id) from contrats where id_point_livre=NEW.id_point_livre and date_signature<>'0000-00-00');
    INSERT INTO messages (date_creation,titre,message) values (dateajout,'Trigger contrats BEFORE INSERT',CONCAT('Compteur bd nb contrat signé pour point livré : ', nb));
    IF nb > 0 
    THEN
    INSERT INTO messages (date_creation,titre,message) values (dateajout,'Trigger contrats BEFORE INSERT','Réinitialiser date_signature et id_contact');
        SET NEW.date_signature := '0000-00-00';
        SET NEW.montat_total_ht := 0;
  ELSE
    SET nbprod=(SELECT COUNT(id_produit) from installations_produits WHERE id_contrat=OLD.id);
    INSERT INTO messages (date_creation,titre,message) values (dateajout,'Trigger contrats AFTER UPDATE',CONCAT('Compteur bd nb prod contrat: ', nbprod));
    IF nbprod < 4 
    THEN 
      INSERT INTO messages (date_creation,titre,message) values (dateajout,'Trigger contrats AFTER UPDATE','Pas 4 produits associés !');
      SET NEW.date_signature := '0000-00-00';
      SET NEW.montat_total_ht := 0;
         ELSE
          /*CALL logme("debug",CONCAT(NEW.id,'|',1,'|',NEW.id_point_livre,'|',NEW.date_signature,'|','0000-00-00'));*/
            IF NEW.date_signature != '0000-00-00' AND OLD.date_signature = '0000-00-00'
            THEN 
                CALL creation_installation(NEW.id,1,NEW.id_point_livre,NEW.date_signature,'0000-00-00');
            END IF;
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `factures`
--

CREATE TABLE `factures` (
  `id` int(11) NOT NULL,
  `id_societe` int(11) DEFAULT NULL,
  `id_contact` int(11) DEFAULT NULL,
  `id_installation` int(11) DEFAULT NULL,
  `id_action` int(11) DEFAULT NULL,
  `date_facture` date DEFAULT '0000-00-00',
  `montant_ht` decimal(6,2) DEFAULT '0.00',
  `montant_ttc` decimal(6,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Triggers `factures`
--
DELIMITER $$
CREATE TRIGGER `factures_BEFORE_INSERT` BEFORE INSERT ON `factures` FOR EACH ROW BEGIN
  DECLARE taux DECIMAL(6,2);
  SET taux = (SELECT montant FROM types_action WHERE libelle = 'tva'); 
  IF NEW.montant_ttc != NEW.montant_ht * (1+taux)
    THEN
     SET NEW.montant_ttc := NEW.montant_ht * (1 + taux);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `factures_BEFORE_UPDATE` BEFORE UPDATE ON `factures` FOR EACH ROW BEGIN
    DECLARE taux DECIMAL(6,2);
    SET taux = (SELECT montant FROM types_action WHERE libelle = 'tva'); 
  IF NEW.montant_ttc != NEW.montant_ht * (1+taux)
    THEN
     SET NEW.montant_ttc := NEW.montant_ht * (1 + taux);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `fonctions`
--

CREATE TABLE `fonctions` (
  `id` int(11) NOT NULL,
  `libelle` varchar(255) NOT NULL,
  `id_service` int(11) DEFAULT NULL,
  `archive` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `installations`
--

CREATE TABLE `installations` (
  `id` int(11) NOT NULL,
  `id_point_livre` int(11) DEFAULT NULL,
  `id_societe` int(11) DEFAULT NULL,
  `date_installation` date DEFAULT '0000-00-00',
  `date_visite_technique` date DEFAULT '0000-00-00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `installations_produits`
--

CREATE TABLE `installations_produits` (
  `id_produit` int(11) DEFAULT NULL,
  `id_contrat` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Triggers `installations_produits`
--
DELIMITER $$
CREATE TRIGGER `installations_produits_BEFORE_INSERT` BEFORE INSERT ON `installations_produits` FOR EACH ROW BEGIN
  DECLARE finboucle INT DEFAULT 0;
    DECLARE datesign DATE;
  DECLARE idp INT;
  DECLARE nbprod INT;
  DECLARE curs1 CURSOR FOR 
  SELECT id_produit FROM installations_produits WHERE id_contrat=NEW.id_contrat 
    AND id_produit IN (SELECT id FROM produits WHERE code_produit 
    like  CONCAT(SUBSTRING((SELECT code_produit FROM produits WHERE id=NEW.id_produit),1,3), '%'));
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET finboucle = 1;
    SET nbprod=(SELECT COUNT(id_produit) FROM installations_produits WHERE id_contrat=NEW.id_contrat 
    AND id_produit IN (SELECT id FROM produits WHERE code_produit 
    like  CONCAT(SUBSTRING((SELECT code_produit FROM produits WHERE id=NEW.id_produit),1,3), '%')));
    /*CALL logme('Nb produits installations_produits',nbprod);*/
    IF nbprod > 0 THEN 
    OPEN curs1;
    read_loop: LOOP
      FETCH curs1 INTO idp;
      IF finboucle THEN
        LEAVE read_loop;
      ELSE 
        SET datesign=(SELECT date_signature FROM contrats where id=NEW.id_contrat);
                IF datesign = '0000-00-00' THEN 
          SET NEW.id_contrat = NULL;
                    SET NEW.id_produit = NULL;
                ELSE 
          SET NEW.id_contrat = NULL;
                    SET NEW.id_produit = NULL;
                END IF;
      END IF;
    END LOOP;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `interventions`
--

CREATE TABLE `interventions` (
  `id` int(11) NOT NULL,
  `id_sous_traitant` int(11) DEFAULT NULL,
  `id_installation` int(11) DEFAULT NULL,
  `id_action` int(11) DEFAULT NULL,
  `date_intervention` date DEFAULT '0000-00-00',
  `cloture` tinyint(4) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `interventions_produits`
--

CREATE TABLE `interventions_produits` (
  `id_intervention` int(11) DEFAULT NULL,
  `id_produit` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `date_creation` date DEFAULT NULL,
  `titre` varchar(128) DEFAULT NULL,
  `message` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `points_livres`
--

CREATE TABLE `points_livres` (
  `id` int(11) NOT NULL,
  `adresse` varchar(255) NOT NULL,
  `adresse_complement` varchar(255) DEFAULT NULL,
  `cp` varchar(10) NOT NULL,
  `ville` varchar(255) NOT NULL,
  `pays` varchar(255) DEFAULT 'France',
  `id_contact` int(11) DEFAULT NULL,
  `residence_principale` tinyint(4) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `produits`
--

CREATE TABLE `produits` (
  `id` int(11) NOT NULL,
  `libelle` varchar(45) DEFAULT NULL,
  `code_produit` varchar(45) DEFAULT NULL,
  `prix_ht` decimal(5,2) DEFAULT '0.00',
  `stock` int(11) NOT NULL DEFAULT '0',
  `id_societe` int(11) DEFAULT NULL,
  `archive` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `projets`
--

CREATE TABLE `projets` (
  `id` int(11) NOT NULL,
  `libelle` varchar(255) NOT NULL,
  `description` text,
  `date_debut` date DEFAULT '0000-00-00',
  `archive` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `id` int(11) NOT NULL,
  `libelle` varchar(255) NOT NULL,
  `archive` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `societes`
--

CREATE TABLE `societes` (
  `id` int(11) NOT NULL,
  `raison_sociale` varchar(255) NOT NULL,
  `siret` varchar(14) NOT NULL,
  `numero_tva` varchar(16) NOT NULL,
  `adresse` text,
  `cp` varchar(5) DEFAULT NULL,
  `ville` varchar(255) DEFAULT NULL,
  `archive` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `types_action`
--

CREATE TABLE `types_action` (
  `id` int(11) NOT NULL,
  `montant` decimal(6,2) DEFAULT '0.00',
  `libelle` varchar(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `types_utilisateur`
--

CREATE TABLE `types_utilisateur` (
  `id` int(11) NOT NULL,
  `libelle` varchar(45) DEFAULT NULL,
  `archive` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `commandes`
--
ALTER TABLE `commandes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_commandes_id_societe_idx` (`id_societe`),
  ADD KEY `FK_commandes_id_installation_idx` (`id_installation`),
  ADD KEY `FK_commandes_id_fournisseur_idx` (`id_fournisseur`),
  ADD KEY `FK_commandes_id_intervention_idx` (`id_intervention`),
  ADD KEY `FK_commandes_id_produit_idx` (`id_produit`);

--
-- Indexes for table `contacts`
--


  INSERT INTO `projets` (`id`, `libelle`, `description`, `date_debut`, `archive`) VALUES
(1, 'Projet 1', 'Installation Mobile', '2017-01-20', 0),
(2, 'Projet 2', 'Installation Piscine', '2016-10-12', 0);
INSERT INTO `types_utilisateur` (`id`, `libelle`, `archive`) VALUES
(1, 'Employé', 0),
(2, 'Client', 0),
(3, 'Fournisseur', 0),
(4, 'Sous-traitant', 0);
INSERT INTO `services` (`id`, `libelle`, `archive`) VALUES
(1, 'Direction', 0),
(2, 'Ressources Humaines', 0),
(3, 'Administratif', 0),
(4, 'Informatique', 0),
(5, 'Production', 0),
(6, 'Commercial', 0),
(7, 'Sécurité', 0),
(8, 'Technique', 0);
INSERT INTO `fonctions` (`id`, `libelle`, `id_service`, `archive`) VALUES
(1, 'Directeur(trice) Général', 1, 0),
(2, 'Directeur(trice) Adjoint', 1, 0),
(3, 'Assistant(e)', 1, 0),
(4, 'Directeur(trice) des ressources humaine', 2, 0),
(5, 'Assistant(e)', 2, 0),
(6, 'Conseiller des ressources humaines', 2, 0),
(7, 'Responsable administratif', 3, 0),
(8, 'Assistant(e)', 3, 0),
(9, 'Agent admlinistratif', 3, 0),
(10, 'Directeur(trice) informatique', 4, 0),
(11, 'Technicien(ne) informatique', 4, 0),
(12, 'Responsable production', 5, 0),
(13, 'Ouvrier(ère) spécialisé(s)', 5, 0),
(14, 'Commercial', 6, 0),
(16, 'Agent maintenance', NULL, 0),
(17, 'Technicien de maintenance', 8, 0),
(18, 'Ingénieur', 5, 0);
INSERT INTO `societes` (`id`, `raison_sociale`, `siret`, `numero_tva`, `adresse`, `cp`, `ville`, `archive`) VALUES
(1, 'Solar Panel', '12345678900001', 'FR12345678900001', '20 Avenue du Général de Gaulle', '31100', 'TOULOUSE', 0),
(2, 'Energy Fournitures', '12345678900002', 'FR12345678900002', '10 Rue du président de Kenedy', '75010', 'PARIS', 0),
(3, 'Pro maintenance', '12345678900003', 'FR12345678900003', '40 Rue du Mozart', '69400', 'LYON', 0);
INSERT INTO `contacts` (`id`, `nom`, `prenom`, `email`, `telephone`, `id_societe`, `id_fonction`, `id_type_utilisateur`, `archive`) VALUES
(1, 'Gagné', 'Sidney', 'SGagne@solarpanel.com', '05.61.00.34.12', 1, 1, 1, 0),
(2, 'Louineaux', 'Bertrand', 'BLouineaux@solarpanel.com', '05.61.00.34.13', 1, 2, 1, 0),
(3, 'Cuillerier', 'Brunella', 'BCuillerier@solarpanel.com', '05.61.00.34.14', 1, 3, 1, 0),
(4, 'Baril', 'Léon', 'LBaril@solarpanel.com', '05.61.00.34.15', 1, 4, 1, 0),
(5, 'Parrot', 'Édith', 'EParrot@solarpanel.com', '05.61.00.34.16', 1, 5, 1, 0),
(6, 'Beaudoin', 'Louis', 'LBeaudoin@solarpanel.com', '05.61.00.34.17', 1, 6, 1, 0),
(7, 'Bonsaint', 'Allyriane', 'ABonsaint@solarpanel.com', '05.61.00.34.18', 1, 6, 1, 0),
(8, 'Primeau', 'Arthur', 'APrimeau@solarpanel.com', '05.61.00.34.19', 1, 7, 1, 0),
(9, 'de Brisay', 'Julienne', 'JdeBrisay@solarpanel.com', '05.61.00.34.20', 1, 8, 1, 0),
(10, 'Francoeur', 'Vivienne', 'VFrancoeur@solarpanel.com', '05.61.00.34.21', 1, 9, 1, 0),
(11, 'Quirion', 'Ninette', 'NQuirion@solarpanel.com', '05.61.00.34.22', 1, 18, 1, 0),
(12, 'Brunault', 'Inès', 'IBrunault@solarpanel.com', '05.61.00.34.23', 1, 10, 1, 0),
(13, 'Jolicoeur', 'Burnell', 'BJolicoeur@solarpanel.com', '05.61.00.34.24', 1, 11, 1, 0),
(14, 'Cotuand', 'Norris', 'NCotuand@solarpanel.com', '05.61.00.34.25', 1, 11, 1, 0),
(15, 'Cressac', 'Alfred', 'ACressac@solarpanel.com', '05.61.00.34.26', 1, 12, 1, 0),
(16, 'Sciverit', 'Philip', 'PSciverit@solarpanel.com', '05.61.00.34.27', 1, 13, 1, 0),
(17, 'Jetté', 'Estelle', 'EJette@solarpanel.com', '05.61.00.34.28', 1, 13, 1, 0),
(18, 'Langlois', 'Suzette', 'SLanglois@solarpanel.com', '05.61.00.34.29', 1, 14, 1, 0),
(19, 'Sylvain', 'Millard', 'MSylvain@solarpanel.com', '05.61.00.34.30', 1, 14, 1, 0),
(20, 'Loiselle', 'Beltane', 'BLoiselle@energyfournitures.fr', '01.53.34.08.20', 2, 1, 3, 0),
(21, 'Bourassa', 'Dorene', 'DBourassa@energyfournitures.fr', '01.53.34.08.21', 2, 3, 3, 0),
(22, 'Covillon', 'Raoul', 'RCovillon@energyfournitures.fr', '01.53.34.08.22', 2, 9, 3, 0),
(23, 'Desruisseaux', 'Pensee', 'PDesruisseaux@energyfournitures.fr', '01.53.34.08.23', 2, 11, 3, 0),
(24, 'Cressac', 'Aubrey', 'ACressac@energyfournitures.fr', '01.53.34.08.24', 2, 13, 3, 0),
(25, 'Pitre', 'Pierre', 'PPitre@energyfournitures.fr', '01.53.34.08.25', 2, 13, 3, 0),
(26, 'Fontaine', 'Thérèse', 'TFontaine@energyfournitures.fr', '01.53.34.08.26', 2, 14, 3, 0),
(27, 'Cadieux', 'Desire', 'DCadieux@energyfournitures.fr', '01.53.34.08.27', 2, 16, 3, 0),
(28, 'Brochu', 'Mavise', 'MBrochu@promaintenance.com', '04.37.18.21.10', 3, 1, 4, 0),
(29, 'Marcoux', 'Christabel', 'CMarcoux@energyfournitures.fr', '04.37.18.21.11', 3, 2, 4, 0),
(30, 'Rocher', 'Cinderella', 'CRocher@energyfournitures.fr', '04.37.18.21.12', 3, 17, 4, 0),
(31, 'Grandbois', 'Fleurette', 'GGrandbois@energyfournitures.fr', '04.37.18.21.13', 3, 17, 4, 0),
(32, 'Dennis', 'Curtis', 'CDennis@socc.com', '04.37.18.21.14', 3, NULL, 2, 0),
(33, 'Roy', 'Julien', 'JRoy@socc.com', '04.37.18.21.15', 3, NULL, 2, 0),
(34, 'Laframboise', 'Hélène', '@socc.com', '04.37.18.21.16', 3, NULL, 2, 0),
(35, 'Compagnon', 'Francis', 'FCompagnon@socc.com', '04.37.18.21.17', 3, NULL, 2, 0),
(36, 'Artois', 'Esperanza', 'EArtois@socc.com', '04.37.18.21.18', 3, NULL, 2, 0),
(37, 'Cousteau', 'Alfred', 'ACousteau@socc.com', '04.37.18.21.19', 3, NULL, 2, 0),
(38, 'Lachapelle', 'Ormazd', 'OLachapelle@socc.com', '04.37.18.21.20', 3, NULL, 2, 0),
(39, 'Marseau', 'Margaux', 'MMarseau@socc.com', '04.37.18.21.21', 3, NULL, 2, 0),
(40, 'Saindon', 'Royale', 'RSaindon@socc.com', '04.37.18.21.22', 3, NULL, 2, 0),
(41, 'Metivier', 'Fabrice', 'FMetivier@socc.com', '04.37.18.21.23', 3, NULL, 2, 0),
(42, 'Etoile', 'Charles', 'CEtoile@socc.com', '04.37.18.21.24', 3, NULL, 2, 0),
(43, 'Cinq-Mars', 'Alphonse', 'ACinq-Mars@socc.com', '04.37.18.21.25', 3, NULL, 2, 0),
(44, 'CinqMars', 'Arnaude', 'ACinqMars@socc.com', '04.37.18.21.26', 3, NULL, 2, 0),
(45, 'Fecteau', 'Quincy', 'QFecteau@socc.com', '04.37.18.21.27', 3, NULL, 2, 0),
(46, 'Cressac', 'Danielle', 'DCressac@socc.com', '04.37.18.21.28', 3, NULL, 2, 0);
INSERT INTO `contact_projet` (`id_contact`, `id_projet`) VALUES
(11, 1),
(11, 2);
INSERT INTO `points_livres` (`id`, `adresse`, `adresse_complement`, `cp`, `ville`, `pays`, `id_contact`, `residence_principale`) VALUES
(1, '99, rue des Dunes', NULL, '35400', 'SAINT-MALO', 'France', 32, 1),
(2, '79, avenue de Bouvines', NULL, '89100', 'SENS', 'France', 33, 1),
(3, '54, Rue du Palais', NULL, '91150', 'ETAMPES', 'France', 34, 1),
(4, '33, Place du Jeu de Paume', NULL, '94800', 'VILLEJUIF', 'France', 33, 0),
(5, '60, Rue du Pic', NULL, '75010', 'Paris', 'France', 35, 0);

INSERT INTO `types_action` (`id`, `montant`, `libelle`) VALUES
(1, '0.20', 'tva'),
(2, '430.00', 'installation'),
(3, '270.00', 'maintenance'),
(4, '180.00', 'controle');
INSERT INTO `produits` (`id`, `libelle`, `code_produit`, `prix_ht`, `stock`, `id_societe`, `archive`) VALUES
(1, 'SOLAR PANEL 1', 'PAN01', '199.00', 10, 1, 0),
(2, 'SOLAR PANEL 2', 'PAN02', '299.00', 10, 1, 0),
(3, 'SOLAR PANEL 3', 'PAN03', '399.00', 10, 1, 0),
(4, 'BATTERY Q1', 'BAT01', '170.00', 10, 1, 0),
(5, 'BATTERY Q2', 'BAT02', '249.00', 10, 1, 0),
(6, 'SECURITY BOX 1', 'SEC01', '159.00', 10, 1, 0),
(7, 'KIT MONTAGE', 'KIT01', '99.00', 10, 1, 0),
(8, 'SOLAR PANEL 1', 'PAN01', '69.00', 30, 2, 0),
(9, 'SOLAR PANEL 2', 'PAN02', '99.00', 30, 2, 0),
(10, 'SOLAR PANEL 3', 'PAN03', '139.00', 30, 2, 0),
(11, 'BATTERY Q1', 'BAT01', '55.00', 20, 2, 0),
(12, 'BATTERY Q2', 'BAT02', '79.00', 20, 2, 0),
(13, 'BATTERY Q3', 'BAT03', '99.00', 20, 2, 0),
(14, 'SECURITY BOX 1', 'SEC01', '49.00', 30, 2, 0),
(15, 'SECURITY BOX 2', 'SEC02', '69.00', 30, 2, 0),
(16, 'KIT MONTAGE', 'KIT01', '29.00', 50, 2, 0);
INSERT INTO `installations` (`id`, `id_point_livre`, `id_societe`, `date_installation`, `date_visite_technique`) VALUES
(1, 1, 1, '2017-10-12', '2016-10-12'),
(2, 2, 1, '2016-03-13', '2018-04-14'),
(3, 3, 1, '2016-11-21', '2017-11-21'),
(4, 4, 1, '2016-04-02', '2018-04-02');

INSERT INTO `installations_produits` (`id_produit`, `id_contrat`) VALUES
(1, 1),
(2, 2),
(3, 3),
(3, 4),
(4, 1),
(4, 2),
(4, 4),
(5, 3),
(6, 1),
(6, 2),
(6, 3),
(6, 4),
(7, 1),
(7, 2),
(7, 3),
(7, 4);
INSERT INTO `factures` (`id`, `id_societe`, `id_contact`, `id_installation`, `id_action`, `date_facture`, `montant_ht`, `montant_ttc`) VALUES
(1, 1, 32, 1, 2, '2015-05-10', '1057.00', '1268.40'),
(2, 1, 33, 2, 2, '2016-03-13', '1157.00', '1388.40'),
(3, 1, 34, 3, 2, '2016-11-21', '1336.00', '1603.20'),
(4, 1, 33, 4, 2, '2016-04-02', '1257.00', '1508.40'),
(5, 1, 32, 1, 4, '2017-05-12', '180.00', '216.00'),
(6, 1, 33, 2, 4, '2017-04-14', '180.00', '216.00'),
(7, 1, 33, 4, 4, '2017-04-02', '180.00', '216.00'),
(8, 1, 34, 3, 3, '2017-09-01', '270.00', '324.00');
INSERT INTO `contrats` (`id`, `id_societe`, `id_commercial`, `id_point_livre`, `date_signature`, `montat_total_ht`) VALUES
(1, 1, 18, 1, '2016-04-29', '1057.00'),
(2, 1, 19, 2, '2016-02-22', '1157.00'),
(3, 1, 18, 3, '2016-11-20', '1336.00'),
(4, 1, 19, 4, '2016-03-14', '1257.00');
INSERT INTO `interventions` (`id`, `id_sous_traitant`, `id_installation`, `id_action`, `date_intervention`, `cloture`) VALUES
(1, 3, 1, 2, '2016-05-10', 1),
(2, 3, 2, 2, '2016-03-13', 1),
(3, 3, 3, 2, '2016-04-02', 1),
(4, 3, 4, 2, '2016-11-19', 1),
(5, 3, 1, 4, '2017-05-12', 1),
(6, 3, 2, 4, '2017-04-14', 1),
(7, 3, 4, 4, '2017-04-02', 1),
(8, 3, 1, 3, '2017-09-01', 1);
INSERT INTO `commandes` (`id`, `id_societe`, `id_installation`, `id_intervention`, `id_fournisseur`, `id_produit`, `quantite`, `prix_total_ht`) VALUES
(1, 1, 1, 1, 3, 8, 1, '69.00'),
(2, 1, 1, 1, 3, 11, 1, '55.00'),
(3, 1, 1, 1, 3, 14, 1, '49.00'),
(4, 1, 1, 1, 3, 16, 1, '29.00'),
(5, 1, 2, 2, 3, 9, 1, '99.00'),
(6, 1, 2, 2, 3, 14, 1, '49.00'),
(7, 1, 2, 2, 3, 16, 1, '29.00'),
(8, 1, 2, 2, 3, 11, 1, '55.00'),
(9, 1, 3, 3, 3, 10, 1, '139.00'),
(10, 1, 3, 3, 3, 12, 1, '79.00'),
(11, 1, 3, 3, 3, 14, 1, '49.00'),
(12, 1, 3, 3, 3, 16, 1, '29.00'),
(13, 1, 4, 4, 3, 10, 1, '139.00'),
(14, 1, 4, 4, 3, 11, 1, '55.00'),
(15, 1, 4, 4, 3, 14, 1, '49.00'),
(16, 1, 4, 4, 3, 16, 1, '29.00'),
(17, 1, 3, 8, 3, 14, 1, '49.00');
INSERT INTO `interventions_produits` (`id_intervention`, `id_produit`) VALUES
(1, 1),
(1, 4),
(1, 6),
(1, 7),
(2, 2),
(2, 4),
(2, 6),
(2, 7),
(3, 3),
(3, 5),
(3, 6),
(3, 7),
(4, 3),
(4, 4),
(4, 6),
(4, 7),
(8, 6);