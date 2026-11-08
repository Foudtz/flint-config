# Refonte du réseau de la maison

> Bilan établi à partir des 7 documents du projet claude.ai « Refonte réseau » (dossier `claude/`) et de ses instructions. **Le dépôt Git `flint-config` (configs, scripts) n'était pas accessible depuis cette conversation** : aucune mesure Git ni de volume de code n'a pu être faite (voir « Questions pour Alexis »).

## Fiche

| | |
|---|---|
| Nature | Perso (réseau de la maison familiale) [documenté] |
| Période | Plan de référence créé le 25/10/2026, dernière révision (rév. 10) le 05/11/2026 [mesuré : dates des documents du projet]. Échanges préparatoires dès septembre 2026 [à confirmer] |
| Statut | **En cours** : lots 0 à 3 sur 10 terminés (audit, routeur, switchs, firewall), lot 4 entamé ; tout est préparé « sur table », réseau familial pas encore basculé [documenté] |
| Stack | Routeur GL.iNet Flint 2 sous OpenWrt 25.12 (firewall, DHCP, DNS, NTP), switchs HP 1910-48G et ProCurve 2610 PoE, VLAN 802.1Q, Git/GitHub privé, scripts shell et PowerShell, Debian 13 (banc de test), Hyper-V, TrueNAS, Docker (Nginx Proxy Manager, Plex, Jellyfin), Home Assistant, Frigate, automates WAGO, AdGuard Home (prévu) [documenté] |
| Volumétrie clé | 7 VLAN, une quarantaine d'appareils inventoriés, 10 caméras, 28 réservations DHCP nommées, 13 flux autorisés/refusés testés, 10 lots planifiés [documenté] |

## En une phrase pour un non-spécialiste

Découper le réseau de la maison en compartiments étanches (serveurs, caméras, objets connectés, enfants, invités…) pour qu'un appareil peu sûr, comme une caméra chinoise, ne puisse plus atteindre les serveurs ou les PC, sans couper Internet à la famille pendant la transition.

Glossaire :
- **VLAN** : réseau virtuel ; un seul câblage physique, plusieurs réseaux isolés.
- **Firewall / matrice des flux** : tableau de « qui a le droit de parler à qui » ; tout est interdit sauf exception.
- **OpenWrt** : système Linux libre pour routeurs, remplaçant le logiciel du fabricant.
- **DHCP / DNS** : distribution automatique des adresses / annuaire qui traduit les noms en adresses.
- **Trunk** : câble qui transporte plusieurs VLAN entre deux équipements.
- **PoE** : alimentation électrique des caméras par le câble réseau.
- **Home Assistant, WAGO, Frigate** : domotique, automates industriels de la maison, enregistreur vidéo.
- **Reverse proxy (NPM)** : porte d'entrée unique qui publie les applications sur Internet.

## Problème de départ

- Réseau « plat » derrière la box Bouygues : tous les appareils (serveurs, NAS, automates, caméras IP chinoises, objets connectés, consoles des enfants, invités) dans un même réseau, chacun pouvant joindre tous les autres [documenté].
- Wi-Fi de la box insuffisant au rez-de-chaussée, répéteur d'appoint [documenté].
- Adresses IP codées en dur dans de nombreuses configurations (Frigate, Home Assistant, NPM, montages NFS, iSCSI, fichiers `hosts`, automates), sans annuaire de noms [documenté].
- Applications exposées sur Internet directement depuis le réseau plat [documenté].
- Pas de contrôle parental réseau [documenté].
- Contrainte forte : une famille qui ne doit pas être privée d'Internet plus de quelques heures [documenté].

## Ce qui a été réalisé

1. **Audit complet (lot 0)** : inventaire de ~40 appareils avec adresse cible par VLAN, inventaire des flux applicatifs réels (relevés dans les configs HA, Frigate, NPM, Docker, fstab, iSCSI, SMB), relevé de l'exposition Internet, liste de toutes les IP codées en dur à changer avant / pendant / après la bascule, plan de sauvegarde avec checklist J-1 et tests de restauration [documenté : 5 livrables].
2. **Routeur (lot 1)** : remplacement du firmware constructeur par OpenWrt vanilla, 7 VLAN, IPv6 désactivé en interne, administration SSH par clé uniquement, configuration exportée et versionnée dans Git avec secrets masqués [documenté].
3. **Switchs d'occasion (lot 2)** : remise à zéro, mise à jour des firmwares, gestion restreinte au VLAN serveurs, services inutiles coupés (Telnet, SNMP…), plan de ports par blocs de VLAN, spanning tree, plan de brassage du panneau, PoE validé de bout en bout [documenté].
4. **Firewall (lot 3)** : matrice de flux complète en « deny par défaut », DNS et NTP forcés vers le routeur, DNS chiffré (DoT) bloqué, accès à la box réservé aux serveurs, caméras sans Internet, redirections Internet vers le reverse proxy [documenté].
5. **Outillage de sécurité des changements** : script `safe-apply.sh` de retour arrière automatique si la modification n'est pas confirmée à temps ; banc de test (mini-PC Debian avec un espace réseau isolé par VLAN, script `banc.sh`) pour valider la matrice sans toucher au réseau familial [documenté].
6. **Annuaire interne (lot 4, en avance)** : 28 réservations DHCP avec noms DNS sous le domaine `.internal` (réservé ICANN 2024), pour passer les configurations des IP aux noms [documenté].
7. **Wi-Fi** : mesure de couverture (dBm par pièce), décision d'un seul point d'accès supplémentaire au lieu de trois, SSID « Limited » (enfants) déjà en place [documenté].
8. **Plan de bascule** : jour J en fenêtre de quelques heures, ordre des changements, contrôles de validation, retour arrière visé en moins de 30 minutes [documenté].

