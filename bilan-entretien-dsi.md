# Refonte du réseau de la maison

> Bilan établi à partir des 7 documents du projet claude.ai « Refonte réseau » (dossier `claude/`), de ses instructions, du dépôt Git `flint-config` (mesures en lecture seule) et des réponses d'Alexis du 06/11/2026 (marquées [Alexis]).

## Fiche

| | |
|---|---|
| Nature | Perso (réseau de la maison familiale) [documenté] |
| Période | Conception depuis septembre 2026 [Alexis] ; plan de référence créé le 25/10/2026, dernière révision (rév. 10) le 05/11/2026 [mesuré : dates des documents du projet] ; dépôt Git du 29/10 au 05/11/2026 [mesuré : `git log`]. Environ **un mois de travail le soir** [Alexis] |
| Statut | **En cours, bascule imminente** : lots 0 à 3 sur 10 terminés (audit, routeur, switchs, firewall), lot 4 entamé, tout préparé « sur table » ; bascule du réseau familial prévue le 07/11/2026 [Alexis] |
| Stack actuelle | Routeur GL.iNet Flint 2 sous OpenWrt 25.12 (firewall, DHCP, DNS, NTP), switchs HP 1910-48G et ProCurve 2610 PoE, VLAN 802.1Q, Git/GitHub privé, scripts shell et PowerShell, Debian 13 (banc de test), Hyper-V, TrueNAS, Docker (Nginx Proxy Manager, Plex, Jellyfin), Home Assistant, Frigate, automates WAGO, AdGuard Home (prévu) [documenté] |
| Stack future | **Cluster k3s (Kubernetes léger) sur 3 ou 4 mini-PC HP**, pour la haute dispo du reverse proxy et des conteneurs Docker de la maison, et comme entraînement à OpenShift pour le travail ; reporté (mini-PC livrés sans disque) [Alexis] |
| Coût | ~340 € de matériel : baie d'occasion 150 €, 2 switchs d'occasion à 30 € chacun, routeur 130 € [Alexis] ; points d'accès Wi-Fi à venir |
| Volumétrie clé | 7 VLAN, une quarantaine d'appareils inventoriés, 10 caméras, 28 réservations DHCP nommées, 13 flux autorisés/refusés testés, 10 lots planifiés [documenté] ; 8 commits, 24 fichiers versionnés, ~2 100 lignes de configuration et scripts [mesuré] |

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
- **k3s** : version allégée de Kubernetes (la technologie derrière OpenShift), qui répartit des applications sur plusieurs machines pour qu'elles survivent à la panne de l'une d'elles.

## Problème de départ

- Réseau « plat » derrière la box Bouygues : tous les appareils (serveurs, NAS, automates, caméras IP chinoises, objets connectés, consoles des enfants, invités) dans un même réseau, chacun pouvant joindre tous les autres [documenté].
- Wi-Fi de la box insuffisant au rez-de-chaussée, répéteur d'appoint [documenté].
- Adresses IP codées en dur dans de nombreuses configurations (Frigate, Home Assistant, NPM, montages NFS, iSCSI, fichiers `hosts`, automates), sans annuaire de noms [documenté].
- Applications exposées sur Internet directement depuis le réseau plat [documenté].
- Pas de contrôle parental réseau [documenté].
- Toutes les applis Docker de la maison sur une seule machine, sans redondance [Alexis].
- Contrainte forte : une famille qui ne doit pas être privée d'Internet plus de quelques heures [documenté].
- Point de départ personnel : **aucune connaissance préalable** du paramétrage de switchs, de routeurs ou de VLAN [Alexis].

Motivations [Alexis] : découverte, sécurisation du domicile, apprentissage (culture réseau et clustering, utiles au travail avec OpenShift).

## Ce qui a été réalisé

