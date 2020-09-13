# TSP-D SOLVER

![logo](https://github.com/thuillierowein/tspd-solver/blob/master/images/logo/Logo%2B.png)

Ce solveur TSP-D se base essentiellement sur les algorithmes de programmation dynamique A1 (AEP) et A2 (EP) issus respectivement des articles de Agatz et al. [1] et de Poikonen et al. [2]. Articles traitant exclusivement du cas mono-objectif et visant à minimiser la durée totale de parcours (z1).

Notre contribution s'articule donc autour d'une extension des algorithmes A1 et A2 afin d'introduire le cas bi-objectif, ceci via l'introduction d'un objectif secondaire : le temps d'attente total (z2) lié aux différentes opérations impliquant une livraison par drone. Nous noterons respectivement ces nouveaux algorithmes 2A1 et 2A2. Ces deux algorithmes ont été présentés lors de la conférence RAMOO'2020 [3].

Par ailleurs, de multiples instances ont été mises à disposition et sont compatibles avec les différents algorithmes mentionnés ci-dessus.


## Utilisation

### Programme principal

Pour lancer le programme principal, il suffit d'utiliser la commande `include("main.jl")` depuis l'interpréteur Julia et de suivre les différentes instructions.

#### Phase 1 : Choix de l'instance

Ici, il s'agit de choisir une instance parmi les bibliothèques suivantes :

- Agatz et al.
- Poikonen et al.
- Nos instances
- TSPLIB : all_tsp
- TSPLIB : vlsi
- TSPLIB : tnm

Note : Il est également possible de créer une instance sur mesure de manière interactive (voir section correspondante).

##### Exemple 

![choixBibliotheque](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/choixBibliotheque.png)

![choixInstance](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/choixInstance.png)

![caracteristiquesInstance](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/caracteristiquesInstance.png)

![graphique1](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/graphique1.png)

#### Phase 2 : Résolution du TSP

Une fois l'instance choisie, l'utilisateur est invité à choisir un solveur pour résoudre le TSP :
 - Résolution exacte : Concorde 
 - Résolution approchée : Linkern (Lin-Kernighan) 
 
 ##### Exemple 
 
![resolutionTSP](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/resolutionTSP.png)

![detailSolutionTSP](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/detailSolutionTSP.png)

![graphique2](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/graphique2.png)

#### Phase 3 : Résolution du TSP-D

À l'issue de la résolution du TSP, l'utilisateur est invité à choisir parmi les méthodes suivantes pour résoudre le TSP-D :
- Mono-objectif
  - A1 (AEP)
  - A2 (EP)
- Bi-objectif
  - 2A1 
  - 2A2 (en cours...)
  
 ##### Exemple 
  
![resolutionTSPD](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/resolutionTSPD.png)

![detailSolutionTSPD](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/detailSolutionTSPD.png)

![graphique3](https://github.com/thuillierowein/tspd-solver/blob/master/images/exemple/graphique3.png)
 
### Programme secondaire (mode interactif)

Pour lancer le programme secondaire, il suffit d'utiliser la commande `include("main_interactif.jl")` depuis l'interpréteur Julia et de suivre les différentes instructions.
  
Il s'agit d'un mode interactif de résolution du TSP-D via les algorithmes A1 (AEP) et A2 (EP) issus de la littérature.

### Création d'instance sur mesure (notre format)

Pour lancer le programme de création d'instances sur mesure, il suffit d'utiliser la commande `include("main_creation_instance.jl")` depuis l'interpréteur Julia et de cliquer sur la figure à de multiples reprises afin de placer les différents points. Le premier point étant le dépôt, par défaut. 

Une fois les points placés, l'utilisateur est invité à appuyer sur la touche "Entrée" depuis la console afin de valider son choix. Il lui sera alors demandé d'indiquer une vitesse pour le drone et pour le camion, avant de donner un nom à l'instance nouvellement créée. 

Celle-ci sera disponible dans le dossier "instances/nous/bibliotheque_autres/" sous le nom indiqué. Elle sera donc utilisable directement depuis les programmes mentionnés ci-dessus.

Note : Il est possible de créer une instance sur mesure directement depuis l'un des deux programmes principaux ci-dessus, au moment du choix de l'instance.

#### Exemple 



## Références 

[1] Niels Agatz, Paul Bouman, and Marie Schmidt,Optimizationapproaches for the traveling salesman problem with drone,Transportation Science52(2018), no. 4, 965–981.

[2] Stefan Poikonen, Bruce Golden, and Edward A. Wasil,Abranch-and-bound approach to the traveling salesman problem with adrone, INFORMS Journal on Computing31(2019), no. 2, 335–346.

[3] Thuillier Owein, Le Colleter Théo, Gandibleux Xavier (2020, September 17). Bi-Objective Traveling Salesman Problemwith Drone (TSP-D). RAMOO’2020: 7th International Workshop on Recent Advances in Multi-Objective Optimization, Johannes Kepler University Linz, Austria. https://moo.univie.ac.at/ramoo-2020-program/


## License

Ce projet est sous licence ``MIT`` - voir le fichier [LICENSE](LICENSE) pour plus d'informations