## Architecture et choix techniques

Pas d'ADR au sens strict, mais un **journal de décisions daté** (9 entrées du 25/10 au 05/11/2026) et une section « Décisions figées » dans le plan [documenté]. Décisions structurantes :

- **Un seul équipement pour routage, firewall, DHCP et DNS** : une seule source de vérité, pas de conflit de serveurs [documenté].
- **Deny par défaut entre zones, exceptions ciblées** (source, destination, port), firewall stateful [documenté].
- **Caméras sans aucun accès Internet**, consultation à distance via les outils de la maison et non les clouds des fabricants [documenté].
- **Objets connectés en mode observation puis restriction** d'après les journaux DNS [documenté].
- **Migration interne découplée du changement de FAI** ; ancienne box conservée comme plan de repli [documenté].
- **Tout configuré et testé sur table avant installation** ; matériel déplacé une seule fois [documenté].
- **Noms DNS plutôt qu'IP** dans les configurations, sauf exceptions justifiées (automates, dépendance au DNS) [documenté].
- **Risque résiduel assumé et documenté** : le serveur exposé sur Internet n'est pas en vraie DMZ ; atténuation prévue au lot 10 [documenté].

Choix « de niveau entreprise » sans obligation dans un contexte domestique [documenté] :
- infrastructure as code légère : configuration exportée, versionnée dans Git, secrets masqués, sauvegarde binaire hors Git ;
- changements risqués protégés par un retour arrière automatique (principe du « commit confirmé ») ;
- environnement de test dédié et tests de non-régression rejouables ;
- administration restreinte à un réseau de gestion, accès par clé, services non utilisés désactivés ;
- inventaire, matrice des flux, plan de bascule avec critère de réussite et objectif de retour arrière chiffré, checklist de sauvegarde et tests de restauration ;
- découpage en lots avec livrables, points ouverts et journal de décisions.

## Chiffres