1. **Audit complet (lot 0)** : inventaire de ~40 appareils avec adresse cible par VLAN, inventaire des flux applicatifs réels (relevés dans les configs HA, Frigate, NPM, Docker, fstab, iSCSI, SMB), relevé de l'exposition Internet, liste de toutes les IP codées en dur à changer avant / pendant / après la bascule, plan de sauvegarde avec checklist J-1 et tests de restauration [documenté : 5 livrables].
2. **Routeur (lot 1)** : remplacement du firmware constructeur par OpenWrt vanilla, 7 VLAN, IPv6 désactivé en interne, administration SSH par clé uniquement, configuration exportée et versionnée dans Git avec secrets masqués [documenté ; mesuré : 3 commits « Lot 1 » des 29 et 30/10].
3. **Switchs d'occasion (lot 2)** : remise à zéro, mise à jour des firmwares, gestion restreinte au VLAN serveurs, services inutiles coupés (Telnet, SNMP…), plan de ports par blocs de VLAN, spanning tree, plan de brassage du panneau, PoE validé de bout en bout [documenté ; mesuré : configs des 2 switchs versionnées, dont une version « avant rééquilibrage des blocs » conservée].
4. **Firewall (lot 3)** : matrice de flux complète en « deny par défaut », DNS et NTP forcés vers le routeur, DNS chiffré (DoT) bloqué, accès à la box réservé aux serveurs, caméras sans Internet, redirections Internet vers le reverse proxy [documenté ; mesuré : fichier `firewall` de 629 lignes].
5. **Outillage de sécurité des changements** : script `safe-apply.sh` de retour arrière automatique si la modification n'est pas confirmée à temps ; `wan-watch.sh` de surveillance du lien WAN ; scripts d'export de la config (shell côté routeur, PowerShell côté PC) [mesuré : `scripts/`, `export-flint.ps1`] ; banc de test (mini-PC Debian avec un espace réseau isolé par VLAN, script `banc.sh`) [documenté ; mesuré : script présent dans `scripts/` mais pas encore commité].
6. **Annuaire interne (lot 4, en avance)** : 28 réservations DHCP avec noms DNS sous le domaine `.internal` (réservé ICANN 2024), pour passer les configurations des IP aux noms [documenté].
7. **Wi-Fi** : mesure de couverture (dBm par pièce), décision d'un seul point d'accès supplémentaire au lieu de trois, SSID « Limited » (enfants) déjà en place [documenté].
8. **Plan de bascule** : jour J en fenêtre de quelques heures, ordre des changements, contrôles de validation, retour arrière visé en moins de 30 minutes [documenté] ; exécution prévue le 07/11/2026 [Alexis].

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
- **Préparer la suite** : le réseau segmenté et l'annuaire DNS sont le socle du futur cluster k3s (reverse proxy et conteneurs en haute dispo sur les mini-PC, Home Assistant restant en VM) [Alexis ; documenté : objectifs des mini-PC].

Choix « de niveau entreprise » sans obligation dans un contexte domestique [documenté] :
- infrastructure as code légère : configuration exportée, versionnée dans Git, secrets masqués, archives binaires exclues de Git (`.gitignore` : `*.tar.gz`) [mesuré] ;
- changements risqués protégés par un retour arrière automatique (principe du « commit confirmé ») ;
- environnement de test dédié et tests de non-régression rejouables ;
- administration restreinte à un réseau de gestion, accès par clé, services non utilisés désactivés ;
- inventaire, matrice des flux, plan de bascule avec critère de réussite et objectif de retour arrière chiffré, checklist de sauvegarde et tests de restauration ;
- découpage en lots avec livrables, points ouverts et journal de décisions ; commits nommés par lot [mesuré].

## Chiffres