| Mesure | Valeur | Source |
|---|---|---|
| Documents de projet | 7 fichiers Markdown | [mesuré] liste des documents du projet |
| Volume documentaire | ~30 100 octets (≈ 30 Ko) | [mesuré] statistiques du projet |
| Création du plan / des livrables du lot 0 / du doc lot 2 | 25/10, 30/10, 03/11/2026 | [mesuré] dates de création des documents |
| Révisions du plan de référence | 10 (rév. 10 du 05/11/2026) | [documenté] |
| Entrées du journal de décisions | 9 | [documenté] |
| Lots | 10 au total, 4 terminés (0 à 3), 1 entamé | [documenté] |
| Durée des lots 0 à 3 | ~12 jours calendaires (25/10 → 05/11/2026) | [documenté] |
| VLAN | 7 | [documenté] |
| Appareils inventoriés | une quarantaine (67 entrées brutes dans l'export de la box) | [documenté] |
| Réservations DHCP nommées | 28 | [documenté] |
| Caméras | 10 | [documenté] |
| Tests de matrice depuis le banc | 6 flux prévus OK, 7 flux non prévus refusés, sur 7 VLAN | [documenté] |
| Points ouverts restants | ~25 | [documenté] section 6 du plan |
| Commits Git, jours actifs, lignes de scripts | **Non mesuré** (dépôt `flint-config` inaccessible ici) | — |
| Tests automatisés, CI, linters | Aucun mentionné ; tests manuels scriptés (banc de test) | [documenté] |

## Rôle de l'IA

- **Méthode** [documenté : instructions du projet] : une conversation par lot ; l'IA lit le plan de référence au début, avance d'une ou deux étapes à la fois, donne pour chaque étape la commande exacte, la vérification et le retour arrière, annonce toute coupure possible avec sa durée ; elle ne doit pas deviner (proposer un test en cas de doute) et ne demande jamais de secret ; en fin de lot, elle propose les mises à jour du plan.
- **Ce qu'a fait l'IA** : rédaction des 7 documents (tous dans le dossier `claude/`, préfixe des documents écrits par l'IA [mesuré]), proposition des commandes UCI/CLI, des scripts et de la matrice, synthèse des relevés en inventaires et plans [à confirmer pour la part exacte].
- **Ce qu'a fait Alexis** : cadrage (objectifs, contraintes famille, budget), toutes les décisions datées du journal, exécution physique des commandes et des tests, relevés (exports de la box, configs, mesures Wi-Fi), arbitrages (ex. domaine `.internal`, un seul AP, Plex/Jellyfin en Docker) [documenté pour les décisions ; à confirmer pour le reste].
- **Garde-fous** [documenté] : retour arrière automatique (`safe-apply.sh`), banc de test, config versionnée, secrets hors documents et hors Git, validation sur table avant production, plan de repli (ancienne box).

## Difficultés et apprentissages

- Les ports 1G de la box ne montent pas le lien avec le port 2,5G du routeur → branchement sur le port 2,5G, switch de la maison déplacé [documenté].
- Pertes de lien intermittentes sur le WAN du routeur, encore à diagnostiquer avant le jour J [documenté, point ouvert].
- Switch PoE : interface web inutilisable (exige Java) → gestion en SSH uniquement ; refus de deux adresses du même sous-réseau sur deux VLAN → changement de gestion par chargement atomique d'un fichier de config complet en TFTP [documenté].
- Switch cœur : HTTPS limité à d'anciennes versions de TLS refusées par les navigateurs → HTTP seul, restreint au VLAN de gestion [documenté].
- Switchs d'occasion avec la configuration de l'ancien propriétaire → remises à zéro (dont une sans câble console) [documenté].
- Plan révisé en cours de route : 3 AP réduits à 1 après mesure, blocs de ports rééquilibrés, domaine `home.arpa` remplacé par `internal`, règle « appareil inconnu → Guest » remplacée, test sur 4 mini-PC remplacé par un banc unique en espaces réseau isolés [documenté].
- Risque de « se couper l'accès » en modifiant le firewall à distance → mécanisme de retour arrière automatique, testé avant usage [documenté].

## Compétences démontrées

- **Architecture réseau** : segmentation en 7 zones, plan d'adressage, trunk 802.1Q, spanning tree [documenté : plan, lot 2].
- **Sécurité** : moindre privilège, deny par défaut, isolement des caméras, DNS/NTP forcés, surface d'administration réduite, analyse de risque résiduel (DMZ) [documenté].
- **Conduite du changement sans interruption** : préparation sur table, bascule en fenêtre courte, critères de réussite, retour arrière chiffré [documenté : stratégie de bascule].
- **Gestion de projet** : 10 lots, livrables, journal de décisions, points ouverts suivis et levés [documenté].
- **Audit et cartographie** : inventaire des appareils, des flux et des dépendances cachées (IP en dur) [documenté : lot 0].
- **Industrialisation légère** : config en Git, scripts réutilisables, banc de test rejouable [documenté].
- **Continuité** : plan de sauvegarde, tests de restauration, sauvegardes hors du NAS [documenté].
- **Montée en compétence rapide** sur un domaine nouveau (débutant OpenWrt/VLAN) avec l'IA [documenté : instructions du projet].
- **Documentation** : documents de référence tenus à jour à chaque lot [mesuré : 10 révisions du plan].

## Transposable à l'entreprise

- La méthode « lot = conversation + document de référence relu à chaque fois + proposition de mise à jour en fin de lot » pour piloter un projet technique avec l'IA sans perte de contexte.
- Le cadre de travail imposé à l'IA (étape par étape, vérification et retour arrière systématiques, interdiction de deviner, aucun secret) comme modèle de règles d'usage.
- Le livrable « IP codées en dur » (avant / jour J / après) et la checklist de sauvegarde J-1, applicables à toute migration d'infrastructure.
- Le principe du changement à confirmation avec retour arrière automatique.
- La matrice de flux validée par un banc de test rejouable avant et après la bascule.

## Démontrable

En 2 minutes :
- **Schéma** : les 7 VLAN et les flux autorisés (à dessiner à partir des sections 2 et 3 du plan, sans IP ni noms d'hôtes).
- **Document** : le plan de référence (structure : décisions figées, lots, points ouverts, journal) — à montrer en version anonymisée (retirer l'IP publique, les adresses MAC et les IP).
- **Commande** : `safe-apply.sh arm` puis fermeture de la session → retour automatique ; ou `banc.sh up` puis un flux refusé et un flux autorisé.
- **Git** : l'historique du dépôt `flint-config` (fréquence des exports de config).

À préparer : captures anonymisées, un schéma simple, vérifier que l'historique Git ne contient aucun secret avant de l'afficher.

## Questions pour Alexis

- Accès au dépôt `flint-config` pour mesurer : premier/dernier commit, nombre de commits, jours actifs, lignes des scripts (`safe-apply.sh`, `banc.sh`, `export-config.sh`, `export-flint.ps1`), commits co-signés par une IA.
- Date réelle de début du projet (échanges dès septembre 2026 ?) et temps passé (soirées, week-ends).
- Part exacte de l'IA : scripts écrits par Claude puis relus, ou écrits par toi ? Combien de corrections après test ?
- Motivation principale (sécurité des caméras, Wi-Fi, apprentissage, contrôle parental, préparation du cluster de mini-PC ?).
- Coût du matériel (switchs d'occasion, routeur, baie, AP à venir).
- Résultats d'usage : rien de basculé pour la famille à ce jour ; date visée du jour J.
- Prochaines étapes à citer : AdGuard et contrôle parental (lot 4), Wi-Fi (lot 5), jour J (lot 6).