| Mesure | Valeur | Source |
|---|---|---|
| Durée de travail | ~1 mois de soirées, conception depuis septembre 2026 | [Alexis] |
| Coût matériel | ~340 € (baie 150 €, 2 × switch 30 €, routeur 130 €) | [Alexis] |
| Premier / dernier commit | 29/10/2026 / 05/11/2026 | [mesuré] `git log` |
| Commits | 8 (4 en octobre, 4 en novembre) | [mesuré] `git rev-list --count HEAD`, `git log --date=format:%Y-%m` |
| Jours actifs distincts (Git) | 4 (29/10, 30/10, 03/11, 05/11) | [mesuré] `git log --date=short` |
| Tags / versions | Aucun | [mesuré] `git tag` |
| Fichiers versionnés | 24 | [mesuré] `git ls-files` |
| Lignes de config routeur (UCI OpenWrt) | ~1 300, dont firewall 629, DHCP 263, network 97, liste des paquets 145 | [mesuré] `wc -l` |
| Lignes de config switchs | ~710 (1910 : 282 + version précédente 281 ; 2610 : 146) | [mesuré] `wc -l` |
| Lignes de scripts | 109 (`safe-apply.sh` 51, `export-flint.ps1` 38, `wan-watch.sh` 11, `export-config.sh` 9) | [mesuré] `wc -l` |
| Commits co-signés par une IA | 0 sur 8 (commits faits à la main après validation) | [mesuré] `grep Co-Authored-By` |
| Fichiers d'IA dans le dépôt (CLAUDE.md, AGENTS.md, prompts) | Aucun ; la méthode IA est dans les instructions du projet claude.ai | [mesuré] `git ls-files` |
| README | 1 ligne (titre seul) ; la documentation vit dans le projet claude.ai | [mesuré] |
| Documents de projet | 7 fichiers Markdown, ~30 Ko | [mesuré] statistiques du projet |
| Révisions du plan de référence | 10 (rév. 10 du 05/11/2026) | [documenté] |
| Entrées du journal de décisions | 9 | [documenté] |
| Lots | 10 au total, 4 terminés (0 à 3), 1 entamé | [documenté] |
| VLAN | 7 | [documenté] |
| Appareils inventoriés | une quarantaine (67 entrées brutes dans l'export de la box) | [documenté] |
| Réservations DHCP nommées | 28 | [documenté] |
| Caméras | 10 | [documenté] |
| Tests de matrice depuis le banc | 6 flux prévus OK, 7 flux non prévus refusés, sur 7 VLAN | [documenté] |
| Points ouverts restants | ~25 | [documenté] section 6 du plan |
| Tests automatisés, CI, linters | Aucun ; tests manuels scriptés (banc de test) | [mesuré : rien dans le dépôt] |

## Rôle de l'IA

- **Méthode** [documenté : instructions du projet] : une conversation par lot ; l'IA lit le plan de référence au début, avance d'une ou deux étapes à la fois, donne pour chaque étape la commande exacte, la vérification et le retour arrière, annonce toute coupure possible avec sa durée ; elle ne doit pas deviner (proposer un test en cas de doute) et ne demande jamais de secret ; en fin de lot, elle propose les mises à jour du plan.
- **Ce qu'a fait l'IA** : génération des scripts et des commandes (UCI OpenWrt, CLI des switchs), rédaction des 7 documents de projet (tous dans le dossier `claude/` [mesuré]), proposition de la matrice de flux, synthèse des relevés en inventaires et plans [Alexis ; documenté].
- **Ce qu'a fait Alexis** : cadrage (objectifs, contraintes famille, budget), toutes les décisions datées du journal, **contrôle de chaque script et commande avant exécution**, exécution physique et tests, relevés (exports de la box, configs, mesures Wi-Fi), arbitrages (domaine `.internal`, un seul AP, Plex/Jellyfin en Docker), commits Git [Alexis ; documenté ; mesuré : 8 commits d'un seul auteur, aucun co-signé IA].
- **Effet de levier** : parti de zéro en paramétrage switch / routeur / VLAN, lots 0 à 3 menés en ~12 jours calendaires, sur du temps du soir [Alexis ; documenté].
- **Garde-fous** [documenté] : retour arrière automatique (`safe-apply.sh`), banc de test, config versionnée, secrets hors documents et hors Git, validation sur table avant production, plan de repli (ancienne box).

## Difficultés et apprentissages

- Les ports 1G de la box ne montent pas le lien avec le port 2,5G du routeur → branchement sur le port 2,5G, switch de la maison déplacé [documenté].
- Pertes de lien intermittentes sur le WAN du routeur → script de surveillance `wan-watch.sh` ajouté, diagnostic à finir avant le jour J [documenté ; mesuré].
- Switch PoE : interface web inutilisable (exige Java) → gestion en SSH uniquement ; refus de deux adresses du même sous-réseau sur deux VLAN → changement de gestion par chargement atomique d'un fichier de config complet en TFTP [documenté].
- Switch cœur : HTTPS limité à d'anciennes versions de TLS refusées par les navigateurs → HTTP seul, restreint au VLAN de gestion [documenté].
- Switchs d'occasion avec la configuration de l'ancien propriétaire → remises à zéro (dont une sans câble console) [documenté].
- Plan révisé en cours de route : 3 AP réduits à 1 après mesure, blocs de ports rééquilibrés (ancienne config conservée dans Git [mesuré]), domaine `home.arpa` remplacé par `internal`, règle « appareil inconnu → Guest » remplacée, test sur 4 mini-PC remplacé par un banc unique en espaces réseau isolés [documenté].
- Risque de « se couper l'accès » en modifiant le firewall à distance → mécanisme de retour arrière automatique, testé avant usage [documenté].
- Cluster k3s reporté : 3 des mini-PC livrés sans disque [Alexis].

## Compétences démontrées

- **Architecture réseau** : segmentation en 7 zones, plan d'adressage, trunk 802.1Q, spanning tree [documenté : plan, lot 2].
- **Sécurité** : moindre privilège, deny par défaut, isolement des caméras, DNS/NTP forcés, surface d'administration réduite, analyse de risque résiduel (DMZ) [documenté ; mesuré : firewall de 629 lignes].
- **Conduite du changement sans interruption** : préparation sur table, bascule en fenêtre courte, critères de réussite, retour arrière chiffré [documenté : stratégie de bascule].
- **Gestion de projet** : 10 lots, livrables, journal de décisions, points ouverts suivis et levés [documenté].
- **Audit et cartographie** : inventaire des appareils, des flux et des dépendances cachées (IP en dur) [documenté : lot 0].
- **Industrialisation légère** : config en Git, scripts réutilisables, banc de test rejouable [mesuré : dépôt `flint-config`].
- **Continuité** : plan de sauvegarde, tests de restauration, sauvegardes hors du NAS [documenté].
- **Montée en compétence rapide** sur un domaine totalement nouveau, avec l'IA comme formateur et l'humain comme contrôleur [Alexis ; documenté : instructions du projet].
- **Documentation** : documents de référence tenus à jour à chaque lot [documenté : 10 révisions du plan].
- **Vision** : réseau pensé comme socle du futur cluster k3s, lien direct avec OpenShift au travail [Alexis].

## Transposable à l'entreprise

- La méthode « lot = conversation + document de référence relu à chaque fois + proposition de mise à jour en fin de lot » pour piloter un projet technique avec l'IA sans perte de contexte.
- Le cadre de travail imposé à l'IA (étape par étape, vérification et retour arrière systématiques, interdiction de deviner, aucun secret) comme modèle de règles d'usage ; l'humain reste responsable de chaque commande exécutée.
- Le livrable « IP codées en dur » (avant / jour J / après) et la checklist de sauvegarde J-1, applicables à toute migration d'infrastructure.
- Le principe du changement à confirmation avec retour arrière automatique.
- La matrice de flux validée par un banc de test rejouable avant et après la bascule.
- Le cluster k3s à venir comme laboratoire personnel d'OpenShift (déploiement, haute dispo, reverse proxy) [Alexis].

## Démontrable

En 2 minutes :
- **Schéma** : les 7 VLAN et les flux autorisés (à dessiner à partir des sections 2 et 3 du plan, sans IP ni noms d'hôtes).
- **Document** : le plan de référence (structure : décisions figées, lots, points ouverts, journal) — à montrer en version anonymisée (retirer l'IP publique, les adresses MAC et les IP).
- **Commande** : `safe-apply.sh arm` puis fermeture de la session → retour automatique ; ou `banc.sh up` puis un flux refusé et un flux autorisé.
- **Git** : `git log --oneline` du dépôt `flint-config` (commits par lot, exports de config) ; un `git diff` entre deux exports.
- **Avant / après** : après la bascule du 07/11, une caméra qui ne peut plus joindre ni Internet ni le serveur.

À préparer : captures anonymisées, un schéma simple ; les messages de commit et les configs contiennent des IP internes, donc les flouter ou ne montrer que le résumé ; vérifier qu'aucun secret ne figure dans l'historique avant de l'afficher.

## Questions pour Alexis

- Résultat de la bascule du 07/11 : durée réelle de coupure, retour arrière utilisé ou non, incidents.
- Le script du banc de test est dans `scripts/` mais pas commité : le versionner avant la démo ?
- Ordre de grandeur des corrections : combien de commandes ou scripts proposés par l'IA ont dû être corrigés après test ?
- Cluster k3s : 3 ou 4 nœuds, date visée (après achat des disques ?).
- Prochaines étapes à citer : AdGuard et contrôle parental (lot 4), Wi-Fi (lot 5), bascule (lot 6), puis k3s.
